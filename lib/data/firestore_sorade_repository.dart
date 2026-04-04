import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sorade/core/constants.dart';
import 'package:sorade/data/firestore_serializers.dart';
import 'package:sorade/data/sorade_repository.dart';
import 'package:sorade/models/expense.dart';
import 'package:sorade/models/gift_order.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/models/inventory_meta.dart';
import 'package:sorade/models/order_line.dart';
import 'package:sorade/models/order_preset.dart';
import 'package:sorade/models/revenue.dart';
import 'package:sorade/models/stock_adjustment.dart';
import 'package:uuid/uuid.dart';

abstract final class _FsCollections {
  static const inventory = 'inventory';
  static const giftOrders = 'gift_orders';
  static const revenues = 'revenues';
  static const expenses = 'expenses';
  static const orderPresets = 'order_presets';
  static const inventoryMeta = 'inventory_meta';
  static const stockAdjustments = 'stock_adjustments';
}

class FirestoreSoradeRepository extends SoradeRepository {
  FirestoreSoradeRepository({
    required String uid,
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _uid = uid,
        _db = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final String _uid;
  final FirebaseFirestore _db;
  final Uuid _uuid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _inv =>
      _userDoc.collection(_FsCollections.inventory);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _userDoc.collection(_FsCollections.giftOrders);
  CollectionReference<Map<String, dynamic>> get _revenues =>
      _userDoc.collection(_FsCollections.revenues);
  CollectionReference<Map<String, dynamic>> get _expenses =>
      _userDoc.collection(_FsCollections.expenses);
  CollectionReference<Map<String, dynamic>> get _presets =>
      _userDoc.collection(_FsCollections.orderPresets);
  CollectionReference<Map<String, dynamic>> get _meta =>
      _userDoc.collection(_FsCollections.inventoryMeta);
  CollectionReference<Map<String, dynamic>> get _stock =>
      _userDoc.collection(_FsCollections.stockAdjustments);

  List<InventoryItem> _inventoryItems = [];
  List<GiftOrder> _giftOrders = [];
  List<Revenue> _revenuesList = [];
  List<Expense> _expensesList = [];
  List<OrderPreset> _orderPresets = [];
  final Map<String, InventoryMeta> _metaMap = {};
  List<StockAdjustment> _stockAdjustments = [];

  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _subs = [];
  void Function()? _onChanged;

  @override
  void attachListener(void Function() onChanged) {
    if (_subs.isNotEmpty) return;
    _onChanged = onChanged;
    _subs.add(
      _inv.snapshots().listen((s) {
        _inventoryItems = s.docs
            .map((d) => FsInventory.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        _onChanged?.call();
      }),
    );
    _subs.add(
      _orders.snapshots().listen((s) {
        _giftOrders = s.docs
            .map((d) => FsGiftOrder.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _onChanged?.call();
      }),
    );
    _subs.add(
      _revenues.snapshots().listen((s) {
        _revenuesList = s.docs
            .map((d) => FsRevenue.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _onChanged?.call();
      }),
    );
    _subs.add(
      _expenses.snapshots().listen((s) {
        _expensesList = s.docs
            .map((d) => FsExpense.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _onChanged?.call();
      }),
    );
    _subs.add(
      _presets.snapshots().listen((s) {
        _orderPresets = s.docs
            .map((d) => FsOrderPreset.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _onChanged?.call();
      }),
    );
    _subs.add(
      _meta.snapshots().listen((s) {
        _metaMap
          ..clear()
          ..addEntries(
            s.docs.map(
              (d) => MapEntry(d.id, FsInventoryMeta.fromMap(d.data())),
            ),
          );
        _onChanged?.call();
      }),
    );
    _subs.add(
      _stock.snapshots().listen((s) {
        _stockAdjustments = s.docs
            .map((d) => FsStockAdjustment.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _onChanged?.call();
      }),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _onChanged = null;
  }

  @override
  List<InventoryItem> get inventoryItems => List.unmodifiable(_inventoryItems);

  @override
  List<GiftOrder> get giftOrders => List.unmodifiable(_giftOrders);

  @override
  List<Revenue> get revenues => List.unmodifiable(_revenuesList);

  @override
  List<Expense> get expenses => List.unmodifiable(_expensesList);

  @override
  List<OrderPreset> get orderPresets => List.unmodifiable(_orderPresets);

  @override
  List<StockAdjustment> get stockAdjustments =>
      List.unmodifiable(_stockAdjustments);

  @override
  InventoryMeta inventoryMetaFor(String inventoryItemId) {
    return _metaMap[inventoryItemId] ?? InventoryMeta.empty;
  }

  @override
  Future<void> putInventoryMeta(String inventoryItemId, InventoryMeta meta) async {
    await _meta.doc(inventoryItemId).set(FsInventoryMeta.toMap(meta));
  }

  @override
  Future<void> upsertOrderPreset(OrderPreset preset) async {
    await _presets.doc(preset.id).set(FsOrderPreset.toMap(preset));
  }

  @override
  Future<void> deleteOrderPreset(String id) async {
    await _presets.doc(id).delete();
  }

  @override
  Future<void> upsertInventoryItem(InventoryItem item) async {
    await _inv.doc(item.id).set(FsInventory.toMap(item));
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    try {
      await FirebaseStorage.instance
          .ref('users/$_uid/inventory_photos/$id.jpg')
          .delete();
    } catch (_) {}
    final b = _db.batch();
    b.delete(_inv.doc(id));
    b.delete(_meta.doc(id));
    await b.commit();
  }

  @override
  InventoryItem? getInventory(String id) {
    for (final e in _inventoryItems) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<void> adjustStock({
    required String inventoryItemId,
    required int delta,
    required String reason,
  }) async {
    if (delta == 0) return;
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw StockException('Reason is required for stock adjustments.');
    }
    await _db.runTransaction((txn) async {
      final ref = _inv.doc(inventoryItemId);
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw StockException('Item not found.');
      }
      final item = FsInventory.fromDoc(snap.id, snap.data()!);
      final next = item.quantity + delta;
      if (next < 0) {
        throw StockException('Stock cannot go below zero.');
      }
      txn.update(ref, FsInventory.toMap(item.copyWith(quantity: next)));
      final adj = StockAdjustment(
        id: _uuid.v4(),
        inventoryItemId: item.id,
        itemDisplaySnapshot: item.displayName,
        delta: delta,
        reason: trimmed,
        date: DateTime.now(),
      );
      txn.set(_stock.doc(adj.id), FsStockAdjustment.toMap(adj));
    });
  }

  @override
  Future<GiftOrder> createGiftOrder({
    required List<OrderLine> lines,
    String? customerLabel,
    String? personalizedMessage,
  }) async {
    if (lines.isEmpty) {
      throw StockException('Add at least one line item.');
    }

    final orderId = _uuid.v4();
    final revenueId = _uuid.v4();
    final createdAt = DateTime.now();

    return _db.runTransaction((txn) async {
      final resolvedLines = <OrderLine>[];
      double total = 0;

      for (final line in lines) {
        final ref = _inv.doc(line.inventoryItemId);
        final snap = await txn.get(ref);
        if (!snap.exists) {
          throw StockException('Missing inventory item for line: ${line.itemName}');
        }
        final item = FsInventory.fromDoc(snap.id, snap.data()!);
        if (item.quantity < line.quantity) {
          throw StockException(
            'Not enough stock for "${item.displayName}" (have ${item.quantity}, need ${line.quantity}).',
          );
        }
        total += line.lineTotal;
        resolvedLines.add(line);
      }

      for (final line in resolvedLines) {
        final ref = _inv.doc(line.inventoryItemId);
        final snap = await txn.get(ref);
        final item = FsInventory.fromDoc(snap.id, snap.data()!);
        txn.update(
          ref,
          FsInventory.toMap(
            item.copyWith(quantity: item.quantity - line.quantity),
          ),
        );
      }

      final order = GiftOrder(
        id: orderId,
        customerLabel: customerLabel,
        personalizedMessage: personalizedMessage,
        lines: resolvedLines,
        totalAmount: total,
        createdAt: createdAt,
      );

      txn.set(_orders.doc(orderId), FsGiftOrder.toMap(order));

      final revenue = Revenue(
        id: revenueId,
        amount: total,
        source: RevenueSources.product,
        date: createdAt,
        linkedOrderId: orderId,
      );
      txn.set(_revenues.doc(revenueId), FsRevenue.toMap(revenue));

      for (final line in resolvedLines) {
        final metaRef = _meta.doc(line.inventoryItemId);
        final metaSnap = await txn.get(metaRef);
        final m = metaSnap.exists && metaSnap.data() != null
            ? FsInventoryMeta.fromMap(metaSnap.data()!)
            : InventoryMeta.empty;
        txn.set(
          metaRef,
          FsInventoryMeta.toMap(
            m.copyWith(lastSoldUnitPrice: line.unitPrice),
          ),
        );
      }

      return order;
    });
  }

  @override
  Future<void> addPhotoboothRevenue({
    required double amount,
    DateTime? date,
  }) async {
    if (amount <= 0) return;
    final rev = Revenue(
      id: _uuid.v4(),
      amount: amount,
      source: RevenueSources.photobooth,
      date: date ?? DateTime.now(),
    );
    await _revenues.doc(rev.id).set(FsRevenue.toMap(rev));
  }

  @override
  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    if (amount <= 0) return;
    final exp = Expense(
      id: _uuid.v4(),
      title: title.trim(),
      amount: amount,
      category: category,
      date: date,
    );
    await _expenses.doc(exp.id).set(FsExpense.toMap(exp));
  }

  @override
  Future<bool> deleteRevenue(String id) async {
    final doc = await _revenues.doc(id).get();
    if (!doc.exists || doc.data() == null) return false;
    final linked = doc.data()!['linkedOrderId'] as String?;
    if (linked != null && linked.isNotEmpty) return false;
    await _revenues.doc(id).delete();
    return true;
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _expenses.doc(id).delete();
  }
}
