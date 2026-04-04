import 'package:sorade/models/expense.dart';
import 'package:sorade/models/gift_order.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/models/inventory_meta.dart';
import 'package:sorade/models/order_line.dart';
import 'package:sorade/models/order_preset.dart';
import 'package:sorade/models/revenue.dart';
import 'package:sorade/models/stock_adjustment.dart';

class StockException implements Exception {
  StockException(this.message);
  final String message;
}

/// Data access for Sora de (cloud: [FirestoreSoradeRepository]).
abstract class SoradeRepository {
  void dispose();

  List<InventoryItem> get inventoryItems;
  List<GiftOrder> get giftOrders;
  List<Revenue> get revenues;
  List<Expense> get expenses;
  List<OrderPreset> get orderPresets;
  List<StockAdjustment> get stockAdjustments;

  InventoryMeta inventoryMetaFor(String inventoryItemId);

  Future<void> putInventoryMeta(String inventoryItemId, InventoryMeta meta);

  double suggestedSalePrice(InventoryItem item) {
    final m = inventoryMetaFor(item.id);
    if (m.lastSoldUnitPrice > 0) return m.lastSoldUnitPrice;
    return item.unitPrice;
  }

  Future<void> upsertOrderPreset(OrderPreset preset);
  Future<void> deleteOrderPreset(String id);

  Future<void> upsertInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(String id);

  InventoryItem? getInventory(String id);

  Future<void> adjustStock({
    required String inventoryItemId,
    required int delta,
    required String reason,
  });

  Future<GiftOrder> createGiftOrder({
    required List<OrderLine> lines,
    String? customerLabel,
    String? personalizedMessage,
  });

  Future<void> addPhotoboothRevenue({
    required double amount,
    DateTime? date,
  });

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  });

  Future<bool> deleteRevenue(String id);

  Future<void> deleteExpense(String id);

  /// Wire remote snapshot updates to [SoradeController.notifyListeners].
  void attachListener(void Function() onChanged) {}
}
