import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/coupon_repository.dart';
import '../../data/repositories/emitra_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/google_drive_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repositories/rider_repository.dart';
import '../../data/repositories/user_repository.dart';

/// Single composition root for dependency injection. Everything downstream
/// (repositories, controllers, screens) reads from these providers, so swapping
/// an implementation (e.g. for tests) is a one-line override on ProviderScope.

// ---- Firebase SDK singletons ----
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);
final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => FirebaseAnalytics.instance,
);

// ---- Services ----
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthProvider)),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(
    ref.watch(firebaseStorageProvider),
    ref.watch(googleDriveServiceProvider),
  ),
);
final googleDriveServiceProvider = Provider<GoogleDriveService>(
  (ref) => GoogleDriveService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.watch(firebaseMessagingProvider)),
);
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(firebaseAnalyticsProvider)),
);

// ---- Repositories ----
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(firestoreProvider),
  ),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageServiceProvider),
  ),
);
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(firestoreProvider)),
);
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(firestoreProvider)),
);
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(firestoreProvider)),
);
final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(firestoreProvider)),
);
final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(firestoreProvider)),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(firestoreProvider)),
);
final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => CouponRepository(ref.watch(firestoreProvider)),
);
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(firestoreProvider)),
);

// ---- E-Mitra (added for DoorBell) ----
final emitraRepositoryProvider = Provider<EMitraRepository>(
  (ref) => EMitraRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageServiceProvider),
  ),
);
final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ShopRepository(firestore);
});

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(storageServiceProvider);
  return RiderRepository(firestore, storage);
});
