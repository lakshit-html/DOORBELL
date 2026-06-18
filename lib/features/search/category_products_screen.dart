import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/firebase_providers.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/product_model.dart';

final _categoryProductsProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, String>((ref, categoryId) =>
        ref.watch(productRepositoryProvider).search('', categoryId: categoryId));

class CategoryProductsScreen extends ConsumerWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(_categoryProductsProvider(categoryId));
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: products.when(
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.category_outlined,
                title: 'Nothing here yet',
                subtitle: 'No products in this category right now.',
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.66,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => ProductCard(
                  product: items[i],
                  onTap: () =>
                      context.push(AppRoutes.product(items[i].productId)),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) =>
            EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }
}
