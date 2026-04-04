class OrderLine {
  OrderLine({
    required this.inventoryItemId,
    required this.itemName,
    this.variantLabel,
    required this.quantity,
    required this.unitPrice,
  });

  final String inventoryItemId;
  final String itemName;
  final String? variantLabel;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;
}
