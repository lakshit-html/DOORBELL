import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/shop_model.dart';
import '../auth/providers/auth_providers.dart';

/// Seller's own shop — depends on stable UID, NOT the full user profile.
final myShopProvider = StreamProvider.autoDispose<ShopModel?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(shopRepositoryProvider).shopForOwner(uid);
});

final myShopProductsProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final shop = ref.watch(myShopProvider).value;
  if (shop == null) return const Stream.empty();
  return ref.watch(productRepositoryProvider).shopProducts(shop.shopId);
});

final myShopOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final shop = ref.watch(myShopProvider).value;
  if (shop == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).shopOrders(shop.shopId);
});

/// Low-stock products for the seller's shop — used to display alerts.
final lowStockProductsProvider =
    StreamProvider.autoDispose<List<ProductModel>>((ref) {
  final shop = ref.watch(myShopProvider).value;
  if (shop == null) return const Stream.empty();
  return ref.watch(productRepositoryProvider).lowStockProducts(
        shop.shopId,
        threshold: shop.lowStockThreshold,
      );
});

class SellerStats {
  const SellerStats({
    this.revenue = 0,
    this.orders = 0,
    this.pending = 0,
  });
  final double revenue;
  final int orders;
  final int pending;
}

final sellerStatsProvider = Provider.autoDispose<SellerStats>((ref) {
  final orders = ref.watch(myShopOrdersProvider).value ?? [];
  double revenue = 0;
  int pending = 0;
  for (final o in orders) {
    revenue += o.totalAmount;
    if (!o.orderStatus.isTerminal) pending++;
  }
  return SellerStats(
      revenue: revenue, orders: orders.length, pending: pending);
});
