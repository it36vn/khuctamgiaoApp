import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/reminder_notification_service.dart';
import '../data/reminder_repository.dart';
import '../domain/reminder.dart';

class ReminderCubit extends Cubit<List<Reminder>> {
  ReminderCubit(this._repository, this._notificationService) : super(const []);

  final ReminderRepository _repository;
  final ReminderNotificationService _notificationService;

  void load() {
    emit(_repository.getAll());
  }

  Reminder? byId(String id) {
    for (final reminder in state) {
      if (reminder.id == id) return reminder;
    }
    return _repository.getById(id);
  }

  Future<Reminder> create({
    required String title,
    required String content,
    required DateTime scheduledAt,
    required ReminderImportance importance,
  }) async {
    final reminder = await _repository.create(
      title: title,
      content: content,
      scheduledAt: scheduledAt,
      importance: importance,
    );
    await _notificationService.schedule(reminder);
    load();
    return reminder;
  }

  Future<Reminder> update(Reminder reminder) async {
    final updated = await _repository.update(
      reminder.copyWith(updatedAt: DateTime.now()),
    );
    await _notificationService.schedule(updated);
    load();
    return updated;
  }

  Future<void> delete(Reminder reminder) async {
    await _repository.delete(reminder.id);
    await _notificationService.cancel(reminder);
    load();
  }
}
