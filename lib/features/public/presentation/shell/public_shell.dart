import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/async_state.dart';
import '../../domain/public_models.dart';
import '../common/app_text.dart';
import '../public_cubits.dart';

class PublicShell extends StatelessWidget {
  const PublicShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final showTopBar = !location.startsWith('/settings');
    final text = context.localize;
    return Scaffold(
      appBar: showTopBar ? const _PublicTopBar() : null,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        onDestinationSelected: (index) {
          final route = [
            '/',
            '/services',
            '/blog',
            '/our-story',
            '/settings',
          ][index];
          if (route == location) return;
          context.go(route);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: text.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: text.services,
          ),
          NavigationDestination(
            icon: const Icon(Icons.article_outlined),
            selectedIcon: const Icon(Icons.article),
            label: text.blog,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories),
            label: text.stories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: text.settings,
          ),
        ],
      ),
    );
  }

  int _indexFor(String location) {
    if (location.startsWith('/services')) return 1;
    if (location.startsWith('/blog')) return 2;
    if (location.startsWith('/our-story')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }
}

class _PublicTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _PublicTopBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: BlocBuilder<SettingsCubit, AsyncState<SiteSettings>>(
        builder: (context, state) {
          final settings = state is AsyncLoaded<SiteSettings>
              ? state.data
              : null;
          return Row(
            children: [
              if (settings?.brandLogo?.url != null) ...[
                AppImage(
                  url: settings!.brandLogo!.url,
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
              ],
              Flexible(child: Text(settings?.siteName ?? 'Khúc Tâm Giao')),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          tooltip: context.localize.search,
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: context.localize.notifications,
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    );
  }
}
