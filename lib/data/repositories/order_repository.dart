import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../models/enums.dart';
import '../models/order_model.dart';

class OrderRepository {
  OrderRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestoreCollections.orders);
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);
  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection(FirestoreCollections.shops);

  /// Places an order in a transaction: validates stock, decrements it, writes
  /// the order, and bumps the shop's order counter — all atomically.
  Future<Result<String>> placeOrder(OrderModel order) async {
    try {
      final orderRef = _orders.doc();
      await _firestore.runTransaction((tx) async {
        // 1. Validate + read stock for every line item first (reads before writes).
        final stockUpdates = <DocumentReference, int>{};
        for (final item in order.items) {
          final ref = _products.doc(item.productId);
          final snap = await tx.get(ref);
          final current = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
          if (current < item.quantity) {
            throw Failure('"${item.name}" is out of stock.');
          }
          stockUpdates[ref] = current - item.quantity;
        }
        // 2. Apply writes.
        stockUpdates.forEach((ref, newStock) {
          tx.update(ref, {
            'stock': newStock,
            'isAvailable': newStock > 0,
          });
        });
        tx.set(orderRef, order.toMap());
        tx.update(_shops.doc(order.shopId),
            {'totalOrders': FieldValue.increment(1)});
      });
      return Success(orderRef.id);
    } on Failure catch (f) {
      return Err(f);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  Stream<OrderModel?> orderStream(String orderId) => _orders
      .doc(orderId)
      .snapshots()
      .map((d) => d.exists ? OrderModel.fromDoc(d) : null);

  Stream<List<OrderModel>> customerOrders(String customerId) => _orders
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  Stream<List<OrderModel>> shopOrders(String shopId) => _orders
      .where('shopId', isEqualTo: shopId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  /// Orders ready for pickup — only sent to riders whose status is 'online'.
  /// The riderId field being null ensures no other rider has claimed it yet.
  Stream<List<OrderModel>> availableForRiders() => _orders
      .where('orderStatus', isEqualTo: OrderStatus.readyForPickup.name)
      .where('riderId', isNull: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  Stream<List<OrderModel>> riderOrders(String riderId) => _orders
      .where('riderId', isEqualTo: riderId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  /// Updates order status. When a rider picks up an order, sets their status
  /// to 'delivering'. When delivered, resets them back to 'online'.
  Future<void> updateStatus(String orderId, OrderStatus status,
      {String? riderId}) async {
    final batch = _firestore.batch();
    batch.update(_orders.doc(orderId), {
      'orderStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (riderId != null) {
      final riderRef = _firestore.collection('riders').doc(riderId);
      if (status == OrderStatus.pickedUp) {
        batch.update(riderRef, {'status': 'delivering'});
      } else if (status == OrderStatus.delivered) {
        batch.update(riderRef, {
          'status': 'online',
          'totalDeliveries': FieldValue.increment(1),
        });
      }
    }
    await batch.commit();
  }

  /// Atomically assigns a rider to an order.
  /// Uses a transaction so only the FIRST rider to tap "Accept" wins —
  /// subsequent taps fail gracefully and return false.
  Future<bool> assignRider(String orderId, String riderId) async {
    try {
      await _firestore.runTransaction((tx) async {
        final ref = _orders.doc(orderId);
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('Order not found');

        final data = snap.data()!;
        final currentStatus = data['orderStatus'] as String?;
        final currentRider = data['riderId'];

        // Only assign if still in readyForPickup and unclaimed.
        if (currentStatus != OrderStatus.readyForPickup.name || currentRider != null) {
          throw Exception('Order already claimed');
        }

        tx.update(ref, {
          'riderId': riderId,
          'orderStatus': OrderStatus.riderAssigned.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (_) {
      return false; // Another rider beat them to it.
    }
  }

  Future<void> updatePayment(
          String orderId, PaymentStatus status, String? paymentId) =>
      _orders.doc(orderId).update({
        'paymentStatus': status.name,
        if (paymentId != null) 'razorpayPaymentId': paymentId,
      });

  // ---- Admin / analytics ----
  Stream<List<OrderModel>> allOrders({int limit = 200}) => _orders
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(OrderModel.fromDoc).toList());

  /// Paginated orders with optional status filter.
  Future<List<OrderModel>> paginatedOrders({
    int limit = 20,
    DocumentSnapshot? startAfter,
    OrderStatus? statusFilter,
  }) async {
    Query<Map<String, dynamic>> query = _orders;
    if (statusFilter != null) {
      query = query.where('orderStatus', isEqualTo: statusFilter.name);
    }
    query = query.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    return snap.docs.map(OrderModel.fromDoc).toList();
  }

  /// Search orders by orderId prefix.
  Future<List<OrderModel>> searchOrders(String query) async {
    final snap = await _orders.limit(200).get();
    final lq = query.toLowerCase().trim();
    return snap.docs
        .map(OrderModel.fromDoc)
        .where((o) =>
            o.orderId.toLowerCase().contains(lq) ||
            o.customerId.toLowerCase().contains(lq))
        .toList();
  }
}
