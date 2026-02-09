import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../services/telegram_service.dart';
import '../utils/input_parser.dart';

class EditPaymentDialog extends StatefulWidget {
  const EditPaymentDialog({super.key, required this.payment});

  final Payment payment;

  @override
  State<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  late DateTime _selectedDate;
  XFile? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _jumlahController.text = widget.payment.jumlahBayar.toStringAsFixed(0);
    _selectedDate = widget.payment.tanggalBayar;
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    final caption =
        'Edit bukti pembayaran\nDebt ID: ${widget.payment.debtId}\nPayment ID: ${widget.payment.id}\nTanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}';
    return TelegramService.uploadPhotoToGroup(
        file: imageFile, caption: caption);
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate()) return;

    final jumlahBayar = parseRupiahInput(_jumlahController.text);
    if (jumlahBayar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah bayar tidak valid')),
      );
      return;
    }

    setState(() => _isSaving = true);
    String? fotoUrl = widget.payment.fotoUrl;

    if (_imageFile != null) {
      if (!TelegramService.isConfigured) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Telegram belum dikonfigurasi. Isi TELEGRAM_BOT_TOKEN dan TELEGRAM_CHAT_ID.',
              ),
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }
      fotoUrl = await _uploadImage(_imageFile!);
      if (fotoUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Upload foto ke Telegram gagal. Cek bot token, chat id, dan izin bot di grup.',
              ),
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.payment.id)
          .update({
        'jumlah_bayar': jumlahBayar,
        'tanggal_bayar': _selectedDate.toIso8601String().split('T').first,
        'foto_url': fotoUrl,
      });

      if (!mounted) return;
      Navigator.of(context).pop(
        Payment(
          id: widget.payment.id,
          debtId: widget.payment.debtId,
          jumlahBayar: jumlahBayar,
          tanggalBayar: _selectedDate,
          createdAt: widget.payment.createdAt,
          fotoUrl: fotoUrl,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Pembayaran'),
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah bayar harus diisi';
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _imageFile != null ? Colors.green : Colors.grey,
                    ),
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
                      : Icon(
                          widget.payment.fotoUrl != null
                              ? Icons.image
                              : Icons.image_not_supported,
                          color: widget.payment.fotoUrl != null
                              ? Colors.blue
                              : Colors.grey,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                      _imageFile != null || widget.payment.fotoUrl != null
                          ? 'Ganti Bukti Bayar'
                          : 'Pilih Bukti Bayar',
                    ),
                  ),
                ),
              ],
            ),
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Foto baru akan dikirim ke grup Telegram',
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
        _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: _saveEdit,
                child: const Text('Simpan Perubahan'),
              ),
      ],
    );
  }
}
