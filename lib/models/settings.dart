import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.reminderEnabled = false,
    this.plannedReminderEnabled = false,
    this.quickPayIncludesPlanned = false,
  });

  final bool reminderEnabled;
  final bool plannedReminderEnabled;
  final bool quickPayIncludesPlanned;

  SettingsState copyWith({
    bool? reminderEnabled,
    bool? plannedReminderEnabled,
    bool? quickPayIncludesPlanned,
  }) {
    return SettingsState(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      plannedReminderEnabled:
          plannedReminderEnabled ?? this.plannedReminderEnabled,
      quickPayIncludesPlanned:
          quickPayIncludesPlanned ?? this.quickPayIncludesPlanned,
    );
  }

  @override
  List<Object?> get props => [
        reminderEnabled,
        plannedReminderEnabled,
        quickPayIncludesPlanned,
      ];
}
