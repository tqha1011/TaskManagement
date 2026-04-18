import 'package:flutter/material.dart';

extension AdaptiveColorExtension on Color {
  Color toAdaptiveColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return this;

    return Color.lerp(this, Colors.white, 0.4) ?? this;
  }
}

