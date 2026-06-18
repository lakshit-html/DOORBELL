import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/firebase_providers.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  ProductSort _sort = ProductSort.relevance;
  Future<List<ProductModel>>? _future;

  void _run() {
    setState(() {
      _future = ref
          .read(productRepositoryProvider)
          .search(_controller.text, sort: _sort);
    });
  }

  @override
  void initState() {
    super.initState();
    _future = ref.read(productRepositoryProvider).search('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _run(),
          decoration: const InputDecoration(
            hintText: 'Search products…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          IconButton(onPressed: _run, icon: const Icon(Icons.search)),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final entry in const {
                  ProductSort.relevance: 'Relevance',
                  ProductSort.priceLowHigh: 'Price ↑',
                  ProductSort.priceHighLow: 'Price ↓',
                  ProductSort.rating: 'Top Rated',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _sort == entry.key,
                      onSelected: (_) {
                        setState(() => _sort = entry.key);
                        _run();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    subtitle: 'Try a different search term or category.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
