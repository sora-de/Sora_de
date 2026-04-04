import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sorade/core/brand_colors.dart';
import 'package:sorade/l10n/app_localizations.dart';
import 'package:sorade/widgets/brand_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static const _bgAsset = 'assets/images/welcome_bg.svg';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            _bgAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BrandColors.cream.withValues(alpha: 0.15),
                  BrandColors.cream.withValues(alpha: 0.88),
                  BrandColors.cream,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const BrandLogo(height: 108),
                  const SizedBox(height: 20),
                  Text(
                    l10n.welcomeTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: BrandColors.primaryGreen.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: l10n.welcomeContinue,
                    child: FilledButton(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(l10n.welcomeContinue),
                    ),
                  ),
                  SizedBox(height: 16 + bottomInset),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
