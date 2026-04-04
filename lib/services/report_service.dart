import 'package:sorade/core/constants.dart';
import 'package:sorade/models/expense.dart';
import 'package:sorade/models/gift_order.dart';
import 'package:sorade/models/monthly_report.dart';
import 'package:sorade/models/revenue.dart';

double calculateProfit(List<Revenue> revenues, List<Expense> expenses) {
  final totalRevenue = revenues.fold<double>(0, (sum, item) => sum + item.amount);
  final totalExpenses = expenses.fold<double>(0, (sum, item) => sum + item.amount);
  return totalRevenue - totalExpenses;
}

MonthlyReport generateMonthlyReport({
  required DateTime month,
  required List<Revenue> revenues,
  required List<Expense> expenses,
}) {
  final monthlyRevenue = revenues.where(
    (r) => r.date.month == month.month && r.date.year == month.year,
  );
  final monthlyExpenses = expenses.where(
    (e) => e.date.month == month.month && e.date.year == month.year,
  );

  final totalRevenue =
      monthlyRevenue.fold<double>(0, (sum, r) => sum + r.amount);
  final totalExpenses =
      monthlyExpenses.fold<double>(0, (sum, e) => sum + e.amount);

  return MonthlyReport(
    totalRevenue: totalRevenue,
    totalExpenses: totalExpenses,
    profit: totalRevenue - totalExpenses,
  );
}

class ReportBreakdown {
  ReportBreakdown({
    required this.productSales,
    required this.photoboothIncome,
    required this.fixedExpenses,
    required this.variableExpenses,
    required this.expenseByTitle,
  });

  final double productSales;
  final double photoboothIncome;
  final double fixedExpenses;
  final double variableExpenses;

  /// Aggregated expense totals keyed by title (e.g. Rent, Salary).
  final Map<String, double> expenseByTitle;
}

ReportBreakdown buildMonthlyBreakdown({
  required DateTime month,
  required List<Revenue> revenues,
  required List<Expense> expenses,
}) {
  bool inMonth(DateTime d) =>
      d.month == month.month && d.year == month.year;

  double product = 0;
  double booth = 0;
  for (final r in revenues) {
    if (!inMonth(r.date)) continue;
    if (r.source == RevenueSources.product) {
      product += r.amount;
    } else if (r.source == RevenueSources.photobooth) {
      booth += r.amount;
    } else {
      product += r.amount;
    }
  }

  double fixed = 0;
  double variable = 0;
  final byTitle = <String, double>{};
  for (final e in expenses) {
    if (!inMonth(e.date)) continue;
    if (e.category == ExpenseCategories.fixed) {
      fixed += e.amount;
    } else {
      variable += e.amount;
    }
    final key = e.title.trim().isEmpty ? 'Other' : e.title.trim();
    byTitle[key] = (byTitle[key] ?? 0) + e.amount;
  }

  return ReportBreakdown(
    productSales: product,
    photoboothIncome: booth,
    fixedExpenses: fixed,
    variableExpenses: variable,
    expenseByTitle: byTitle,
  );
}

/// Quantities sold/consumed from gift orders in a month (by inventory id).
Map<String, int> inventoryUsageForMonth({
  required DateTime month,
  required List<GiftOrder> orders,
}) {
  final usage = <String, int>{};
  for (final order in orders) {
    if (order.createdAt.month != month.month ||
        order.createdAt.year != month.year) {
      continue;
    }
    for (final line in order.lines) {
      final id = line.inventoryItemId;
      usage[id] = (usage[id] ?? 0) + line.quantity;
    }
  }
  return usage;
}

double todayProductSales(List<Revenue> revenues, DateTime now) {
  return revenues
      .where(
        (r) =>
            r.source == RevenueSources.product &&
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day,
      )
      .fold<double>(0, (s, r) => s + r.amount);
}

double todayPhotobooth(List<Revenue> revenues, DateTime now) {
  return revenues
      .where(
        (r) =>
            r.source == RevenueSources.photobooth &&
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day,
      )
      .fold<double>(0, (s, r) => s + r.amount);
}

double todayTotalSales(List<Revenue> revenues, DateTime now) {
  return todayProductSales(revenues, now) + todayPhotobooth(revenues, now);
}

bool _inMonth(DateTime d, DateTime month) =>
    d.month == month.month && d.year == month.year;

/// Product COGS for gift orders in a month using current unit cost per SKU.
class MonthTrendPoint {
  const MonthTrendPoint({
    required this.month,
    required this.revenue,
    required this.expenses,
  });

  final DateTime month;
  final double revenue;
  final double expenses;
}

/// Oldest → newest, exactly [count] months ending at [endMonth].
List<MonthTrendPoint> sixMonthsEnding({
  required DateTime endMonth,
  required List<Revenue> revenues,
  required List<Expense> expenses,
  int count = 6,
}) {
  final out = <MonthTrendPoint>[];
  var y = endMonth.year;
  var m = endMonth.month;
  for (var i = 0; i < count; i++) {
    final monthDate = DateTime(y, m);
    final rpt = generateMonthlyReport(
      month: monthDate,
      revenues: revenues,
      expenses: expenses,
    );
    out.add(
      MonthTrendPoint(
        month: monthDate,
        revenue: rpt.totalRevenue,
        expenses: rpt.totalExpenses,
      ),
    );
    m--;
    if (m == 0) {
      m = 12;
      y--;
    }
  }
  return out.reversed.toList();
}

double monthlyProductCogsFromOrders({
  required DateTime month,
  required List<GiftOrder> orders,
  required double Function(String inventoryItemId) unitCost,
}) {
  var cogs = 0.0;
  for (final order in orders) {
    if (!_inMonth(order.createdAt, month)) continue;
    for (final line in order.lines) {
      final c = unitCost(line.inventoryItemId);
      if (c > 0) cogs += line.quantity * c;
    }
  }
  return cogs;
}
