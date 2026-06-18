import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  WalletRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _wallet(String uid) =>
      _firestore.collection(FirestoreCollections.wallets).doc(uid);

  Stream<WalletModel> walletStream(String uid) => _wallet(uid).snapshots().map(
      (d) => d.exists
          ? WalletModel.fromMap(uid, d.data()!)
          : WalletModel(userId: uid));

  Stream<List<WalletTransaction>> transactions(String uid) => _wallet(uid)
      .collection(FirestoreCollections.transactions)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => WalletTransaction.fromMap(d.id, d.data()))
          .toList());

  /// Adds money or deducts it atomically and records a transaction.
  Future<void> applyTransaction(
    String uid, {
    required TransactionType type,
    required double amount,
    required String description,
    String? orderId,
  }) async {
    final walletRef = _wallet(uid);
    final txnRef =
        walletRef.collection(FirestoreCollections.transactions).doc();
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(walletRef);
      final current = (snap.data()?['balance'] as num?)?.toDouble() ?? 0;
      final delta = type == TransactionType.credit ? amount : -amount;
      final next = current + delta;
      if (next < 0) throw Exception('Insufficient wallet balance');
      tx.set(walletRef, {'balance': next}, SetOptions(merge: true));
      tx.set(
          txnRef,
          WalletTransaction(
            id: txnRef.id,
            type: type,
            amount: amount,
            description: description,
            orderId: orderId,
          ).toMap());
    });
  }
}
