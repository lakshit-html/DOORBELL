import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/enums.dart';
import '../models/rider_model.dart';
import '../services/storage_service.dart';

class RiderRepository {
  final FirebaseFirestore _firestore;
  final StorageService _storage;

  RiderRepository(this._firestore, this._storage);

  CollectionReference<Map<String, dynamic>> get _riders =>
      _firestore.collection(FirestoreCollections.riders);

  Future<RiderModel?> getRider(String riderId) async {
    final doc = await _riders.doc(riderId).get();
    return doc.exists ? RiderModel.fromDoc(doc) : null;
  }

  Stream<RiderModel?> riderStream(String riderId) => _riders
      .doc(riderId)
      .snapshots()
      .map((d) => d.exists ? RiderModel.fromDoc(d) : null);

  /// Registers a rider profile (riderId == Firebase auth uid).
  /// New riders are immediately active.
  Future<void> register(RiderModel rider) =>
      _riders.doc(rider.riderId).set(rider.toMap());

  /// Uploads a KYC document image and returns its download URL.
  Future<String> uploadDoc(String riderId, String docName, File file) =>
      _storage.uploadFile(
        '${StoragePaths.riderDocs(riderId)}/$docName.jpg',
        file,
      );

  Future<void> updateLocation(String riderId, double lat, double lng) =>
      _riders.doc(riderId).update({
        'currentLocation': {'lat': lat, 'lng': lng},
      });

  Future<void> setStatus(String riderId, RiderStatus status) =>
      _riders.doc(riderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── Admin ────────────────────────────────────────────────────────────────

  /// All riders for admin management.
  Future<List<RiderModel>> getAllRiders() async {
    final snapshot = await _riders
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snapshot.docs.map(RiderModel.fromDoc).toList();
  }

  /// Suspend a rider (admin only).
  Future<void> suspendRider(String riderId, {String? reason}) =>
      _riders.doc(riderId).update({
        'approvalStatus': ApprovalStatus.suspended.name,
        if (reason != null && reason.isNotEmpty) 'suspensionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

  /// Reactivate a suspended rider (admin only).
  Future<void> reactivateRider(String riderId) => _riders.doc(riderId).update({
    'approvalStatus': ApprovalStatus.active.name,
    'reviewedAt': FieldValue.serverTimestamp(),
  });

  // ── Earnings ─────────────────────────────────────────────────────────────

  /// Increment a rider's completed deliveries and earnings after a delivery.
  Future<void> recordDelivery(String riderId, double fee) =>
      _riders.doc(riderId).update({
        'totalDeliveries': FieldValue.increment(1),
        'earnings': FieldValue.increment(fee),
        'status': RiderStatus.online.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
