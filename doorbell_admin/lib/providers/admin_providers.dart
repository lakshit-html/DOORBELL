import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/rider_model.dart';
import '../models/shop_model.dart';
import '../models/user_model.dart';

// ── Firebase SDK singletons ──
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// ── Auth State ──
final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(firebaseAuthProvider).authStateChanges());

/// The admin user's Firestore profile.
final adminUserProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((d) => d.exists ? UserModel.fromDoc(d) : null);
});

/// Whether the current user is an admin — used for auth guard.
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(adminUserProvider).value;
  return user?.role == UserRole.admin;
});

// ── Dashboard Stats ──
class AdminStats {
  const AdminStats({
    this.totalUsers = 0,
    this.totalShops = 0,
    this.totalRiders = 0,
    this.totalOrders = 0,
    this.revenue = 0,
    this.pendingIssues = 0,
  });
  final int totalUsers;
  final int totalShops;
  final int totalRiders;
  final int totalOrders;
  final double revenue;
  final int pendingIssues;
}

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) async {
  final fs = ref.watch(firestoreProvider);

  Future<int> count(String col) async {
    final agg = await fs.collection(col).count().get();
    return agg.count ?? 0;
  }

  final users = await count('users');
  final shops = await count('shops');
  final riders = await count('riders');

  final ordersSnap =
      await fs.collection('orders').where('paymentStatus', isEqualTo: 'paid').get();
  final revenue = ordersSnap.docs.fold<double>(
      0, (sum, d) => sum + ((d.data()['totalAmount'] as num?)?.toDouble() ?? 0));

  return AdminStats(
    totalUsers: users,
    totalShops: shops,
    totalRiders: riders,
    totalOrders: ordersSnap.size,
    revenue: revenue,
  );
});

// ── Users ──
final allUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromDoc).toList());
});

// ── Shops ──
final allShopsProvider = StreamProvider.autoDispose<List<ShopModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('shops')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(ShopModel.fromDoc).toList());
});

// ── Riders ──
final allRidersProvider = StreamProvider.autoDispose<List<RiderModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('riders')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(RiderModel.fromDoc).toList());
});

// ── Orders ──
final allOrdersProvider = StreamProvider.autoDispose<List<OrderModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());
});

// ── Products ──
final allProductsProvider = StreamProvider.autoDispose<List<ProductModel>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('products')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromDoc).toList());
});

// ── Admin Actions ──
class AdminActions {
  AdminActions(this._fs);
  final FirebaseFirestore _fs;

  // User management
  Future<void> suspendUser(String uid) =>
      _fs.collection('users').doc(uid).update({'status': 'suspended'});
  Future<void> reactivateUser(String uid) =>
      _fs.collection('users').doc(uid).update({'status': 'active'});
  Future<void> deleteUser(String uid) =>
      _fs.collection('users').doc(uid).delete();

  // Shop management
  Future<void> suspendShop(String shopId) => _fs.collection('shops').doc(shopId).update({
        'approvalStatus': 'suspended',
        'isApproved': false,
      });
  Future<void> reactivateShop(String shopId) => _fs.collection('shops').doc(shopId).update({
        'approvalStatus': 'active',
        'isApproved': true,
      });

  // Rider management
  Future<void> suspendRider(String riderId) =>
      _fs.collection('riders').doc(riderId).update({'approvalStatus': 'suspended'});
  Future<void> reactivateRider(String riderId) =>
      _fs.collection('riders').doc(riderId).update({'approvalStatus': 'active'});

  // Order management
  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _fs.collection('orders').doc(orderId).update({
        'orderStatus': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
  Future<void> assignRider(String orderId, String riderId) =>
      _fs.collection('orders').doc(orderId).update({
        'riderId': riderId,
        'orderStatus': OrderStatus.riderAssigned.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
  Future<void> cancelOrder(String orderId) =>
      _fs.collection('orders').doc(orderId).update({
        'orderStatus': OrderStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // Product management
  Future<void> hideProduct(String id) =>
      _fs.collection('products').doc(id).update({'isAvailable': false});
  Future<void> unhideProduct(String id) =>
      _fs.collection('products').doc(id).update({'isAvailable': true});
  Future<void> deleteProduct(String id) =>
      _fs.collection('products').doc(id).delete();

  // Notifications
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _fs.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': 'admin',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> broadcastNotification({
    required String title,
    required String body,
    UserRole? targetRole,
  }) async {
    Query<Map<String, dynamic>> query = _fs.collection('users');
    if (targetRole != null) {
      query = query.where('role', isEqualTo: targetRole.name);
    }
    final users = await query.limit(500).get();
    final batch = _fs.batch();
    for (final userDoc in users.docs) {
      final ref = _fs.collection('notifications').doc();
      batch.set(ref, {
        'userId': userDoc.id,
        'title': title,
        'body': body,
        'type': 'broadcast',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // App config
  Future<void> setMaintenanceMode(bool enabled) =>
      _fs.collection('appConfig').doc('settings').set(
        {'maintenanceMode': enabled},
        SetOptions(merge: true),
      );
}

final adminActionsProvider = Provider<AdminActions>(
    (ref) => AdminActions(ref.watch(firestoreProvider)));
