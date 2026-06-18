import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  const ProductModel({
    required this.productId,
    required this.shopId,
    required this.name,
    this.description = '',
    this.image,
    required this.price,
    this.stock = 0,
    this.rating = 0,
    this.isAvailable = true,
    this.createdAt,
  });

  final String productId;
  final String shopId;
  final String name;
  final String description;
  final String? image;
  final double price;
  final int stock;
  final double rating;
  final bool isAvailable;
  final DateTime? createdAt;

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) => ProductModel(
        productId: id,
        shopId: map['shopId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        image: map['image'] as String?,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        stock: (map['stock'] as num?)?.toInt() ?? 0,
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        isAvailable: map['isAvailable'] as bool? ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory ProductModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ProductModel.fromMap(doc.id, doc.data() ?? {});
}
