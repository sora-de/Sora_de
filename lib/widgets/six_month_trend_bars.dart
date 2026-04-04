import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/l10n/app_localizations.dart';
import 'package:sorade/services/report_service.dart';

/// Lightweight bar comparison (no chart package): revenue vs expenses per month.
class SixMonthTrendBars extends StatelessWidget {
  const SixMonthTrendBars({
    super.key,
    required this.points,
  });

  final List<MonthTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final revColor = cs.primary;
    final expColor = cs.tertiary;

    var maxVal = 1.0;
    for (final p in points) {
      if (p.revenue > maxVal) maxVal = p.revenue;
      if (p.expenses > maxVal) maxVal = p.expenses;
    }

    final monthFmt = DateFormat.MMM(Localizations.localeOf(context).toLanguageTag());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reportsTrendTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LegendStripe(color: revColor, label: l10n.reportsTrendRevenue),
                _LegendStripe(color: expColor, label: l10n.reportsTrendExpenses),
              ],
            ),
            const SizedBox(height: 16),
            Semantics(
              label: '${l10n.reportsTrendTitle}: ${points.length} months of revenue and expense bars',
              child: SizedBox(
                height: 132,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: points
                      .map(
                        (p) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _VerticalBar(
                                        value: p.revenue,
                                        maxValue: maxVal,
                                        color: revColor,
                                        semanticLabel: l10n.reportsTrendRevenue,
                                      ),
                                      const SizedBox(width: 4),
                                      _VerticalBar(
                                        value: p.expenses,
                                        maxValue: maxVal,
                                        color: expColor,
                                        semanticLabel: l10n.reportsTrendExpenses,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  monthFmt.format(p.month),
                                  style: Theme.of(context).textTheme.labelSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendStripe extends StatelessWidget {
  const _LegendStripe({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _VerticalBar extends StatelessWidget {
  const _VerticalBar({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.semanticLabel,
  });

  final double value;
  final double maxValue;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final f = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: '$semanticLabel ${formatMoney(context, value)}',
      child: SizedBox(
        width: 10,
        height: 100,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: f,
            widthFactor: 1,
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
