import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sorade/data/sorade_repository.dart';
import 'package:sorade/services/inventory_photo_storage.dart';
import 'package:sorade/models/expense.dart';
import 'package:sorade/models/gift_order.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/models/inventory_meta.dart';
import 'package:sorade/models/order_line.dart';
import 'package:sorade/models/order_preset.dart';
import 'package:sorade/models/revenue.dart';
import 'package:sorade/models/stock_adjustment.dart';

class SoradeController extends ChangeNotifier {
  SoradeController(this._repo) {
    _repo.attachListener(notifyListeners);
  }

  final SoradeRepository _repo;

  @override
  void dispose() {
    _repo.dispose();
    super.dispose();
  }

  /// Forces widgets to rebuild (e.g. pull-to-refresh on the dashboard).
  void refreshUi() => notifyListeners();

  List<InventoryItem> get inventoryItems => _repo.inventoryItems;
  List<GiftOrder> get giftOrders => _repo.giftOrders;
  List<Revenue> get revenues => _repo.revenues;
  List<Expense> get expenses => _repo.expenses;
  List<OrderPreset> get orderPresets => _repo.orderPresets;
  List<StockAdjustment> get stockAdjustments => _repo.stockAdjustments;

  List<InventoryItem> get lowStockItems =>
      inventoryItems.where((e) => e.isLowStock).toList();

  InventoryItem? inventoryById(String id) => _repo.getInventory(id);

  InventoryMeta inventoryMetaFor(String id) => _repo.inventoryMetaFor(id);

  double suggestedSalePrice(InventoryItem item) => _repo.suggestedSalePrice(item);

  /// Units below target stock (0 if none / already satisfied).
  int suggestedRestockUnits(InventoryItem item) {
    final t = _repo.inventoryMetaFor(item.id).targetStockLevel;
    if (t <= 0) return 0;
    if (item.quantity >= t) return 0;
    return t - item.quantity;
  }

  Future<void> upsertInventoryItem(InventoryItem item) async {
    await _repo.upsertInventoryItem(item);
    notifyListeners();
  }

  Future<void> putInventoryMeta(String id, InventoryMeta meta) async {
    await _repo.putInventoryMeta(id, meta);
    notifyListeners();
  }

  Future<void> deleteInventoryItem(String id) async {
    await _repo.deleteInventoryItem(id);
    notifyListeners();
  }

  /// Uploads a JPEG and updates the item’s [photoUrl] in Firestore.
  ///
  /// Pass the same [item] you just persisted so we do not rely on the async
  /// Firestore snapshot (which can lag and made [getInventory] return null).
  Future<void> setInventoryItemPhotoJpeg(InventoryItem item, Uint8List jpegBytes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final url = await uploadInventoryPhotoJpeg(
      uid: uid,
      itemId: item.id,
      jpegBytes: jpegBytes,
    );
    await _repo.upsertInventoryItem(item.copyWith(photoUrl: url));
    notifyListeners();
  }

  /// Removes the Storage file and clears [photoUrl] on the item.
  Future<void> clearInventoryItemPhoto(InventoryItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await deleteInventoryPhotoFile(uid: uid, itemId: item.id);
    }
    await _repo.upsertInventoryItem(item.copyWith(clearPhoto: true));
    notifyListeners();
  }

  Future<void> adjustStock({
    required String inventoryItemId,
    required int delta,
    required String reason,
  }) async {
    await _repo.adjustStock(
      inventoryItemId: inventoryItemId,
      delta: delta,
      reason: reason,
    );
    notifyListeners();
  }

  Future<void> upsertOrderPreset(OrderPreset preset) async {
    await _repo.upsertOrderPreset(preset);
    notifyListeners();
  }

  Future<void> deleteOrderPreset(String id) async {
    await _repo.deleteOrderPreset(id);
    notifyListeners();
  }

  Future<void> createGiftOrder({
    required List<OrderLine> lines,
    String? customerLabel,
    String? personalizedMessage,
  }) async {
    await _repo.createGiftOrder(
      lines: lines,
      customerLabel: customerLabel,
      personalizedMessage: personalizedMessage,
    );
    notifyListeners();
  }

  Future<void> addPhotoboothRevenue({
    required double amount,
    DateTime? date,
  }) async {
    await _repo.addPhotoboothRevenue(amount: amount, date: date);
    notifyListeners();
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    await _repo.addExpense(
      title: title,
      amount: amount,
      category: category,
      date: date,
    );
    notifyListeners();
  }

  /// Returns `false` if the row is tied to an order and cannot be deleted.
  Future<bool> deleteRevenue(String id) async {
    final ok = await _repo.deleteRevenue(id);
    notifyListeners();
    return ok;
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    notifyListeners();
  }
}
