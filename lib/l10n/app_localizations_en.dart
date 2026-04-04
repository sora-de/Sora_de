// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sora de';

  @override
  String get welcomeTagline => 'Gifting & photobooth — inventory, orders, and profit in one place.';

  @override
  String get welcomeContinue => 'Enter app';

  @override
  String get profitLabel => 'Profit';

  @override
  String get profitNetGain => 'Net gain';

  @override
  String get profitNetLoss => 'Net loss';

  @override
  String profitSemantic(String status, String amount) {
    return '$status, $amount';
  }

  @override
  String get reportsShareCsv => 'Share month as CSV';

  @override
  String get reportsShareCsvSubject => 'Sora de monthly report';

  @override
  String get reportsTrendTitle => 'Last 6 months';

  @override
  String get reportsTrendRevenue => 'Revenue';

  @override
  String get reportsTrendExpenses => 'Expenses';

  @override
  String get reportsCsvSummary => 'Summary';

  @override
  String get reportsCsvBreakdown => 'Breakdown';

  @override
  String get reportsCsvInventoryUsage => 'Inventory usage';

  @override
  String get reportsCsvFieldMetric => 'Metric';

  @override
  String get reportsCsvFieldAmount => 'Amount';

  @override
  String get reportsCsvFieldLabel => 'Label';

  @override
  String get reportsCsvFieldUnits => 'Units';

  @override
  String get shareCsvError => 'Could not share file';

  @override
  String get dashboardTitle => 'Sora de';

  @override
  String get dashboardSubtitle => 'Booth-friendly overview';

  @override
  String get metricTodaysSales => 'Today\'s sales';

  @override
  String get metricMonthlyRevenue => 'Monthly revenue';

  @override
  String get metricMonthlyExpenses => 'Monthly expenses';

  @override
  String get metricNetProfitLoss => 'Net profit / loss';
}
