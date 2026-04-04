import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/navigation/sorade_provider_route.dart';
import 'package:sorade/models/order_preset.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:uuid/uuid.dart';

class OrderPresetsScreen extends StatelessWidget {
  const OrderPresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SoradeController>();
    final list = c.orderPresets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bundle presets'),
      ),
      body: list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Create combos you sell often (e.g. bouquet + card + envelope). '
                  'They show as one-tap chips on New order.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = list[i];
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.lines.length} line(s)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            await Navigator.of(context).push<void>(
                              soradeMaterialPageRoute(
                                context,
                                OrderPresetEditScreen(existing: p),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete preset?'),
                                content: Text('Remove “${p.name}”?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              await context.read<SoradeController>().deleteOrderPreset(p.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_order_presets_new',
        onPressed: () async {
          await Navigator.of(context).push<void>(
            soradeMaterialPageRoute(context, const OrderPresetEditScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New preset'),
      ),
    );
  }
}

class OrderPresetEditScreen extends StatefulWidget {
  const OrderPresetEditScreen({super.key, this.existing});

  final OrderPreset? existing;

  @override
  State<OrderPresetEditScreen> createState() => _OrderPresetEditScreenState();
}

class _OrderPresetEditScreenState extends State<OrderPresetEditScreen> {
  final _name = TextEditingController();
  final List<OrderPresetLine> _lines = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _lines.addAll(e.lines);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickLine(SoradeController c) async {
    final items = c.inventoryItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add inventory items first.')),
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
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return ListTile(
                title: Text(it.displayName),
                onTap: () {
                  setState(() {
                    final idx = _lines.indexWhere((l) => l.inventoryItemId == it.id);
                    if (idx >= 0) {
                      final old = _lines[idx];
                      _lines[idx] = OrderPresetLine(
                        inventoryItemId: old.inventoryItemId,
                        quantity: old.quantity + 1,
                      );
                    } else {
                      _lines.add(OrderPresetLine(inventoryItemId: it.id, quantity: 1));
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

  Future<void> _save(SoradeController c) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one inventory line')),
      );
      return;
    }
    final id = widget.existing?.id ?? const Uuid().v4();
    await c.upsertOrderPreset(OrderPreset(id: id, name: name, lines: List.from(_lines)));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SoradeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New preset' : 'Edit preset'),
        actions: [
          TextButton(onPressed: () => _save(c), child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Preset name',
              hintText: 'e.g. Bouquet + card pack',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => _pickLine(c),
            icon: const Icon(Icons.add),
            label: const Text('Add inventory line'),
          ),
          const SizedBox(height: 16),
          Text(
            'Lines',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (_lines.isEmpty)
            Text(
              'Tap “Add inventory line”. Tap the same item again to increase qty.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          else
            ..._lines.asMap().entries.map((e) {
              final i = e.key;
              final line = e.value;
              final item = c.inventoryById(line.inventoryItemId);
              final label = item?.displayName ?? 'Unknown item';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(label),
                  subtitle: Text('Qty ${line.quantity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          if (line.quantity > 1) {
                            _lines[i] = OrderPresetLine(
                              inventoryItemId: line.inventoryItemId,
                              quantity: line.quantity - 1,
                            );
                          } else {
                            _lines.removeAt(i);
                          }
                        }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() {
                          _lines[i] = OrderPresetLine(
                            inventoryItemId: line.inventoryItemId,
                            quantity: line.quantity + 1,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
