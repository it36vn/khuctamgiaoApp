import 'package:uuid/uuid.dart';

import '../../../core/storage/cache_storage.dart';
import '../domain/reminder.dart';

class ReminderRepository {
  ReminderRepository(this._cacheStorage);

  final CacheStorage _cacheStorage;

  List<Reminder> getAll() {
    final reminders = _cacheStorage.reminderJsonList
        .map(Reminder.fromJson)
        .toList();
    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  Reminder? getById(String id) {
    for (final reminder in getAll()) {
      if (reminder.id == id) return reminder;
    }
    return null;
  }

  Future<Reminder> create({
    required String title,
    required String content,
    required DateTime scheduledAt,
    required ReminderImportance importance,
  }) async {
    final now = DateTime.now();
    final reminder = Reminder(
      id: const Uuid().v4(),
      title: title,
      content: content,
      scheduledAt: scheduledAt,
      importance: importance,
      createdAt: now,
      updatedAt: now,
    );
    await _save([...getAll(), reminder]);
    return reminder;
  }

  Future<Reminder> update(Reminder reminder) async {
    final reminders = getAll()
        .map((item) => item.id == reminder.id ? reminder : item)
        .toList();
    await _save(reminders);
    return reminder;
  }

  Future<void> delete(String id) async {
    final reminders = getAll().where((item) => item.id != id).toList();
    await _save(reminders);
  }

  Future<void> _save(List<Reminder> reminders) {
    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return _cacheStorage.setReminderJsonList(
      reminders.map((item) => item.toJson()).toList(),
    );
  }
}
