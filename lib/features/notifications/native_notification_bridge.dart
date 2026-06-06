import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class NativeNotificationBridge {
  static const MethodChannel _methods = MethodChannel(
    'khuctamgiao/notifications',
  );
  static const EventChannel _events = EventChannel(
    'khuctamgiao/notifications/events',
  );

  StreamSubscription<dynamic>? _subscription;

  Future<void> start(GoRouter router) async {
    final initial = await initialNotification();
    _open(router, initial);
    _subscription = _events.receiveBroadcastStream().listen(
      (event) => _open(router, _toPayload(event)),
    );
  }

  Future<bool> requestPermission() async {
    final granted = await _methods.invokeMethod<bool>('requestPermission');
    return granted ?? false;
  }

  Future<String?> deviceToken() {
    return _methods.invokeMethod<String>('getDeviceToken');
  }

  Future<bool> areNotificationsEnabled() async {
    final enabled = await _methods.invokeMethod<bool>(
      'areNotificationsEnabled',
    );
    return enabled ?? false;
  }

  Future<void> openNotificationSettings() {
    return _methods.invokeMethod<void>('openNotificationSettings');
  }

  Future<Map<String, dynamic>?> initialNotification() async {
    final payload = await _methods.invokeMethod<dynamic>(
      'getInitialNotification',
    );
    return _toPayload(payload);
  }

  Future<void> clearInitialNotification() {
    return _methods.invokeMethod<void>('clearInitialNotification');
  }

  void _open(GoRouter router, Map<String, dynamic>? payload) {
    final route = routeFromPayload(payload);
    if (route != null) {
      router.go(route);
      clearInitialNotification();
    }
  }

  String? routeFromPayload(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    final rawUrl =
        payload['url'] ??
        payload['data.url'] ??
        payload['route'] ??
        payload['payload'];
    if (rawUrl == null) return null;
    final uri = Uri.tryParse(rawUrl.toString());
    if (uri == null) return null;
    final path = uri.hasScheme ? uri.path : rawUrl.toString();
    if (path.isEmpty) return '/';
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
      (prefix) => path == prefix || path.startsWith('$prefix/'),
    )) {
      return uri.hasQuery ? '$path?${uri.query}' : path;
    }
    return null;
  }

  Map<String, dynamic>? _toPayload(Object? value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  Future<void> dispose() async => _subscription?.cancel();
}
