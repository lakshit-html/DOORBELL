import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// A delivery partner with KYC documents and live status.
class RiderModel {
  const RiderModel({
    required this.riderId,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    this.licenseNumber,
    this.aadhaarImage,
    this.licenseImage,
    this.rcImage,
    this.selfieImage,
    this.currentLat,
    this.currentLng,
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
  final VehicleType vehicleType;
  final String vehicleNumber;
  final String? licenseNumber;
  final String? aadhaarImage;
  final String? licenseImage;
  final String? rcImage;
  final String? selfieImage;
  final double? currentLat;
  final double? currentLng;
  final ApprovalStatus approvalStatus;
  final RiderStatus status;
  final double rating;
  final int totalDeliveries;
  final double earnings;
  final DateTime? createdAt;

  factory RiderModel.fromMap(String id, Map<String, dynamic> map) {
    final loc = map['currentLocation'] as Map<String, dynamic>?;
    return RiderModel(
      riderId: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      vehicleType: VehicleType.fromString(map['vehicleType'] as String?),
      vehicleNumber: map['vehicleNumber'] as String? ?? '',
      licenseNumber: map['licenseNumber'] as String?,
      aadhaarImage: map['aadhaarImage'] as String?,
      licenseImage: map['licenseImage'] as String?,
      rcImage: map['rcImage'] as String?,
      selfieImage: map['selfieImage'] as String?,
      currentLat: (loc?['lat'] as num?)?.toDouble(),
      currentLng: (loc?['lng'] as num?)?.toDouble(),
      approvalStatus: ApprovalStatus.fromString(
        map['approvalStatus'] as String? ?? 'pending',
      ),
      status: RiderStatus.fromString(map['status'] as String?),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      totalDeliveries: (map['totalDeliveries'] as num?)?.toInt() ?? 0,
      earnings: (map['earnings'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory RiderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      RiderModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'vehicleType': vehicleType.name,
    'vehicleNumber': vehicleNumber,
    'licenseNumber': licenseNumber,
    'aadhaarImage': aadhaarImage,
    'licenseImage': licenseImage,
    'rcImage': rcImage,
    'selfieImage': selfieImage,
    if (currentLat != null && currentLng != null)
      'currentLocation': {'lat': currentLat, 'lng': currentLng},
    'approvalStatus': approvalStatus.name,
    'status': status.name,
    'rating': rating,
    'totalDeliveries': totalDeliveries,
    'earnings': earnings,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
