import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/core/constants.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/data/sorade_repository.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/models/order_line.dart';
import 'package:sorade/models/order_preset.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:sorade/widgets/inventory_item_thumbnail.dart';

class _DraftLine {
  _DraftLine({
    required this.item,
    double? saleUnitPrice,
    int initialQty = 1,
  })  : qty = initialQty,
        unitPrice = saleUnitPrice ?? item.unitPrice;

  final InventoryItem item;
  int qty;
  double unitPrice;

  OrderLine toOrderLine() {
    return OrderLine(
      inventoryItemId: item.id,
      itemName: item.name,
      variantLabel: item.variantLabel,
      quantity: qty,
      unitPrice: unitPrice,
    );
  }
}

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _customer = TextEditingController();
  final _message = TextEditingController();
  final List<_DraftLine> _lines = [];

  @override
  void dispose() {
    _customer.dispose();
    _message.dispose();
    super.dispose();
  }

  double get _total =>
      _lines.fold<double>(0, (s, l) => s + l.qty * l.unitPrice);

  Widget _bigStep({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 56),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Icon(icon, size: 28),
    );
  }

  void _applyPreset(OrderPreset p, SoradeController c) {
    final missing = <String>[];
    for (final pl in p.lines) {
      final item = c.inventoryById(pl.inventoryItemId);
      if (item == null) {
        missing.add('A preset line points to a removed item.');
        continue;
      }
      if (item.kind != InventoryKind.product) {
        continue;
      }
      if (item.quantity < pl.quantity) {
        missing.add(
          '${item.displayName}: need ${pl.quantity}, have ${item.quantity}',
        );
      }
    }
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missing.take(4).join('\n'),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
      return;
    }

    var productLines = 0;
    setState(() {
      for (final pl in p.lines) {
        final item = c.inventoryById(pl.inventoryItemId);
        if (item == null || item.kind != InventoryKind.product) continue;
        productLines++;
        final price = c.suggestedSalePrice(item);
        final hit = _lines.where((l) => l.item.id == item.id).toList();
        if (hit.isEmpty) {
          _lines.add(
            _DraftLine(
              item: item,
              saleUnitPrice: price,
              initialQty: pl.quantity,
            ),
          );
        } else {
          hit.first.qty += pl.quantity;
        }
      }
    });
    if (productLines == 0 && p.lines.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This preset has no resell products. Supplies and utilities are not sold on orders.',
          ),
        ),
      );
    }
  }

  Future<void> _pickItems(SoradeController c) async {
    final items = c.inventoryItems
        .where((e) => e.quantity > 0 && e.kind == InventoryKind.product)
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add product inventory with stock first (resell items only).'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              final price = c.suggestedSalePrice(it);
              return ListTile(
                leading: InventoryItemThumbnail(item: it, size: 44),
                title: Text(it.displayName),
                subtitle: Text(
                  'In stock: ${it.quantity} · Suggested ${formatMoney(context, price)}',
                ),
                onTap: () {
                  setState(() {
                    final existing = _lines.where((l) => l.item.id == it.id).toList();
                    if (existing.isEmpty) {
                      _lines.add(_DraftLine(item: it, saleUnitPrice: price));
                    } else {
                      existing.first.qty += 1;
                    }
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submit(SoradeController c) async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product line.')),
      );
      return;
    }
    for (final d in _lines) {
      final live = c.inventoryById(d.item.id);
      if (live == null || live.quantity < d.qty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough stock for "${d.item.displayName}" (have ${live?.quantity ?? 0}).',
            ),
          ),
        );
        return;
      }
    }

    try {
      await c.createGiftOrder(
        lines: _lines.map((e) => e.toOrderLine()).toList(),
        customerLabel: _customer.text.trim().isEmpty ? null : _customer.text.trim(),
        personalizedMessage: _message.text.trim().isEmpty ? null : _message.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } on StockException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SoradeController>();
    final presets = c.orderPresets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New order'),
        actions: [
          IconButton(
            tooltip: 'Barcode / SKU (coming soon)',
            icon: const Icon(Icons.qr_code_scanner_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Barcode scanning — coming soon')),
              );
            },
          ),
          TextButton(
            onPressed: () => _submit(c),
            child: const Text('Place order'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (presets.isNotEmpty) ...[
                  Text(
                    'Quick bundles',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final pr = presets[i];
                        return ActionChip(
                          label: Text(pr.name),
                          onPressed: () => _applyPreset(pr, c),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.tonalIcon(
                  onPressed: () => _pickItems(c),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add product line'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customer,
                  decoration: const InputDecoration(
                    labelText: 'Customer (optional)',
                    hintText: 'Name or table #',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _message,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Personalized message (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cart',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (_lines.isEmpty)
                  Text(
                    'Use quick bundles or “Add product line”. Only resell products appear here; '
                    'supplies and utilities stay in inventory for booth use. Stock deducts when you place the order. '
                    'Prices default to the last amount you charged for that item.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  ..._lines.asMap().entries.map((e) {
                    final idx = e.key;
                    final line = e.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    line.item.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => _lines.removeAt(idx)),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _bigStep(
                                  icon: Icons.remove,
                                  onPressed: line.qty > 1
                                      ? () => setState(() => line.qty -= 1)
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    '${line.qty}',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                _bigStep(
                                  icon: Icons.add,
                                  onPressed: () => setState(() => line.qty += 1),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    final ctrl =
                                        TextEditingController(text: '${line.unitPrice}');
                                    final next = await showDialog<double>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Unit price'),
                                        content: TextField(
                                          controller: ctrl,
                                          keyboardType: const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Price per unit',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              final p = double.tryParse(ctrl.text.trim());
                                              Navigator.pop(ctx, p);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                    ctrl.dispose();
                                    if (next != null && next >= 0) {
                                      setState(() => line.unitPrice = next);
                                    }
                                  },
                                  child: Text(formatMoney(context, line.unitPrice)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    formatMoney(context, _total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
