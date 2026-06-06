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
import '../common/public_standalone_screen.dart';
import '../public_cubits.dart';

class SearchStandaloneScreen extends StatefulWidget {
  const SearchStandaloneScreen({super.key});

  @override
  State<SearchStandaloneScreen> createState() => _SearchStandaloneScreenState();
}

class _SearchStandaloneScreenState extends State<SearchStandaloneScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SearchCubit(getIt.publicRepository, context.read<LocaleCubit>()),
      child: Builder(
        builder: (context) {
          final colors = Theme.of(context).colorScheme;
          final text = context.localize;
          return PublicStandaloneScreen(
            title: text.search,
            titleWidget: SearchBar(
              controller: _controller,
              hintText: text.search,
              autoFocus: true,
              leading: const Icon(Icons.search, size: 20),
              backgroundColor: WidgetStatePropertyAll(colors.surface),
              elevation: const WidgetStatePropertyAll(0),
              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colors.outlineVariant),
                ),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
              constraints: const BoxConstraints(minHeight: 42),
              onSubmitted: context.read<SearchCubit>().search,
            ),
            child: const SearchScreen(),
          );
        },
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocaleCubit, String>(
      listener: (context, _) => context.read<SearchCubit>().refresh(),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          BlocBuilder<SearchCubit, AsyncState<Map<String, List<ContentItem>>>>(
            builder: (context, state) {
              final data = switch (state) {
                AsyncLoaded<Map<String, List<ContentItem>>>(:final data) =>
                  data,
                AsyncLoading<Map<String, List<ContentItem>>>(:final previous) =>
                  previous,
                AsyncFailure<Map<String, List<ContentItem>>>(:final previous) =>
                  previous,
                _ => null,
              };
              if (data == null && state is AsyncLoading) {
                return const AppSkeletonGrid(itemCount: 3);
              }
              if (data == null &&
                  state is AsyncFailure<Map<String, List<ContentItem>>>) {
                return AppInlineError(
                  message: state.failure.message,
                  onRetry: context.read<SearchCubit>().refresh,
                );
              }
              if (data == null) return const SizedBox.shrink();
              final sections = data.entries
                  .where((entry) => entry.value.isNotEmpty)
                  .toList();
              if (sections.isEmpty) {
                return Center(child: Text(context.localize.noResults));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in sections)
                    _SearchResultSection(
                      title: context.localize.searchSectionTitle(_routeForType(entry.key)),
                      items: entry.value,
                      routeKey: _routeForType(entry.key),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _routeForType(String type) {
    final normalized = type.toLowerCase().replaceAll('_', '-');
    return switch (normalized) {
      'blog-posts' || 'posts' || 'journal' => 'blog',
      'wedding-stories' || 'stories' => 'our-story',
      'service' => 'services',
      'testimonial' => 'testimonials',
      _ => normalized,
    };
  }
}

class _SearchResultSection extends StatelessWidget {
  const _SearchResultSection({
    required this.title,
    required this.items,
    required this.routeKey,
  });

  final String title;
  final List<ContentItem> items;
  final String routeKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          ...items.map(
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
      ),
    );
  }
}
