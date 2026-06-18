import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../models/emitra_order_model.dart';
import '../services/storage_service.dart';

class EMitraRepository {
  EMitraRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final StorageService _storage;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('emitra_orders');

  Future<String> uploadDocument(
      String uid, String filename, File file) =>
      _storage.uploadFile(
          'emitra/$uid/${DateTime.now().millisecondsSinceEpoch}_$filename',
          file);

  Future<Result<String>> placeOrder(EMitraOrderModel order) async {
    try {
      final ref = _orders.doc();
      await ref.set(order.toMap());
      return Success(ref.id);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  Stream<List<EMitraOrderModel>> customerOrders(String customerId) =>
      _orders
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(EMitraOrderModel.fromDoc).toList());

  Stream<List<EMitraOrderModel>> pendingOrders() => _orders
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(EMitraOrderModel.fromDoc).toList());

  Future<void> updateStatus(String orderId, String status) =>
      _orders.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
