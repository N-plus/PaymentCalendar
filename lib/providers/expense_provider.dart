import 'dart:async';

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/person.dart';
import '../services/image_storage_service.dart';
import '../services/local_storage_service.dart';
import '../services/reminder_service.dart';

class PersonSummary {
  PersonSummary({
    required this.person,
    required this.unpaidTotal,
    required this.plannedCount,
  });

  final Person person;
  final int unpaidTotal;
  final int plannedCount;
}

enum ExpenseStatusFilter { normal, planned, both }

enum ExpenseSortType { dateDesc, dateAsc, amountDesc, amountAsc }

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider() {
    _init();
  }

  final LocalStorageService _storage = LocalStorageService();
  final ReminderService _reminderService = ReminderService();
  final ImageStorageService _imageStorageService = ImageStorageService();
  final _uuid = const Uuid();

  List<Person> _persons = [];
  List<Expense> _expenses = [];
  bool _isLoading = true;
  bool _remindDaily = false;
  bool _remindPlanned = false;

  bool get isLoading => _isLoading;
  List<Person> get persons => List.unmodifiable(_persons);
  List<Expense> get expenses => List.unmodifiable(_expenses);
  bool get remindDaily => _remindDaily;
  bool get remindPlanned => _remindPlanned;

  Future<void> _init() async {
    final state = await _storage.load();
    _persons = state.persons;
    _expenses = state.expenses;
    _remindDaily = state.remindDaily;
    _remindPlanned = state.remindPlanned;
    _isLoading = false;
    if (_remindDaily) {
      unawaited(_reminderService.scheduleDailyReminder());
    }
    if (_remindPlanned) {
      for (final expense in _expenses.where((e) => e.isPlanned && !e.isPaid)) {
        unawaited(_reminderService.schedulePlannedReminder(expense));
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.save(
      persons: _persons,
      expenses: _expenses,
      remindDaily: _remindDaily,
      remindPlanned: _remindPlanned,
    );
  }

  Person getPerson(String id) {
    return _persons.firstWhere((element) => element.id == id);
  }

  Future<Person> addPerson({
    required String name,
    required AvatarType avatarType,
    String? photoUri,
    String? iconKey,
  }) async {
    final person = Person(
      id: _uuid.v4(),
      name: name,
      avatarType: avatarType,
      photoUri: photoUri,
      iconKey: iconKey,
    );
    _persons.add(person);
    await _persist();
    notifyListeners();
    return person;
  }

  Future<void> updatePerson(Person person) async {
    final index = _persons.indexWhere((p) => p.id == person.id);
    if (index == -1) return;
    _persons[index] = person;
    await _persist();
    notifyListeners();
  }

  Future<void> deletePerson(String personId) async {
    final removedExpenses =
        _expenses.where((expense) => expense.personId == personId).toList();
    _persons.removeWhere((person) => person.id == personId);
    _expenses.removeWhere((expense) => expense.personId == personId);
    await _persist();
    notifyListeners();
    if (_remindPlanned) {
      for (final expense in removedExpenses) {
        unawaited(_reminderService.cancelPlannedReminder(expense.id));
      }
    }
  }

  Future<Expense> addExpense({
    required DateTime date,
    required String personId,
    required int amount,
    String? memo,
    List<String>? photoUris,
    bool? isPlanned,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      date: date,
      personId: personId,
      amount: amount,
      memo: memo,
      photoUris: photoUris ?? <String>[],
      isPlanned: isPlanned,
    );
    _expenses.add(expense);
    await _persist();
    notifyListeners();
    if (_remindPlanned) {
      unawaited(_reminderService.schedulePlannedReminder(expense));
    }
    return expense;
  }

  Future<void> updateExpense(Expense updated) async {
    final index = _expenses.indexWhere((expense) => expense.id == updated.id);
    if (index == -1) return;
    final previous = _expenses[index];
    _expenses[index] = updated;
    await _persist();
    notifyListeners();
    if (_remindPlanned) {
      if (!updated.isPlanned || updated.isPaid) {
        unawaited(_reminderService.cancelPlannedReminder(updated.id));
      } else {
        unawaited(_reminderService.schedulePlannedReminder(updated));
      }
    }
  }

  Future<void> deleteExpense(String id) async {
    final expense = _expenses.firstWhereOrNull((element) => element.id == id);
    _expenses.removeWhere((element) => element.id == id);
    await _persist();
    notifyListeners();
    if (expense != null && _remindPlanned) {
      unawaited(_reminderService.cancelPlannedReminder(expense.id));
    }
  }

  Future<void> markAsPaid(String id) async {
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index == -1) return;
    final expense = _expenses[index];
    expense.isPaid = true;
    expense.paidAt = DateTime.now();
    expense.isPlanned = false;
    await _persist();
    notifyListeners();
    if (_remindPlanned) {
      unawaited(_reminderService.cancelPlannedReminder(expense.id));
    }
  }

  Future<void> markAsUnpaid(String id) async {
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index == -1) return;
    final expense = _expenses[index];
    expense.isPaid = false;
    expense.paidAt = null;
    expense.isPlanned = expense.date.isAfter(_today());
    await _persist();
    notifyListeners();
    if (_remindPlanned && expense.isPlanned) {
      unawaited(_reminderService.schedulePlannedReminder(expense));
    }
  }

  Future<void> updatePlannedStatus(String id, bool isPlanned) async {
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index == -1) return;
    final expense = _expenses[index];
    expense.isPlanned = isPlanned;
    await _persist();
    notifyListeners();
    if (_remindPlanned) {
      if (isPlanned && !expense.isPaid) {
        unawaited(_reminderService.schedulePlannedReminder(expense));
      } else {
        unawaited(_reminderService.cancelPlannedReminder(expense.id));
      }
    }
  }

  Future<void> changeExpenseDate(String id, DateTime date) async {
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index == -1) return;
    final expense = _expenses[index];
    expense.date = date;
    expense.isPlanned = expense.isPaid ? false : date.isAfter(_today());
    await _persist();
    notifyListeners();
    if (_remindPlanned) {
      if (expense.isPlanned) {
        unawaited(_reminderService.schedulePlannedReminder(expense));
      } else {
        unawaited(_reminderService.cancelPlannedReminder(expense.id));
      }
    }
  }

  Future<void> setDailyReminder(bool value) async {
    _remindDaily = value;
    await _persist();
    notifyListeners();
    if (value) {
      await _reminderService.scheduleDailyReminder();
    } else {
      await _reminderService.cancelDailyReminder();
    }
  }

  Future<void> setPlannedReminder(bool value) async {
    _remindPlanned = value;
    await _persist();
    notifyListeners();
    if (value) {
      for (final expense in _expenses.where((e) => e.isPlanned && !e.isPaid)) {
        unawaited(_reminderService.schedulePlannedReminder(expense));
      }
    } else {
      await _reminderService.cancelAllPlannedReminders(
        _expenses.map((e) => e.id),
      );
    }
  }

  List<PersonSummary> summaries({bool includePlanned = false}) {
    final Map<String, List<Expense>> grouped = groupBy<Expense, String>(
      _expenses.where((expense) {
        if (expense.isPaid) return false;
        if (!includePlanned && expense.isPlanned) return false;
        return true;
      }),
      (expense) => expense.personId,
    );

    return _persons.map((person) {
      final personExpenses = grouped[person.id] ?? [];
      final unpaidTotal = personExpenses.fold<int>(0, (prev, e) => prev + e.amount);
      final plannedCount = _expenses
          .where((expense) => expense.personId == person.id && expense.isPlanned && !expense.isPaid)
          .length;
      return PersonSummary(
        person: person,
        unpaidTotal: unpaidTotal,
        plannedCount: plannedCount,
      );
    }).toList();
  }

  List<Expense> filteredExpenses({
    String? personId,
    DateTimeRange? range,
    ExpenseStatusFilter status = ExpenseStatusFilter.both,
    ExpenseSortType sortType = ExpenseSortType.dateDesc,
    String keyword = '',
  }) {
    Iterable<Expense> data = _expenses.where((expense) => !expense.isPaid);

    if (personId != null) {
      data = data.where((expense) => expense.personId == personId);
    }

    if (range != null) {
      data = data.where((expense) {
        final dateOnly = DateTime(expense.date.year, expense.date.month, expense.date.day);
        return !dateOnly.isBefore(range.start) && !dateOnly.isAfter(range.end);
      });
    }

    switch (status) {
      case ExpenseStatusFilter.normal:
        data = data.where((expense) => !expense.isPlanned);
        break;
      case ExpenseStatusFilter.planned:
        data = data.where((expense) => expense.isPlanned);
        break;
      case ExpenseStatusFilter.both:
        break;
    }

    if (keyword.isNotEmpty) {
      data = data.where((expense) =>
          (expense.memo ?? '').toLowerCase().contains(keyword.toLowerCase()));
    }

    final List<Expense> result = data.toList();
    result.sort((a, b) {
      switch (sortType) {
        case ExpenseSortType.dateDesc:
          return b.date.compareTo(a.date);
        case ExpenseSortType.dateAsc:
          return a.date.compareTo(b.date);
        case ExpenseSortType.amountDesc:
          return b.amount.compareTo(a.amount);
        case ExpenseSortType.amountAsc:
          return a.amount.compareTo(b.amount);
      }
    });
    return result;
  }

  int totalUnpaidAmount({bool includePlanned = true}) {
    return _expenses.where((expense) {
      if (expense.isPaid) return false;
      if (!includePlanned && expense.isPlanned) return false;
      return true;
    }).fold<int>(0, (prev, e) => prev + e.amount);
  }

  Future<String> saveImage(XFile file) {
    return _imageStorageService.saveImage(file);
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
