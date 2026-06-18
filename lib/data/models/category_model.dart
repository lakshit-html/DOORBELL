import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  const CategoryModel({
    required this.categoryId,
    required this.name,
    this.image,
  });

  final String categoryId;
  final String name;
  final String? image;

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) =>
      CategoryModel(
        categoryId: id,
        name: map['name'] as String? ?? '',
        image: map['image'] as String?,
      );

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      CategoryModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {'name': name, 'image': image};
}
