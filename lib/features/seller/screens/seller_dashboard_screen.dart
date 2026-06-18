import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/enums.dart';
import '../../auth/providers/auth_providers.dart';
import '../../orders/screens/orders_screen.dart';
import '../seller_providers.dart';
import 'product_form_sheet.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(myShopProvider);

    return shop.when(
      data: (s) {
        if (s == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Seller'),
              actions: [_signOut(ref)],
            ),
            body: EmptyState(
              icon: Icons.storefront_outlined,
              title: 'Register your store',
              subtitle: 'Set up your shop to start selling on DoorBell.',
              actionLabel: 'Register Store',
              onAction: () => context.push(AppRoutes.sellerRegister),
            ),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(s.shopName),
              actions: [
                if (!s.isApproved)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Chip(
                        label: Text(
                          // ignore: unrelated_type_equality_checks
                          s.approvalStatus == 'rejected'
                              ? 'Rejected'
                              : 'Pending approval',
                          style: TextStyle(
                            // ignore: unrelated_type_equality_checks
                            color: s.approvalStatus == 'rejected'
                                ? AppColors.error
                                : null,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                _signOut(ref),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Inventory'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [_OverviewTab(), _OrdersTab(), _InventoryTab()],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, __) => Scaffold(
        body: EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }

  Widget _signOut(WidgetRef ref) => IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
  );
}

// ---- Overview ----

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(sellerStatsProvider);
    final lowStock = ref.watch(lowStockProductsProvider).value ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Low-stock alert banner
        if (lowStock.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lowStock.length} item${lowStock.length > 1 ? 's' : ''} running low on stock',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        lowStock.map((p) => p.name).join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        Row(
          children: [
            _StatCard(
              title: 'Revenue',
              value: Formatters.currency(stats.revenue),
              icon: Icons.currency_rupee,
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: 'Total Orders',
              value: '${stats.orders}',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              title: 'Pending',
              value: '${stats.pending}',
              icon: Icons.pending_actions,
              color: AppColors.warning,
            ),
            const SizedBox(width: 12),
            _StatCard(
              title: 'Avg. Order',
              value: Formatters.currency(
                stats.orders == 0 ? 0 : stats.revenue / stats.orders,
              ),
              icon: Icons.show_chart,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ---- Orders ----

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myShopOrdersProvider);
    return orders.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final o = list[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${o.orderId.substring(0, 6).toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            OrderStatusChip(status: o.orderStatus),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${o.itemCount} items • ${Formatters.currency(o.totalAmount)}',
                        ),
                        if (o.scheduledSlot != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  o.scheduledSlot!.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        _orderActions(ref, o),
                      ],
                    ),
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
    );
  }

  Widget _orderActions(WidgetRef ref, o) {
    final repo = ref.read(orderRepositoryProvider);
    switch (o.orderStatus as OrderStatus) {
      case OrderStatus.placed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    repo.updateStatus(o.orderId, OrderStatus.rejected),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    repo.updateStatus(o.orderId, OrderStatus.accepted),
                child: const Text('Accept'),
              ),
            ),
          ],
        );
      case OrderStatus.accepted:
        return FilledButton(
          onPressed: () => repo.updateStatus(o.orderId, OrderStatus.preparing),
          child: const Text('Start Preparing'),
        );
      case OrderStatus.preparing:
        return FilledButton(
          onPressed: () =>
              repo.updateStatus(o.orderId, OrderStatus.readyForPickup),
          child: const Text('Mark Ready for Pickup'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---- Inventory ----

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(myShopProductsProvider);
    final shop = ref.watch(myShopProvider).value;
    final threshold = shop?.lowStockThreshold ?? 5;

    return Scaffold(
      floatingActionButton: shop == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => ProductFormSheet(shopId: shop.shopId),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
      body: products.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No products',
                subtitle: 'Add your first product to start selling.',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  final isLow = p.stock > 0 && p.stock <= threshold;
                  return Card(
                    child: ListTile(
                      leading: AppNetworkImage(
                        url: p.image,
                        width: 48,
                        height: 48,
                      ),
                      title: Text(p.name),
                      subtitle: Row(
                        children: [
                          Text(
                            '${Formatters.currency(p.effectivePrice)} • Stock: ${p.stock}',
                          ),
                          if (isLow)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.warning_amber,
                                size: 14,
                                color: AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit' && shop != null) {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => ProductFormSheet(
                                shopId: shop.shopId,
                                existing: p,
                              ),
                            );
                          } else if (v == 'delete') {
                            ref
                                .read(productRepositoryProvider)
                                .deleteProduct(p.productId);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }
}
