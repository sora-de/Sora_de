import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sorade/core/constants.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/models/inventory_meta.dart';
import 'package:sorade/services/inventory_photo_storage.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:sorade/widgets/inventory_item_thumbnail.dart';
import 'package:uuid/uuid.dart';

class InventoryEditScreen extends StatefulWidget {
  const InventoryEditScreen({super.key, this.existing});

  final InventoryItem? existing;

  @override
  State<InventoryEditScreen> createState() => _InventoryEditScreenState();
}

class _InventoryEditScreenState extends State<InventoryEditScreen> {
  final _name = TextEditingController();
  final _variant = TextEditingController();
  final _customType = TextEditingController();
  final _qty = TextEditingController(text: '0');
  final _low = TextEditingController(text: '3');
  final _price = TextEditingController(text: '0');
  final _cost = TextEditingController(text: '0');
  final _target = TextEditingController(text: '0');
  final _supplier = TextEditingController();
  final _lastPurchasePrice = TextEditingController(text: '0');
  final _lastPurchaseQty = TextEditingController(text: '0');

  InventoryKind _kind = InventoryKind.product;
  String _presetType = ProductTypePresets.all.first;
  bool _useCustomType = false;
  bool _metaLoaded = false;
  DateTime? _lastPurchaseDate;
  Uint8List? _pickedJpeg;
  bool _removePhotoOnSave = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _variant.text = e.variantLabel ?? '';
      _kind = e.kind;
      _low.text = '${e.lowStockThreshold}';
      _price.text = '${e.unitPrice}';
      final pt = e.productTypeLabel;
      if (pt != null && pt.isNotEmpty) {
        final presets = _presetsForKind(_kind);
        if (presets.contains(pt)) {
          _presetType = pt;
          _useCustomType = false;
        } else {
          _useCustomType = true;
          _customType.text = pt;
        }
      }
    } else {
      _qty.text = '0';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_metaLoaded) return;
    final e = widget.existing;
    if (e != null) {
      final m = context.read<SoradeController>().inventoryMetaFor(e.id);
      _cost.text = m.costPerUnit > 0 ? '${m.costPerUnit}' : '0';
      _target.text = m.targetStockLevel > 0 ? '${m.targetStockLevel}' : '0';
      _supplier.text = m.supplierName ?? '';
      _lastPurchasePrice.text = m.lastPurchaseUnitPrice > 0 ? '${m.lastPurchaseUnitPrice}' : '0';
      _lastPurchaseQty.text = m.lastPurchaseQuantity > 0 ? '${m.lastPurchaseQuantity}' : '0';
      _lastPurchaseDate = m.lastPurchaseAt;
    }
    _metaLoaded = true;
  }

  List<String> _presetsForKind(InventoryKind k) {
    return switch (k) {
      InventoryKind.product => ProductTypePresets.all,
      InventoryKind.supply => SupplyTypePresets.all,
      InventoryKind.utility => UtilityTypePresets.all,
    };
  }

  @override
  void dispose() {
    _name.dispose();
    _variant.dispose();
    _customType.dispose();
    _qty.dispose();
    _low.dispose();
    _price.dispose();
    _cost.dispose();
    _target.dispose();
    _supplier.dispose();
    _lastPurchasePrice.dispose();
    _lastPurchaseQty.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be under 5 MB.')),
      );
      return;
    }
    setState(() {
      _pickedJpeg = bytes;
      _removePhotoOnSave = false;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    final isNew = widget.existing == null;
    var qtyParsed = int.tryParse(_qty.text.trim()) ?? 0;
    final lastPurchaseQty = int.tryParse(_lastPurchaseQty.text.trim()) ?? 0;
    if (isNew && qtyParsed <= 0 && lastPurchaseQty > 0) {
      qtyParsed = lastPurchaseQty;
    }
    final qty = isNew ? (qtyParsed < 0 ? 0 : qtyParsed) : widget.existing!.quantity;

    final low = int.tryParse(_low.text.trim()) ?? 0;
    final price = double.tryParse(_price.text.trim()) ?? 0;
    final cost = double.tryParse(_cost.text.trim()) ?? 0;
    final target = int.tryParse(_target.text.trim()) ?? 0;

    String? productType;
    if (_kind == InventoryKind.product) {
      productType = _useCustomType
          ? (_customType.text.trim().isEmpty ? null : _customType.text.trim())
          : _presetType;
    } else if (_kind == InventoryKind.supply) {
      productType = _useCustomType
          ? (_customType.text.trim().isEmpty ? null : _customType.text.trim())
          : _presetType;
    } else {
      productType = _useCustomType
          ? (_customType.text.trim().isEmpty ? null : _customType.text.trim())
          : _presetType;
    }

    final variant = _variant.text.trim().isEmpty ? null : _variant.text.trim();
    final id = widget.existing?.id ?? const Uuid().v4();

    final item = InventoryItem(
      id: id,
      name: name,
      variantLabel: variant,
      kind: _kind,
      productTypeLabel: productType,
      quantity: qty,
      lowStockThreshold: low < 0 ? 0 : low,
      unitPrice: price < 0 ? 0 : price,
      photoUrl: widget.existing?.photoUrl,
    );

    final ctrl = context.read<SoradeController>();
    final lastPurchase = double.tryParse(_lastPurchasePrice.text.trim()) ?? 0;
    final meta = InventoryMeta(
      costPerUnit: cost < 0 ? 0 : cost,
      targetStockLevel: target < 0 ? 0 : target,
      lastSoldUnitPrice: ctrl.inventoryMetaFor(id).lastSoldUnitPrice,
      supplierName: _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
      lastPurchaseUnitPrice: lastPurchase < 0 ? 0 : lastPurchase,
      lastPurchaseQuantity: lastPurchaseQty < 0 ? 0 : lastPurchaseQty,
      lastPurchaseAt: _lastPurchaseDate,
    );

    try {
      await ctrl.upsertInventoryItem(item);
      await ctrl.putInventoryMeta(id, meta);

      if (_pickedJpeg != null) {
        await ctrl.setInventoryItemPhotoJpeg(item, _pickedJpeg!);
      } else if (_removePhotoOnSave && widget.existing?.photoUrl != null) {
        await ctrl.clearInventoryItemPhoto(item);
      }

      if (mounted) Navigator.of(context).pop();
    } on InventoryPhotoException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${e.displayName}" from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<SoradeController>().deleteInventoryItem(e.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _pickLastPurchaseDate() async {
    final now = DateTime.now();
    final initial = _lastPurchaseDate ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (d != null && mounted) setState(() => _lastPurchaseDate = d);
  }

  @override
  Widget build(BuildContext context) {
    final presets = _presetsForKind(_kind);
    if (!presets.contains(_presetType)) {
      _presetType = presets.first;
    }
    final existing = widget.existing;
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add item' : 'Edit item'),
        actions: [
          if (existing != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (existing != null)
            Card(
              child: ListTile(
                leading: Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                title: Text('Stock: ${existing.quantity}'),
                subtitle: const Text(
                  'To change quantity, use Adjust stock on the inventory list (reason is saved).',
                ),
              ),
            ),
          if (existing != null) const SizedBox(height: 12),
          Text(
            'Photo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PhotoPreview(
                existing: existing,
                pickedJpeg: _pickedJpeg,
                removeRequested: _removePhotoOnSave,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose from gallery'),
                    ),
                    const SizedBox(height: 8),
                    if (existing?.photoUrl != null || _pickedJpeg != null)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _pickedJpeg = null;
                          _removePhotoOnSave = true;
                        }),
                        icon: const Icon(Icons.hide_image_outlined),
                        label: const Text('Remove photo'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'JPEG from gallery · max 5 MB · helps staff match variants at the booth.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _variant,
            decoration: const InputDecoration(
              labelText: 'Variant (optional)',
              hintText: 'Size, color, scent…',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<InventoryKind>(
            // ignore: deprecated_member_use
            value: _kind,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: InventoryKind.product, child: Text('Product')),
              DropdownMenuItem(value: InventoryKind.supply, child: Text('Customization supply')),
              DropdownMenuItem(value: InventoryKind.utility, child: Text('Utility')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _kind = v;
                _useCustomType = false;
                _presetType = _presetsForKind(v).first;
              });
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Custom type label'),
            subtitle: const Text('Otherwise pick a preset for faster entry'),
            value: _useCustomType,
            onChanged: (b) => setState(() => _useCustomType = b),
          ),
          if (_useCustomType)
            TextField(
              controller: _customType,
              decoration: const InputDecoration(
                labelText: 'Type label',
                hintText: 'e.g. Restocking — ribbons',
              ),
            )
          else
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _presetType,
              decoration: const InputDecoration(labelText: 'Preset type'),
              items: presets
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _presetType = v ?? presets.first),
            ),
          const SizedBox(height: 20),
          Text(
            'Reorder & supplier',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _supplier,
            decoration: const InputDecoration(
              labelText: 'Supplier (optional)',
              hintText: 'Who you usually reorder from',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _lastPurchasePrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Buy price per piece',
                    hintText: 'e.g. 100',
                    prefixText: '₹ ',
                    helperText: 'What you paid for one unit',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _lastPurchaseQty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pieces bought',
                    hintText: 'e.g. 5',
                    helperText: '0 = skip',
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Example: 5 sanitizers at ₹100 each — enter 5 and 100.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Last purchase date'),
            subtitle: Text(
              _lastPurchaseDate == null ? 'Not set' : dateFmt.format(_lastPurchaseDate!),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_lastPurchaseDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _lastPurchaseDate = null),
                    tooltip: 'Clear date',
                  ),
                FilledButton.tonal(
                  onPressed: _pickLastPurchaseDate,
                  child: const Text('Pick date'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (existing == null)
            TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Starting stock qty',
                helperText:
                    'Leave 0 to match pieces bought above. After creation, use Adjust stock for changes.',
              ),
            ),
          if (existing == null) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _low,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Low-stock alert at'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _target,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target stock',
                    hintText: '0 = off',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Default sale price',
                    hintText: 'New orders use last sale if set',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Unit cost (COGS)',
                    hintText: '0 = off',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.existing,
    required this.pickedJpeg,
    required this.removeRequested,
  });

  final InventoryItem? existing;
  final Uint8List? pickedJpeg;
  final bool removeRequested;

  @override
  Widget build(BuildContext context) {
    const size = 96.0;
    if (pickedJpeg != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          pickedJpeg!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    if (removeRequested) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Text(
          'Will remove',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }
    if (existing != null) {
      return InventoryItemThumbnail(item: existing!, size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
