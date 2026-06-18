import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  const ProductModel({
    required this.productId,
    required this.shopId,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.image,
    required this.price,
    this.discountedPrice,
    this.unit = '1 pc',
    this.stock = 0,
    this.rating = 0,
    this.isAvailable = true,
    this.tags = const [],
    this.createdAt,
  });

  final String productId;
  final String shopId;
  final String categoryId;
  final String name;
  final String description;
  final String? image;
  final double price;
  final double? discountedPrice;
  final String unit;
  final int stock;
  final double rating;
  final bool isAvailable;
  final List<String> tags;
  final DateTime? createdAt;

  double get effectivePrice => discountedPrice ?? price;
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;
  int get discountPercent =>
      hasDiscount ? (((price - discountedPrice!) / price) * 100).round() : 0;
  bool get inStock => isAvailable && stock > 0;

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) =>
      ProductModel(
        productId: id,
        shopId: map['shopId'] as String? ?? '',
        categoryId: map['categoryId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        image: map['image'] as String?,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        discountedPrice: (map['discountedPrice'] as num?)?.toDouble(),
        unit: map['unit'] as String? ?? '1 pc',
        stock: (map['stock'] as num?)?.toInt() ?? 0,
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        isAvailable: map['isAvailable'] as bool? ?? true,
        tags: List<String>.from(map['tags'] as List? ?? const []),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory ProductModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ProductModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'image': image,
        'price': price,
        'discountedPrice': discountedPrice,
        'unit': unit,
        'stock': stock,
        'rating': rating,
        'isAvailable': isAvailable,
        'tags': tags,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  ProductModel copyWith({
    String? name,
    String? description,
    String? image,
    double? price,
    double? discountedPrice,
    String? unit,
    int? stock,
    bool? isAvailable,
    List<String>? tags,
  }) =>
      ProductModel(
        productId: productId,
        shopId: shopId,
        categoryId: categoryId,
        name: name ?? this.name,
        description: description ?? this.description,
        image: image ?? this.image,
        price: price ?? this.price,
        discountedPrice: discountedPrice ?? this.discountedPrice,
        unit: unit ?? this.unit,
        stock: stock ?? this.stock,
        rating: rating,
        isAvailable: isAvailable ?? this.isAvailable,
        tags: tags ?? this.tags,
        createdAt: createdAt,
      );
}

extension ProductLowStock on ProductModel {
  bool isLowStock(int threshold) => stock > 0 && stock <= threshold;
}
