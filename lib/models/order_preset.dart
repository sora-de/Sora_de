class OrderPresetLine {
  OrderPresetLine({
    required this.inventoryItemId,
    required this.quantity,
  });

  final String inventoryItemId;
  final int quantity;
}

class OrderPreset {
  OrderPreset({
    required this.id,
    required this.name,
    required this.lines,
  });

  final String id;
  final String name;
  final List<OrderPresetLine> lines;
}
