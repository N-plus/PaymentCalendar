class SettingsState {
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
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SettingsState &&
        other.reminderEnabled == reminderEnabled &&
        other.plannedReminderEnabled == plannedReminderEnabled &&
        other.quickPayIncludesPlanned == quickPayIncludesPlanned;
  }

  @override
  int get hashCode => Object.hash(
        reminderEnabled,
        plannedReminderEnabled,
        quickPayIncludesPlanned,
      );
}
