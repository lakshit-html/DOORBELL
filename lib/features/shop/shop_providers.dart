import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/product_model.dart';
import '../../data/models/shop_model.dart';

final shopProvider = StreamProvider.autoDispose
    .family<ShopModel?, String>((ref, shopId) =>
        ref.watch(shopRepositoryProvider).shopStream(shopId));

final shopProductsProvider = StreamProvider.autoDispose
    .family<List<ProductModel>, String>((ref, shopId) =>
        ref.watch(productRepositoryProvider).shopProducts(shopId));
