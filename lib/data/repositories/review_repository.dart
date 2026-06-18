import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/review_model.dart';

class ReviewRepository {
  ReviewRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection(FirestoreCollections.reviews);

  Stream<List<ReviewModel>> forProduct(String productId) => _reviews
      .where('productId', isEqualTo: productId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ReviewModel.fromDoc).toList());

  Future<void> addReview(ReviewModel review) =>
      _reviews.add(review.toMap());
}
