import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/models/inventory_item.dart';
import 'package:sorade/models/inventory_purchase.dart';
import 'package:sorade/state/sorade_controller.dart';

class InventoryPurchaseHistoryScreen extends StatefulWidget {
  const InventoryPurchaseHistoryScreen({super.key, required this.item});

  final InventoryItem item;

  @override
  State<InventoryPurchaseHistoryScreen> createState() =>
      _InventoryPurchaseHistoryScreenState();
}

class _InventoryPurchaseHistoryScreenState
    extends State<InventoryPurchaseHistoryScreen> {
  Future<List<InventoryPurchase>>? _future;

  Future<void> _refresh() async {
    final f =
        context.read<SoradeController>().inventoryPurchasesFor(widget.item.id);
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    _future ??=
        context.read<SoradeController>().inventoryPurchasesFor(widget.item.id);
    final dateFmt = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());

    return Scaffold(
      appBar: AppBar(
        title: Text('Purchases · ${widget.item.displayName}'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<InventoryPurchase>>(
          future: _future!,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('${snap.error}'),
                  ),
                ],
              );
            }
            final rows = snap.data ?? [];
            if (rows.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No purchase records yet. Use Record purchase on the inventory list to log a buy.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final p = rows[i];
                final sub = <String>[
                  '${p.quantity} × ${formatMoney(context, p.unitPrice)} = ${formatMoney(context, p.lineTotal)}',
                  if (p.supplierName != null && p.supplierName!.isNotEmpty)
                    'Supplier: ${p.supplierName}',
                  if (p.note != null && p.note!.isNotEmpty) p.note!,
                ].join('\n');
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(dateFmt.format(p.purchasedAt.toLocal())),
                    subtitle: Text(sub),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
