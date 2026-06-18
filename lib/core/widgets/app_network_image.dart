import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Cached network image with shimmer placeholder and graceful error fallback.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: (url == null || url!.isEmpty)
          ? _fallback()
          : CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHighlight,
                child: Container(
                  width: width,
                  height: height,
                  color: Colors.white,
                ),
              ),
              errorWidget: (_, __, ___) => _fallback(),
            ),
    );
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        child: const Icon(Icons.image_outlined, color: AppColors.primary),
      );
}
