import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/core/constants.dart';
import 'package:sorade/core/money_format.dart';
import 'package:sorade/services/report_service.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:sorade/widgets/metric_card.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Revenue'),
              Tab(text: 'Expenses'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _RevenueTab(),
              _ExpensesTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueTab extends StatelessWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SoradeController>();
    final list = c.revenues;
    final now = DateTime.now();
    final monthAnchor = DateTime(now.year, now.month);

    final todayP = todayProductSales(c.revenues, now);
    final todayB = todayPhotobooth(c.revenues, now);
    final monthBd = buildMonthlyBreakdown(
      month: monthAnchor,
      revenues: c.revenues,
      expenses: c.expenses,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Today (booth)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Product (orders)',
                value: formatMoney(context, todayP),
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: 'Photobooth',
                value: formatMoney(context, todayB),
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MetricCard(
          label: 'Today total',
          value: formatMoney(context, todayP + todayB),
          compact: true,
        ),
        const SizedBox(height: 20),
        Text(
          'This calendar month',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Product sales',
                value: formatMoney(context, monthBd.productSales),
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: 'Photobooth',
                value: formatMoney(context, monthBd.photoboothIncome),
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MetricCard(
          label: 'Month total revenue',
          value: formatMoney(context, monthBd.productSales + monthBd.photoboothIncome),
          compact: true,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Product revenue is logged when you complete an order (cannot be deleted here). '
              'Photobooth entries are manual — use the button below.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _addPhotobooth(context),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Add photobooth income'),
        ),
        const SizedBox(height: 16),
        Text(
          'Recent revenue',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: Text('No revenue entries yet.')),
          )
        else
          ...list.take(80).map(
                (r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(formatMoney(context, r.amount)),
                    subtitle: Text(
                      '${r.source} · ${r.date.toLocal()}'.split('.').first,
                    ),
                    trailing: r.source == RevenueSources.photobooth
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete entry?'),
                                  content: const Text('Remove this photobooth revenue record?'),
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
                                final removed =
                                    await context.read<SoradeController>().deleteRevenue(r.id);
                                if (!removed && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This row is protected (linked to an order).'),
                                    ),
                                  );
                                }
                              }
                            },
                          )
                        : Tooltip(
                            message: 'From order — cannot delete',
                            child: Icon(
                              Icons.lock_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                  ),
                ),
              ),
      ],
    );
  }

  Future<void> _addPhotobooth(BuildContext context) async {
    final amountCtrl = TextEditingController();
    var date = DateTime.now();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Photobooth income'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${date.toLocal()}'.split('.').first),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setLocal(() => date = picked);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      final v = double.tryParse(amountCtrl.text.trim()) ?? 0;
      amountCtrl.dispose();
      if (v > 0) {
        await context.read<SoradeController>().addPhotoboothRevenue(amount: v, date: date);
      }
    } else {
      amountCtrl.dispose();
    }
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SoradeController>();
    final list = c.expenses;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        FilledButton.icon(
          onPressed: () => _addExpense(context),
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: Text('No expenses yet.')),
          )
        else
          ...list.take(120).map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(e.title.isEmpty ? 'Expense' : e.title),
                    subtitle: Text('${e.category} · ${e.date.toLocal()}'.split('.').first),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatMoney(context, e.amount),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete expense?'),
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
                              await context.read<SoradeController>().deleteExpense(e.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Future<void> _addExpense(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var category = ExpenseCategories.variable;
    var date = DateTime.now();

    final presets = ['Rent', 'Salary', 'Electricity', 'Restocking', 'Supplies'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('New expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets
                      .map(
                        (p) => ActionChip(
                          label: Text(p),
                          onPressed: () => titleCtrl.text = p,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(
                      value: ExpenseCategories.fixed,
                      child: Text('Fixed'),
                    ),
                    DropdownMenuItem(
                      value: ExpenseCategories.variable,
                      child: Text('Variable'),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => category = v ?? ExpenseCategories.variable),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text('${date.toLocal()}'.split('.').first),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setLocal(() => date = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      final title = titleCtrl.text.trim();
      final v = double.tryParse(amountCtrl.text.trim()) ?? 0;
      titleCtrl.dispose();
      amountCtrl.dispose();
      if (title.isNotEmpty && v > 0) {
        await context.read<SoradeController>().addExpense(
              title: title,
              amount: v,
              category: category,
              date: date,
            );
      }
    } else {
      titleCtrl.dispose();
      amountCtrl.dispose();
    }
  }
}
