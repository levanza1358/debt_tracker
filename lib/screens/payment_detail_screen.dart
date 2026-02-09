import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment.dart';
import '../utils/currency_formatter.dart';
import '../widgets/edit_payment_dialog.dart';
import '../widgets/telegram_image_view.dart';

class PaymentDetailScreen extends StatefulWidget {
  final Payment payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  late Payment _payment;

  @override
  void initState() {
    super.initState();
    _payment = widget.payment;
  }

  Future<void> _editPayment() async {
    final updatedPayment = await showDialog<Payment>(
      context: context,
      builder: (context) => EditPaymentDialog(payment: _payment),
    );
    if (updatedPayment != null && mounted) {
      setState(() => _payment = updatedPayment);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil diperbarui')),
      );
    }
  }

  Future<void> _openFullScreenImage(String imageUrl) async {
    debugPrint('[PaymentDetail] openFullScreenImage called. url=$imageUrl');
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImagePage(imageUrl: imageUrl),
      ),
    );
    debugPrint('[PaymentDetail] full screen image page closed.');
  }

  @override
  Widget build(BuildContext context) {
    final photoReference = _payment.fotoUrl;
    final hasTelegramLink =
        photoReference != null && photoReference.startsWith('https://t.me/');
    final hasTelegramFileUrl = photoReference != null &&
        photoReference.startsWith('https://api.telegram.org/file/');
    final telegramUploadedOnly = photoReference != null &&
        photoReference.startsWith('telegram_uploaded:');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        actions: [
          IconButton(
            onPressed: _editPayment,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Pembayaran',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Pembayaran',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.attach_money),
                        const SizedBox(width: 8),
                        Text(
                          'Jumlah: ${formatCurrency(_payment.jumlahBayar)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(
                          'Tanggal: ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_payment.tanggalBayar)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (photoReference != null) ...[
              const SizedBox(height: 24),
              Text(
                'Bukti Pembayaran',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: hasTelegramLink
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.telegram),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      'Bukti pembayaran dikirim ke grup Telegram'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(photoReference);
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Buka di Telegram'),
                            ),
                          ],
                        )
                      : telegramUploadedOnly
                          ? const Row(
                              children: [
                                Icon(Icons.telegram),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Foto sudah terkirim ke grup Telegram, tapi link pesan tidak tersedia.',
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      debugPrint(
                                        '[PaymentDetail] image tapped. '
                                        'url=$photoReference '
                                        'hasTelegramFileUrl=$hasTelegramFileUrl',
                                      );
                                      _openFullScreenImage(photoReference);
                                    },
                                    child: hasTelegramFileUrl
                                        ? TelegramImageView(
                                            url: photoReference,
                                            height: 200,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () {
                                              debugPrint(
                                                '[PaymentDetail] telegram image clicked via web element. '
                                                'url=$photoReference',
                                              );
                                              _openFullScreenImage(
                                                  photoReference);
                                            },
                                          )
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.network(
                                              photoReference,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const SizedBox(
                                                  height: 200,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height: 200,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.broken_image,
                                                          size: 48,
                                                          color: Colors.grey,
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                            'Gagal memuat gambar'),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.image),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Foto bukti pembayaran (tap untuk perbesar)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembayaran ini bisa diedit jika ada kesalahan nominal, tanggal, atau foto bukti.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  const _FullScreenImagePage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final isTelegramFileUrl =
        imageUrl.startsWith('https://api.telegram.org/file/');
    debugPrint(
      '[FullScreenImagePage] build. '
      'isTelegramFileUrl=$isTelegramFileUrl url=$imageUrl',
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto Bukti'),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) => InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: isTelegramFileUrl
                ? TelegramImageView(
                    url: imageUrl,
                    height: constraints.maxHeight,
                    borderRadius: BorderRadius.zero,
                    fit: BoxFit.contain,
                  )
                : Image.network(
                    imageUrl,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Gagal memuat gambar.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
