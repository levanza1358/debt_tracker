import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/input_parser.dart';

class AddDebtDialog extends StatefulWidget {
  const AddDebtDialog({super.key});

  @override
  State<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _jumlahController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _deskripsiController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _jumlahController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      final jumlahHutang = parseRupiahInput(_jumlahController.text);
      if (jumlahHutang == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah hutang tidak valid')),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('debts').add({
          'nama_hutang': _namaController.text,
          'jumlah_hutang': jumlahHutang,
          'tanggal_hutang': _selectedDate.toIso8601String().split('T').first,
          'deskripsi': _deskripsiController.text.isEmpty
              ? null
              : _deskripsiController.text,
        });
        if (mounted) {
          Navigator.of(context).pop();
        }
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
    return AlertDialog(
      title: const Text('Tambah Hutang Baru'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Hutang',
                hintText: 'Contoh: Hutang ke Ahmad',
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Nama hutang harus diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Hutang (Rp)',
                hintText: 'Contoh: 500000',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah hutang harus diisi';
                }
                if (parseRupiahInput(value) == null) {
                  return 'Format nominal tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Ubah'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deskripsiController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Catatan tambahan...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saveDebt,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
