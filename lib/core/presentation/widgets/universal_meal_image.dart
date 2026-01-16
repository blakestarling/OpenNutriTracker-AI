import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_placeholder.dart';

class UniversalMealImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const UniversalMealImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? const MealPlaceholder();
    }

    if (imageUrl!.startsWith('http')) {
      return CachedNetworkImage(
        width: width,
        height: height,
        cacheManager: locator<CacheManager>(),
        imageUrl: imageUrl!,
        fit: fit,
        placeholder: (context, string) =>
            placeholder ?? const MealPlaceholder(),
        errorWidget: (context, url, error) =>
            errorWidget ?? const MealPlaceholder(),
      );
    } else {
      return Image.file(
        File(imageUrl!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const MealPlaceholder();
        },
      );
    }
  }
}
