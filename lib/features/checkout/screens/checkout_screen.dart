import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/address_model.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/wallet_model.dart';
import '../../../data/services/payment_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cart/providers/cart_provider.dart';
import '../../profile/address_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressModel? _selectedAddress;
  PaymentMethod _method = PaymentMethod.cod;
  DeliverySlot _slot = DeliverySlot.asap;
  bool _placing = false;

  /// Payment methods shown in checkout.
  static const _paymentMethods = [
    PaymentMethod.cod,
    PaymentMethod.wallet,
    PaymentMethod.razorpay,
    PaymentMethod.upi,
    PaymentMethod.card,
  ];

  Future<void> _placeOrder() async {
    final cart = ref.read(cartProvider);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    if (_selectedAddress == null) {
      AppSnackbar.error(context, 'Please select a delivery address');
      return;
    }
    if (cart.shopId == null) return;

    setState(() => _placing = true);

    var paymentStatus = PaymentStatus.pending;
    String? paymentId;

    if (_method.requiresGateway) {
      final gateway = PaymentService.gatewayFor(_method);
      try {
        final result = await gateway.pay(
          amount: cart.total,
          name: 'DoorBell',
          description: 'Order payment',
          email: user.email,
          contact: user.phone,
        );
        gateway.dispose();
        if (!result.success) {
          if (mounted) {
            setState(() => _placing = false);
            AppSnackbar.error(context, result.error ?? 'Payment failed');
          }
          return;
        }
        paymentStatus = PaymentStatus.paid;
        paymentId = result.paymentId;
      } catch (e) {
        gateway.dispose();
        if (mounted) {
          setState(() => _placing = false);
          AppSnackbar.error(context, e.toString());
        }
        return;
      }
    } else if (_method == PaymentMethod.wallet) {
      try {
        await ref.read(walletRepositoryProvider).applyTransaction(
              user.uid,
              type: TransactionType.debit,
              amount: cart.total,
              description: 'Order payment',
            );
        paymentStatus = PaymentStatus.paid;
      } catch (e) {
        if (mounted) {
          setState(() => _placing = false);
          AppSnackbar.error(context, 'Wallet: $e');
        }
        return;
      }
    }

    final order = OrderModel(
      orderId: '',
      customerId: user.uid,
      shopId: cart.shopId!,
      items: cart.items
          .map(
            (e) => OrderItem(
              productId: e.product.productId,
              name: e.product.name,
              image: e.product.image,
              price: e.product.effectivePrice,
              quantity: e.quantity,
            ),
          )
          .toList(),
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      discount: cart.discount,
      totalAmount: cart.total,
      paymentMethod: _method,
      paymentStatus: paymentStatus,
      orderStatus: OrderStatus.placed,
      deliveryAddress: _selectedAddress!,
      couponCode: cart.coupon?.code,
      razorpayPaymentId: paymentId,
      scheduledSlot: _slot == DeliverySlot.asap ? null : _slot,
    );

    final result = await ref.read(orderRepositoryProvider).placeOrder(order);
    if (!mounted) return;
    setState(() => _placing = false);

    result.when(
      success: (orderId) {
        ref.read(cartProvider.notifier).clear();
        ref.read(analyticsServiceProvider).logPurchase(order.totalAmount, orderId);
        context.go(AppRoutes.track(orderId));
      },
      failure: (f) => AppSnackbar.error(context, f.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final addresses = ref.watch(addressesProvider);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Your cart is empty',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Delivery Address ─────────────────────────────────────────
          _sectionTitle(context, 'Delivery Address'),
          addresses.when(
            data: (list) {
              if (list.isEmpty) {
                return _AddAddressPrompt(
                  onTap: () => context.push(AppRoutes.addresses),
                );
              }
              _selectedAddress ??= list.firstWhere(
                (a) => a.isDefault,
                orElse: () => list.first,
              );
              return Column(
                children: list
                    .map(
                      (a) => RadioListTile<AddressModel>(
                        value: a,
                        groupValue: _selectedAddress,
                        onChanged: (v) => setState(() => _selectedAddress = v),
                        title: Text(
                          a.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(a.formatted),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Text('$e'),
          ),
          const SizedBox(height: 16),

          // ── Delivery Slot ─────────────────────────────────────────────
          _sectionTitle(context, 'Delivery Time'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DeliverySlot>(
                value: _slot,
                isExpanded: true,
                items: DeliverySlot.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => setState(() => _slot = v!),
              ),
            ),
          ),
          if (_slot != DeliverySlot.asap)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${_slot.label}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ── Payment Method ────────────────────────────────────────────
          _sectionTitle(context, 'Payment Method'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _paymentMethods.map((m) {
                return RadioListTile<PaymentMethod>(
                  value: m,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: Text(m.label),
                  secondary: Icon(_paymentIcon(m), color: AppColors.primary),
                  dense: true,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Order Summary ─────────────────────────────────────────────
          _sectionTitle(context, 'Order Summary'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _row('Items (${cart.totalItems})', Formatters.currency(cart.subtotal)),
                _row(
                  'Delivery',
                  cart.deliveryFee == 0 ? 'FREE' : Formatters.currency(cart.deliveryFee),
                ),
                if (cart.discount > 0)
                  _row('Discount', '- ${Formatters.currency(cart.discount)}'),
                const Divider(),
                _row('To Pay', Formatters.currency(cart.total), bold: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'Place Order • ${Formatters.currency(cart.total)}',
            isLoading: _placing,
            onPressed: _placeOrder,
          ),
        ),
      ),
    );
  }

  IconData _paymentIcon(PaymentMethod m) => switch (m) {
        PaymentMethod.cod => Icons.payments_outlined,
        PaymentMethod.upi => Icons.account_balance_outlined,
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.wallet => Icons.account_balance_wallet_outlined,
        PaymentMethod.razorpay => Icons.bolt,
      };

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      );

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
            Text(value,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ],
        ),
      );
}

class _AddAddressPrompt extends StatelessWidget {
  const _AddAddressPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
        title: const Text('Add a delivery address'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
