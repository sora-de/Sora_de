import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/l10n/app_localizations.dart';
import 'package:sorade/services/report_service.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:sorade/widgets/accessible_profit_summary.dart';
import 'package:sorade/widgets/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.watch<SoradeController>();
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final report = generateMonthlyReport(
      month: month,
      revenues: c.revenues,
      expenses: c.expenses,
    );
    final todaySales = todayTotalSales(c.revenues, now);
    final low = c.lowStockItems;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SoradeController>().refreshUi();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            l10n.dashboardTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dashboardSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: l10n.metricTodaysSales,
                  value: formatMoney(context, todaySales),
                  compact: true,
                  semanticsLabel: '${l10n.metricTodaysSales}, ${formatMoney(context, todaySales)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: l10n.metricMonthlyRevenue,
                  value: formatMoney(context, report.totalRevenue),
                  compact: true,
                  semanticsLabel:
                      '${l10n.metricMonthlyRevenue}, ${formatMoney(context, report.totalRevenue)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricCard(
                  label: l10n.metricMonthlyExpenses,
                  value: formatMoney(context, report.totalExpenses),
                  compact: true,
                  semanticsLabel:
                      '${l10n.metricMonthlyExpenses}, ${formatMoney(context, report.totalExpenses)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AccessibleProfitSummary(
                  profit: report.profit,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Low stock',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (low.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('All items above threshold'),
                subtitle: Text(
                  '${c.inventoryItems.length} SKUs tracked',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...low.take(8).map(
                  (e) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(e.displayName),
                      subtitle: Text('Qty ${e.quantity} · alert ≤ ${e.lowStockThreshold}'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
