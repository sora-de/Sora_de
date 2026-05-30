import 'package:flutter/foundation.dart';

@immutable
class DailyCollection {
  const DailyCollection({
    required this.id,
    required this.date,
    required this.cashAmount,
    required this.upiAmount,
    required this.cardAmount,
    required this.otherAmount,
    required this.totalCollection,
    required this.submittedBy,
    required this.submittedByName,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final double cashAmount;
  final double upiAmount;
  final double cardAmount;
  final double otherAmount;
  final double totalCollection;
  final String submittedBy;
  final String submittedByName;
  final DateTime createdAt;
}
