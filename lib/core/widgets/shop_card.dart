import 'package:flutter/material.dart';

import '../../data/models/shop_model.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'app_network_image.dart';

class ShopCard extends StatelessWidget {
  const ShopCard({
    super.key,
    required this.shop,
    this.distanceKm,
    this.onTap,
  });

  final ShopModel shop;
  final double? distanceKm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: shop.coverImage,
                  height: 130,
                  width: double.infinity,
                  borderRadius: 18,
                ),
                if (!shop.isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Currently Closed',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(shop.shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 2),
                            Text(shop.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.categories.isEmpty
                        ? shop.address
                        : shop.categories.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      if (distanceKm != null)
                        Text(Formatters.distance(distanceKm!),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(shop.openingHours,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
