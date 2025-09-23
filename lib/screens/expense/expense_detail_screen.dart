import 'dart:io';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense.dart';
import '../../models/person.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/people_provider.dart';
import '../../utils/format.dart';
import 'expense_form_sheet.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    Expense? expense;
    for (final item in expenses) {
      if (item.id == expenseId) {
        expense = item;
        break;
      }
    }
    if (expense == null) {
      return const Scaffold(
        body: Center(child: Text('明細が見つかりませんでした')),
      );
    }
    final people = ref.watch(peopleProvider);
    Person? person;
    for (final p in people) {
      if (p.id == expense.personId) {
        person = p;
        break;
      }
    }
    if (person == null) {
      return const Scaffold(
        body: Center(child: Text('人の情報が見つかりませんでした')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('明細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openEditor(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(
                  person.emoji ??
                      (person.name.characters.isNotEmpty
                          ? person.name.characters.first
                          : '?'),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _StatusChip(status: expense.status),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(label: '日付', value: formatDate(expense.date)),
          _DetailRow(label: '金額', value: formatCurrency(expense.amount)),
          if (expense.memo.isNotEmpty)
            _DetailRow(label: 'メモ', value: expense.memo),
          if (expense.paidAt != null)
            _DetailRow(
              label: '支払日',
              value: formatDate(expense.paidAt!),
            ),
          const SizedBox(height: 16),
          if (expense.photoPaths.isNotEmpty) ...[
            Text(
              '添付写真',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: expense.photoPaths.length,
              itemBuilder: (context, index) {
                final path = expense.photoPaths[index];
                return GestureDetector(
                  onTap: () => _openPhoto(context, path),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImage(path),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (expense.status != ExpenseStatus.paid)
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(expensesProvider.notifier).markAsPaid(expense.id);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(expense.status == ExpenseStatus.planned
                      ? '今日支払った'
                      : '支払い済みにする'),
                ),
              if (expense.status == ExpenseStatus.planned)
                OutlinedButton.icon(
                  onPressed: () => _changeDueDate(context, ref),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('期日変更'),
                ),
              if (expense.status == ExpenseStatus.paid)
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(expensesProvider.notifier).markAsUnpaid(expense.id);
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('未払いに戻す'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExpenseFormSheet(expenseId: expenseId),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除'),
        content: const Text('この明細を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(expensesProvider.notifier).deleteExpense(expenseId);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _changeDueDate(BuildContext context, WidgetRef ref) async {
    final expense =
        ref.read(expensesProvider).firstWhere((e) => e.id == expenseId);
    final picked = await showDatePicker(
      context: context,
      initialDate: expense.date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(expensesProvider.notifier).changeDate(expenseId, picked);
}

  Widget _buildImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image),
      );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
    );
  }
}

  void _openPhoto(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(path: path),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case ExpenseStatus.unpaid:
        color = Colors.redAccent;
        label = '未払い';
        break;
      case ExpenseStatus.planned:
        color = Colors.deepPurple;
        label = '予定';
        break;
      case ExpenseStatus.paid:
        color = Colors.green;
        label = '支払い済み';
        break;
    }
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.15),
      side: BorderSide(color: color.withOpacity(0.4)),
      labelStyle: TextStyle(color: color.darken()),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
