import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_'
    'r'
    'ive'
    'r'
    'pod/flutter_'
    'r'
    'ive'
    'r'
    'pod.dart';

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
  return SettingsNotifier(service);
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
  SettingsNotifier(this._reminderService) : super(const SettingsState());

  final ReminderService _reminderService;

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
