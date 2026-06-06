import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../public/presentation/common/app_text.dart';
import '../domain/reminder.dart';
import 'reminder_cubit.dart';

class ReminderListScreen extends StatelessWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.localize;
    return BlocBuilder<ReminderCubit, List<Reminder>>(
      builder: (context, reminders) {
        if (reminders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                text.noReminders,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }
        final now = DateTime.now();
        final upcoming =
            reminders
                .where((reminder) => !reminder.scheduledAt.isBefore(now))
                .toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final past =
            reminders
                .where((reminder) => reminder.scheduledAt.isBefore(now))
                .toList()
              ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            if (upcoming.isNotEmpty)
              _ReminderSection(
                title: text.upcomingReminders,
                items: upcoming,
                initiallyExpanded: true,
              ),
            if (upcoming.isNotEmpty && past.isNotEmpty)
              const SizedBox(height: 18),
            if (past.isNotEmpty)
              _ReminderSection(
                title: text.pastReminders,
                items: past,
                initiallyExpanded: false,
              ),
          ],
        );
      },
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.title,
    required this.items,
    required this.initiallyExpanded,
  });

  final String title;
  final List<Reminder> items;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(items);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey('reminder-section-$title'),
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              for (final entry in grouped.entries) ...[
                if (entry.value.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Text(
                      _formatDateHeader(context, entry.key),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                for (final reminder in entry.value) ...[
                  _ReminderTile(reminder: reminder),
                  if (reminder != entry.value.last) const SizedBox(height: 10),
                ],
                if (entry.key != grouped.keys.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<Reminder>> _groupByDate(List<Reminder> reminders) {
    final grouped = <DateTime, List<Reminder>>{};
    for (final reminder in reminders) {
      final date = DateUtils.dateOnly(reminder.scheduledAt);
      grouped.putIfAbsent(date, () => []).add(reminder);
    }
    return grouped;
  }
}

class ReminderDetailScreen extends StatelessWidget {
  const ReminderDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final text = context.localize;
    return BlocBuilder<ReminderCubit, List<Reminder>>(
      builder: (context, _) {
        final reminder = context.read<ReminderCubit>().byId(id);
        if (reminder == null) {
          return Center(child: Text(text.reminderNotFound));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImportanceIcon(importance: reminder.importance, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.schedule,
              label: text.reminderTime,
              value: _formatDateTime(context, reminder.scheduledAt),
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.priority_high,
              label: text.importance,
              value: reminder.importance.label(text.locale),
            ),
            if (reminder.content.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                reminder.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/reminders/${reminder.id}/edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(text.edit),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: text.delete,
                  onPressed: () async {
                    final deleted = await _confirmDelete(context, reminder);
                    if (!context.mounted || deleted != true) return;
                    context.go('/reminders');
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class ReminderEditScreen extends StatefulWidget {
  const ReminderEditScreen({super.key, this.id});

  final String? id;

  @override
  State<ReminderEditScreen> createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(minutes: 5));
  ReminderImportance _importance = ReminderImportance.normal;
  bool _initialized = false;
  bool _saving = false;

  bool get _hasTitle => _titleController.text.trim().isNotEmpty;

  bool get _hasValidScheduledAt {
    return _scheduledAt.isAfter(DateTime.now().add(const Duration(minutes: 1)));
  }

  bool get _canSave => !_saving && _hasTitle && _hasValidScheduledAt;

  Reminder? get _existing {
    final id = widget.id;
    if (id == null) return null;
    return context.read<ReminderCubit>().byId(id);
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refreshSaveState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final reminder = _existing;
    if (reminder != null) {
      _titleController.text = reminder.title;
      _contentController.text = reminder.content;
      _scheduledAt = reminder.scheduledAt;
      _importance = reminder.importance;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshSaveState);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.localize;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: '${text.reminderTitle} *',
              prefixIcon: const Icon(Icons.title),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? text.requiredField
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _contentController,
            minLines: 4,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: text.reminderContent,
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(text.reminderTime),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDateTime(context, _scheduledAt)),
                if (!_hasValidScheduledAt)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      text.reminderTimeMustBeFuture,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ReminderImportance>(
            initialValue: _importance,
            decoration: InputDecoration(
              labelText: text.importance,
              prefixIcon: const Icon(Icons.priority_high),
            ),
            items: ReminderImportance.values
                .map(
                  (importance) => DropdownMenuItem(
                    value: importance,
                    child: Text(importance.label(text.locale)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _importance = value);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _canSave ? _save : null,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(text.save),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      locale: Locale(
        navigatorKey.currentContext?.localizeCallback.locale ?? 'vi',
      ),
      initialDate: _scheduledAt.isBefore(now) ? now : _scheduledAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: context.localizeCallback.selectDate,
      cancelText: context.localizeCallback.cancel,
      confirmText: context.localizeCallback.select,
      fieldHintText: 'dd/MM/yyyy',
      fieldLabelText: context.localizeCallback.selectDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      helpText: context.localizeCallback.selectTime,
      cancelText: context.localizeCallback.cancel,
      confirmText: context.localizeCallback.select,
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasValidScheduledAt) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.localize.reminderTimeMustBeFuture)),
      );
      return;
    }

    setState(() => _saving = true);
    final cubit = context.read<ReminderCubit>();
    final existing = _existing;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final reminder = existing == null
        ? await cubit.create(
            title: title,
            content: content,
            scheduledAt: _scheduledAt,
            importance: _importance,
          )
        : await cubit.update(
            existing.copyWith(
              title: title,
              content: content,
              scheduledAt: _scheduledAt,
              importance: _importance,
            ),
          );

    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/reminders/${reminder.id}');
  }

  void _refreshSaveState() {
    setState(() {});
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final text = context.localize;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: _ImportanceIcon(importance: reminder.importance),
        title: Text(reminder.title),
        subtitle: Text(
          '${_formatDateTime(context, reminder.scheduledAt)}\n'
          '${reminder.importance.label(text.locale)}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: text.delete,
          onPressed: () => _confirmDelete(context, reminder),
          icon: const Icon(Icons.delete_outline),
        ),
        onTap: () => context.push('/reminders/${reminder.id}'),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImportanceIcon extends StatelessWidget {
  const _ImportanceIcon({required this.importance, this.size = 26});

  final ReminderImportance importance;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = switch (importance) {
      ReminderImportance.normal => Theme.of(context).colorScheme.primary,
      ReminderImportance.important => Colors.orange.shade700,
      ReminderImportance.critical => Theme.of(context).colorScheme.error,
    };
    return Icon(Icons.notifications_active_outlined, color: color, size: size);
  }
}

Future<bool?> _confirmDelete(BuildContext context, Reminder reminder) {
  final text = context.localize;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(text.deleteReminder),
      content: Text(reminder.title),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(text.cancel),
        ),
        FilledButton.icon(
          onPressed: () async {
            await context.read<ReminderCubit>().delete(reminder);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(text.delete),
        ),
      ],
    ),
  );
}

String _formatDateTime(BuildContext context, DateTime value) {
  final locale = context.localize.locale;
  final pattern = locale == 'vi' ? 'HH:mm, dd/MM/yyyy' : 'MMM d, yyyy HH:mm';
  return DateFormat(pattern).format(value);
}

String _formatDateHeader(BuildContext context, DateTime value) {
  final locale = context.localize.locale;
  final pattern = locale == 'vi' ? 'dd/MM/yyyy' : 'MMM d, yyyy';
  return DateFormat(pattern).format(value);
}
