/// Revenue [Revenue.source] values (keep stable for reports & future sync).
abstract final class RevenueSources {
  static const String product = 'Product';
  static const String photobooth = 'Photobooth';
}

/// Expense [Expense.category] values.
abstract final class ExpenseCategories {
  static const String fixed = 'Fixed';
  static const String variable = 'Variable';
}

/// Inventory grouping for products / supplies / utilities.
enum InventoryKind {
  product,
  supply,
  utility,
}

/// Suggested product types (user can still type a custom label).
abstract final class ProductTypePresets {
  static const List<String> all = [
    'Plushies',
    'Crochet Bouquets',
    'Candles',
    'Chocolates',
  ];
}

abstract final class SupplyTypePresets {
  static const List<String> all = [
    'Pens',
    'Paper notes',
    'Stickers',
    'Envelopes',
  ];
}

abstract final class UtilityTypePresets {
  static const List<String> all = [
    'Sanitizers',
    'Tissues',
  ];
}

/// Suggested reasons for stock adjustments (user can still type a custom reason).
abstract final class StockAdjustmentReasons {
  static const List<String> presets = [
    'Damaged / spoilage',
    'Gift / sample',
    'Count correction',
    'Restock intake',
    'Booth use',
  ];
}
