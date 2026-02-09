// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

Widget buildTelegramImageView({
  required String url,
  required double height,
  required BorderRadius borderRadius,
  required BoxFit fit,
  VoidCallback? onTap,
}) {
  final viewType =
      'telegram-img-${url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';

  ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final image = html.ImageElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _toCssObjectFit(fit)
      ..style.cursor = onTap != null ? 'pointer' : 'default';
    if (onTap != null) {
      image.onClick.listen((_) => onTap());
      image.onTouchStart.listen((_) => onTap());
    }
    return image;
  });

  return ClipRRect(
    borderRadius: borderRadius,
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: HtmlElementView(viewType: viewType),
    ),
  );
}

String _toCssObjectFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.cover:
      return 'cover';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitHeight:
      return 'scale-down';
    case BoxFit.fitWidth:
      return 'scale-down';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
