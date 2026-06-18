import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/coupon_model.dart';

class CouponRepository {
  CouponRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _coupons =>
      _firestore.collection(FirestoreCollections.coupons);

  Future<CouponModel?> getByCode(String code) async {
    final doc = await _coupons.doc(code.toUpperCase().trim()).get();
    return doc.exists ? CouponModel.fromDoc(doc) : null;
  }

  Stream<List<CouponModel>> activeCoupons() => _coupons
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(CouponModel.fromDoc).toList());

  Future<void> upsert(String code, CouponModel coupon) =>
      _coupons.doc(code.toUpperCase().trim()).set(coupon.toMap());
}
