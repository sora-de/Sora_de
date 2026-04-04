import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Indian Rupees — all amounts in the app use this (UI, CSV, semantics).
final NumberFormat _inr = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

/// Format [value] as ₹ (Indian Rupees). [context] is kept for call-site compatibility.
String formatMoney(BuildContext _, double value) {
  return _inr.format(value);
}

/// Same as [formatMoney] when you do not have a [BuildContext] (e.g. CSV export).
String formatMoneyValue(double value) => _inr.format(value);

String formatMonthYear(BuildContext context, DateTime month) {
  final tag = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMM(tag).format(DateTime(month.year, month.month));
}
