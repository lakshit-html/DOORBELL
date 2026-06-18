import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/enums.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';

/// Aggregate counts for the admin dashboard.
class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.totalShops,
    required this.totalRiders,
    required this.totalOrders,
    required this.revenue,
    this.pendingIssues = 0,
  });

  final int totalUsers;
  final int totalShops;
  final int totalRiders;
  final int totalOrders;
  final double revenue;
  final int pendingIssues;
}

class AdminRepository {
  AdminRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<int> _count(String collection) async {
    final agg =
        await _firestore.collection(collection).count().get();
    return agg.count ?? 0;
  }

  Future<AdminStats> fetchStats() async {
    final users = await _count(FirestoreCollections.users);
    final shops = await _count(FirestoreCollections.shops);
    final riders = await _count(FirestoreCollections.riders);

    final ordersSnap = await _firestore
        .collection(FirestoreCollections.orders)
        .where('paymentStatus', isEqualTo: 'paid')
        .get();
    final revenue = ordersSnap.docs.fold<double>(
        0, (sum, d) => sum + ((d.data()['totalAmount'] as num?)?.toDouble() ?? 0));

    final pendingIssues = await _firestore
        .collection(FirestoreCollections.supportTickets)
        .where('status', isEqualTo: 'open')
        .count()
        .get();

    return AdminStats(
      totalUsers: users,
      totalShops: shops,
      totalRiders: riders,
      totalOrders: ordersSnap.size,
      revenue: revenue,
      pendingIssues: pendingIssues.count ?? 0,
    );
  }

  Stream<int> liveCount(String collection) => _firestore
      .collection(collection)
      .snapshots()
      .map((s) => s.size);

  // ── User Management ──────────────────────────────────────────────────────

  Stream<List<UserModel>> allUsers() => _firestore
      .collection(FirestoreCollections.users)
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(UserModel.fromDoc).toList());

  Future<List<UserModel>> searchUsers(String query) async {
    final snap = await _firestore
        .collection(FirestoreCollections.users)
        .limit(200)
        .get();
    final lq = query.toLowerCase().trim();
    return snap.docs
        .map(UserModel.fromDoc)
        .where((u) =>
            u.name.toLowerCase().contains(lq) ||
            u.email.toLowerCase().contains(lq) ||
            (u.phone?.contains(lq) ?? false))
        .toList();
  }

  Future<void> banUser(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .update({'status': AccountStatus.suspended.name});

  Future<void> suspendUser(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .update({'status': AccountStatus.suspended.name});

  Future<void> reactivateUser(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .update({'status': AccountStatus.active.name});

  Future<void> deleteUser(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .delete();

  // ── Orders Management ────────────────────────────────────────────────────

  Stream<List<OrderModel>> allOrders({int limit = 200}) => _firestore
      .collection(FirestoreCollections.orders)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  Stream<List<OrderModel>> ordersByStatus(OrderStatus status) => _firestore
      .collection(FirestoreCollections.orders)
      .where('orderStatus', isEqualTo: status.name)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _firestore.collection(FirestoreCollections.orders).doc(orderId).update({
        'orderStatus': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> assignRiderToOrder(String orderId, String riderId) =>
      _firestore.collection(FirestoreCollections.orders).doc(orderId).update({
        'riderId': riderId,
        'orderStatus': OrderStatus.riderAssigned.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> cancelOrder(String orderId) =>
      _firestore.collection(FirestoreCollections.orders).doc(orderId).update({
        'orderStatus': OrderStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Products Management ──────────────────────────────────────────────────

  Stream<List<ProductModel>> allProducts({int limit = 200}) => _firestore
      .collection(FirestoreCollections.products)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromDoc).toList());

  Future<void> hideProduct(String productId) => _firestore
      .collection(FirestoreCollections.products)
      .doc(productId)
      .update({'isAvailable': false});

  Future<void> unhideProduct(String productId) => _firestore
      .collection(FirestoreCollections.products)
      .doc(productId)
      .update({'isAvailable': true});

  Future<void> deleteProduct(String productId) => _firestore
      .collection(FirestoreCollections.products)
      .doc(productId)
      .delete();

  // ── Notifications ────────────────────────────────────────────────────────

  /// Send notification to a specific user.
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'admin',
  }) async {
    await _firestore.collection(FirestoreCollections.notifications).add(
      NotificationModel(
        notificationId: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
      ).toMap(),
    );
  }

  /// Broadcast notification to all users of a specific role, or all.
  Future<void> broadcastNotification({
    required String title,
    required String body,
    UserRole? targetRole,
  }) async {
    var query = _firestore.collection(FirestoreCollections.users).limit(500);
    if (targetRole != null) {
      query = _firestore
          .collection(FirestoreCollections.users)
          .where('role', isEqualTo: targetRole.name)
          .limit(500);
    }
    final users = await query.get();
    final batch = _firestore.batch();
    for (final userDoc in users.docs) {
      final ref = _firestore.collection(FirestoreCollections.notifications).doc();
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

  // ── Analytics ────────────────────────────────────────────────────────────

  /// Get orders within a date range for analytics.
  Future<List<OrderModel>> ordersInRange(DateTime start, DateTime end) async {
    final snap = await _firestore
        .collection(FirestoreCollections.orders)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(OrderModel.fromDoc).toList();
  }

  // ── App Config ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAppConfig() async {
    final doc = await _firestore.collection('appConfig').doc('settings').get();
    return doc.data() ?? {};
  }

  Future<void> updateAppConfig(Map<String, dynamic> config) =>
      _firestore.collection('appConfig').doc('settings').set(
        config,
        SetOptions(merge: true),
      );

  Future<void> setMaintenanceMode(bool enabled) =>
      updateAppConfig({'maintenanceMode': enabled});
}
