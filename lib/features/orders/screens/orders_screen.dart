import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order_model.dart';
import '../orders_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(customerOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                subtitle: 'Your past and active orders will appear here.',
                actionLabel: 'Start Shopping',
                onAction: () => context.go(AppRoutes.home),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _OrderTile(order: list[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.track(order.orderId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Order #${order.orderId.substring(0, 6).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                OrderStatusChip(status: order.orderStatus),
              ],
            ),
            const SizedBox(height: 6),
            Text('${order.itemCount} items • ${Formatters.currency(order.totalAmount)}',
                style: const TextStyle(color: AppColors.textSecondary)),
            if (order.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(Formatters.dateTime(order.createdAt!),
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Coloured chip for an [OrderStatus]. Reused on seller/rider screens.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});
  final OrderStatus status;

  Color get _color => switch (status) {
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled || OrderStatus.rejected => AppColors.error,
        OrderStatus.outForDelivery ||
        OrderStatus.pickedUp ||
        OrderStatus.riderAssigned =>
          AppColors.info,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              color: _color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
