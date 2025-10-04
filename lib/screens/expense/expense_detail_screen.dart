import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense.dart';
import '../../models/person.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/people_provider.dart';
import '../../utils/color_utils.dart';
import '../../utils/date_util.dart';
import '../../widgets/person_avatar.dart';
import 'expense_form_sheet.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final matchingExpenses = expenses.where((item) => item.id == expenseId);
    if (matchingExpenses.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('明細が見つかりませんでした')),
      );
    }
    final expense = matchingExpenses.first;

    final people = ref.watch(peopleProvider);
    final matchingPeople = people.where((person) => person.id == expense.personId);
    if (matchingPeople.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('人の情報が見つかりませんでした')),
      );
    }
    final person = matchingPeople.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPersonInfo(context, person, expense),
            _StatusChip(status: expense.status),
            _buildDetailInfo(context, expense),
            _buildPhotoSection(context, expense),
            _buildActionButtons(context, ref, expense),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonInfo(BuildContext context, Person person, Expense expense) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildAvatar(person),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  formatCurrency(expense.amount),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Person person) {
    const double size = 56;
    return PersonAvatar(
      person: person,
      size: size,
      backgroundColor: kPersonAvatarBackgroundColor,
      textStyle: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailInfo(BuildContext context, Expense expense) {
    final rows = <Widget>[
      _InfoRow(label: '日付', value: formatDate(expense.date)),
      _InfoRow(label: '金額', value: formatCurrency(expense.amount)),
    ];

    if (expense.memo.isNotEmpty) {
      rows.addAll([
        const SizedBox(height: 12),
        _InfoRow(label: 'メモ', value: expense.memo),
      ]);
    }

    if (expense.paidAt != null) {
      rows.addAll([
        const SizedBox(height: 12),
        _InfoRow(
          label: '支払い日時',
          value: formatDateTime(expense.paidAt!),
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context, Expense expense) {
    if (expense.photoPaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '添付写真',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in expense.photoPaths.asMap().entries)
                    GestureDetector(
                      onTap: () => _openPhotoViewer(
                        context,
                        expense.photoPaths,
                        entry.key,
                      ),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildImage(entry.value),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Expense expense) {
    final isPaid = expense.status == ExpenseStatus.paid;
    final isPlanned = expense.status == ExpenseStatus.planned;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isPaid) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markAsPaid(context, ref, expense),
                icon: const Icon(Icons.payment),
                label: Text(isPlanned ? '今日支払った' : '支払い済みにする'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (isPlanned)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _changeDueDate(context, ref, expense),
                  icon: const Icon(Icons.date_range),
                  label: const Text('期日変更'),
                ),
              ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _revertToPending(context, ref, expense),
                icon: const Icon(Icons.undo),
                label: const Text('未払いに戻す'),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.edit, color: Colors.black),
                  label: const Text('編集'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteExpense(context, ref),
                  icon: const Icon(Icons.delete),
                  label: const Text('削除'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('支払い確認'),
        content: Text('${formatCurrency(expense.amount)}を今日支払い済みにしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('支払い済み'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(expensesProvider.notifier).markAsPaid(expense.id);
      if (!messenger.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('支払い済みにしました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _changeDueDate(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: expense.date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != expense.date) {
      ref.read(expensesProvider.notifier).changeDate(expense.id, picked);
      if (!messenger.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('期日を変更しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _revertToPending(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('支払い状態を変更'),
        content: const Text('この明細を未払いに戻しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('未払いに戻す'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(expensesProvider.notifier).markAsUnpaid(expense.id);
      if (!messenger.mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('未払いに戻しました'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この明細を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(expensesProvider.notifier).deleteExpense(expenseId);
      if (!navigator.mounted) {
        return;
      }
      navigator.pop();
    }
  }

  void _openEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExpenseFormSheet(expenseId: expenseId),
    );
  }

  void _openPhotoViewer(
    BuildContext context,
    List<String> photoPaths,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
          photoPaths: photoPaths,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.grey.shade600);
    final valueStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: labelStyle),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case ExpenseStatus.unpaid:
        color = const Color(0xFFFF0033);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: color.darken(),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color.withOpacityValue(0.12),
        side: BorderSide(color: color.withOpacityValue(0.3)),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photoPaths, required this.initialIndex});

  final List<String> photoPaths;
  final int initialIndex;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photoPaths.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photoPaths.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final path = widget.photoPaths[index];
          final file = File(path);

          if (!file.existsSync()) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    '画像を読み込めませんでした',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          return InteractiveViewer(
            maxScale: 3,
            child: Center(
              child: Image.file(
                file,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
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
