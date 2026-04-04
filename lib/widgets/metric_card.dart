import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.compact = false,
    this.semanticsLabel,
  });

  final String label;
  final String value;
  final Color? accent;
  final bool compact;

  /// Full TalkBack / VoiceOver phrase, e.g. "Monthly revenue, 1,234.00".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = accent ?? cs.onSurface;
    final card = Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: compact ? 4 : 8),
            Text(
              value,
              style: (compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.headlineSmall)
                  ?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
    if (semanticsLabel == null) return card;
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: card,
    );
  }
}
