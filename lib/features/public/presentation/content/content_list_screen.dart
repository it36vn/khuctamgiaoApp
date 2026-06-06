import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_state.dart';
import '../../domain/public_models.dart';
import '../common/app_text.dart';
import '../common/content_card.dart';
import '../common/content_routes.dart';
import '../public_cubits.dart';

class ContentListScreen extends StatelessWidget {
  const ContentListScreen({super.key, required this.routeKey});

  final String routeKey;

  @override
  Widget build(BuildContext context) {
    final type = contentRoutes[routeKey] ?? routeKey;
    return BlocProvider(
      create: (_) =>
          ContentListCubit(getIt.publicRepository, context.read<LocaleCubit>())
            ..load(type),
      child: BlocListener<LocaleCubit, String>(
        listener: (context, _) => context.read<ContentListCubit>().load(type),
        child: BlocBuilder<ContentListCubit, AsyncState<ContentListData>>(
          builder: (context, state) {
            final data = switch (state) {
              AsyncLoaded<ContentListData>(:final data) => data,
              AsyncLoading<ContentListData>(:final previous) => previous,
              AsyncFailure<ContentListData>(:final previous) => previous,
              _ => null,
            };
            if (data == null && state is AsyncLoading<ContentListData>) {
              return AppSkeleton.contentList();
            }
            if (data == null && state is AsyncFailure<ContentListData>) {
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    context.localize.routeTitle(routeKey),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  AppInlineError(
                    message: state.failure.message,
                    onRetry: () => context.read<ContentListCubit>().load(type),
                  ),
                ],
              );
            }
            if (data == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  context.localize.routeTitle(routeKey),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                ...data.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SizedBox(
                      height: 230,
                      child: ContentCard(
                        item: item,
                        onTap: () => context.push('/$routeKey/${item.path}', extra: item.title),
                      ),
                    ),
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
