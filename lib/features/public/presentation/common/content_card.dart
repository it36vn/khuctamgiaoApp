import 'package:flutter/material.dart';

import '../../../../core/widgets/app_image.dart';
import '../../domain/public_models.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.item, this.onTap});

  final ContentItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppImage(
                url: item.imageUrl ?? item.detailImageUrl,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.excerpt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.excerpt!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
