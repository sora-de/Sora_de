import 'package:flutter/foundation.dart';

@immutable
class DailySale {
  const DailySale({
    required this.id,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.paymentMethod,
    required this.notes,
    required this.soldBy,
    required this.soldByName,
    required this.createdAt,
  });

  final String id;
  final String productName;
  final String category;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String paymentMethod;
  final String notes;
  final String soldBy;
  final String soldByName;
  final DateTime createdAt;
}
