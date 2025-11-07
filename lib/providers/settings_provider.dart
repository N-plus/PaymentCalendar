import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_check/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';
import '../models/settings.dart';
import '../services/reminder_service.dart';
import 'expenses_provider.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  throw UnimplementedError('ReminderService must be provided in main.dart');
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.watch(reminderServiceProvider);
  final preferences = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(service, preferences);
});

final reminderCoordinatorProvider = Provider<void>((ref) {
  ref.listen<List<Expense>>(expensesProvider, (_, next) {
    unawaited(ref.read(settingsProvider.notifier).refreshReminders(next));
  });
  ref.listen<SettingsState>(settingsProvider, (_, __) {
    unawaited(ref
        .read(settingsProvider.notifier)
        .refreshReminders(ref.read(expensesProvider)));
  });
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._reminderService, this._preferences)
      : super(const SettingsState()) {
    unawaited(_restoreSettings());
  }

  final ReminderService _reminderService;
  final SharedPreferences _preferences;

  static const _themeColorKey = 'theme_color';

  Future<void> toggleReminder(bool value) async {
    state = state.copyWith(reminderEnabled: value);
    if (value) {
      await _reminderService.scheduleDailyUnpaidReminder();
      if (state.plannedReminderEnabled) {
        await _reminderService.schedulePlannedReminder();
      }
    } else {
      await _reminderService.cancelAll();
    }
  }

  Future<void> togglePlannedReminder(bool value) async {
    state = state.copyWith(plannedReminderEnabled: value);
    if (!state.reminderEnabled) {
      return;
    }
    if (value) {
      await _reminderService.schedulePlannedReminder();
    } else {
      await _reminderService.cancelPlannedReminder();
    }
  }

  void setQuickPayIncludesPlanned(bool value) {
    state = state.copyWith(quickPayIncludesPlanned: value);
  }

  Future<void> setThemeColor(Color color) async {
    state = state.copyWith(themeColor: color);
    await _preferences.setInt(_themeColorKey, color.value);
  }

  Future<void> _restoreSettings() async {
    final colorValue = _preferences.getInt(_themeColorKey);
    if (colorValue != null) {
      state = state.copyWith(themeColor: Color(colorValue));
    }
  }

  Future<void> refreshReminders(List<Expense> expenses) async {
    if (!state.reminderEnabled) {
      return;
    }
    final hasUnpaid =
        expenses.any((expense) => expense.status == ExpenseStatus.unpaid);
    if (hasUnpaid) {
      await _reminderService.scheduleDailyUnpaidReminder();
    } else {
      await _reminderService.cancelUnpaidReminder();
    }

    if (!state.plannedReminderEnabled) {
      return;
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final hasPlannedForTomorrow = expenses.any((expense) {
      if (expense.status != ExpenseStatus.planned) {
        return false;
      }
      final date = DateUtils.dateOnly(expense.date);
      return date.difference(today).inDays == 1;
    });
    if (hasPlannedForTomorrow) {
      await _reminderService.schedulePlannedReminder();
    } else {
      await _reminderService.cancelPlannedReminder();
    }
  }
}
