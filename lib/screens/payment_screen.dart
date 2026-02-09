import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../models/payment.dart';
import '../widgets/add_payment_dialog.dart';
import '../utils/currency_formatter.dart';
import 'payment_detail_screen.dart';

const _deletePin = String.fromEnvironment('DELETE_PIN', defaultValue: '3351');

class PaymentScreen extends StatefulWidget {
  final Debt debt;

  const PaymentScreen({super.key, required this.debt});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _isLoading = true);
    try {
      final response = await FirebaseFirestore.instance
          .collection('payments')
          .where('debt_id', isEqualTo: widget.debt.id)
          .get();
      _payments = response.docs
          .map((doc) => Payment.fromJson({'id': doc.id, ...doc.data()}))
          .toList()
        ..sort((a, b) {
          final dateCompare = b.tanggalBayar.compareTo(a.tanggalBayar);
          if (dateCompare != 0) return dateCompare;
          final aCreated = a.createdAt ?? a.tanggalBayar;
          final bCreated = b.createdAt ?? b.tanggalBayar;
          return bCreated.compareTo(aCreated);
        });
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

  void _addPayment() {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(debtId: widget.debt.id),
    ).then((_) => _fetchPayments());
  }

  Future<void> _deletePayment(Payment payment) async {
    // PIN verification first
    final pinVerified = await showDialog<bool>(
      context: context,
      builder: (context) => const _PinDialog(expectedPin: _deletePin),
    );

    if (pinVerified != true) {
      return; // Cancel deletion if PIN is wrong or cancelled
    }
    if (!mounted) return;

    // Confirmation dialog after PIN verification
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content:
            const Text('Apakah Anda yakin ingin menghapus pembayaran ini?'),
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
    if (!mounted) return;

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(payment.id)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran berhasil dihapus')),
          );
        }
        _fetchPayments();
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
    final totalPaid =
        _payments.fold(0.0, (total, payment) => total + payment.jumlahBayar);
    final remaining = widget.debt.jumlahHutang - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran - ${widget.debt.namaHutang}'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Hutang',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        formatCurrency(widget.debt.jumlahHutang),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Dibayar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        formatCurrency(totalPaid),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Sisa',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        formatCurrency(remaining),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: remaining > 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                    ? const Center(child: Text('Belum ada pembayaran'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return Card(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PaymentDetailScreen(payment: payment),
                                  ),
                                ).then((_) => _fetchPayments());
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formatCurrency(payment.jumlahBayar),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd/MM/yyyy')
                                                .format(payment.tanggalBayar),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (payment.fotoUrl != null)
                                          const Icon(Icons.image,
                                              color: Colors.green)
                                        else
                                          const Icon(Icons.image_not_supported,
                                              color: Colors.grey),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () =>
                                              _deletePayment(payment),
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          tooltip: 'Hapus Pembayaran',
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPayment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.expectedPin});

  final String expectedPin;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verifikasi PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Masukkan PIN untuk menghapus pembayaran:'),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'PIN',
              hintText: '4 digit PIN',
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_pinController.text == widget.expectedPin) {
              Navigator.of(context).pop(true);
            } else {
              setState(() {
                _errorMessage = 'PIN salah! Coba lagi.';
                _pinController.clear();
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Verifikasi'),
        ),
      ],
    );
  }
}
