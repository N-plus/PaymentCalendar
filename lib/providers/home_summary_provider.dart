import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../models/person.dart';
import '../models/person_summary.dart';
import 'expenses_provider.dart';
import 'people_provider.dart';

final includePlannedInSummaryProvider = StateProvider<bool>((ref) => false);

final homeSummariesProvider = Provider<List<PersonSummary>>((ref) {
  final people = ref.watch(peopleProvider);
  final peopleMap = {for (final person in people) person.id: person};
  final expenses = ref.watch(expensesProvider);
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
    for (final entry in grouped.values)
      if (entry.unpaidAmount > 0)
        PersonSummary(
          payer: entry.payer,
          payee: entry.payee,
          unpaidAmount: entry.unpaidAmount,
          unpaidCount: entry.unpaidCount,
          plannedAmount: entry.plannedAmount,
          plannedCount: entry.plannedCount,
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
