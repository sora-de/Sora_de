import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sorade/core/constants.dart';
import 'package:sorade/data/sorade_repository.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:sorade/widgets/inventory_item_thumbnail.dart';

/// Pick an existing catalog item, then log pieces bought and price per piece.
class RecordPurchaseScreen extends StatefulWidget {
  const RecordPurchaseScreen({super.key, this.initialItem});

  final InventoryItem? initialItem;

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  final _search = TextEditingController();
  InventoryItem? _picked;
  final _qty = TextEditingController(text: '1');
  final _unitPrice = TextEditingController();
  final _supplier = TextEditingController();
  final _note = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialItem;
  }

  @override
  void dispose() {
    _search.dispose();
    _qty.dispose();
    _unitPrice.dispose();
    _supplier.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _kindLabel(InventoryKind k) {
    return switch (k) {
      InventoryKind.product => 'Product',
      InventoryKind.supply => 'Customization supply',
      InventoryKind.utility => 'Utility',
    };
  }

  List<InventoryItem> _filtered(List<InventoryItem> all) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((e) {
      final c = context.read<SoradeController>();
      final supplier = c.inventoryMetaFor(e.id).supplierName ?? '';
      final blob =
          '${e.displayName} ${e.productTypeLabel ?? ''} $supplier'.toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime(_purchaseDate.year, _purchaseDate.month, _purchaseDate.day);
    final d = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (d != null && mounted) {
      setState(() => _purchaseDate = DateTime(d.year, d.month, d.day));
    }
  }

  Future<void> _submit() async {
    final item = _picked;
    if (item == null) return;
    final qty = int.tryParse(_qty.text.trim()) ?? 0;
    final price = double.tryParse(_unitPrice.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter how many pieces you bought (greater than zero).')),
      );
      return;
    }
    if (price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit price cannot be negative.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<SoradeController>().recordInventoryPurchase(
            inventoryItemId: item.id,
            quantity: qty,
            unitPrice: price,
            purchasedAt: _purchaseDate,
            supplierName: _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } on StockException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    final all = context.watch<SoradeController>().inventoryItems;
    final filtered = _filtered(all);

    return Scaffold(
      appBar: AppBar(
        title: Text(_picked == null ? 'Record purchase' : 'Restock'),
        leading: _picked != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (widget.initialItem != null) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _picked = null);
                  }
                },
              )
            : null,
      ),
      body: _picked == null
          ? Column(
              children: [
                if (all.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Add a catalog item first, then record purchases against it.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Search items',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _search.clear()),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: InventoryItemThumbnail(item: e, size: 48),
                            title: Text(e.displayName),
                            subtitle: Text(
                              'Stock ${e.quantity} · ${_kindLabel(e.kind)}',
                            ),
                            onTap: () => setState(() => _picked = e),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: InventoryItemThumbnail(item: _picked!, size: 56),
                  title: Text(_picked!.displayName),
                  subtitle: Text('Current stock: ${_picked!.quantity}'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pieces bought',
                    hintText: 'e.g. 5',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _unitPrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Buy price per piece',
                    hintText: 'e.g. 100',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Purchase date'),
                  subtitle: Text(dateFmt.format(_purchaseDate)),
                  trailing: FilledButton.tonal(
                    onPressed: _pickDate,
                    child: const Text('Change'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _supplier,
                  decoration: const InputDecoration(
                    labelText: 'Supplier (optional)',
                    hintText: 'Updates supplier on this item if filled',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save purchase'),
                ),
              ],
            ),
    );
  }
}
