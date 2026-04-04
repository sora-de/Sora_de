import 'package:sorade/core/constants.dart';

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    this.variantLabel,
    required this.kind,
    this.productTypeLabel,
    required this.quantity,
    required this.lowStockThreshold,
    required this.unitPrice,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? variantLabel;
  final InventoryKind kind;

  /// When [kind] is product, optional preset label (e.g. Plushies).
  final String? productTypeLabel;
  final int quantity;
  final int lowStockThreshold;
  final double unitPrice;

  /// Firebase Storage download URL for a thumbnail (optional).
  final String? photoUrl;

  bool get isLowStock => quantity <= lowStockThreshold;

  String get displayName {
    if (variantLabel != null && variantLabel!.trim().isNotEmpty) {
      return '$name — $variantLabel';
    }
    return name;
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? variantLabel,
    InventoryKind? kind,
    String? productTypeLabel,
    int? quantity,
    int? lowStockThreshold,
    double? unitPrice,
    String? photoUrl,
    bool clearVariant = false,
    bool clearProductType = false,
    bool clearPhoto = false,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      variantLabel: clearVariant ? null : (variantLabel ?? this.variantLabel),
      kind: kind ?? this.kind,
      productTypeLabel:
          clearProductType ? null : (productTypeLabel ?? this.productTypeLabel),
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unitPrice: unitPrice ?? this.unitPrice,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
    );
  }
}
