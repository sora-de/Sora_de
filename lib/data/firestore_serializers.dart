import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sorade/core/constants.dart';
import 'package:sorade/models/expense.dart';
import 'package:sorade/models/gift_order.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/models/inventory_meta.dart';
import 'package:sorade/models/order_line.dart';
import 'package:sorade/models/order_preset.dart';
import 'package:sorade/models/revenue.dart';
import 'package:sorade/models/stock_adjustment.dart';

Timestamp? _toTs(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v;
  if (v is DateTime) return Timestamp.fromDate(v);
  return null;
}

DateTime _readDate(dynamic v) {
  final ts = _toTs(v);
  if (ts != null) return ts.toDate();
  return DateTime.fromMillisecondsSinceEpoch(0);
}

double _readDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _readInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

InventoryKind _readKind(dynamic v) {
  if (v is String) {
    for (final k in InventoryKind.values) {
      if (k.name == v) return k;
    }
  }
  return InventoryKind.product;
}

class FsInventory {
  static Map<String, dynamic> toMap(InventoryItem e) {
    return {
      'name': e.name,
      'variantLabel': e.variantLabel,
      'kind': e.kind.name,
      'productTypeLabel': e.productTypeLabel,
      'quantity': e.quantity,
      'lowStockThreshold': e.lowStockThreshold,
      'unitPrice': e.unitPrice,
      if (e.photoUrl != null && e.photoUrl!.trim().isNotEmpty) 'photoUrl': e.photoUrl,
    };
  }

  static InventoryItem fromDoc(String id, Map<String, dynamic> m) {
    final rawPhoto = m['photoUrl'];
    final photoUrl = rawPhoto is String && rawPhoto.trim().isNotEmpty ? rawPhoto.trim() : null;
    return InventoryItem(
      id: id,
      name: m['name'] as String? ?? '',
      variantLabel: m['variantLabel'] as String?,
      kind: _readKind(m['kind']),
      productTypeLabel: m['productTypeLabel'] as String?,
      quantity: _readInt(m['quantity']),
      lowStockThreshold: _readInt(m['lowStockThreshold']),
      unitPrice: _readDouble(m['unitPrice']),
      photoUrl: photoUrl,
    );
  }
}

Map<String, dynamic> orderLineToMap(OrderLine l) => {
      'inventoryItemId': l.inventoryItemId,
      'itemName': l.itemName,
      'variantLabel': l.variantLabel,
      'quantity': l.quantity,
      'unitPrice': l.unitPrice,
    };

OrderLine orderLineFromMap(Map<String, dynamic> m) {
  return OrderLine(
    inventoryItemId: m['inventoryItemId'] as String? ?? '',
    itemName: m['itemName'] as String? ?? '',
    variantLabel: m['variantLabel'] as String?,
    quantity: _readInt(m['quantity']),
    unitPrice: _readDouble(m['unitPrice']),
  );
}

class FsGiftOrder {
  static Map<String, dynamic> toMap(GiftOrder o) {
    return {
      'customerLabel': o.customerLabel,
      'personalizedMessage': o.personalizedMessage,
      'lines': o.lines.map(orderLineToMap).toList(),
      'totalAmount': o.totalAmount,
      'createdAt': Timestamp.fromDate(o.createdAt),
    };
  }

  static GiftOrder fromDoc(String id, Map<String, dynamic> m) {
    final rawLines = m['lines'];
    final lines = <OrderLine>[];
    if (rawLines is List) {
      for (final e in rawLines) {
        if (e is Map<String, dynamic>) {
          lines.add(orderLineFromMap(e));
        } else if (e is Map) {
          lines.add(orderLineFromMap(Map<String, dynamic>.from(e)));
        }
      }
    }
    return GiftOrder(
      id: id,
      customerLabel: m['customerLabel'] as String?,
      personalizedMessage: m['personalizedMessage'] as String?,
      lines: lines,
      totalAmount: _readDouble(m['totalAmount']),
      createdAt: _readDate(m['createdAt']),
    );
  }
}

class FsRevenue {
  static Map<String, dynamic> toMap(Revenue r) {
    return {
      'amount': r.amount,
      'source': r.source,
      'date': Timestamp.fromDate(r.date),
      'linkedOrderId': r.linkedOrderId,
    };
  }

