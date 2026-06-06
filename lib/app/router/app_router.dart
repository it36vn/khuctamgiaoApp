import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_error_view.dart';
import '../../features/public/presentation/common/app_text.dart';
import '../../features/public/presentation/public_screens.dart';
import '../../features/reminders/presentation/reminder_screens.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
class AppRouter {
  AppRouter() {
    router = GoRouter(
      initialLocation: '/',
      navigatorKey: navigatorKey,
      routes: [
        ShellRoute(
          builder: (context, state, child) => PublicShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            GoRoute(
              path: '/services',
              builder: (_, __) => const ContentListScreen(routeKey: 'services'),
            ),
            GoRoute(
              path: '/blog',
              builder: (_, __) => const ContentListScreen(routeKey: 'blog'),
            ),
            GoRoute(
              path: '/planner',
              builder: (_, __) => const ContentListScreen(routeKey: 'planner'),
            ),
            GoRoute(
              path: '/our-story',
              builder: (_, __) =>
                  const ContentListScreen(routeKey: 'our-story'),
            ),
            GoRoute(
              path: '/testimonials',
              builder: (_, __) =>
                  const ContentListScreen(routeKey: 'testimonials'),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const PublicSettingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, __) => PublicStandaloneScreen(
            title: context.localize.notifications,
            child: const NotificationsScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => const SearchStandaloneScreen(),
        ),
        GoRoute(
          path: '/reminders',
          builder: (context, __) => PublicStandaloneScreen(
            title: context.localize.reminderList,
            rightWidget: IconButton(
              tooltip: context.localize.addReminder,
              onPressed: () => context.push('/reminders/new'),
              icon: const Icon(Icons.add_alarm_outlined),
            ),
            child: const ReminderListScreen(),
          ),
        ),
        GoRoute(
          path: '/reminders/new',
          builder: (context, __) => PublicStandaloneScreen(
            title: context.localize.addReminder,
            child: const ReminderEditScreen(),
          ),
        ),
        GoRoute(
          path: '/reminders/:id',
          builder: (context, state) => PublicStandaloneScreen(
            title: context.localize.reminderDetail,
            child: ReminderDetailScreen(id: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/reminders/:id/edit',
          builder: (context, state) => PublicStandaloneScreen(
            title: context.localize.editReminder,
            child: ReminderEditScreen(id: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/services/:path',
          builder: (context, state) {
            final path = state.pathParameters['path']!;
            final title = state.extra as String? ?? context.localize.detail;
            return PublicStandaloneScreen(
              title: context.localize.detail,
              rightWidget: ContentDetailActions(
                routeKey: 'services',
                path: path,
                title: title,
              ),
              child: ContentDetailScreen(routeKey: 'services', path: path),
            );
          },
        ),
        GoRoute(
          path: '/blog/:path',
          builder: (context, state) {
            final path = state.pathParameters['path']!;
            final title = state.extra as String? ?? context.localize.detail;
            return PublicStandaloneScreen(
              title: context.localize.detail,
              rightWidget: ContentDetailActions(routeKey: 'blog', path: path, title: title),
              child: ContentDetailScreen(routeKey: 'blog', path: path),
            );
          },
        ),
        GoRoute(
          path: '/planner/:path',
          builder: (context, state) {
            final path = state.pathParameters['path']!;
            final title = state.extra as String? ?? context.localize.detail;
            return PublicStandaloneScreen(
              title: context.localize.detail,
              rightWidget: ContentDetailActions(
                routeKey: 'planner',
                path: path,
                title: title,
              ),
              child: ContentDetailScreen(routeKey: 'planner', path: path),
            );
          },
        ),
        GoRoute(
          path: '/our-story/:path',
          builder: (context, state) {
            final path = state.pathParameters['path']!;
            final title = state.extra as String? ?? context.localize.detail;
            return PublicStandaloneScreen(
              title: context.localize.detail,
              rightWidget: ContentDetailActions(
                routeKey: 'our-story',
                path: path,
                title: title,
              ),
              child: ContentDetailScreen(routeKey: 'our-story', path: path),
            );
          },
        ),
        GoRoute(
          path: '/testimonials/:path',
          builder: (context, state) {
            final path = state.pathParameters['path']!;
            final title = state.extra as String? ?? context.localize.detail;
            return PublicStandaloneScreen(
              title: context.localize.detail,
              rightWidget: ContentDetailActions(
                routeKey: 'testimonials',
                path: path,
                title: title,
              ),
              child: ContentDetailScreen(routeKey: 'testimonials', path: path),
            );
          },
        ),
      ],
      errorBuilder: (ctx, state) => Scaffold(
        body: AppErrorView(
          message: state.error.toString(),
          retryButton: FilledButton.icon(
            onPressed: () => router.go('/'),
            icon: const Icon(Icons.arrow_back),
            label: Text(ctx.localize.home),
          ),
        ),
      ),
    );
  }

  late final GoRouter router;
}
