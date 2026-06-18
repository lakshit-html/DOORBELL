import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';

final productProvider = FutureProvider.autoDispose
    .family<ProductModel?, String>((ref, id) =>
        ref.watch(productRepositoryProvider).getProduct(id));

final productReviewsProvider = StreamProvider.autoDispose
    .family<List<ReviewModel>, String>((ref, productId) =>
        ref.watch(reviewRepositoryProvider).forProduct(productId));
