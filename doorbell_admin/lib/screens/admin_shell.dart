import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_providers.dart';
import 'dashboard_screen.dart';
import 'users_screen.dart';
import 'shops_screen.dart';
import 'riders_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'notifications_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

/// The admin shell with a NavigationRail on the left and content on the right.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.selectedIndex});
  final int selectedIndex;

  static const _routes = [
    '/',
    '/users',
    '/shops',
    '/riders',
    '/orders',
    '/products',
    '/notifications',
    '/analytics',
    '/settings',
  ];

  static const _labels = [
    'Dashboard',
    'Users',
    'Sellers',
    'Riders',
    'Orders',
    'Products',
    'Notifications',
    'Analytics',
    'Settings',
  ];

  static const _icons = [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.store_rounded,
    Icons.delivery_dining_rounded,
    Icons.receipt_long_rounded,
    Icons.inventory_2_rounded,
    Icons.notifications_rounded,
    Icons.analytics_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminUser = ref.watch(adminUserProvider).value;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 900,
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(_routes[i]),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFF34C759),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (MediaQuery.of(context).size.width > 900)
                    const Text(
                      'DoorBell Admin',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34C759),
                      ),
                    ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (adminUser != null) ...[
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(
                            0xFF34C759,
                          ).withAlpha(40),
                          child: Text(
                            adminUser.name.isNotEmpty
                                ? adminUser.name[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Color(0xFF34C759),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        tooltip: 'Sign Out',
                        onPressed: () =>
                            ref.read(firebaseAuthProvider).signOut(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: List.generate(
              _labels.length,
              (i) => NavigationRailDestination(
                icon: Icon(_icons[i]),
                label: Text(_labels[i]),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const UsersScreen();
      case 2:
        return const ShopsScreen();
      case 3:
        return const RidersScreen();
      case 4:
        return const OrdersScreen();
      case 5:
        return const ProductsScreen();
      case 6:
        return const AdminNotificationsScreen();
      case 7:
        return const AnalyticsScreen();
      case 8:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }
}
