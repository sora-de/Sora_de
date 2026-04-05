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
                'Go to Orders → New order. Add product lines (only items you resell — supplies and utilities never appear here) or tap a Bundle preset. Set customer name and optional message, then place the order. Stock for each line drops automatically.',
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
              'Three kinds of rows:\n'
              '• Product — what you resell on gift orders. Has a default sale price and can appear in New order and bundle presets.\n'
              '• Customization supply & Utility — booth use (pens, sanitizer, etc.). They do not appear on gift orders; track stock and cost only.\n\n'
              'Adding stock — tap the floating Add button, then choose:\n'
              '• New catalog item — first time this SKU exists. Name, category, optional photo, optional first buy (price per piece, how many pieces, date), starting stock, low-stock alert, target, and for products: sale price and unit cost (COGS).\n'
              '• Record purchase — you already have the item; you bought more. Pick the item, enter pieces bought, buy price per piece, purchase date, optional supplier and note. Stock goes up and a dated line is saved in Purchase history (receipt icon on the list, or open the item → Purchase history).\n\n'
              'Search and filters: by product / supply / utility, or search by name, type, or supplier.\n\n'
              'Edit item: change name, photo, category, supplier, thresholds, and for products sale price and COGS. For existing items you’ll also see shortcuts to Record purchase and Purchase history. Stock count itself is changed via Adjust stock or Record purchase — not by typing a new total in edit.\n\n'
              'Adjust stock: add or remove units with a required reason (damage, count correction, booth use, etc.). Use this when it is not a normal buy with a price you want to remember; use Record purchase when you want stock plus a purchase record.\n\n'
              'Accurate quantities, purchases, and COGS keep orders and monthly reports reliable.',
              style: bodySmall,
            ),
          ),
          _ExpandableGuide(
            title: 'Orders',
            child: Text(
              'Gift orders tie revenue to product inventory only.\n\n'
              '• New order: “Add product line” only lists in-stock products (resell items). Set quantity and sale price per line (defaults from the item or last price charged). Add customer name and optional message, then Place order.\n'
              '• Bundle presets: Orders → Bundle presets. Build combos from products only — supplies and utilities are excluded so presets match what New order can sell. On New order, tap a preset chip to add those lines in one step; stock is checked first.\n'
              '• After placing an order, stock drops for each line and product revenue shows in Money and Reports for that date.\n\n'
              'Use presets for repeat bundles; use Add product line for one-off mixes.',
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
            '• Use Record purchase when you restock something you already sell — you keep one catalog row and a clear history of buys and prices.\n'
            '• Set low-stock thresholds when editing items so Home highlights what to reorder.\n'
            '• Bundle presets should only include products you actually ring up on gift orders.\n'
            '• Enter photobooth revenue on the days you collect it so “today” and monthly totals match reality.\n'
            '• After a physical count, use Adjust stock with reason “Count correction” (or similar).',
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
