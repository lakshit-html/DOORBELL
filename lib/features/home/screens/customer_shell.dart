import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../cart/providers/cart_provider.dart';
import '../../emitra/screens/emitra_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/search_screen.dart';
import 'home_screen.dart';

/// Customer bottom-navigation shell with 5 tabs: Home, Search, E-Mitra, Orders, Profile.
class CustomerShell extends ConsumerStatefulWidget {
  const CustomerShell({super.key});

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    SearchScreen(),
    EMitraScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: cart.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CartBar(
                items: cart.totalItems,
                total: cart.total,
                onTap: () => context.push(AppRoutes.cart),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.print_outlined),
              activeIcon: Icon(Icons.print),
              label: 'E-Mitra'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar(
      {required this.items, required this.total, required this.onTap});

  final int items;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            const SizedBox(width: 10),
            Text('$items item${items > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${Formatters.currency(total)}  •  View Cart',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
