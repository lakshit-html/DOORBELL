import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/shop_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../location/location_provider.dart';
import '../product_providers.dart';

// ---------------------------------------------------------------------------
// Price comparison provider
// ---------------------------------------------------------------------------

/// Finds the same product (matched by name, case-insensitive) in all nearby
/// shops and returns them sorted cheapest-first.
final priceComparisonProvider = FutureProvider.autoDispose
    .family<List<_ShopPrice>, String>((ref, productName) async {
  final location = ref.watch(locationProvider).value;
  final lat = location?.latitude ?? 26.3016;
  final lng = location?.longitude ?? 73.0179;

  final shops = await ref
      .read(shopRepositoryProvider)
      .nearbyShops(lat: lat, lng: lng);

  final results = <_ShopPrice>[];
  final lName = productName.toLowerCase().trim();

  for (final sw in shops) {
    final products = await ref
        .read(productRepositoryProvider)
        .search(productName, shopId: sw.shop.shopId);
    for (final p in products) {
      if (p.name.toLowerCase().trim() == lName && p.inStock) {
        results.add(_ShopPrice(
          shop: sw.shop,
          product: p,
          distanceKm: sw.distanceKm,
        ));
        break; // one entry per shop
      }
    }
  }
  results.sort((a, b) => a.product.effectivePrice.compareTo(b.product.effectivePrice));
  return results;
});

class _ShopPrice {
  const _ShopPrice({
    required this.shop,
    required this.product,
    required this.distanceKm,
  });
  final ShopModel shop;
  final ProductModel product;
  final double distanceKm;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(productId));
    final reviews = ref.watch(productReviewsProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: product.when(
        data: (p) {
          if (p == null) {
            return const EmptyState(
                icon: Icons.inventory_2_outlined, title: 'Product not found');
          }
          final qty = ref.watch(cartProvider).quantityOf(p.productId);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Product image ────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AppNetworkImage(
                          url: p.image, height: 240, width: double.infinity),
                    ),
                    const SizedBox(height: 16),

                    // ── Name + badges ────────────────────────────────────
                    Row(children: [
                      Expanded(
                        child: Text(p.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      if (!p.inStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Out of stock',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(p.unit,
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),

                    // ── Price ────────────────────────────────────────────
                    Row(children: [
                      Text(Formatters.currency(p.effectivePrice),
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary)),
                      if (p.hasDiscount) ...[
                        const SizedBox(width: 10),
                        Text(Formatters.currency(p.price),
                            style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${p.discountPercent}% off',
                              style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 12),
                    Text(p.description.isEmpty
                        ? 'Fresh, quality product delivered to your door.'
                        : p.description),
                    const SizedBox(height: 24),

                    // ── Price comparison ─────────────────────────────────
                    _PriceComparisonSection(
                        productName: p.name, currentProductId: p.productId),
                    const SizedBox(height: 24),

                    // ── Reviews ──────────────────────────────────────────
                    Text('Reviews',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    reviews.when(
                      data: (list) => list.isEmpty
                          ? const Text('No reviews yet.',
                              style: TextStyle(
                                  color: AppColors.textSecondary))
                          : Column(
                              children: list
                                  .map((r) => _ReviewTile(review: r))
                                  .toList()),
                      loading: () => const SizedBox(
                          height: 40,
                          child: Center(
                              child: CircularProgressIndicator())),
                      error: (e, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // ── Add to cart bar ──────────────────────────────────────
              if (p.inStock)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border:
                        Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: qty == 0
                      ? PrimaryButton(
                          label: 'Add to Cart',
                          onPressed: () {
                            ref
                                .read(cartProvider.notifier)
                                .add(p);
                            AppSnackbar.success(
                                context, '${p.name} added to cart');
                          },
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            QuantityStepper(
                              quantity: qty,
                              onRemove: () => ref
                                  .read(cartProvider.notifier)
                                  .decrement(p),
                              onAdd: () => ref
                                  .read(cartProvider.notifier)
                                  .add(p),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              Formatters.currency(
                                  p.effectivePrice * qty),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, __) =>
            EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price comparison section
// ---------------------------------------------------------------------------

class _PriceComparisonSection extends ConsumerWidget {
  const _PriceComparisonSection({
    required this.productName,
    required this.currentProductId,
  });
  final String productName;
  final String currentProductId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref.watch(priceComparisonProvider(productName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.compare_arrows, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('Compare prices nearby',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        comparison.when(
          data: (list) {
            if (list.isEmpty) {
              return const Text(
                'No other shops carry this item nearby.',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: list.map((sp) {
                final isCurrent = sp.product.productId == currentProductId;
                return _PriceRow(
                  shopPrice: sp,
                  isCurrent: isCurrent,
                  onTap: isCurrent
                      ? null
                      : () => context.push(
                          AppRoutes.product(sp.product.productId)),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Checking nearby shops…',
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.shopPrice,
    required this.isCurrent,
    this.onTap,
  });
  final _ShopPrice shopPrice;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = shopPrice.product;
    final s = shopPrice.shop;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(children: [
          // Shop thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AppNetworkImage(
                url: s.coverImage, width: 40, height: 40),
          ),
          const SizedBox(width: 12),
          // Shop + distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(s.shopName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (isCurrent)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Text('current',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
                Text(
                  '${shopPrice.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatters.currency(p.effectivePrice),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isCurrent
                          ? AppColors.primary
                          : AppColors.success,
                      fontSize: 15)),
              if (p.hasDiscount)
                Text(Formatters.currency(p.price),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.lineThrough)),
            ],
          ),
          if (!isCurrent) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 18),
          ],
        ]),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final dynamic review;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person_outline, color: AppColors.primary),
        ),
        title: Row(children: [
          ...List.generate(
              5,
              (i) => Icon(
                    i < (review.rating as double).round()
                        ? Icons.star
                        : Icons.star_border,
                    size: 14,
                    color: AppColors.warning,
                  )),
          const SizedBox(width: 6),
          Text(Formatters.relativeTime(review.createdAt),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ]),
        subtitle: Text(review.comment as String),
      );
}
