import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('カテゴリ'),
            subtitle: Wrap(
              spacing: 8,
              children: provider.categories
                  .map((c) => Chip(label: Text(c)))
                  .toList(),
            ),
          ),
          ListTile(
            title: const Text('メンバー'),
            subtitle: Wrap(
              spacing: 8,
              children: provider.members
                  .map((m) => Chip(label: Text('${m.icon} ${m.name}')))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
