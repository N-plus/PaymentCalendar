import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];

  final List<Member> members = [
    Member(name: '母', icon: '👩'),
    Member(name: '父', icon: '👨'),
    Member(name: 'キャラ', icon: '🐱'),
  ];

  final List<String> categories = ['食費', '交通費', '娯楽費'];

  List<Expense> get expenses => List.unmodifiable(_expenses);

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void togglePaid(Expense expense) {
    expense.isPaid = !expense.isPaid;
    notifyListeners();
  }

  List<Expense> expensesOn(DateTime day) =>
      _expenses.where((e) => isSameDay(e.date, day)).toList();

  Map<String, int> monthlySummary(DateTime month) {
    final Map<String, int> data = {
      for (final c in categories) c: 0,
    };
    for (final e in _expenses) {
      if (e.date.year == month.year && e.date.month == month.month) {
        data[e.category] = (data[e.category] ?? 0) + e.amount;
      }
    }
    return data;
  }

  List<Expense> unpaidExpenses() =>
      _expenses.where((e) => !e.isPaid).toList();
}
