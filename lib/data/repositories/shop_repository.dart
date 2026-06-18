import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doorbell/core/constants/firebase_constants.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/geo_utils.dart';
import '../models/enums.dart';
import '../models/shop_model.dart';

/// Shop CRUD + nearby-shop discovery with hyperlocal radius support.
class ShopRepository {
  final FirebaseFirestore _firestore;

  ShopRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection(FirestoreCollections.shops);

  Future<ShopModel?> getShop(String shopId) async {
    final doc = await _shops.doc(shopId).get();
    return doc.exists ? ShopModel.fromDoc(doc) : null;
  }

  Stream<ShopModel?> shopStream(String shopId) => _shops
      .doc(shopId)
      .snapshots()
      .map((d) => d.exists ? ShopModel.fromDoc(d) : null);

  /// All active shops within [radiusKm] of the given point, nearest first.
  Future<List<ShopWithDistance>> nearbyShops({
    required double lat,
    required double lng,
    double? radiusKm,
    bool useHyperlocal = false,
  }) async {
    final effectiveRadius =
        radiusKm ??
        (useHyperlocal
            ? AppConstants.hyperlocalRadiusKm
            : AppConstants.defaultDeliveryRadiusKm);

    final snap = await _shops
        .where('approvalStatus', isEqualTo: ApprovalStatus.active.name)
        .limit(200)
        .get();
    final result = <ShopWithDistance>[];
    for (final doc in snap.docs) {
      final shop = ShopModel.fromDoc(doc);
      final d = GeoUtils.distanceKm(lat, lng, shop.latitude, shop.longitude);
      if (d <= effectiveRadius) {
        result.add(ShopWithDistance(shop, d));
      }
    }
    result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return result;
  }

  Stream<ShopModel?> shopForOwner(String ownerId) => _shops
      .where('ownerId', isEqualTo: ownerId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : ShopModel.fromDoc(s.docs.first));

  Future<String> createShop(ShopModel shop) async {
    final ref = _shops.doc();
    await ref.set(shop.toMap());
    return ref.id;
  }

  Future<void> updateShop(String shopId, Map<String, dynamic> data) =>
      _shops.doc(shopId).update(data);

  Future<List<ShopModel>> getAllShops() async {
    final snapshot = await _shops.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(ShopModel.fromDoc).toList();
  }

  Future<List<ShopWithDistance>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final allShops = await getAllShops();
    return allShops
        .map(
          (shop) => ShopWithDistance(
            shop,
            _calculateDistance(
              latitude,
              longitude,
              shop.latitude,
              shop.longitude,
            ),
          ),
        )
        .where((entry) => entry.distanceKm <= radiusKm)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  // ── Admin ────────────────────────────────────────────────────────────────

  /// All shops for admin management.
  Stream<List<ShopModel>> allShops() => _shops
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(ShopModel.fromDoc).toList());

  /// Suspend a shop (admin only).
  Future<void> suspendShop(String shopId, {String? reason}) =>
      _shops.doc(shopId).update({
        'approvalStatus': ApprovalStatus.suspended.name,
        'isApproved': false,
        if (reason != null && reason.isNotEmpty) 'suspensionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

  /// Reactivate a suspended shop (admin only).
  Future<void> reactivateShop(String shopId) => _shops.doc(shopId).update({
    'approvalStatus': ApprovalStatus.active.name,
    'isApproved': true,
    'reviewedAt': FieldValue.serverTimestamp(),
  });
}
