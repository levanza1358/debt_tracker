import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AddPaymentDialog extends StatefulWidget {
  final String debtId;

  const AddPaymentDialog({super.key, required this.debtId});

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  XFile? _imageFile;
  bool _isUploading = false;

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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(imageFile.path);
      await Supabase.instance.client.storage
          .from('debt_photos')
          .upload(fileName, file);
      final publicUrl = Supabase.instance.client.storage
          .from('debt_photos')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      String? fotoUrl;
      if (_imageFile != null) {
        fotoUrl = await _uploadImage(_imageFile!);
      }
      try {
        await Supabase.instance.client.from('payments').insert({
          'debt_id': widget.debtId,
          'jumlah_bayar': double.parse(_jumlahController.text),
          'tanggal_bayar': _selectedDate.toIso8601String().split('T').first,
          'foto_url': fotoUrl,
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
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Pembayaran'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Bayar (Rp)',
                hintText: 'Contoh: 100000',
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Jumlah bayar harus diisi' : null,
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: _imageFile != null ? Colors.green : Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? (kIsWeb
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imageFile!.path),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ))
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(_imageFile != null ? 'Ganti Bukti Bayar' : 'Pilih Bukti Bayar'),
                  ),
                ),
              ],
            ),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bukti pembayaran akan diupload',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: _savePayment,
                child: const Text('Simpan'),
              ),
      ],
    );
  }
}