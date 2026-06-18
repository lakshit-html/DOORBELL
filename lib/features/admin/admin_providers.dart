import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/enums.dart';
import '../../data/models/rider_model.dart';
import '../../data/models/shop_model.dart';

// Repository Providers
final shopRepositoryProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ShopRepository(firestore);
});

final riderRepositoryProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(storageServiceProvider);
  return RiderRepository(firestore, storage);
});

// Shop Providers
final pendingShopsProvider = FutureProvider<List<ShopModel>>((ref) async {
  final repo = ref.watch(shopRepositoryProvider);
  final allShops = await repo.getAllShops();
  return allShops
      .where((shop) => shop.approvalStatus == ApprovalStatus.pending)
      .toList();
});

final approvedShopsProvider = FutureProvider<List<ShopModel>>((ref) async {
  final repo = ref.watch(shopRepositoryProvider);
  final allShops = await repo.getAllShops();
  return allShops
      .where(
        (shop) =>
            shop.approvalStatus == ApprovalStatus.approved ||
            shop.approvalStatus == ApprovalStatus.rejected,
      )
      .toList();
});

// Rider Providers
final pendingRidersProvider = FutureProvider<List<RiderModel>>((ref) async {
  final repo = ref.watch(riderRepositoryProvider);
  final allRiders = await repo.getAllRiders();
  return allRiders
      .where((rider) => rider.approvalStatus == ApprovalStatus.pending)
      .toList();
});

final reviewedRidersProvider = FutureProvider<List<RiderModel>>((ref) async {
  final repo = ref.watch(riderRepositoryProvider);
  final allRiders = await repo.getAllRiders();
  return allRiders
      .where(
        (rider) =>
            rider.approvalStatus == ApprovalStatus.approved ||
            rider.approvalStatus == ApprovalStatus.rejected,
      )
      .toList();
});

// Admin Stats Provider
final adminStatsProvider = FutureProvider((ref) async {
  final shopRepo = ref.watch(shopRepositoryProvider);
  final riderRepo = ref.watch(riderRepositoryProvider);

  final shops = await shopRepo.getAllShops();
  final riders = await riderRepo.getAllRiders();

  return AdminStats(
    totalShops: shops.length,
    totalRiders: riders.length,
    totalUsers: 0,
    totalOrders: 0,
    revenue: 0.0,
  );
});

class AdminStats {
  final int totalShops;
  final int totalRiders;
  final int totalUsers;
  final int totalOrders;
  final double revenue;

  AdminStats({
    required this.totalShops,
    required this.totalRiders,
    required this.totalUsers,
    required this.totalOrders,
    required this.revenue,
  });
}
