import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/order_model.dart';
import '../auth/providers/auth_providers.dart';

/// Customer orders — depends on stable UID, NOT the full user profile.
/// This prevents stream recreation when profile fields change.
final customerOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(orderRepositoryProvider).customerOrders(uid);
});

final orderStreamProvider = StreamProvider.autoDispose
    .family<OrderModel?, String>((ref, orderId) =>
        ref.watch(orderRepositoryProvider).orderStream(orderId));

/// All orders — admin only. Stable stream that doesn't depend on profile.
final allOrdersProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).allOrders(limit: 200);
});
