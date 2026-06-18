import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/shop_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../location/location_provider.dart';
import '../../notifications/notification_providers.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const userLat = 0.0;
    const userLng = 0.0;

    final nearbyShops = ref.watch(nearbyShopsProvider);
    final categories = ref.watch(categoriesProvider);
    final popularProducts = ref.watch(popularProductsProvider);
    final unread = ref.watch(unreadCountProvider);
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(locationProvider.notifier).refresh();
          ref.invalidate(nearbyShopsProvider);
          ref.invalidate(popularProductsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              expandedHeight: 116,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Deliver to ${user?.name ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    location.value?.address ??
                                        'Detecting location…',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _IconBadge(
                              icon: Icons.notifications_outlined,
                              count: unread,
                              onTap: () =>
                                  context.push(AppRoutes.notifications),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.search),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Text(
                          'Search for groceries, stores…',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _PromoBanner()),

            // Categories
            SliverToBoxAdapter(
              child: categories.when(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : _Section(
                        title: 'Shop by Category',
                        child: SizedBox(
                          height: 104,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) {
                              final c = list[i];
                              return GestureDetector(
                                onTap: () => context.push(
                                  '${AppRoutes.category(c.categoryId)}?name=${c.name}',
                                ),
                                child: Column(
                                  children: [
                                    AppNetworkImage(
                                      url: c.image,
                                      height: 64,
                                      width: 64,
                                      borderRadius: 18,
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 68,
                                      child: Text(
                                        c.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Popular products
            SliverToBoxAdapter(
              child: popularProducts.when(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : _Section(
                        title: 'Popular Right Now',
                        child: SizedBox(
                          height: 230,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) => SizedBox(
                              width: 150,
                              child: ProductCard(
                                product: list[i],
                                onTap: () => context.push(
                                  AppRoutes.product(list[i].productId),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: SizedBox(),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Nearby shops
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Stores Near You',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            nearbyShops.when(
              data: (list) => list.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.store_mall_directory_outlined,
                        title: 'No stores nearby yet',
                        subtitle:
                            'We are expanding fast. Check back soon for stores '
                            'in your area.',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            ShopCard(
                                  shop: list[i].shop,
                                  distanceKm: list[i].distanceKm,
                                  onTap: () => context.push(
                                    AppRoutes.shop(list[i].shop.shopId),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: (i * 60).ms)
                                .slideY(begin: 0.1),
                      ),
                    ),
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, __) => SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load stores',
                  subtitle: '$e',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        child,
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 140,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.local_grocery_store,
              size: 140,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Free delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'On your first order above ₹499',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Code: LOCAL50',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97));
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.count,
    required this.onTap,
  });
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
