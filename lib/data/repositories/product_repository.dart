import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/product_model.dart';

/// Sort options for product search results.
enum ProductSort {
  relevance,
  priceLowHigh,
  priceHighLow,
  rating,
  newest,
}

class ProductRepository {
  ProductRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  Future<ProductModel?> getProduct(String id) async {
    final doc = await _products.doc(id).get();
    return doc.exists ? ProductModel.fromDoc(doc) : null;
  }

  Stream<ProductModel?> productStream(String id) => _products
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? ProductModel.fromDoc(d) : null);

  Stream<List<ProductModel>> shopProducts(String shopId) => _products
      .where('shopId', isEqualTo: shopId)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromDoc).toList());

  Stream<List<ProductModel>> categoryProducts(String categoryId) => _products
      .where('categoryId', isEqualTo: categoryId)
      .where('isAvailable', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromDoc).toList());

  /// Full-text style search: fetches up to 200 available products then
  /// filters and sorts in-memory (works well for ≤ 10 k products; upgrade to
  /// Algolia / Typesense when the catalogue grows).
  Future<List<ProductModel>> search(
    String query, {
    ProductSort sort = ProductSort.relevance,
    String? shopId,
    String? categoryId,
  }) async {
    var q = _products.where('isAvailable', isEqualTo: true);
    if (shopId != null) q = q.where('shopId', isEqualTo: shopId);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);

    final snap = await q.limit(200).get();
    var results = snap.docs.map(ProductModel.fromDoc).toList();

    // Filter by query string (name + description).
    final lq = query.toLowerCase().trim();
    if (lq.isNotEmpty) {
      results = results
          .where((p) =>
              p.name.toLowerCase().contains(lq) ||
              p.description.toLowerCase().contains(lq) ||
              (p.tags.any((t) => t.toLowerCase().contains(lq))))
          .toList();
    }

    // Sort.
    switch (sort) {
      case ProductSort.priceLowHigh:
        results.sort((a, b) =>
            a.effectivePrice.compareTo(b.effectivePrice));
      case ProductSort.priceHighLow:
        results.sort((a, b) =>
            b.effectivePrice.compareTo(a.effectivePrice));
      case ProductSort.rating:
        results.sort((a, b) => b.rating.compareTo(a.rating));
      case ProductSort.newest:
        results.sort((a, b) {
          final ca = a.createdAt;
          final cb = b.createdAt;
          if (ca == null && cb == null) return 0;
          if (ca == null) return 1;
          if (cb == null) return -1;
          return cb.compareTo(ca);
        });
      case ProductSort.relevance:
        // Boost exact-name matches to the top.
        if (lq.isNotEmpty) {
          results.sort((a, b) {
            final aExact = a.name.toLowerCase() == lq ? 0 : 1;
            final bExact = b.name.toLowerCase() == lq ? 0 : 1;
            if (aExact != bExact) return aExact.compareTo(bExact);
            final aStarts = a.name.toLowerCase().startsWith(lq) ? 0 : 1;
            final bStarts = b.name.toLowerCase().startsWith(lq) ? 0 : 1;
            return aStarts.compareTo(bStarts);
          });
        }
    }

    return results;
  }

  Future<String> addProduct(ProductModel product) async {
    final ref = _products.doc();
    await ref.set(product.toMap());
    return ref.id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) =>
      _products.doc(id).update(data);

  Future<void> deleteProduct(String id) => _products.doc(id).delete();

  /// Products for a shop that are at or below the low-stock threshold.
  Stream<List<ProductModel>> lowStockProducts(
    String shopId, {
    int threshold = AppConstants.lowStockThreshold,
  }) =>
      _products
          .where('shopId', isEqualTo: shopId)
          .where('isAvailable', isEqualTo: true)
          .where('stock', isGreaterThan: 0)
          .where('stock', isLessThanOrEqualTo: threshold)
          .snapshots()
          .map((s) => s.docs.map(ProductModel.fromDoc).toList());

  /// Atomically update stock; marks product unavailable when stock hits zero.
  Future<void> updateStock(String productId, int newStock) =>
      _products.doc(productId).update({
        'stock': newStock,
        'isAvailable': newStock > 0,
      });

  /// Products sorted by rating — used for "Popular near you" on the home screen.
  Future<List<ProductModel>> popularProducts({int limit = 20}) async {
    final snap = await _products
        .where('isAvailable', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(ProductModel.fromDoc).toList();
  }
}
