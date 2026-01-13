import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../models/payment.dart';
import '../widgets/add_payment_dialog.dart';
import '../utils/currency_formatter.dart';
import 'payment_detail_screen.dart';

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
      final response = await Supabase.instance.client
          .from('payments')
          .select()
          .eq('debt_id', widget.debt.id);
      _payments = (response as List).map((json) => Payment.fromJson(json)).toList();
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

  Future<void> _deletePayment(String paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus pembayaran ini?'),
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
        await Supabase.instance.client
            .from('payments')
            .delete()
            .eq('id', paymentId);
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
    final totalPaid = _payments.fold(0.0, (sum, payment) => sum + payment.jumlahBayar);
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    children: [
                      Text(
                        'Sisa',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        formatCurrency(remaining),
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
                                    builder: (context) => PaymentDetailScreen(payment: payment),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formatCurrency(payment.jumlahBayar),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(payment.tanggalBayar),
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (payment.fotoUrl != null)
                                          const Icon(Icons.image, color: Colors.green)
                                        else
                                          const Icon(Icons.image_not_supported, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () => _deletePayment(payment.id),
                                          icon: const Icon(Icons.delete, color: Colors.red),
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