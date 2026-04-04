import 'package:flutter/material.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/l10n/app_localizations.dart';

/// Profit / loss with explicit text status and icon — not color alone (a11y).
class AccessibleProfitSummary extends StatelessWidget {
  const AccessibleProfitSummary({
    super.key,
    required this.profit,
    this.compact = false,
  });

  final double profit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final positive = profit >= 0;
    final cs = Theme.of(context).colorScheme;
    final accent = positive ? cs.primary : cs.error;
    final icon = positive ? Icons.trending_up : Icons.trending_down;
    final statusText = positive ? l10n.profitNetGain : l10n.profitNetLoss;
    final amountText = formatMoney(context, profit);

    return Semantics(
      container: true,
      label: l10n.profitSemantic(statusText, amountText),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(icon, size: compact ? 22 : 26, color: accent),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      l10n.profitLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                statusText,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
              ),
              SizedBox(height: compact ? 4 : 8),
              Text(
                amountText,
                style: (compact
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.w800, color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
