import 'package:flutter/material.dart';
import 'package:sorade/core/brand_colors.dart';

/// In-app guide: recommended workflows and what each area of the app does.
class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bodySmall = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: cs.onSurface,
        );
    final sectionTitle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: BrandColors.primaryGreen,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('How to use Sora de'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Sora de helps you run gifting and photobooth sales: stock, customer orders, money in/out, and monthly reports. Everything below the top bar is organized in five tabs.',
            style: bodySmall,
          ),
          const SizedBox(height: 20),
          Text('Recommended daily flow', style: sectionTitle),
          const SizedBox(height: 8),
          _NumberedStep(
            n: 1,
            title: 'Open Home',
            body:
                'Check today’s sales, this month’s revenue and expenses, profit summary, and any low-stock alerts. Pull down on the list to refresh numbers from the server.',
          ),
          _NumberedStep(
            n: 2,
            title: 'Record booth or walk-in cash',
            body:
                'Go to Money → Revenue. Add photobooth revenue for the day (or per session) and pick the date. Product revenue from gift orders is counted automatically when you create orders.',
          ),
          _NumberedStep(
            n: 3,
            title: 'Sell a gift bundle',
            body:
                'Go to Orders → New order. Add line items (or start from a Bundle preset), set customer name and optional message, then save. Stock for each line is reduced automatically.',
          ),
          _NumberedStep(
            n: 4,
            title: 'Log what you spent',
            body:
                'Go to Money → Expenses. Add rent, supplies, or other costs with amount and date so monthly profit stays accurate.',
          ),
          _NumberedStep(
            n: 5,
            title: 'Review the month',
            body:
                'Use Reports to move between calendar months, see COGS, gross margin on product sales, inventory usage, and export CSV to share or archive.',
          ),
          const SizedBox(height: 16),
          Text('Bottom navigation', style: sectionTitle),
          const SizedBox(height: 8),
          _ExpandableGuide(
            title: 'Home (Dashboard)',
            child: Text(
              'Snapshot of the business: today’s total sales, this month’s revenue and expenses, accessible profit summary, and a list of items that are low on stock.\n\n'
              'Pull to refresh if you want to force the latest data from Firebase. Low-stock items link back to inventory levels you set on each product.',
              style: bodySmall,
            ),
          ),
          _ExpandableGuide(
            title: 'Stock (Inventory)',
            child: Text(
              'Your catalog: products you sell in bundles, supplies, and utility items.\n\n'
              '• Add: tap the floating “add” button, fill name, kind, quantity, unit price, optional photo, supplier, and cost per unit (used for margin in reports).\n'
              '• Search and filters: narrow the list by type (product / supply / utility) or search by name, type label, or supplier.\n'
              '• Edit: open an item to change details, photo, reorder thresholds, or delete.\n'
              '• Adjust stock: quick add/remove units with a reason (damage, recount, etc.) without going through a sale.\n\n'
              'Accurate quantities and costs make order fulfillment and monthly COGS reliable.',
              style: bodySmall,
            ),
          ),
          _ExpandableGuide(
            title: 'Orders',
            child: Text(
              'Gift orders tie revenue to inventory usage.\n\n'
              '• New order: add one or more inventory lines, set quantity and sale price per line (defaults can come from the item). Enter customer name and optional personalized message, then submit.\n'
              '• Bundle presets: save common combinations (e.g. “Standard hamper”) under Bundle presets. From New order you can apply a preset to fill lines in one step; the app checks stock before applying.\n'
              '• After saving, each line reduces stock for that inventory item. Product revenue from orders flows into Money and Reports for the order date.\n\n'
              'Use presets for speed; use one-off lines for custom bundles.',
              style: bodySmall,
            ),
          ),
          _ExpandableGuide(
            title: 'Money',
            child: Text(
              'Two tabs:\n\n'
              'Revenue\n'
              '• Product (orders): driven by gift orders you create — no duplicate entry needed for those sales.\n'
              '• Photobooth: add entries manually when you collect booth fees; pick amount and date.\n'
              '• You can remove mistaken revenue entries from the list where supported.\n\n'
              'Expenses\n'
              '• Record operating costs (rent, props, transport, etc.) with category-style labels, amount, and date.\n'
              '• Expenses roll into the same month as Reports and Dashboard.\n\n'
              'Together, revenue and expenses define monthly profit in Reports.',
              style: bodySmall,
            ),
          ),
          _ExpandableGuide(
            title: 'Reports',
            child: Text(
              'Pick any calendar month with the arrows. You’ll see revenue, expenses, net, product sales, estimated COGS from orders, gross margin, and how much of each inventory item was used in that month.\n\n'
              'There is often a six-month trend chart for context. Use Share / export CSV when you need a spreadsheet for tax, partners, or your own files.\n\n'
              'Margins depend on cost per unit on inventory items and actual order lines — keep inventory costs up to date.',
              style: bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          Text('Account & profile (this screen)', style: sectionTitle),
          const SizedBox(height: 8),
          Text(
            'From any main screen, open the person icon in the top app bar to reach Account & settings. There you see your email, verification status, and can change your password (email/password accounts only). Sign out is available from the same bar.',
            style: bodySmall,
          ),
          const SizedBox(height: 16),
          Text('Sync & devices', style: sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Data is stored in Firebase under your signed-in account. The banner under the app bar reminds you that data is synced. Use the same login on another phone or browser to see the same inventory, orders, and finances.\n\n'
            'If the network is slow, the app may still show cached data until the connection catches up.',
            style: bodySmall,
          ),
          const SizedBox(height: 16),
          Text('Tips', style: sectionTitle),
          const SizedBox(height: 8),
          Text(
            '• Set low-stock thresholds when editing inventory so Home highlights what to reorder.\n'
            '• Define bundle presets for packages you sell repeatedly.\n'
            '• Enter photobooth revenue on the days you actually collect it so “today” and monthly totals match reality.\n'
            '• Reconcile stock with “Adjust stock” after physical counts.',
            style: bodySmall,
          ),
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({
    required this.n,
    required this.title,
    required this.body,
  });

  final int n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: BrandColors.primaryPink.withValues(alpha: 0.2),
            child: Text(
              '$n',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: BrandColors.primaryPink,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: cs.onSurface,
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

class _ExpandableGuide extends StatefulWidget {
  const _ExpandableGuide({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  State<_ExpandableGuide> createState() => _ExpandableGuideState();
}

class _ExpandableGuideState extends State<_ExpandableGuide> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            trailing: Icon(_open ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
