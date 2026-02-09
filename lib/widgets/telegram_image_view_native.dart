import 'package:flutter/material.dart';

Widget buildTelegramImageView({
  required String url,
  required double height,
  required BorderRadius borderRadius,
  required BoxFit fit,
  VoidCallback? onTap,
}) {
  final image = ClipRRect(
    borderRadius: borderRadius,
    child: Image.network(
      url,
      width: double.infinity,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: borderRadius,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Gagal memuat gambar'),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (onTap == null) return image;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: image,
    ),
  );
}
