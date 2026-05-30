import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:intl/intl.dart';

class DailyCollectionAdminScreen extends StatelessWidget {
  const DailyCollectionAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SoradeController>();
    final isAdmin = controller.currentUserRole?.isAdmin == true;
    final collections = isAdmin
        ? controller.dailyCollections
        : controller.dailyCollections.where((c) => c.submittedBy == controller.currentUserRole?.id).toList();
    
    return Scaffold(
      body: collections.isEmpty
          ? const Center(child: Text('No collections recorded yet.'))
          : ListView.builder(
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final col = collections[index];
                
                final sales = controller.dailySales.where((s) {
                  return s.createdAt.year == col.date.year &&
                         s.createdAt.month == col.date.month &&
                         s.createdAt.day == col.date.day &&
                         s.soldBy == col.submittedBy;
                }).toList();

                double totalSales = 0;
                int totalItems = 0;
                for (final s in sales) {
                  totalSales += s.totalAmount;
                  totalItems += s.quantity;
                }

                return ExpansionTile(
                  title: Text(DateFormat.yMMMd().format(col.date)),
                  subtitle: Text('Total: ₹${col.totalCollection.toStringAsFixed(2)} • By: ${col.submittedByName}'),
                  children: [
                    ListTile(title: const Text('Cash'), trailing: Text('₹${col.cashAmount.toStringAsFixed(2)}')),
                    ListTile(title: const Text('UPI'), trailing: Text('₹${col.upiAmount.toStringAsFixed(2)}')),
                    ListTile(title: const Text('Card'), trailing: Text('₹${col.cardAmount.toStringAsFixed(2)}')),
                    ListTile(title: const Text('Other'), trailing: Text('₹${col.otherAmount.toStringAsFixed(2)}')),
                    const Divider(),
                    ListTile(
                      title: const Text('Total Sales'),
                      subtitle: Text('$totalItems items sold'),
                      trailing: Text(
                        '₹${totalSales.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (totalSales - col.totalCollection).abs() < 0.01 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                    ),
                    if (sales.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: Column(
                          children: [
                            for (final s in sales)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${s.quantity}x ${s.productName}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                    Text(
                                      '₹${s.totalAmount.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
