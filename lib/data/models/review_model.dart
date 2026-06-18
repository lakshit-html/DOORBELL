import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  const ReviewModel({
    required this.reviewId,
    required this.customerId,
    required this.customerName,
    required this.productId,
    this.shopId,
    required this.rating,
    this.review = '',
    this.createdAt,
  });

  final String reviewId;
  final String customerId;
  final String customerName;
  final String productId;
  final String? shopId;
  final double rating;
  final String review;
  final DateTime? createdAt;

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) =>
      ReviewModel(
        reviewId: id,
        customerId: map['customerId'] as String? ?? '',
        customerName: map['customerName'] as String? ?? 'Anonymous',
        productId: map['productId'] as String? ?? '',
        shopId: map['shopId'] as String?,
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        review: map['review'] as String? ?? '',
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory ReviewModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ReviewModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'productId': productId,
        'shopId': shopId,
        'rating': rating,
        'review': review,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
