import 'package:flutter/material.dart';

const Color kDefaultThemeColor = Color(0xFF3366FF);

class SettingsState {
  const SettingsState({
    this.reminderEnabled = false,
    this.plannedReminderEnabled = false,
    this.quickPayIncludesPlanned = false,
    this.themeColor = kDefaultThemeColor,
  });

  final bool reminderEnabled;
  final bool plannedReminderEnabled;
  final bool quickPayIncludesPlanned;
  final Color themeColor;

  SettingsState copyWith({
    bool? reminderEnabled,
    bool? plannedReminderEnabled,
    bool? quickPayIncludesPlanned,
    Color? themeColor,
  }) {
    return SettingsState(
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      plannedReminderEnabled:
          plannedReminderEnabled ?? this.plannedReminderEnabled,
      quickPayIncludesPlanned:
          quickPayIncludesPlanned ?? this.quickPayIncludesPlanned,
      themeColor: themeColor ?? this.themeColor,
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
        other.quickPayIncludesPlanned == quickPayIncludesPlanned &&
        other.themeColor == themeColor;
  }

  @override
  int get hashCode => Object.hash(
        reminderEnabled,
        plannedReminderEnabled,
        quickPayIncludesPlanned,
        themeColor,
      );
}
