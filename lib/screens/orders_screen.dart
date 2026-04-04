import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/navigation/sorade_provider_route.dart';
import 'package:sorade/models/gift_order.dart';
import 'package:sorade/screens/order_create_screen.dart';
import 'package:sorade/screens/order_presets_screen.dart';
import 'package:sorade/state/sorade_controller.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SoradeController>();
    final orders = c.giftOrders;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  soradeMaterialPageRoute(context, const OrderPresetsScreen()),
                );
              },
              icon: const Icon(Icons.dashboard_customize_outlined),
              label: const Text('Bundle presets'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No orders yet.\nCreate one when a customer buys a gift — stock updates automatically.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_orders_new_order',
        onPressed: () async {
          await Navigator.of(context).push<void>(
            soradeMaterialPageRoute(context, const OrderCreateScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New order'),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final GiftOrder order;

  @override
  Widget build(BuildContext context) {
    final msg = order.personalizedMessage?.trim();
    return Card(
      child: ExpansionTile(
        title: Text(formatMoney(context, order.totalAmount)),
        subtitle: Text(
          '${order.createdAt.toLocal()}'.split('.').first,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (order.customerLabel != null && order.customerLabel!.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Customer: ${order.customerLabel}'),
            ),
          if (msg != null && msg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Message:\n$msg'),
            ),
          ],
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Line items', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          ...order.lines.map(
            (l) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                l.variantLabel != null && l.variantLabel!.isNotEmpty
                    ? '${l.itemName} — ${l.variantLabel}'
                    : l.itemName,
              ),
              subtitle: Text('${l.quantity} × ${formatMoney(context, l.unitPrice)}'),
              trailing: Text(formatMoney(context, l.lineTotal)),
            ),
          ),
        ],
      ),
    );
  }
}
