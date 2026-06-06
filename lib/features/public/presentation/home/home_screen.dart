import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_state.dart';
import '../../domain/public_models.dart';
import '../common/app_text.dart';
import '../common/content_card.dart';
import '../public_cubits.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HomeCubit(getIt.publicRepository, context.read<LocaleCubit>())
            ..load(),
      child: BlocListener<LocaleCubit, String>(
        listener: (context, _) => context.read<HomeCubit>().load(),
        child: BlocBuilder<HomeCubit, AsyncState<HomeData>>(
          builder: (context, state) {
            var data = switch (state) {
              AsyncLoaded<HomeData>(:final data) => data,
              AsyncLoading<HomeData>(:final previous) => previous,
              AsyncFailure<HomeData>(:final previous) => previous,
              _ => null,
            };
            if (data == null && state is AsyncLoading<HomeData>) {
              return AppSkeleton.home();
            }
            final failure = state is AsyncFailure<HomeData> ? state : null;
            data ??= HomeData(
              settings: SiteSettings(
                siteName: 'Khúc Tâm Giao',
                siteTagline: context.localize.weddingAndEventPlanning,
              ),
            );
            final text = context.localize;
            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().load(),
              child: ListView(
                children: [
                  if (failure != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: AppInlineError(
                        message: failure.failure.message,
                        onRetry: () => context.read<HomeCubit>().load(),
                      ),
                    ),
                  _Hero(settings: data.settings),
                  _Section(
                    title: text.services,
                    items: data.services,
                    baseRoute: '/services',
                  ),
                  _Section(
                    title: text.weddingStories,
                    items: data.weddingStories,
                    baseRoute: '/our-story',
                  ),
                  _Section(
                    title: text.journal,
                    items: data.blogPosts,
                    baseRoute: '/blog',
                  ),
                  _Contact(settings: data.settings),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.settings});

  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(url: settings.homeBackgroundImage?.url, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.siteName,
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      settings.siteTagline ??
                          context.localize.weddingAndEventPlanning,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.baseRoute,
  });

  final String title;
  final List<ContentItem> items;
  final String baseRoute;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 620
                  ? 2
                  : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 0.86,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: items.length,
                itemBuilder: (_, index) => ContentCard(
                  item: items[index],
                  onTap: () => context.push('$baseRoute/${items[index].path}', extra: items[index].title),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.settings});

  final SiteSettings settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.localize.contact,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (settings.contactEmail != null) Text(settings.contactEmail!),
          if (settings.contactPhone != null) Text(settings.contactPhone!),
          if (settings.contactAddress != null) Text(settings.contactAddress!),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: settings.socialUrls.entries
                .map(
                  (entry) => OutlinedButton(
                    onPressed: () => launchUrl(Uri.parse(entry.value)),
                    child: Text(entry.key.replaceAll('_url', '')),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
