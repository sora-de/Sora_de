import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/models/daily_sale.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:uuid/uuid.dart';

class AddSaleEntryScreen extends StatefulWidget {
  const AddSaleEntryScreen({super.key});

  @override
  State<AddSaleEntryScreen> createState() => _AddSaleEntryScreenState();
}

class _AddSaleEntryScreenState extends State<AddSaleEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _productName = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  
  String _category = 'Plushie';
  final List<String> _categories = [
    'Plushie', 'Crochet', 'Keychain', 'Bouquet', 'Photobooth Print', 'Sticker', 'Other'
  ];

  String _paymentMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'UPI', 'Card', 'Other'];

  bool _reduceInventory = false;

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final qty = int.tryParse(_quantity.text) ?? 1;
      final price = double.tryParse(_price.text) ?? 0.0;
      final total = qty * price;
      
      final controller = context.read<SoradeController>();
      final role = controller.currentUserRole;

      final sale = DailySale(
        id: const Uuid().v4(),
        productName: _productName.text,
        category: _category,
        quantity: qty,
        unitPrice: price,
        totalAmount: total,
        paymentMethod: _paymentMethod,
        notes: _notes.text,
        soldBy: role?.id ?? '',
        soldByName: role?.name ?? 'Unknown',
        createdAt: DateTime.now(),
      );

      controller.addDailySale(sale, deductInventory: _reduceInventory);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Sale Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _productName,
              decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            // ignore: deprecated_member_use
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Unit Price (₹)', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ignore: deprecated_member_use
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
              items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Reduce Inventory Automatically'),
              subtitle: const Text('If a product with this exact name exists, deduct stock.'),
              value: _reduceInventory,
              onChanged: (v) => setState(() => _reduceInventory = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Save Sale Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
