import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_state.dart';
import '../../domain/public_models.dart';
import '../common/app_text.dart';
import '../common/content_routes.dart';
import '../public_cubits.dart';

class ContentDetailScreen extends StatelessWidget {
  const ContentDetailScreen({
    super.key,
    required this.routeKey,
    required this.path,
  });

  final String routeKey;
  final String path;

  @override
  Widget build(BuildContext context) {
    final type = contentRoutes[routeKey] ?? routeKey;
    return BlocProvider(
      create: (_) => ContentDetailCubit(
        getIt.publicRepository,
        context.read<LocaleCubit>(),
      )..load(type, path),
      child: BlocListener<LocaleCubit, String>(
        listener: (context, _) =>
            context.read<ContentDetailCubit>().load(type, path),
        child: BlocBuilder<ContentDetailCubit, AsyncState<ContentDetailData>>(
          builder: (context, state) {
            final data = switch (state) {
              AsyncLoaded<ContentDetailData>(:final data) => data,
              AsyncLoading<ContentDetailData>(:final previous) => previous,
              AsyncFailure<ContentDetailData>(:final previous) => previous,
              _ => null,
            };
            if (data == null && state is AsyncLoading<ContentDetailData>) {
              return AppSkeleton.contentDetail();
            }
            if (data == null && state is AsyncFailure<ContentDetailData>) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  AppInlineError(
                    message: state.failure.message,
                    onRetry: () =>
                        context.read<ContentDetailCubit>().load(type, path),
                  ),
                ],
              );
            }
            if (data == null) return const SizedBox.shrink();
            final item = data.item;
            return ListView(
              children: [
                AppImage(
                  url: item.detailImageUrl ?? item.imageUrl,
                  height: 360,
                  width: double.infinity,
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (item.excerpt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          item.excerpt!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                      const SizedBox(height: 18),
                      Html(data: item.bodyHtml ?? ''),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ContentDetailActions extends StatelessWidget {
  const ContentDetailActions({
    super.key,
    required this.title,
    required this.routeKey,
    required this.path,
  });

  static const _shareHost = 'thuongag.com';
  final String title;
  final String routeKey;
  final String path;

  @override
  Widget build(BuildContext context) {
    final text = context.localize;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<FavoriteContentCubit, Set<String>>(
          builder: (context, favorites) {
            final isFavorite = favorites.contains(
              FavoriteContentCubit.keyFor(routeKey, path),
            );
            return IconButton(
              tooltip: isFavorite ? text.unfavorite : text.favorite,
              onPressed: () =>
                  context.read<FavoriteContentCubit>().toggle(routeKey, path),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
            );
          },
        ),
        Builder(
          builder: (buttonContext) {
            return IconButton(
              tooltip: text.share,
              onPressed: () => _share(buttonContext, title),
              icon: const Icon(Icons.share_outlined),
            );
          },
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context, String title) {
    final box = context.findRenderObject() as RenderBox?;
    final uri = Uri.https(_shareHost, '/$routeKey/$path');
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: title,
        text: '$uri',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}