  static Revenue fromDoc(String id, Map<String, dynamic> m) {
    return Revenue(
      id: id,
      amount: _readDouble(m['amount']),
      source: m['source'] as String? ?? RevenueSources.product,
      date: _readDate(m['date']),
      linkedOrderId: m['linkedOrderId'] as String?,
    );
  }
}

class FsExpense {
  static Map<String, dynamic> toMap(Expense e) {
    return {
      'title': e.title,
      'amount': e.amount,
      'category': e.category,
      'date': Timestamp.fromDate(e.date),
    };
  }

  static Expense fromDoc(String id, Map<String, dynamic> m) {
    return Expense(
      id: id,
      title: m['title'] as String? ?? '',
      amount: _readDouble(m['amount']),
      category: m['category'] as String? ?? ExpenseCategories.variable,
      date: _readDate(m['date']),
    );
  }
}

class FsOrderPreset {
  static Map<String, dynamic> toMap(OrderPreset p) {
    return {
      'name': p.name,
      'lines': p.lines
          .map(
            (l) => {
              'inventoryItemId': l.inventoryItemId,
              'quantity': l.quantity,
            },
          )
          .toList(),
    };
  }

  static OrderPreset fromDoc(String id, Map<String, dynamic> m) {
    final lines = <OrderPresetLine>[];
    final raw = m['lines'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final mm = Map<String, dynamic>.from(e);
          lines.add(
            OrderPresetLine(
              inventoryItemId: mm['inventoryItemId'] as String? ?? '',
              quantity: _readInt(mm['quantity']),
            ),
          );
        }
      }
    }
    return OrderPreset(
      id: id,
      name: m['name'] as String? ?? '',
      lines: lines,
    );
  }
}

class FsInventoryMeta {
  static Map<String, dynamic> toMap(InventoryMeta meta) {
    return {
      'costPerUnit': meta.costPerUnit,
      'targetStockLevel': meta.targetStockLevel,
      'lastSoldUnitPrice': meta.lastSoldUnitPrice,
      if (meta.supplierName != null && meta.supplierName!.trim().isNotEmpty)
        'supplierName': meta.supplierName!.trim(),
      'lastPurchaseUnitPrice': meta.lastPurchaseUnitPrice,
      if (meta.lastPurchaseAt != null)
        'lastPurchaseAt': Timestamp.fromDate(meta.lastPurchaseAt!),
    };
  }

  static InventoryMeta fromMap(Map<String, dynamic> m) {
    final rawAt = m['lastPurchaseAt'];
    DateTime? lastPurchaseAt;
    if (rawAt != null) {
      final d = _readDate(rawAt);
      if (d.millisecondsSinceEpoch > 0) lastPurchaseAt = d;
    }
    final sn = m['supplierName'];
    return InventoryMeta(
      costPerUnit: _readDouble(m['costPerUnit']),
      targetStockLevel: _readInt(m['targetStockLevel']),
      lastSoldUnitPrice: _readDouble(m['lastSoldUnitPrice']),
      supplierName: sn is String && sn.trim().isNotEmpty ? sn.trim() : null,
      lastPurchaseUnitPrice: _readDouble(m['lastPurchaseUnitPrice']),
      lastPurchaseAt: lastPurchaseAt,
    );
  }
}

class FsStockAdjustment {
  static Map<String, dynamic> toMap(StockAdjustment a) {
    return {
      'inventoryItemId': a.inventoryItemId,
      'itemDisplaySnapshot': a.itemDisplaySnapshot,
      'delta': a.delta,
      'reason': a.reason,
      'date': Timestamp.fromDate(a.date),
    };
  }

  static StockAdjustment fromDoc(String id, Map<String, dynamic> m) {
    return StockAdjustment(
      id: id,
      inventoryItemId: m['inventoryItemId'] as String? ?? '',
      itemDisplaySnapshot: m['itemDisplaySnapshot'] as String? ?? '',
      delta: _readInt(m['delta']),
      reason: m['reason'] as String? ?? '',
      date: _readDate(m['date']),
    );
  }
}
