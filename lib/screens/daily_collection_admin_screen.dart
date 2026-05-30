import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:intl/intl.dart';

class DailyCollectionAdminScreen extends StatelessWidget {
  const DailyCollectionAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SoradeController>();
    final collections = controller.dailyCollections;
    
    return Scaffold(
      body: collections.isEmpty
          ? const Center(child: Text('No collections recorded yet.'))
          : ListView.builder(
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final col = collections[index];
                return ExpansionTile(
                  title: Text(DateFormat.yMMMd().format(col.date)),
                  subtitle: Text('Total: ₹${col.totalCollection.toStringAsFixed(2)} • By: ${col.submittedByName}'),
                  children: [
                    ListTile(title: const Text('Cash'), trailing: Text('₹${col.cashAmount.toStringAsFixed(2)}')),
                    ListTile(title: const Text('UPI'), trailing: Text('₹${col.upiAmount.toStringAsFixed(2)}')),
                    ListTile(title: const Text('Card'), trailing: Text('₹${col.cardAmount.toStringAsFixed(2)}')),
                    ListTile(title: const Text('Other'), trailing: Text('₹${col.otherAmount.toStringAsFixed(2)}')),
                  ],
                );
              },
            ),
    );
  }
}
