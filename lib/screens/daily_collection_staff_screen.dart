import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/models/daily_collection.dart';
import 'package:sorade/screens/add_sale_entry_screen.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:uuid/uuid.dart';

class DailyCollectionStaffScreen extends StatelessWidget {
  const DailyCollectionStaffScreen({super.key});

  void _submitCollection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _SubmitCollectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SoradeController>();
    
    final today = DateTime.now();
    final todaySales = controller.dailySales.where((s) {
      return s.createdAt.year == today.year &&
             s.createdAt.month == today.month &&
             s.createdAt.day == today.day;
    }).toList();

    double total = 0;
    int items = 0;
    for (final s in todaySales) {
      total += s.totalAmount;
      items += s.quantity;
    }

    final todayCollections = controller.dailyCollections.where((c) {
      return c.date.year == today.year &&
             c.date.month == today.month &&
             c.date.day == today.day &&
             c.submittedBy == controller.currentUserRole?.id;
    }).toList();

    double totalSubmitted = 0;
    double cashSubmitted = 0;
    for (final c in todayCollections) {
      totalSubmitted += c.totalCollection;
      cashSubmitted += c.cashAmount;
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s Total', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    Text('₹${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    if (totalSubmitted > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Submitted: ₹${totalSubmitted.toStringAsFixed(2)} (Cash: ₹${cashSubmitted.toStringAsFixed(2)})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Items Sold', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    Text('$items', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: todaySales.isEmpty
                ? const Center(child: Text('No sales recorded today.'))
                : ListView.builder(
                    itemCount: todaySales.length,
                    itemBuilder: (context, index) {
                      final sale = todaySales[index];
                      return ListTile(
                        title: Text(sale.productName),
                        subtitle: Text('${sale.quantity}x @ ₹${sale.unitPrice.toStringAsFixed(2)} • ${sale.paymentMethod}'),
                        trailing: Text('₹${sale.totalAmount.toStringAsFixed(2)}'),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _submitCollection(context),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Submit Collection'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AddSaleEntryScreen(),
                      ));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Sale'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitCollectionDialog extends StatefulWidget {
  const _SubmitCollectionDialog();

  @override
  State<_SubmitCollectionDialog> createState() => _SubmitCollectionDialogState();
}

class _SubmitCollectionDialogState extends State<_SubmitCollectionDialog> {
  final _cash = TextEditingController();
  final _upi = TextEditingController();
  final _card = TextEditingController();
  final _other = TextEditingController();

  double _parse(String s) => double.tryParse(s) ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Today\'s Collection'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _cash, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cash Amount (₹)')),
            const SizedBox(height: 8),
            TextField(controller: _upi, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'UPI Amount (₹)')),
            const SizedBox(height: 8),
            TextField(controller: _card, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Card Amount (₹)')),
            const SizedBox(height: 8),
            TextField(controller: _other, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Other Amount (₹)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final c = _parse(_cash.text);
            final u = _parse(_upi.text);
            final cd = _parse(_card.text);
            final o = _parse(_other.text);
            final total = c + u + cd + o;
            
            final controller = context.read<SoradeController>();
            final role = controller.currentUserRole;
            
            final col = DailyCollection(
              id: const Uuid().v4(),
              date: DateTime.now(),
              cashAmount: c,
              upiAmount: u,
              cardAmount: cd,
              otherAmount: o,
              totalCollection: total,
              submittedBy: role?.id ?? '',
              submittedByName: role?.name ?? 'Unknown',
              createdAt: DateTime.now(),
            );
            controller.submitDailyCollection(col);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collection submitted successfully')));
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
