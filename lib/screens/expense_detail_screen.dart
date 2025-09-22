import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/person_avatar.dart';
import 'expense_input_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final expense = provider.expenses.firstWhereOrNull(
          (element) => element.id == expenseId,
        );
        if (expense == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('詳細')),
            body: const Center(child: Text('記録が見つかりませんでした。')),
          );
        }
        final person = provider.getPerson(expense.personId);
        final formatter = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
        final dateText = DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(expense.date);
        final statusText = expense.isPaid
            ? '支払い済み'
            : expense.isPlanned
                ? '予定'
                : '未払い';
        final statusColor = expense.isPaid
            ? Colors.green
            : expense.isPlanned
                ? Colors.orange
                : Theme.of(context).colorScheme.primary;

        return Scaffold(
          appBar: AppBar(
            title: const Text('記録詳細'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => showExpenseEditor(context, expense: expense),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('削除しますか？'),
                        content: const Text('この記録を削除すると元に戻せません。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('キャンセル'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('削除'),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    await provider.deleteExpense(expense.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  PersonAvatar(person: person, size: 60),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                formatter.format(expense.amount),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(dateText),
              if (expense.paidAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('支払い日: ${DateFormat('yyyy/M/d (E)', 'ja_JP').format(expense.paidAt!)}'),
                ),
              const SizedBox(height: 16),
              if (expense.memo?.isNotEmpty == true)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('メモ', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(expense.memo!),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              if (expense.photoUris.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('レシート', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: expense.photoUris.length,
                        controller: PageController(viewportFraction: 0.85),
                        itemBuilder: (context, index) {
                          final uri = expense.photoUris[index];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _PhotoViewer(imagePath: uri),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(uri),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              if (!expense.isPaid)
                SwitchListTile.adaptive(
                  value: expense.isPlanned,
                  onChanged: (value) async {
                    await provider.updatePlannedStatus(expense.id, value);
                  },
                  title: const Text('予定として扱う'),
                ),
              const SizedBox(height: 12),
              if (!expense.isPaid)
                FilledButton.icon(
                  onPressed: () async {
                    await provider.markAsPaid(expense.id);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(expense.isPlanned ? '今日支払った' : '支払い済みにする'),
                ),
              if (!expense.isPaid && expense.isPlanned)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expense.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        locale: const Locale('ja'),
                      );
                      if (picked != null) {
                        await provider.changeExpenseDate(expense.id, picked);
                      }
                    },
                    icon: const Icon(Icons.event),
                    label: const Text('期日を変更'),
                  ),
                ),
              if (expense.isPaid)
                FilledButton.icon(
                  onPressed: () async {
                    await provider.markAsUnpaid(expense.id);
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('未払いに戻す'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}
