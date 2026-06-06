import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CacheStorage {
  CacheStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = 'locale';
  static const _deviceIdKey = 'device_id';
  static const _notificationPromptedKey = 'notification_permission_prompted';
  static const _favoriteContentKeysKey = 'favorite_content_keys';
  static const _remindersKey = 'reminders';

  String get locale => _prefs.getString(_localeKey) ?? 'en';

  Future<void> setLocale(String locale) => _prefs.setString(_localeKey, locale);

  Future<String> stableDeviceId() async {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    await _prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  bool get hasPromptedForNotificationPermission =>
      _prefs.getBool(_notificationPromptedKey) ?? false;

  Future<void> markNotificationPermissionPrompted() {
    return _prefs.setBool(_notificationPromptedKey, true);
  }

  Set<String> get favoriteContentKeys =>
      (_prefs.getStringList(_favoriteContentKeysKey) ?? const []).toSet();

  Future<void> setFavoriteContentKeys(Set<String> keys) {
    final sortedKeys = keys.toList()..sort();
    return _prefs.setStringList(_favoriteContentKeysKey, sortedKeys);
  }

  List<Map<String, dynamic>> get reminderJsonList {
    return (_prefs.getStringList(_remindersKey) ?? const [])
        .map((item) => jsonDecode(item))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> setReminderJsonList(List<Map<String, dynamic>> reminders) {
    return _prefs.setStringList(
      _remindersKey,
      reminders.map(jsonEncode).toList(),
    );
  }
}
