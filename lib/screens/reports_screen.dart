import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/l10n/app_localizations.dart';
import 'package:sorade/services/report_csv_export.dart';
import 'package:sorade/services/report_service.dart';
import 'package:sorade/services/report_share.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:sorade/widgets/accessible_profit_summary.dart';
import 'package:sorade/widgets/metric_card.dart';
import 'package:sorade/widgets/six_month_trend_bars.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _shareCsv(BuildContext context, SoradeController c) async {
    final l10n = AppLocalizations.of(context)!;
    final report = generateMonthlyReport(
      month: _month,
      revenues: c.revenues,
      expenses: c.expenses,
    );
    final bd = buildMonthlyBreakdown(
      month: _month,
      revenues: c.revenues,
      expenses: c.expenses,
    );
    final usage = inventoryUsageForMonth(month: _month, orders: c.giftOrders);
    final cogs = monthlyProductCogsFromOrders(
      month: _month,
      orders: c.giftOrders,
      unitCost: (id) => c.inventoryMetaFor(id).costPerUnit,
    );
    final grossMargin = bd.productSales - cogs;
    final labels = <String, String>{};
    for (final id in usage.keys) {
      labels[id] = c.inventoryById(id)?.displayName ?? id;
    }
    final csv = buildMonthlyReportCsv(
      l10n: l10n,
      month: _month,
      report: report,
      breakdown: bd,
      cogs: cogs,
      grossMargin: grossMargin,
      usage: usage,
      inventoryLabels: labels,
    );
    await shareMonthlyCsv(context, csv, _month);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.watch<SoradeController>();
    final report = generateMonthlyReport(
      month: _month,
      revenues: c.revenues,
      expenses: c.expenses,
    );
    final bd = buildMonthlyBreakdown(
      month: _month,
      revenues: c.revenues,
      expenses: c.expenses,
    );
    final usage = inventoryUsageForMonth(month: _month, orders: c.giftOrders);
    final cogs = monthlyProductCogsFromOrders(
      month: _month,
      orders: c.giftOrders,
      unitCost: (id) => c.inventoryMetaFor(id).costPerUnit,
    );
    final grossMargin = bd.productSales - cogs;

    final keys = usage.keys.toList()..sort();
    final trend = sixMonthsEnding(
      endMonth: _month,
      revenues: c.revenues,
      expenses: c.expenses,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(
                formatMonthYear(context, _month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _shareCsv(context, c),
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.reportsShareCsv),
        ),
        const SizedBox(height: 16),
        SixMonthTrendBars(points: trend),
        const SizedBox(height: 16),
        MetricCard(
          label: 'Total revenue',
          value: formatMoney(context, report.totalRevenue),
          semanticsLabel: 'Total revenue, ${formatMoney(context, report.totalRevenue)}',
        ),
        const SizedBox(height: 12),
        MetricCard(
          label: 'Total expenses',
          value: formatMoney(context, report.totalExpenses),
          semanticsLabel: 'Total expenses, ${formatMoney(context, report.totalExpenses)}',
        ),
        const SizedBox(height: 12),
        AccessibleProfitSummary(profit: report.profit),
        const SizedBox(height: 24),
        Text(
          'Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _BreakdownRow(label: 'Product sales', value: formatMoney(context, bd.productSales)),
        _BreakdownRow(label: 'Photobooth income', value: formatMoney(context, bd.photoboothIncome)),
        const SizedBox(height: 12),
        Text(
          'Product margin (COGS)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Uses unit cost from each SKU. Photobooth is excluded.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        _BreakdownRow(label: 'Est. COGS (orders)', value: formatMoney(context, cogs)),
        _BreakdownRow(
          label: 'Gross margin (products)',
          value: formatMoney(context, grossMargin),
        ),
        const Divider(height: 24),
        _BreakdownRow(label: 'Fixed expenses', value: formatMoney(context, bd.fixedExpenses)),
        _BreakdownRow(label: 'Variable expenses', value: formatMoney(context, bd.variableExpenses)),
        const SizedBox(height: 12),
        Text(
          'Expenses by title',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (bd.expenseByTitle.isEmpty)
          Text(
            'No expenses this month.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          ...bd.expenseByTitle.entries.map(
            (e) => _BreakdownRow(label: e.key, value: formatMoney(context, e.value)),
          ),
        const SizedBox(height: 24),
        Text(
          'Inventory usage (from orders)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (keys.isEmpty)
          Text(
            'No orders with line items this month.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          ...keys.map((id) {
            final name = c.inventoryById(id)?.displayName ?? 'Removed item ($id)';
            final qty = usage[id] ?? 0;
            return _BreakdownRow(label: name, value: '$qty units');
          }),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
