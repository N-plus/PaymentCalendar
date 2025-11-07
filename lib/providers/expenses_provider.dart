import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_check/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return ExpensesNotifier(preferences);
});

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier(this._preferences) : super(const []) {
    _initialization = _restoreInitialExpenses();
  }

  static const _placeholderExpenses = [
    _PlaceholderExpenseSignature(
      payerId: 'mother',
      payeeId: 'father',
      amount: 1560,
      memo: 'スーパーでの買い物',
    ),
    _PlaceholderExpenseSignature(
      payerId: 'father',
      payeeId: 'mother',
      amount: 780,
      memo: '電車代',
    ),
    _PlaceholderExpenseSignature(
      payerId: 'mother',
      payeeId: 'child',
      amount: 2400,
      memo: '子どもの服',
    ),
    _PlaceholderExpenseSignature(
      payerId: 'mother',
      payeeId: 'mother',
      amount: 4200,
      memo: '美容院（予約）',
    ),
  ];

  static List<Expense> _seedExpenses() {
    const uuid = Uuid();
    final now = DateUtils.dateOnly(DateTime.now());
    return [
      Expense.newRecord(
        id: uuid.v4(),
        payerId: 'mother',
        payeeId: 'father',
        date: now.subtract(const Duration(days: 2)),
        amount: 1560,
        memo: 'スーパーでの買い物',
        category: ExpenseCategory.fallback,
      ),
      Expense.newRecord(
        id: uuid.v4(),
        payerId: 'father',
        payeeId: 'mother',
        date: now.subtract(const Duration(days: 1)),
        amount: 780,
        memo: '電車代',
        category: ExpenseCategory.fallback,
      ),
      Expense.newRecord(
        id: uuid.v4(),
        payerId: 'mother',
        payeeId: 'child',
        date: now,
        amount: 2400,
        memo: '子どもの服',
        category: ExpenseCategory.fallback,
      ),
      Expense.newRecord(
        id: uuid.v4(),
        payerId: 'mother',
        payeeId: 'mother',
        date: now.add(const Duration(days: 3)),
        amount: 4200,
        memo: '美容院（予約）',
        category: ExpenseCategory.fallback,
      ),
      Expense(
        id: uuid.v4(),
        payerId: 'father',
        payeeId: 'mother',
        date: now.subtract(const Duration(days: 7)),
        amount: 3200,
        memo: 'ガソリン代',
        status: ExpenseStatus.paid,
        category: ExpenseCategory.fallback,
        paidAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  final _uuid = const Uuid();
  static const _storageKey = 'expenses_data';
  final SharedPreferences _preferences;
  late final Future<void> _initialization;

  Future<void> _restoreInitialExpenses() async {
    final jsonString = _preferences.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      final seeded = _seedExpenses();
      state = seeded;
      await _saveExpenses();
      return;
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      state = [
        for (final dynamic item in decoded)
          Expense.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      final seeded = _seedExpenses();
      state = seeded;
      await _saveExpenses();
    }
  }

  Future<void> ensureInitialized() => _initialization;

  Future<void> _saveExpenses() async {
    final encoded = jsonEncode([
      for (final expense in state) expense.toJson(),
    ]);
    await _preferences.setString(_storageKey, encoded);
  }

  void removePlaceholderUnpaidExpenses() {
    if (state.isEmpty) {
      return;
    }
    final filtered = state.where((expense) {
      if (expense.isPaid) {
        return true;
      }
      for (final signature in _placeholderExpenses) {
        if (signature.matches(expense)) {
          return false;
        }
      }
      return true;
    }).toList();
    if (filtered.length != state.length) {
      state = filtered;
      unawaited(_saveExpenses());
    }
  }

  void addExpense({
    required String payerId,
    required String payeeId,
    required DateTime date,
    required int amount,
    String memo = '',
    String? category,
    List<String> photoPaths = const [],
  }) {
    final expense = Expense.newRecord(
      id: _uuid.v4(),
      payerId: payerId,
      payeeId: payeeId,
      date: date,
      amount: amount,
      memo: memo,
      category: category,
      photoPaths: photoPaths,
    );
    state = [...state, expense];
    unawaited(_saveExpenses());
  }

  void saveExpense(Expense expense) {
    final exists = state.any((element) => element.id == expense.id);
    if (exists) {
      updateExpense(expense);
    } else {
      state = [...state, expense];
      unawaited(_saveExpenses());
    }
  }

  void updateExpense(Expense expense) {
    state = [
      for (final e in state)
        if (e.id == expense.id) expense.adjustStatus() else e,
    ];
    unawaited(_saveExpenses());
  }

  void deleteExpense(String id) {
    state = state.where((e) => e.id != id).toList();
    unawaited(_saveExpenses());
  }

  void markAsPaid(String id) {
    state = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(status: ExpenseStatus.paid, paidAt: DateTime.now())
        else
          e,
    ];
    unawaited(_saveExpenses());
  }

  void markAsUnpaid(String id) {
    state = [
      for (final e in state)
        if (e.id == id) e.adjustStatus(paid: false) else e,
    ];
    unawaited(_saveExpenses());
  }

  void changeDate(String id, DateTime date) {
    state = [
      for (final e in state)
        if (e.id == id) e.adjustStatus(date: date) else e,
    ];
    unawaited(_saveExpenses());
  }

  void replaceCategory(String from, String to) {
    if (from == to) {
      return;
    }
    state = [
      for (final e in state)
        if (e.category == from) e.copyWith(category: to) else e,
    ];
    unawaited(_saveExpenses());
  }

  List<Expense> markPaidForPair(
    String payerId,
    String payeeId, {
    required bool includePlanned,
  }) {
    final now = DateTime.now();
    final updated = <Expense>[];
    state = [
      for (final e in state)
        if (e.payerId == payerId &&
            e.payeeId == payeeId &&
            (e.status == ExpenseStatus.unpaid ||
                (includePlanned && e.status == ExpenseStatus.planned)))
          () {
            updated.add(e);
            return e.copyWith(status: ExpenseStatus.paid, paidAt: now);
          }()
        else
          e,
    ];
    unawaited(_saveExpenses());
    return updated;
  }

  void restoreMany(List<Expense> original) {
    if (original.isEmpty) {
      return;
    }
    final replacements = {for (final item in original) item.id: item};
    final updated = <Expense>[];
    for (final expense in state) {
      final replacement = replacements[expense.id];
      updated.add(replacement ?? expense);
    }
    for (final item in original) {
      if (updated.every((element) => element.id != item.id)) {
        updated.add(item);
      }
    }
    state = updated;
    unawaited(_saveExpenses());
  }
}

class _PlaceholderExpenseSignature {
  const _PlaceholderExpenseSignature({
    required this.payerId,
    required this.payeeId,
    required this.amount,
    required this.memo,
  });

  final String payerId;
  final String payeeId;
  final int amount;
  final String memo;

  bool matches(Expense expense) {
    return expense.payerId == payerId &&
        expense.payeeId == payeeId &&
        expense.amount == amount &&
        expense.memo == memo;
  }
}
