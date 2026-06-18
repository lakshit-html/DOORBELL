import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class ShopModel {
  const ShopModel({
    required this.shopId,
    required this.ownerId,
    required this.shopName,
    this.description = '',
    required this.address,
    this.rating = 0,
    this.totalOrders = 0,
    this.approvalStatus = ApprovalStatus.active,
    this.isOpen = true,
    this.createdAt,
  });

  final String shopId;
  final String ownerId;
  final String shopName;
  final String description;
  final String address;
  final double rating;
  final int totalOrders;
  final ApprovalStatus approvalStatus;
  final bool isOpen;
  final DateTime? createdAt;

  bool get isApproved => approvalStatus == ApprovalStatus.active;

  factory ShopModel.fromMap(String id, Map<String, dynamic> map) => ShopModel(
        shopId: id,
        ownerId: map['ownerId'] as String? ?? '',
        shopName: map['shopName'] as String? ?? '',
        description: map['description'] as String? ?? '',
        address: map['address'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
        approvalStatus: ApprovalStatus.fromString(map['approvalStatus'] as String?),
        isOpen: map['isOpen'] as bool? ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory ShopModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ShopModel.fromMap(doc.id, doc.data() ?? {});
}
