import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/rider_model.dart';
import '../auth/providers/auth_providers.dart';

/// Rider's own profile — depends on stable UID, NOT the full user profile.
final myRiderProvider = StreamProvider.autoDispose<RiderModel?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(riderRepositoryProvider).riderStream(uid);
});

/// Orders ready for pickup — only streamed when the rider is Online.
/// If the rider is offline/sleep/busy/delivering, returns an empty list
/// so the UI shows nothing and no Firestore reads are wasted.
final availableDeliveriesProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final rider = ref.watch(myRiderProvider).value;
  if (rider == null || !rider.status.canReceiveOrders) {
    return Stream.value(const []);
  }
  return ref.watch(orderRepositoryProvider).availableForRiders();
});

/// Rider's own deliveries — depends on stable UID.
final myDeliveriesProvider =
    StreamProvider.autoDispose<List<OrderModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(orderRepositoryProvider).riderOrders(uid);
});
