import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

class ExpenseInputScreen extends StatefulWidget {
  const ExpenseInputScreen({Key? key, this.initialDate}) : super(key: key);

  final DateTime? initialDate;

  @override
  State<ExpenseInputScreen> createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends State<ExpenseInputScreen> {
  late DateTime _date;
  final _amountController = TextEditingController();
  String? _category;
  Member? _member;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    _category ??= provider.categories.first;
    _member ??= provider.members.first;
    return Scaffold(
      appBar: AppBar(title: const Text('支出入力')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
              title: const Text('日付'),
              subtitle: Text(DateFormat.yMd().format(_date)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
              ),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: '金額'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: _category,
              items: provider.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              decoration: const InputDecoration(labelText: '項目'),
            ),
            DropdownButtonFormField<Member>(
              value: _member,
              items: provider.members
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.icon} ${m.name}'),
                      ))
                  .toList(),
              onChanged: (m) => setState(() => _member = m),
              decoration: const InputDecoration(labelText: '使った人'),
            ),
            CheckboxListTile(
              title: const Text('支払い済み'),
              value: _isPaid,
              onChanged: (v) => setState(() => _isPaid = v ?? false),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(_amountController.text) ?? 0;
                if (amount > 0 && _category != null && _member != null) {
                  provider.addExpense(Expense(
                    date: _date,
                    amount: amount,
                    category: _category!,
                    person: '${_member!.icon}${_member!.name}',
                    isPaid: _isPaid,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            )
          ],
        ),
      ),
    );
  }
}
