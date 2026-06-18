import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    this.image,
    required this.price,
    required this.quantity,
  });
  final String productId;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  double get lineTotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        image: map['image'] as String?,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );
}

class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.customerId,
    required this.shopId,
    this.riderId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.createdAt,
    this.updatedAt,
  });

  final String orderId;
  final String customerId;
  final String shopId;
  final String? riderId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus orderStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get itemCount => items.fold(0, (sum, e) => sum + e.quantity);

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) => OrderModel(
        orderId: id,
        customerId: map['customerId'] as String? ?? '',
        shopId: map['shopId'] as String? ?? '',
        riderId: map['riderId'] as String?,
        items: (map['products'] as List? ?? const [])
            .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
        paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String?),
        paymentStatus: PaymentStatus.fromString(map['paymentStatus'] as String?),
        orderStatus: OrderStatus.fromString(map['orderStatus'] as String?),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      OrderModel.fromMap(doc.id, doc.data() ?? {});
}
