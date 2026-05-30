import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sorade/screens/dashboard_screen.dart';
import 'package:sorade/screens/finance_screen.dart';
import 'package:sorade/screens/inventory_screen.dart';
import 'package:sorade/screens/orders_screen.dart';
import 'package:sorade/screens/reports_screen.dart';
import 'package:sorade/screens/settings_screen.dart';
import 'package:sorade/screens/daily_collection_staff_screen.dart';
import 'package:sorade/screens/daily_collection_admin_screen.dart';
import 'package:sorade/state/sorade_controller.dart';
import 'package:sorade/widgets/local_data_banner.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SoradeController>();
    final isAdmin = controller.currentUserRole?.isAdmin ?? true; // Default to admin while loading

    final titles = isAdmin
        ? ['Dashboard', 'Inventory', 'Orders', 'Money', 'Reports', 'Collections']
        : ['Daily Sales', 'Inventory', 'Orders'];

    final screens = isAdmin
        ? const [
            DashboardScreen(),
            InventoryScreen(),
            OrdersScreen(),
            FinanceScreen(),
            ReportsScreen(),
            DailyCollectionAdminScreen(),
          ]
        : const [
            DailyCollectionStaffScreen(),
            InventoryScreen(),
            OrdersScreen(),
          ];

    final destinations = isAdmin
        ? const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Money'),
            NavigationDestination(icon: Icon(Icons.assessment_outlined), selectedIcon: Icon(Icons.assessment), label: 'Reports'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Collections'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          ];

    final activeIndex = _index >= screens.length ? 0 : _index;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[activeIndex]),
        actions: [
          IconButton(
            tooltip: 'Account & settings',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LocalDataBanner(),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: activeIndex,
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
