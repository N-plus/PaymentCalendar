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
import '../models/person.dart';
import '../models/person_summary.dart';
import 'expenses_provider.dart';
import 'people_provider.dart';

final includePlannedInSummaryProvider = StateProvider<bool>((ref) => false);

final homeSummariesProvider = Provider<List<PersonSummary>>((ref) {
  final people = ref.watch(peopleProvider);
  final expenses = ref.watch(expensesProvider);
  return [
    for (final person in people)
      _buildSummary(person: person, expenses: expenses),
  ];
});

PersonSummary _buildSummary(
    {required Person person, required List<Expense> expenses}) {
  final personExpenses =
      expenses.where((expense) => expense.personId == person.id);
  var unpaidAmount = 0;
  var plannedAmount = 0;
  var unpaidCount = 0;
  var plannedCount = 0;
  for (final expense in personExpenses) {
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
  return PersonSummary(
    person: person,
    unpaidAmount: unpaidAmount,
    unpaidCount: unpaidCount,
    plannedAmount: plannedAmount,
    plannedCount: plannedCount,
  );
}
