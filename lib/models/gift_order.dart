import 'package:sorade/models/order_line.dart';

class GiftOrder {
  GiftOrder({
    required this.id,
    this.customerLabel,
    this.personalizedMessage,
    required this.lines,
    required this.totalAmount,
    required this.createdAt,
  });

  final String id;
  final String? customerLabel;
  final String? personalizedMessage;
  final List<OrderLine> lines;
  final double totalAmount;
  final DateTime createdAt;
}
