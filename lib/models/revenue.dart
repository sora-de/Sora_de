class Revenue {
  Revenue({
    required this.id,
    required this.amount,
    required this.source,
    required this.date,
    this.linkedOrderId,
  });

  final String id;
  final double amount;

  /// "Product" or "Photobooth"
  final String source;
  final DateTime date;

  /// Set when created from a gift order.
  final String? linkedOrderId;
}
