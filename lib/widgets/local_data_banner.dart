import 'package:flutter/material.dart';
import 'package:sorade/core/brand_colors.dart';

/// Firestore syncs in the background; local cache still helps when the network drops.
class LocalDataBanner extends StatelessWidget {
  const LocalDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Color.alphaBlend(
        BrandColors.accentGlow.withValues(alpha: 0.35),
        cs.surface,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.cloud_done_outlined, color: BrandColors.primaryGreen),
        title: Text(
          'Synced to your account',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Data is stored in Firebase. You stay signed in on this device.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
