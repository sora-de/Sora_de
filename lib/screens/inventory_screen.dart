import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/navigation/sorade_provider_route.dart';
import 'package:sorade/core/constants.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/data/sorade_repository.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/screens/inventory_edit_screen.dart';
import 'package:sorade/screens/inventory_purchase_history_screen.dart';
import 'package:sorade/screens/record_purchase_screen.dart';
import 'package:sorade/widgets/inventory_item_thumbnail.dart';
import 'package:sorade/state/sorade_controller.dart';

enum _InvFilter { all, product, supply, utility }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  _InvFilter _filter = _InvFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<InventoryItem> _applyFilters(List<InventoryItem> all) {
    var list = all;
    switch (_filter) {
      case _InvFilter.all:
        break;
      case _InvFilter.product:
        list = list.where((e) => e.kind == InventoryKind.product).toList();
        break;
      case _InvFilter.supply:
        list = list.where((e) => e.kind == InventoryKind.supply).toList();
        break;
      case _InvFilter.utility:
        list = list.where((e) => e.kind == InventoryKind.utility).toList();
        break;
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((e) {
      final supplier = context
              .read<SoradeController>()
              .inventoryMetaFor(e.id)
              .supplierName ??
          '';
      final blob = '${e.displayName} ${e.productTypeLabel ?? ''} $supplier'
          .toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  Future<void> _openAdjustStock(
      BuildContext context, InventoryItem item) async {
    final c = context.read<SoradeController>();
    final deltaCtrl = TextEditingController(text: '1');
    final reasonCtrl = TextEditingController();
    var sign = 1;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Adjust stock · ${item.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Current: ${item.quantity}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: -1, label: Text('Remove')),
                          ButtonSegment(value: 1, label: Text('Add')),
                        ],
                        selected: {sign},
                        onSelectionChanged: (s) =>
                            setLocal(() => sign = s.first),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deltaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'How many units',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reason',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: StockAdjustmentReasons.presets
                      .map(
                        (r) => ActionChip(
                          label: Text(r, style: const TextStyle(fontSize: 12)),
                          onPressed: () => setLocal(() => reasonCtrl.text = r),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason (required)',
                    hintText: 'Pick a chip or type your own',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Apply')),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      final raw = int.tryParse(deltaCtrl.text.trim()) ?? 0;
      deltaCtrl.dispose();
      final delta = raw.abs() * sign;
      final reason = reasonCtrl.text.trim();
      reasonCtrl.dispose();
      if (delta == 0) return;
      try {
        await c.adjustStock(
          inventoryItemId: item.id,
          delta: delta,
          reason: reason,
        );
      } on StockException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } else {
      deltaCtrl.dispose();
      reasonCtrl.dispose();
    }
  }

  void _openInventoryAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('New catalog item'),
              subtitle: const Text('A product or SKU you do not have yet'),
              onTap: () {
                Navigator.pop(ctx);
                if (!context.mounted) return;
                Navigator.of(context).push<void>(
                  soradeMaterialPageRoute(context, const InventoryEditScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Record purchase'),
              subtitle: const Text('Same item, new buy — updates stock and history'),
              onTap: () {
                Navigator.pop(ctx);
                if (!context.mounted) return;
                Navigator.of(context).push<void>(
                  soradeMaterialPageRoute(context, const RecordPurchaseScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPurchaseHistory(BuildContext context, InventoryItem item) async {
    await Navigator.of(context).push<void>(
      soradeMaterialPageRoute(
        context,
        InventoryPurchaseHistoryScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SoradeController>();
    final all = c.inventoryItems;
    final filtered = _applyFilters(all);

    final products =
        filtered.where((e) => e.kind == InventoryKind.product).toList();
    final supplies =
        filtered.where((e) => e.kind == InventoryKind.supply).toList();
    final utils =
        filtered.where((e) => e.kind == InventoryKind.utility).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _search.clear();
                        }),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == _InvFilter.all,
                  onSelected: (_) => setState(() => _filter = _InvFilter.all),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Products'),
                  selected: _filter == _InvFilter.product,
                  onSelected: (_) =>
                      setState(() => _filter = _InvFilter.product),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Supplies'),
                  selected: _filter == _InvFilter.supply,
                  onSelected: (_) =>
                      setState(() => _filter = _InvFilter.supply),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Utilities'),
                  selected: _filter == _InvFilter.utility,
                  onSelected: (_) =>
                      setState(() => _filter = _InvFilter.utility),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                if (filtered.isEmpty && all.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text(
                        'No matches. Try another search or filter.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                _Section(
                  title: 'Products',
                  subtitle: 'Plushies, bouquets, candles, chocolates',
                  items: products,
                  onAdjust: (it) => _openAdjustStock(context, it),
                  onPurchaseHistory: (it) => _openPurchaseHistory(context, it),
                ),
                _Section(
                  title: 'Customization supplies',
                  subtitle: 'Pens, notes, stickers, envelopes',
                  items: supplies,
                  onAdjust: (it) => _openAdjustStock(context, it),
                  onPurchaseHistory: (it) => _openPurchaseHistory(context, it),
                ),
                _Section(
                  title: 'Utilities',
                  subtitle: 'Sanitizers, tissues',
                  items: utils,
                  onAdjust: (it) => _openAdjustStock(context, it),
                  onPurchaseHistory: (it) => _openPurchaseHistory(context, it),
                ),
                if (all.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text('No items yet. Tap Add to create a catalog item.'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_inventory_add',
        onPressed: () => _openInventoryAddMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onAdjust,
    required this.onPurchaseHistory,
  });

  final String title;
  final String subtitle;
  final List<InventoryItem> items;
  final void Function(InventoryItem) onAdjust;
  final void Function(InventoryItem) onPurchaseHistory;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        Text(subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...items.map(
          (e) => _InventoryTile(
            item: e,
            onAdjust: () => onAdjust(e),
            onPurchaseHistory: () => onPurchaseHistory(e),
          ),
        ),
      ],
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.item,
    required this.onAdjust,
    required this.onPurchaseHistory,
  });

  final InventoryItem item;
  final VoidCallback onAdjust;
  final VoidCallback onPurchaseHistory;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SoradeController>();
    final restock = c.suggestedRestockUnits(item);
    final meta = c.inventoryMetaFor(item.id);
    final costNote = meta.costPerUnit > 0
        ? ' · Cost ${formatMoney(context, meta.costPerUnit)}'
        : '';
    final supplierNote =
        meta.supplierName != null && meta.supplierName!.trim().isNotEmpty
            ? 'Supplier: ${meta.supplierName!.trim()}'
            : null;
    final lastBuy = meta.lastPurchaseUnitPrice > 0 &&
            meta.lastPurchaseAt != null
        ? 'Last bought ${formatMoney(context, meta.lastPurchaseUnitPrice)} · ${meta.lastPurchaseAt!.toLocal().toString().split(' ').first}'
        : meta.lastPurchaseUnitPrice > 0
            ? 'Last bought ${formatMoney(context, meta.lastPurchaseUnitPrice)}'
            : null;
    final salePart = item.kind == InventoryKind.product
        ? ' · ${formatMoney(context, item.unitPrice)} each'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: InventoryItemThumbnail(item: item),
        onTap: () async {
          await Navigator.of(context).push<void>(
            soradeMaterialPageRoute(
              context,
              InventoryEditScreen(existing: item),
            ),
          );
        },
        title: Text(item.displayName),
        subtitle: Text(
          [
            'Stock ${item.quantity} · Low at ${item.lowStockThreshold}$salePart$costNote',
            if (supplierNote != null) supplierNote,
            if (lastBuy != null) lastBuy,
            if (restock > 0) 'Suggested reorder: +$restock to reach target',
          ].join('\n'),
        ),
        isThreeLine: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isLowStock)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.warning_amber,
                    color: Theme.of(context).colorScheme.error),
              ),
            IconButton(
              tooltip: 'Purchase history',
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: onPurchaseHistory,
            ),
            IconButton(
              tooltip: 'Adjust stock',
              icon: const Icon(Icons.tune),
              onPressed: onAdjust,
            ),
          ],
        ),
      ),
    );
  }
}
