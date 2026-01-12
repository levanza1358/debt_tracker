import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../widgets/add_debt_dialog.dart';
import 'payment_screen.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  List<Debt> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDebts();
  }

  Future<void> _fetchDebts() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.from('debts').select();
      _debts = (response as List).map((json) => Debt.fromJson(json)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<double> _getTotalPayments(String debtId) async {
    try {
      final response = await Supabase.instance.client
          .from('payments')
          .select('jumlah_bayar')
          .eq('debt_id', debtId);
      final payments = (response as List<dynamic>).map<double>((json) {
        final data = json as Map<String, dynamic>;
        return (data['jumlah_bayar'] as num).toDouble();
      }).toList();
      return payments.fold<double>(0.0, (double sum, double amount) => sum + amount);
    } catch (e) {
      return 0.0;
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
      MaterialPageRoute(
        builder: (context) => PaymentScreen(debt: debt),
      ),
    ).then((_) => _fetchDebts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Hutang'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debts.isEmpty
              ? const Center(child: Text('Belum ada hutang'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _debts.length,
                  itemBuilder: (context, index) {
                    final debt = _debts[index];
                    return FutureBuilder<double>(
                      future: _getTotalPayments(debt.id),
                      builder: (context, snapshot) {
                        final totalPaid = snapshot.data ?? 0.0;
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
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                      ),
                                      if (isFullyPaid)
                                        const Icon(Icons.check_circle, color: Colors.green)
                                      else
                                        const Icon(Icons.pending, color: Colors.orange),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tanggal: ${DateFormat('dd/MM/yyyy').format(debt.tanggalHutang)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  if (debt.deskripsi != null && debt.deskripsi!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Deskripsi: ${debt.deskripsi}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Hutang',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Rp ${debt.jumlahHutang.toStringAsFixed(0)}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sudah Dibayar',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Rp ${totalPaid.toStringAsFixed(0)}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sisa',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Rp ${remaining.toStringAsFixed(0)}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: remaining > 0 ? Colors.red : Colors.green,
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