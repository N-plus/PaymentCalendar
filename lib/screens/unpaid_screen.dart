import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/person.dart';
import '../providers/expense_provider.dart';
import '../widgets/person_avatar.dart';
import 'expense_input_screen.dart';
import 'expense_detail_screen.dart';

enum PeriodFilter { thisMonth, lastMonth, custom }

class UnpaidListScreen extends StatefulWidget {
  const UnpaidListScreen({
    super.key,
    this.initialPersonId,
    this.initialStatus,
  });

  final String? initialPersonId;
  final ExpenseStatusFilter? initialStatus;

  @override
  State<UnpaidListScreen> createState() => _UnpaidListScreenState();
}

class _UnpaidListScreenState extends State<UnpaidListScreen> {
  String? _selectedPersonId;
  PeriodFilter _periodFilter = PeriodFilter.thisMonth;
  DateTimeRange? _selectedRange;
  ExpenseStatusFilter _statusFilter = ExpenseStatusFilter.both;
  ExpenseSortType _sortType = ExpenseSortType.dateDesc;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _selectedPersonId = widget.initialPersonId;
    _statusFilter = widget.initialStatus ?? ExpenseStatusFilter.both;
    _applyPeriod(_periodFilter);
  }

  Future<void> _applyPeriod(PeriodFilter filter) async {
    final now = DateTime.now();
    if (filter == PeriodFilter.thisMonth) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      setState(() {
        _periodFilter = filter;
        _selectedRange = DateTimeRange(start: start, end: end);
      });
    } else if (filter == PeriodFilter.lastMonth) {
      final prev = DateTime(now.year, now.month - 1, 1);
      final start = DateTime(prev.year, prev.month, 1);
      final end = DateTime(prev.year, prev.month + 1, 0);
      setState(() {
        _periodFilter = filter;
        _selectedRange = DateTimeRange(start: start, end: end);
      });
    } else {
      setState(() {
        _periodFilter = filter;
      });
      final picked = await _pickCustomRange();
      if (picked != null) {
        setState(() {
          _selectedRange = DateTimeRange(
            start: DateTime(picked.start.year, picked.start.month, picked.start.day),
            end: DateTime(picked.end.year, picked.end.month, picked.end.day),
          );
        });
      } else {
        setState(() {
          _periodFilter = PeriodFilter.thisMonth;
        });
        await _applyPeriod(PeriodFilter.thisMonth);
      }
    }
  }

  Future<DateTimeRange?> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedRange,
      locale: const Locale('ja'),
    );
    return picked;
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: _keyword);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('検索'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'メモで検索'),
            autofocus: true,
            onSubmitted: (_) {
              setState(() => _keyword = controller.text.trim());
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                setState(() => _keyword = '');
                Navigator.of(context).pop();
              },
              child: const Text('クリア'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _keyword = controller.text.trim());
                Navigator.of(context).pop();
              },
              child: const Text('検索'),
            ),
          ],
        );
      },
    );
  }

  void _changeSort(ExpenseSortType sortType) {
    setState(() {
      _sortType = sortType;
    });
  }

  Future<void> _confirmDelete(Expense expense) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: const Text('この記録を削除しますか？'),
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
    if (result == true) {
      await context.read<ExpenseProvider>().deleteExpense(expense.id);
    }
  }

  void _openDetail(Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(expenseId: expense.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.filteredExpenses(
      personId: _selectedPersonId,
      range: _selectedRange,
      status: _statusFilter,
      sortType: _sortType,
      keyword: _keyword,
    );
    final total = expenses.fold<int>(0, (prev, e) => prev + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('未払い一覧'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<ExpenseSortType>(
            icon: const Icon(Icons.sort),
            initialValue: _sortType,
            onSelected: _changeSort,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ExpenseSortType.dateDesc,
                child: Text('日付 降順'),
              ),
              PopupMenuItem(
                value: ExpenseSortType.dateAsc,
                child: Text('日付 昇順'),
              ),
              PopupMenuItem(
                value: ExpenseSortType.amountDesc,
                child: Text('金額 高い順'),
              ),
              PopupMenuItem(
                value: ExpenseSortType.amountAsc,
                child: Text('金額 低い順'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterSection(
            provider: provider,
            selectedPersonId: _selectedPersonId,
            onPersonChanged: (value) => setState(() => _selectedPersonId = value),
            periodFilter: _periodFilter,
            onPeriodChanged: _applyPeriod,
            statusFilter: _statusFilter,
            onStatusChanged: (value) => setState(() => _statusFilter = value),
            selectedRange: _selectedRange,
          ),
          const Divider(height: 1),
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text('未払いの記録はありません。'))
                : ListView.separated(
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final person = provider.getPerson(expense.personId);
                      return _ExpenseTile(
                        expense: expense,
                        person: person,
                        onChecked: () => provider.markAsPaid(expense.id),
                        onTap: () => _openDetail(expense),
                        onEdit: () => showExpenseEditor(context, expense: expense),
                        onDelete: () => _confirmDelete(expense),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('未払い合計'),
                Text(NumberFormat.currency(locale: 'ja_JP', symbol: '¥').format(total)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showExpenseEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.provider,
    required this.selectedPersonId,
    required this.onPersonChanged,
    required this.periodFilter,
    required this.onPeriodChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.selectedRange,
  });

  final ExpenseProvider provider;
  final String? selectedPersonId;
  final ValueChanged<String?> onPersonChanged;
  final PeriodFilter periodFilter;
  final Future<void> Function(PeriodFilter) onPeriodChanged;
  final ExpenseStatusFilter statusFilter;
  final ValueChanged<ExpenseStatusFilter> onStatusChanged;
  final DateTimeRange? selectedRange;

  @override
  Widget build(BuildContext context) {
    final periodText = <PeriodFilter, String>{
      PeriodFilter.thisMonth: '今月',
      PeriodFilter.lastMonth: '先月',
      PeriodFilter.custom: 'カスタム',
    };
    final statusText = <ExpenseStatusFilter, String>{
      ExpenseStatusFilter.both: 'すべて',
      ExpenseStatusFilter.normal: '通常',
      ExpenseStatusFilter.planned: '予定',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: selectedPersonId,
                  decoration: const InputDecoration(labelText: '人'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全員')),
                    ...provider.persons.map(
                      (person) => DropdownMenuItem(
                        value: person.id,
                        child: Text(person.name),
                      ),
                    ),
                  ],
                  onChanged: onPersonChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<ExpenseStatusFilter>(
                  value: statusFilter,
                  decoration: const InputDecoration(labelText: '区分'),
                  items: statusText.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onStatusChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: periodText.entries.map((entry) {
              final selected = entry.key == periodFilter;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => onPeriodChanged(entry.key),
              );
            }).toList(),
          ),
          if (periodFilter == PeriodFilter.custom && selectedRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${DateFormat('yyyy/MM/dd').format(selectedRange!.start)} - ${DateFormat('yyyy/MM/dd').format(selectedRange!.end)}',
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.person,
    required this.onChecked,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final Person person;
  final VoidCallback onChecked;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
    final dateText = DateFormat('M/d (E)', 'ja_JP').format(expense.date);

    return Slidable(
      key: ValueKey(expense.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            icon: Icons.edit,
            label: '編集',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            icon: Icons.delete,
            label: '削除',
            backgroundColor: Colors.redAccent,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: false,
                onChanged: (_) => onChecked(),
              ),
              const SizedBox(width: 8),
              PersonAvatar(person: person, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.memo?.isNotEmpty == true ? expense.memo! : 'メモなし',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(person.name),
                        Text(dateText),
                        if (expense.isPlanned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('予定'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                formatter.format(expense.amount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
