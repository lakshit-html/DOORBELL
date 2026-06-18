import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class RiderModel {
  const RiderModel({
    required this.riderId,
    required this.name,
    required this.phone,
    this.approvalStatus = ApprovalStatus.active,
    this.status = RiderStatus.offline,
    this.rating = 0,
    this.totalDeliveries = 0,
    this.earnings = 0,
    this.createdAt,
  });

  final String riderId;
  final String name;
  final String phone;
  final ApprovalStatus approvalStatus;
  final RiderStatus status;
  final double rating;
  final int totalDeliveries;
  final double earnings;
  final DateTime? createdAt;

  factory RiderModel.fromMap(String id, Map<String, dynamic> map) => RiderModel(
        riderId: id,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        approvalStatus: ApprovalStatus.fromString(map['approvalStatus'] as String?),
        status: RiderStatus.fromString(map['status'] as String?),
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        totalDeliveries: (map['totalDeliveries'] as num?)?.toInt() ?? 0,
        earnings: (map['earnings'] as num?)?.toDouble() ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory RiderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      RiderModel.fromMap(doc.id, doc.data() ?? {});
}
