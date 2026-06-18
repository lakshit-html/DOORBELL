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
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _coupon = TextEditingController();
  bool _applying = false;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _coupon.text.trim();
    if (code.isEmpty) return;
    setState(() => _applying = true);
    final coupon = await ref.read(couponRepositoryProvider).getByCode(code);
    if (!mounted) return;
    setState(() => _applying = false);
    if (coupon == null) {
      AppSnackbar.error(context, 'Invalid coupon code');
      return;
    }
    final (_, error) =
        coupon.discountFor(ref.read(cartProvider).subtotal);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    ref.read(cartProvider.notifier).applyCoupon(coupon);
    AppSnackbar.success(context, 'Coupon applied!');
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add items from a store to get started.',
              actionLabel: 'Browse Stores',
              onAction: () => context.go(AppRoutes.home),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...cart.items.map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                AppNetworkImage(
                                    url: item.product.image,
                                    width: 60,
                                    height: 60),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(item.product.unit,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                          Formatters.currency(item.lineTotal),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                                QuantityStepper(
                                  quantity: item.quantity,
                                  compact: true,
                                  onAdd: () => ref
                                      .read(cartProvider.notifier)
                                      .add(item.product),
                                  onRemove: () => ref
                                      .read(cartProvider.notifier)
                                      .decrement(item.product),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                      // Coupon row
                      if (cart.coupon == null)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _coupon,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'Enter coupon code',
                                  prefixIcon: Icon(Icons.local_offer_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SecondaryButton(
                              label: _applying ? '…' : 'Apply',
                              onPressed: _applying ? null : _applyCoupon,
                            ),
                          ],
                        )
                      else
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_circle,
                              color: AppColors.success),
                          title: Text('${cart.coupon!.code} applied'),
                          subtitle:
                              Text('You saved ${Formatters.currency(cart.discount)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                ref.read(cartProvider.notifier).removeCoupon(),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _BillSummary(cart: cart),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PrimaryButton(
                      label:
                          'Proceed to Checkout • ${Formatters.currency(cart.total)}',
                      onPressed: () => context.push(AppRoutes.checkout),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BillSummary extends StatelessWidget {
  const _BillSummary({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row('Subtotal', Formatters.currency(cart.subtotal)),
          _row(
              'Delivery Fee',
              cart.deliveryFee == 0
                  ? 'FREE'
                  : Formatters.currency(cart.deliveryFee)),
          if (cart.discount > 0)
            _row('Discount', '- ${Formatters.currency(cart.discount)}',
                color: AppColors.success),
          const Divider(),
          _row('Total', Formatters.currency(cart.total), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
          {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: color)),
          ],
        ),
      );
}
