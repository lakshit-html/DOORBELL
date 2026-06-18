import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_card.dart';
import '../shop_providers.dart';

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopProvider(shopId));
    final products = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      body: shop.when(
        data: (s) {
          if (s == null) {
            return const EmptyState(
                icon: Icons.store_outlined, title: 'Store not found');
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(s.shopName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                          url: s.coverImage, borderRadius: 0),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _badge(Icons.star, s.rating.toStringAsFixed(1),
                              AppColors.success),
                          const SizedBox(width: 10),
                          _badge(Icons.shopping_bag_outlined,
                              '${s.totalOrders} orders', AppColors.info),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(s.description.isEmpty
                          ? 'Fresh products delivered to your door.'
                          : s.description),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(s.openingHours,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Products',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              products.when(
                data: (items) => items.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No products listed yet'),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.66,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => ProductCard(
                              product: items[i],
                              onTap: () => context.push(
                                  AppRoutes.product(items[i].productId)),
                            ),
                            childCount: items.length,
                          ),
                        ),
                      ),
                loading: () => const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()))),
                error: (e, __) => SliverToBoxAdapter(
                    child: Center(child: Text('$e'))),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(text,
                style:
                    TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
