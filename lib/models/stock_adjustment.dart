class StockAdjustment {
  StockAdjustment({
    required this.id,
    required this.inventoryItemId,
    required this.itemDisplaySnapshot,
    required this.delta,
    required this.reason,
    required this.date,
  });

  final String id;
  final String inventoryItemId;
  final String itemDisplaySnapshot;
  final int delta;
  final String reason;
  final DateTime date;
}
