import 'package:flutter/material.dart';
import 'telegram_image_view_impl.dart' as impl;

class TelegramImageView extends StatelessWidget {
  const TelegramImageView({
    super.key,
    required this.url,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.cover,
    this.onTap,
  });

  final String url;
  final double height;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return impl.buildTelegramImageView(
      url: url,
      height: height,
      borderRadius: borderRadius,
      fit: fit,
      onTap: onTap,
    );
  }
}
