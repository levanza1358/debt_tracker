import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../widgets/add_debt_dialog.dart';
import 'payment_screen.dart';
import '../utils/currency_formatter.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  List<Debt> _debts = [];
  Map<String, double> _paymentTotals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDebts();
  }

  Future<void> _fetchDebts() async {
    setState(() => _isLoading = true);
    try {
      final debtsFuture = FirebaseFirestore.instance.collection('debts').get();
      final paymentsFuture =
          FirebaseFirestore.instance.collection('payments').get();
      final debtsResponse = await debtsFuture;
      final paymentsResponse = await paymentsFuture;

      _debts = debtsResponse.docs
          .map((doc) => Debt.fromJson({'id': doc.id, ...doc.data()}))
          .toList()
        ..sort((a, b) => b.tanggalHutang.compareTo(a.tanggalHutang));

      final totals = <String, double>{};
      for (final item in paymentsResponse.docs) {
        final data = item.data();
        final debtId = data['debt_id'] as String?;
        final amount = (data['jumlah_bayar'] as num?)?.toDouble() ?? 0.0;
        if (debtId == null) continue;
        totals[debtId] = (totals[debtId] ?? 0.0) + amount;
      }
      _paymentTotals = totals;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addDebt() {
    showDialog(
      context: context,
      builder: (context) => const AddDebtDialog(),
    ).then((_) => _fetchDebts());
  }

  void _viewPayments(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen(debt: debt)),
    ).then((_) => _fetchDebts());
  }

  Future<void> _deleteDebt(String debtId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus hutang ini? Semua pembayaran terkait juga akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final paymentSnapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('debt_id', isEqualTo: debtId)
            .get();

        for (final doc in paymentSnapshot.docs) {
          final fotoUrl = doc.data()['foto_url'] as String?;
          if (fotoUrl != null && fotoUrl.isNotEmpty) {
            try {
              await FirebaseStorage.instance.refFromURL(fotoUrl).delete();
            } catch (_) {}
          }
          await doc.reference.delete();
        }

        await FirebaseFirestore.instance
            .collection('debts')
            .doc(debtId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hutang berhasil dihapus')),
          );
        }
        _fetchDebts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Hutang')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
              ? const Center(child: Text('Belum ada hutang'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _debts.length,
                  itemBuilder: (context, index) {
                    final debt = _debts[index];
                    final totalPaid = _paymentTotals[debt.id] ?? 0.0;
                    final remaining = debt.jumlahHutang - totalPaid;
                    final isFullyPaid = remaining <= 0;

                    return Card(
                      child: InkWell(
                        onTap: () => _viewPayments(debt),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      debt.namaHutang,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (isFullyPaid)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      else
                                        const Icon(
                                          Icons.pending,
                                          color: Colors.orange,
                                        ),
                                      IconButton(
                                        onPressed: () => _deleteDebt(debt.id),
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Hapus Hutang',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tanggal: ${DateFormat('dd/MM/yyyy').format(debt.tanggalHutang)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (debt.deskripsi != null &&
                                  debt.deskripsi!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Deskripsi: ${debt.deskripsi}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Hutang',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          formatCurrency(debt.jumlahHutang),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sudah Dibayar',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          formatCurrency(totalPaid),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sisa',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Text(
                                          formatCurrency(remaining),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: remaining > 0
                                                    ? Colors.red
                                                    : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDebt,
        child: const Icon(Icons.add),
      ),
    );
  }
}
