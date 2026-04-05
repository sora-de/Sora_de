class InventoryPurchase {
  const InventoryPurchase({
    required this.id,
    required this.inventoryItemId,
    required this.purchasedAt,
    required this.quantity,
    required this.unitPrice,
    this.supplierName,
    this.note,
  });

  final String id;
  final String inventoryItemId;
  final DateTime purchasedAt;
  final int quantity;
  final double unitPrice;
  final String? supplierName;
  final String? note;

  double get lineTotal => quantity * unitPrice;
}
