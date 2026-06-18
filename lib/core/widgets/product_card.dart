import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_model.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'app_network_image.dart';
import 'app_snackbar.dart';
import 'quantity_stepper.dart';

/// Grid product card with inline add-to-cart. Handles the single-shop cart rule
/// by prompting before replacing items from another shop.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final ProductModel product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider).quantityOf(product.productId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: product.image,
                  height: 110,
                  width: double.infinity,
                  borderRadius: 16,
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${product.discountPercent}% OFF',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(product.unit,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Formatters.currency(product.effectivePrice),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                            if (product.hasDiscount)
                              Text(Formatters.currency(product.price),
                                  style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.textHint,
                                      fontSize: 11)),
                          ],
                        ),
                      ),
                      if (!product.inStock)
                        const Text('Out',
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w600))
                      else if (qty == 0)
                        _AddButton(
                            onTap: () => _add(context, ref))
                      else
                        QuantityStepper(
                          quantity: qty,
                          compact: true,
                          onAdd: () => _add(context, ref),
                          onRemove: () => ref
                              .read(cartProvider.notifier)
                              .decrement(product),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    if (notifier.wouldReplaceCart(product)) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start a new cart?'),
          content: const Text(
              'Your cart has items from another store. Adding this will clear '
              'the current cart.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                notifier.add(product, replace: true);
                Navigator.pop(ctx);
              },
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      return;
    }
    notifier.add(product);
    AppSnackbar.success(context, '${product.name} added to cart');
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(54, 30),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        side: const BorderSide(color: AppColors.primary),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('ADD',
          style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12)),
    );
  }
}
