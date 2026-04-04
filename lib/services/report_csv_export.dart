import 'package:sorade/core/money_format.dart';
import 'package:sorade/l10n/app_localizations.dart';
import 'package:sorade/models/monthly_report.dart';
import 'package:sorade/services/report_service.dart';

String _cell(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String _row(List<String> cells) => '${cells.map(_cell).join(',')}\n';

/// UTF-8 friendly CSV for the selected month (Excel / Sheets).
String buildMonthlyReportCsv({
  required AppLocalizations l10n,
  required DateTime month,
  required MonthlyReport report,
  required ReportBreakdown breakdown,
  required double cogs,
  required double grossMargin,
  required Map<String, int> usage,
  required Map<String, String> inventoryLabels,
}) {
  final buf = StringBuffer();
  buf.write('\uFEFF');
  buf.write(_row([l10n.appTitle, '${month.year}-${month.month.toString().padLeft(2, '0')}']));
  buf.write(_row([]));

  buf.write(_row([l10n.reportsCsvSummary]));
  buf.write(_row([l10n.reportsCsvFieldMetric, l10n.reportsCsvFieldAmount]));
  buf.write(_row(['Total revenue', formatMoneyValue(report.totalRevenue)]));
  buf.write(_row(['Total expenses', formatMoneyValue(report.totalExpenses)]));
  buf.write(_row(['Net profit', formatMoneyValue(report.profit)]));
  buf.write(_row([]));

  buf.write(_row([l10n.reportsCsvBreakdown]));
  buf.write(_row([l10n.reportsCsvFieldLabel, l10n.reportsCsvFieldAmount]));
  buf.write(_row(['Product sales', formatMoneyValue(breakdown.productSales)]));
  buf.write(_row(['Photobooth income', formatMoneyValue(breakdown.photoboothIncome)]));
  buf.write(_row(['Est COGS', formatMoneyValue(cogs)]));
  buf.write(_row(['Gross margin products', formatMoneyValue(grossMargin)]));
  buf.write(_row(['Fixed expenses', formatMoneyValue(breakdown.fixedExpenses)]));
  buf.write(_row(['Variable expenses', formatMoneyValue(breakdown.variableExpenses)]));
  for (final e in breakdown.expenseByTitle.entries) {
    buf.write(_row([e.key, formatMoneyValue(e.value)]));
  }
  buf.write(_row([]));

  buf.write(_row([l10n.reportsCsvInventoryUsage]));
  buf.write(_row([l10n.reportsCsvFieldLabel, l10n.reportsCsvFieldUnits]));
  final keys = usage.keys.toList()..sort();
  for (final id in keys) {
    final label = inventoryLabels[id] ?? id;
    buf.write(_row([label, '${usage[id] ?? 0}']));
  }

  return buf.toString();
}
