import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/coupon_model.dart';
import '../../../data/models/product_model.dart';

/// Immutable snapshot of the cart's computed totals.
class CartState {
  const CartState({
    this.items = const [],
    this.shopId,
    this.coupon,
    this.distanceKm = 2.0,
  });

  final List<CartItem> items;
  final String? shopId;
  final CouponModel? coupon;
  final double distanceKm;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.fold(0, (s, e) => s + e.quantity);
  double get subtotal => items.fold(0, (s, e) => s + e.lineTotal);

  double get deliveryFee {
    if (subtotal >= AppConstants.freeDeliveryThreshold || subtotal == 0) {
      return 0;
    }
    return AppConstants.baseDeliveryFee +
        (distanceKm * AppConstants.perKmDeliveryFee);
  }

  double get discount {
    if (coupon == null) return 0;
    return coupon!.discountFor(subtotal).$1;
  }

  double get total => (subtotal + deliveryFee - discount).clamp(0, double.infinity);

  int quantityOf(String productId) => items
      .where((e) => e.product.productId == productId)
      .fold(0, (s, e) => s + e.quantity);

  CartState copyWith({
    List<CartItem>? items,
    String? shopId,
    CouponModel? coupon,
    bool clearCoupon = false,
    bool clearShop = false,
    double? distanceKm,
  }) =>
      CartState(
        items: items ?? this.items,
        shopId: clearShop ? null : (shopId ?? this.shopId),
        coupon: clearCoupon ? null : (coupon ?? this.coupon),
        distanceKm: distanceKm ?? this.distanceKm,
      );
}

/// The cart. Like Zepto/Blinkit, the cart holds items from a single shop at a
/// time — adding a product from a different shop prompts a reset (handled in UI
/// via [wouldReplaceCart]).
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  bool wouldReplaceCart(ProductModel product) =>
      state.shopId != null && state.shopId != product.shopId;

  void add(ProductModel product, {bool replace = false}) {
    if (wouldReplaceCart(product)) {
      if (!replace) return;
      state = CartState(items: [CartItem(product: product, quantity: 1)],
          shopId: product.shopId);
      return;
    }
    final items = [...state.items];
    final idx =
        items.indexWhere((e) => e.product.productId == product.productId);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    } else {
      items.add(CartItem(product: product, quantity: 1));
    }
    state = state.copyWith(items: items, shopId: product.shopId);
  }

  void decrement(ProductModel product) {
    final items = [...state.items];
    final idx =
        items.indexWhere((e) => e.product.productId == product.productId);
    if (idx < 0) return;
    final qty = items[idx].quantity - 1;
    if (qty <= 0) {
      items.removeAt(idx);
    } else {
      items[idx] = items[idx].copyWith(quantity: qty);
    }
    if (items.isEmpty) {
      state = const CartState();
    } else {
      state = state.copyWith(items: items);
    }
  }

  void remove(String productId) {
    final items =
        state.items.where((e) => e.product.productId != productId).toList();
    state = items.isEmpty ? const CartState() : state.copyWith(items: items);
  }

  void applyCoupon(CouponModel coupon) => state = state.copyWith(coupon: coupon);
  void removeCoupon() => state = state.copyWith(clearCoupon: true);
  void setDistance(double km) => state = state.copyWith(distanceKm: km);

  void clear() => state = const CartState();
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
