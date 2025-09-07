import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({Key? key, required this.day}) : super(key: key);

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.expensesOn(day);
    return Scaffold(
      appBar: AppBar(title: Text(DateFormat.yMd().format(day))),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, i) {
          final e = expenses[i];
          return ListTile(
            title: Text('${e.amount}円｜${e.category}｜${e.person}'),
            trailing: Checkbox(
              value: e.isPaid,
              onChanged: (_) => provider.togglePaid(e),
            ),
          );
        },
      ),
    );
  }
}
