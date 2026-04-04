import 'package:flutter/material.dart';

/// Sora de brand tokens (aligned with `config.py` theme colors).
abstract final class BrandColors {
  static const Color primaryPink = Color(0xFFE8B7C5);
  static const Color primaryGreen = Color(0xFF1F3D2B);
  static const Color cream = Color(0xFFFDFBF7);
  static const Color darkBg = Color(0xFF0D1A12);
  static const Color softWhite = Color(0xFFF5F0EB);
  static const Color accentGlow = Color(0xFFF2D0DC);

  /// Optional raster logo — drop a PNG at this path to replace the text mark on the welcome screen.
  static const String logoPng = 'assets/images/logo.png';
}
