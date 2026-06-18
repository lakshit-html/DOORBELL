import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../data/models/shop_model.dart';
import '../../../data/repositories/shop_repository.dart' show ShopWithDistance;

final nearbyShopsProvider = FutureProvider<List<ShopWithDistance>>((ref) async {
  final repo = ref.watch(shopRepositoryProvider);
  return repo.getNearbyShops(latitude: 0.0, longitude: 0.0);
});

final allShopsProvider = FutureProvider<List<ShopModel>>((ref) async {
  final repo = ref.watch(shopRepositoryProvider);
  return repo.getAllShops();
});

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async => []);
final popularProductsProvider = FutureProvider<List<dynamic>>(
  (ref) async => [],
);
