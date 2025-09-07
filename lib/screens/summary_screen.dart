import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final month = DateTime.now();
    final summary = provider.monthlySummary(month);
    return Scaffold(
      appBar: AppBar(title: const Text('サマリー')),
      body: ListView(
        children: summary.entries
            .map(
              (e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value}円'),
              ),
            )
            .toList(),
      ),
    );
  }
}
