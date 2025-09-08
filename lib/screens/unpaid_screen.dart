import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class UnpaidScreen extends StatelessWidget {
  const UnpaidScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final unpaid = provider.unpaidExpenses();
    return Scaffold(
      appBar: AppBar(title: const Text('未払い一覧')),
      body: ListView.builder(
        itemCount: unpaid.length,
        itemBuilder: (context, i) {
          final e = unpaid[i];
          return ListTile(
            title: Text(
                '${DateFormat.Md().format(e.date)}｜${e.personIcon}${e.person}｜${e.category}｜${e.amount}円'),
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
