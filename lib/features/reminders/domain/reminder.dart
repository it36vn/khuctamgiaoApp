enum ReminderImportance {
  normal,
  important,
  critical;

  String label(String locale) {
    final isVi = locale == 'vi';
    return switch (this) {
      ReminderImportance.normal => isVi ? 'Bình thường' : 'Normal',
      ReminderImportance.important => isVi ? 'Quan trọng' : 'Important',
      ReminderImportance.critical => isVi ? 'Rất quan trọng' : 'Very important',
    };
  }
}

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.content,
    required this.scheduledAt,
    required this.importance,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime scheduledAt;
  final ReminderImportance importance;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  int get notificationId {
    return id.codeUnits.fold<int>(0, (value, code) {
      return ((value * 31) + code) & 0x7fffffff;
    });
  }

  Reminder copyWith({
    String? title,
    String? content,
    DateTime? scheduledAt,
    ReminderImportance? importance,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      importance: importance ?? this.importance,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      scheduledAt: DateTime.parse(json['scheduled_at'].toString()),
      importance: ReminderImportance.values.firstWhere(
        (item) => item.name == json['importance'],
        orElse: () => ReminderImportance.normal,
      ),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'scheduled_at': scheduledAt.toIso8601String(),
      'importance': importance.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
