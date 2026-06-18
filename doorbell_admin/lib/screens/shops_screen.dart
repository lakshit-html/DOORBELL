import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shop_model.dart';
import '../models/enums.dart';
import '../providers/admin_providers.dart';

class ShopsScreen extends ConsumerWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(allShopsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Seller Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Expanded(
            child: shopsAsync.when(
              data: (shops) => shops.isEmpty
                  ? const Center(child: Text('No shops found'))
                  : ListView.builder(
                      itemCount: shops.length,
                      itemBuilder: (_, i) => _ShopTile(shop: shops[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopTile extends ConsumerWidget {
  const _ShopTile({required this.shop});
  final ShopModel shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = shop.approvalStatus == ApprovalStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withAlpha(30),
          child: const Icon(Icons.store, color: Colors.green),
        ),
        title: Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${shop.address} • ${shop.totalOrders} orders • Rating: ${shop.rating.toStringAsFixed(1)}',
          style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                shop.approvalStatus.label,
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              IconButton(
                icon: const Icon(Icons.block, color: Colors.orange, size: 20),
                tooltip: 'Suspend',
                onPressed: () => ref.read(adminActionsProvider).suspendShop(shop.shopId),
              )
            else
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                tooltip: 'Reactivate',
                onPressed: () => ref.read(adminActionsProvider).reactivateShop(shop.shopId),
              ),
          ],
        ),
      ),
    );
  }
}
