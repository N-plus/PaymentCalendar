import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/person.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider();

  final List<Expense> _expenses = [];

  final List<Person> members = const [
    Person(id: 'mother', name: '母', emoji: '👩'),
    Person(id: 'father', name: '父', emoji: '👨'),
    Person(id: 'child', name: '子ども', emoji: '🧒'),
  ];

  List<Expense> get expenses => List.unmodifiable(_expenses);

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void removeExpense(Expense expense) {
    _expenses.removeWhere((element) => element.id == expense.id);
    notifyListeners();
  }

  void togglePaid(Expense expense) {
    final index = _expenses.indexWhere((element) => element.id == expense.id);
    if (index == -1) {
      return;
    }
    final current = _expenses[index];
    _expenses[index] = current.adjustStatus(paid: !current.isPaid);
    notifyListeners();
  }

  List<Expense> expensesOn(DateTime day) {
    return _expenses.where((expense) => _isSameDay(expense.date, day)).toList();
  }

  Map<String, int> monthlySummary(DateTime month) {
    final summary = <String, int>{
      for (final member in members) member.name: 0,
    };

    for (final expense in _expenses) {
      if (expense.date.year == month.year &&
          expense.date.month == month.month) {
        final memberName = _memberNameFor(expense.payeeId) ?? expense.payeeId;
        summary.update(
          memberName,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
    }

    return summary;
  }

  List<Expense> unpaidExpenses() {
    return _expenses.where((expense) => expense.isUnpaid).toList();
  }

  String? _memberNameFor(String personId) {
    for (final member in members) {
      if (member.id == personId) {
        return member.name;
      }
    }
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
