import 'package:cloud_firestore/cloud_firestore.dart';

/// A promo code. Either a percentage or a flat discount.
class CouponModel {
  const CouponModel({
    required this.code,
    required this.description,
    required this.isPercent,
    required this.value,
    this.maxDiscount,
    this.minOrderValue = 0,
    this.isActive = true,
    this.expiresAt,
  });

  final String code;
  final String description;
  final bool isPercent;
  final double value;
  final double? maxDiscount;
  final double minOrderValue;
  final bool isActive;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Computes the discount this coupon applies to [subtotal], or returns
  /// `(0, reason)` if it cannot be applied.
  (double discount, String? error) discountFor(double subtotal) {
    if (!isActive) return (0, 'Coupon is not active');
    if (isExpired) return (0, 'Coupon has expired');
    if (subtotal < minOrderValue) {
      return (0, 'Minimum order ₹${minOrderValue.toStringAsFixed(0)} required');
    }
    var discount = isPercent ? subtotal * value / 100 : value;
    if (maxDiscount != null && discount > maxDiscount!) discount = maxDiscount!;
    if (discount > subtotal) discount = subtotal;
    return (discount, null);
  }

  factory CouponModel.fromMap(String id, Map<String, dynamic> map) =>
      CouponModel(
        code: id,
        description: map['description'] as String? ?? '',
        isPercent: map['isPercent'] as bool? ?? true,
        value: (map['value'] as num?)?.toDouble() ?? 0,
        maxDiscount: (map['maxDiscount'] as num?)?.toDouble(),
        minOrderValue: (map['minOrderValue'] as num?)?.toDouble() ?? 0,
        isActive: map['isActive'] as bool? ?? true,
        expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      );

  factory CouponModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      CouponModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'description': description,
        'isPercent': isPercent,
        'value': value,
        'maxDiscount': maxDiscount,
        'minOrderValue': minOrderValue,
        'isActive': isActive,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      };
}
