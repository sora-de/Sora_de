import 'package:flutter/material.dart';
import 'package:sorade/core/brand_colors.dart';

/// Typographic “Sora de” mark. To use a PNG instead, add `assets/images/logo.png`
/// to the project, set [_useRasterLogo] to true, and run `flutter pub get`.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 96});

  final double height;

  /// Set to true after you add `assets/images/logo.png` (avoids 404s when missing).
  static const bool _useRasterLogo = false;

  @override
  Widget build(BuildContext context) {
    if (_useRasterLogo) {
      return SizedBox(
        height: height,
        child: Image.asset(
          BrandColors.logoPng,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _TextWordmark(height: height),
        ),
      );
    }
    return _TextWordmark(height: height);
  }
}

class _TextWordmark extends StatelessWidget {
  const _TextWordmark({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final fs = (height * 0.28).clamp(22.0, 40.0);
    final base = TextStyle(
      fontSize: fs,
      fontWeight: FontWeight.w800,
      color: BrandColors.primaryGreen,
      letterSpacing: -0.5,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'Sora'),
            TextSpan(
              text: ' de',
              style: base.copyWith(
                color: BrandColors.primaryPink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
