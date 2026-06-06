import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_loading.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  final String? url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    final child = imageUrl == null || imageUrl.isEmpty
        ? _Placeholder(height: height, width: width)
        : CachedNetworkImage(
            imageUrl: imageUrl,
            height: height,
            width: width,
            fit: fit,
            placeholder: (_, __) => _Placeholder(height: height, width: width),
            errorWidget: (_, __, ___) => _Placeholder(
              height: height,
              width: width,
              icon: Icons.broken_image_outlined,
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.height, this.width, this.icon = Icons.image});

  final double? height;
  final double? width;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: icon == Icons.image
          ? const SkeletonBox(borderRadius: 0)
          : Icon(icon, color: Theme.of(context).colorScheme.outline),
    );
  }
}
