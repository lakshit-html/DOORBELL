import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import 'enums.dart';

/// A local store registered on the DoorBell platform.
class ShopModel {
  const ShopModel({
    required this.shopId,
    required this.ownerId,
    required this.shopName,
    this.description = '',
    required this.address,
    required this.latitude,
    required this.longitude,
    this.categories = const [],
    this.images = const [],
    this.rating = 0,
    this.totalOrders = 0,
    this.approvalStatus = ApprovalStatus.active,
    this.isOpen = true,
    this.openingHours = '9:00 AM - 9:00 PM',
    this.deliveryRadius = AppConstants.defaultDeliveryRadiusKm,
    this.gstNumber,
    this.enableLowStockAlerts = true,
    this.lowStockThreshold = AppConstants.lowStockThreshold,
    this.createdAt,
  });

  final String shopId;
  final String ownerId;
  final String shopName;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> categories;
  final List<String> images;
  final double rating;
  final int totalOrders;
  final ApprovalStatus approvalStatus;
  bool get isApproved => approvalStatus == ApprovalStatus.active;
  final bool isOpen;
  final String openingHours;
  final double deliveryRadius;
  final String? gstNumber;
  final bool enableLowStockAlerts;
  final int lowStockThreshold;
  final DateTime? createdAt;

  String? get coverImage => images.isNotEmpty ? images.first : null;

  factory ShopModel.fromMap(String id, Map<String, dynamic> map) => ShopModel(
    shopId: id,
    ownerId: map['ownerId'] as String? ?? '',
    shopName: map['shopName'] as String? ?? '',
    description: map['description'] as String? ?? '',
    address: map['address'] as String? ?? '',
    latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    categories: List<String>.from(map['categories'] as List? ?? const []),
    images: List<String>.from(map['images'] as List? ?? const []),
    rating: (map['rating'] as num?)?.toDouble() ?? 0,
    totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
    approvalStatus: ApprovalStatus.fromString(
      map['approvalStatus'] as String? ?? 'pending',
    ),
    isOpen: map['isOpen'] as bool? ?? true,
    openingHours: map['openingHours'] as String? ?? '9:00 AM - 9:00 PM',
    deliveryRadius:
        (map['deliveryRadius'] as num?)?.toDouble() ??
        AppConstants.defaultDeliveryRadiusKm,
    gstNumber: map['gstNumber'] as String?,
    enableLowStockAlerts: map['enableLowStockAlerts'] as bool? ?? true,
    lowStockThreshold:
        (map['lowStockThreshold'] as num?)?.toInt() ??
        AppConstants.lowStockThreshold,
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );

  factory ShopModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ShopModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'shopName': shopName,
    'description': description,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'categories': categories,
    'images': images,
    'rating': rating,
    'totalOrders': totalOrders,
    'isApproved': isApproved,
    'approvalStatus': approvalStatus.name,
    'isOpen': isOpen,
    'openingHours': openingHours,
    'deliveryRadius': deliveryRadius,
    'gstNumber': gstNumber,
    'enableLowStockAlerts': enableLowStockAlerts,
    'lowStockThreshold': lowStockThreshold,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}

/// A shop paired with its computed distance from the user (query-time only).
class ShopWithDistance {
  const ShopWithDistance(this.shop, this.distanceKm);
  final ShopModel shop;
  final double distanceKm;
}
