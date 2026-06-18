import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// An E-Mitra document / print service order.
class EMitraOrderModel {
  const EMitraOrderModel({
    required this.orderId,
    required this.customerId,
    required this.serviceType,
    required this.description,
    this.documentUrls = const [],
    this.printCopies = 1,
    this.isColour = false,
    this.status = 'pending',
    this.totalAmount = 0,
    this.shopId,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String orderId;
  final String customerId;
  final EMitraServiceType serviceType;
  final String description;
  /// Firebase Storage URLs of uploaded documents.
  final List<String> documentUrls;
  final int printCopies;
  final bool isColour;
  /// 'pending' | 'processing' | 'ready' | 'delivered' | 'cancelled'
  final String status;
  final double totalAmount;
  final String? shopId;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EMitraOrderModel.fromMap(String id, Map<String, dynamic> map) =>
      EMitraOrderModel(
        orderId: id,
        customerId: map['customerId'] as String? ?? '',
        serviceType:
            EMitraServiceType.fromString(map['serviceType'] as String?),
        description: map['description'] as String? ?? '',
        documentUrls:
            List<String>.from(map['documentUrls'] as List? ?? const []),
        printCopies: (map['printCopies'] as num?)?.toInt() ?? 1,
        isColour: map['isColour'] as bool? ?? false,
        status: map['status'] as String? ?? 'pending',
        totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
        shopId: map['shopId'] as String?,
        notes: map['notes'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  factory EMitraOrderModel.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      EMitraOrderModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'serviceType': serviceType.name,
        'description': description,
        'documentUrls': documentUrls,
        'printCopies': printCopies,
        'isColour': isColour,
        'status': status,
        'totalAmount': totalAmount,
        'shopId': shopId,
        'notes': notes,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
