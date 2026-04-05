class InventoryMeta {
  const InventoryMeta({
    this.costPerUnit = 0,
    this.targetStockLevel = 0,
    this.lastSoldUnitPrice = 0,
    this.supplierName,
    this.lastPurchaseUnitPrice = 0,
    this.lastPurchaseQuantity = 0,
    this.lastPurchaseAt,
  });

  /// Unit cost (COGS). 0 means not set.
  final double costPerUnit;

  /// Ideal on-hand qty for reorder hints. 0 means not set.
  final int targetStockLevel;

  /// Last price used on an order. 0 means fall back to catalog [InventoryItem.unitPrice].
  final double lastSoldUnitPrice;

  /// Primary supplier / reorder contact (optional).
  final String? supplierName;

  /// Last purchase unit price you paid. 0 means not set.
  final double lastPurchaseUnitPrice;

  /// How many units you bought last time (reorder record). 0 means not set.
  final int lastPurchaseQuantity;

  /// When you last bought at [lastPurchaseUnitPrice] (optional).
  final DateTime? lastPurchaseAt;

  static const empty = InventoryMeta();

  InventoryMeta copyWith({
    double? costPerUnit,
    int? targetStockLevel,
    double? lastSoldUnitPrice,
    String? supplierName,
    double? lastPurchaseUnitPrice,
    int? lastPurchaseQuantity,
    DateTime? lastPurchaseAt,
    bool clearSupplier = false,
    bool clearLastPurchase = false,
  }) {
    return InventoryMeta(
      costPerUnit: costPerUnit ?? this.costPerUnit,
      targetStockLevel: targetStockLevel ?? this.targetStockLevel,
      lastSoldUnitPrice: lastSoldUnitPrice ?? this.lastSoldUnitPrice,
      supplierName: clearSupplier ? null : (supplierName ?? this.supplierName),
      lastPurchaseUnitPrice:
          clearLastPurchase ? 0 : (lastPurchaseUnitPrice ?? this.lastPurchaseUnitPrice),
      lastPurchaseQuantity:
          clearLastPurchase ? 0 : (lastPurchaseQuantity ?? this.lastPurchaseQuantity),
      lastPurchaseAt: clearLastPurchase ? null : (lastPurchaseAt ?? this.lastPurchaseAt),
    );
  }
}
