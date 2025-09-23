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
import 'package:uuid/uuid.dart';

import '../models/expense.dart';

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<Expense>>((ref) {
  return ExpensesNotifier();
});

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  ExpensesNotifier() : super(_seedExpenses());

  static List<Expense> _seedExpenses() {
    final uuid = const Uuid();
    final now = DateUtils.dateOnly(DateTime.now());
    return [
      Expense.newRecord(
        id: uuid.v4(),
        personId: 'mother',
        date: now.subtract(const Duration(days: 2)),
        amount: 1560,
        memo: 'スーパーでの買い物',
      ),
      Expense.newRecord(
        id: uuid.v4(),
        personId: 'father',
        date: now.subtract(const Duration(days: 1)),
        amount: 780,
        memo: '電車代',
      ),
      Expense.newRecord(
        id: uuid.v4(),
        personId: 'pet',
        date: now,
        amount: 2400,
        memo: 'キャットフードまとめ買い',
      ),
      Expense.newRecord(
        id: uuid.v4(),
        personId: 'mother',
        date: now.add(const Duration(days: 3)),
        amount: 4200,
        memo: '美容院（予約）',
      ),
      Expense(
        id: uuid.v4(),
        personId: 'father',
        date: now.subtract(const Duration(days: 7)),
        amount: 3200,
        memo: 'ガソリン代',
        status: ExpenseStatus.paid,
        paidAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }

  final _uuid = const Uuid();

  void addExpense({
    required String personId,
    required DateTime date,
    required int amount,
    String memo = '',
    List<String> photoPaths = const [],
  }) {
    final expense = Expense.newRecord(
      id: _uuid.v4(),
      personId: personId,
      date: date,
      amount: amount,
      memo: memo,
      photoPaths: photoPaths,
    );
    state = [...state, expense];
  }

  void saveExpense(Expense expense) {
    final exists = state.any((element) => element.id == expense.id);
    if (exists) {
      updateExpense(expense);
    } else {
      state = [...state, expense];
    }
  }

  void updateExpense(Expense expense) {
    state = [
      for (final e in state)
        if (e.id == expense.id) expense.adjustStatus() else e,
    ];
  }

  void deleteExpense(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void markAsPaid(String id) {
    state = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(status: ExpenseStatus.paid, paidAt: DateTime.now())
        else
          e,
    ];
  }

  void markAsUnpaid(String id) {
    state = [
      for (final e in state)
        if (e.id == id) e.adjustStatus(paid: false) else e,
    ];
  }

  void changeDate(String id, DateTime date) {
    state = [
      for (final e in state)
        if (e.id == id) e.adjustStatus(date: date) else e,
    ];
  }

  List<Expense> markPaidForPerson(
    String personId, {
    required bool includePlanned,
  }) {
    final now = DateTime.now();
    final updated = <Expense>[];
    state = [
      for (final e in state)
        if (e.personId == personId &&
            (e.status == ExpenseStatus.unpaid ||
                (includePlanned && e.status == ExpenseStatus.planned)))
          () {
            updated.add(e);
            return e.copyWith(status: ExpenseStatus.paid, paidAt: now);
          }()
        else
          e,
    ];
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
  }
}
