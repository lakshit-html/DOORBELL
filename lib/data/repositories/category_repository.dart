import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection(FirestoreCollections.categories);

  Stream<List<CategoryModel>> categories() => _categories
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(CategoryModel.fromDoc).toList());

  Future<void> addCategory(CategoryModel category) =>
      _categories.add(category.toMap());

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();
}
