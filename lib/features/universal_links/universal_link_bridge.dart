import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class UniversalLinkBridge {
  static const MethodChannel _methods = MethodChannel(
    'khuctamgiao/universal_links',
  );
  static const EventChannel _events = EventChannel(
    'khuctamgiao/universal_links/events',
  );

  StreamSubscription<dynamic>? _subscription;

  Future<void> start(GoRouter router) async {
    final initial = await initialLink();
    _open(router, initial);
    _subscription = _events.receiveBroadcastStream().listen(
      (event) => _open(router, event?.toString()),
    );
  }

  Future<String?> initialLink() {
    return _methods.invokeMethod<String>('getInitialLink');
  }

  Future<void> clearInitialLink() {
    return _methods.invokeMethod<void>('clearInitialLink');
  }

  void _open(GoRouter router, String? rawLink) {
    final route = routeFromLink(rawLink);
    if (route != null) {
      router.go(route);
      clearInitialLink();
    }
  }

  String? routeFromLink(String? rawLink) {
    if (rawLink == null || rawLink.isEmpty) return null;
    final uri = Uri.tryParse(rawLink);
    if (uri == null) return null;

    final path = uri.hasScheme ? uri.path : rawLink;
    final normalizedPath = path.isEmpty ? '/' : path;
    final allowedPrefixes = [
      '/',
      '/services',
      '/blog',
      '/planner',
      '/our-story',
      '/testimonials',
      '/search',
      '/notifications',
      '/reminders',
    ];

    if (allowedPrefixes.any(
      (prefix) =>
          normalizedPath == prefix || normalizedPath.startsWith('$prefix/'),
    )) {
      return uri.hasQuery ? '$normalizedPath?${uri.query}' : normalizedPath;
    }
    return null;
  }

  Future<void> dispose() async => _subscription?.cancel();
}
