import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../models/person.dart';
import '../models/person_summary.dart';
import '../utils/date_util.dart';
import 'expenses_provider.dart';
import 'people_provider.dart';

List<Expense> visibleExpenses(
  List<Expense> all, {
  required bool includePlanned,
}) {
  if (includePlanned) {
    return List<Expense>.unmodifiable(all);
  }
  return List<Expense>.unmodifiable(
    all.where((expense) => !isFutureDate(expense.date)).toList(),
  );
}

List<Expense> _unpaidSource(
  List<Expense> all, {
  required bool includePlanned,
}) {
  final unpaid = all.where((expense) {
    if (expense.status == ExpenseStatus.unpaid) {
      return true;
    }
    if (!includePlanned) {
      return false;
    }
    return expense.status == ExpenseStatus.planned;
  }).toList();
  return visibleExpenses(unpaid, includePlanned: includePlanned);
}

class DebtEdge {
  DebtEdge(this.payerId, this.payeeId, this.amount);

  final String payerId;
  final String payeeId;
  final double amount;
}

List<DebtEdge> buildDebtEdges(List<Expense> expenses) {
  final map = <(String, String), double>{};
  for (final expense in expenses) {
    final key = (expense.payerId, expense.payeeId);
    map[key] = (map[key] ?? 0) + expense.amount.toDouble();
  }
  return [
    for (final entry in map.entries)
      DebtEdge(entry.key.$1, entry.key.$2, entry.value),
  ];
}

final includePlannedInSummaryProvider = StateProvider<bool>((ref) => false);

final visibleDebtExpensesProvider = Provider<List<Expense>>((ref) {
  final all = ref.watch(expensesProvider);
  final includePlanned = ref.watch(includePlannedInSummaryProvider);
  return _unpaidSource(all, includePlanned: includePlanned);
});

final debtEdgesProvider = Provider<List<DebtEdge>>((ref) {
  final expenses = ref.watch(visibleDebtExpensesProvider);
  return buildDebtEdges(expenses);
});

final homeSummariesProvider = Provider<List<PersonSummary>>((ref) {
  final people = ref.watch(peopleProvider);
  final includePlanned = ref.watch(includePlannedInSummaryProvider);
  final peopleMap = {for (final person in people) person.id: person};
  final expenses = ref.watch(visibleDebtExpensesProvider);
  final grouped = <String, _SummaryAccumulator>{};
  for (final expense in expenses) {
    final payer = peopleMap[expense.payerId];
    final payee = peopleMap[expense.payeeId];
    if (payer == null || payee == null) {
      continue;
    }
    final key = '${expense.payerId}__${expense.payeeId}';
    final accumulator =
        grouped.putIfAbsent(key, () => _SummaryAccumulator(payer, payee));
    accumulator.add(expense);
  }

  final summaries = [
    for (final accumulator in grouped.values)
      if (_hasVisibleEntries(accumulator, includePlanned))
        PersonSummary(
          payer: accumulator.payer,
          payee: accumulator.payee,
          unpaidAmount: accumulator.unpaidAmount,
          unpaidCount: accumulator.unpaidCount,
          plannedAmount: accumulator.plannedAmount,
          plannedCount: accumulator.plannedCount,
        ),
  ]
    ..sort((a, b) {
      final payeeCompare = a.payee.name.compareTo(b.payee.name);
      if (payeeCompare != 0) {
        return payeeCompare;
      }
      return a.payer.name.compareTo(b.payer.name);
    });

  return summaries;
});

bool _hasVisibleEntries(_SummaryAccumulator accumulator, bool includePlanned) {
  if (accumulator.unpaidCount > 0) {
    return true;
  }
  if (includePlanned && accumulator.plannedCount > 0) {
    return true;
  }
  return false;
}

class _SummaryAccumulator {
  _SummaryAccumulator(this.payer, this.payee);

  final Person payer;
  final Person payee;
  var unpaidAmount = 0;
  var unpaidCount = 0;
  var plannedAmount = 0;
  var plannedCount = 0;

  void add(Expense expense) {
    switch (expense.status) {
      case ExpenseStatus.unpaid:
        unpaidAmount += expense.amount;
        unpaidCount += 1;
        break;
      case ExpenseStatus.planned:
        plannedAmount += expense.amount;
        plannedCount += 1;
        break;
      case ExpenseStatus.paid:
        break;
    }
  }
}
