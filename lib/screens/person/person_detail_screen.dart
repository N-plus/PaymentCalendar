import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense.dart';
import '../../models/person.dart';
import '../../providers/expenses_provider.dart';
import '../../utils/format.dart';
import '../expense/expense_detail_screen.dart';

enum _PeriodFilter { thisMonth, lastMonth, custom }

enum _SortOption { dateDesc, dateAsc, amountDesc, amountAsc }

class PersonDetailScreen extends ConsumerStatefulWidget {
  const PersonDetailScreen({super.key, required this.person});

  final Person person;

  @override
  ConsumerState<PersonDetailScreen> createState() =>
      _PersonDetailScreenState();
}

class _PersonDetailScreenState
    extends ConsumerState<PersonDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _PeriodFilter _period = _PeriodFilter.thisMonth;
  DateTimeRange? _customRange;
  _SortOption _sort = _SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unpaidExpenses = _filteredExpenses(ExpenseStatus.unpaid);
    final plannedExpenses = _filteredExpenses(ExpenseStatus.planned);
    final paidExpenses = _filteredExpenses(ExpenseStatus.paid);
    final totals = {
      0: unpaidExpenses.fold<int>(0, (sum, e) => sum + e.amount),
      1: plannedExpenses.fold<int>(0, (sum, e) => sum + e.amount),
      2: paidExpenses.fold<int>(0, (sum, e) => sum + e.amount),
    };
    final currentTotal = totals[_tabController.index] ?? 0;
    final totalLabel = () {
      switch (_tabController.index) {
        case 0:
          return '未払い合計';
        case 1:
          return '予定合計';
        default:
          return '支払い済み合計';
      }
    }();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(widget.person.emoji ?? widget.person.name[0]),
            ),
            const SizedBox(width: 12),
            Text(widget.person.name),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$totalLabel: ${formatCurrency(currentTotal)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '未払い'),
              Tab(text: '予定'),
              Tab(text: '支払い済み'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _selectPeriod,
                  icon: const Icon(Icons.filter_list),
                  label: Text(_periodLabel()),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _selectSort,
                  icon: const Icon(Icons.sort),
                  label: Text(_sortLabel()),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ExpenseList(
                  expenses: unpaidExpenses,
                  onCheck: (expense) => _markAsPaid(expense),
                  onTap: _openDetail,
                ),
                _ExpenseList(
                  expenses: plannedExpenses,
                  showPlannedBadge: true,
                  onCheck: (expense) => _markAsPaid(expense),
                  onTap: _openDetail,
                ),
                _ExpenseList(
                  expenses: paidExpenses,
                  checked: true,
                  onUncheck: (expense) => _markAsUnpaid(expense),
                  onTap: _openDetail,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Text(
              '$totalLabel: ${formatCurrency(currentTotal)}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Expense> _filteredExpenses(ExpenseStatus status) {
    final expenses = ref.watch(expensesProvider);
    final filtered = expenses.where((expense) {
      if (expense.personId != widget.person.id) {
        return false;
      }
      if (expense.status != status) {
        return false;
      }
      return _isWithinPeriod(expense.date);
    }).toList();
    filtered.sort((a, b) {
      switch (_sort) {
        case _SortOption.dateDesc:
          return b.date.compareTo(a.date);
        case _SortOption.dateAsc:
          return a.date.compareTo(b.date);
        case _SortOption.amountDesc:
          return b.amount.compareTo(a.amount);
        case _SortOption.amountAsc:
          return a.amount.compareTo(b.amount);
      }
    });
    return filtered;
  }

  bool _isWithinPeriod(DateTime date) {
    final target = DateUtils.dateOnly(date);
    switch (_period) {
      case _PeriodFilter.thisMonth:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1).subtract(
          const Duration(days: 1),
        );
        return !target.isBefore(start) && !target.isAfter(end);
      case _PeriodFilter.lastMonth:
        final now = DateTime.now();
        final month = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(month.year, month.month, 1);
        final end = DateTime(month.year, month.month + 1, 1).subtract(
          const Duration(days: 1),
        );
        return !target.isBefore(start) && !target.isAfter(end);
      case _PeriodFilter.custom:
        final range = _customRange;
        if (range == null) {
          return true;
        }
        final start = DateUtils.dateOnly(range.start);
        final end = DateUtils.dateOnly(range.end);
        return !target.isBefore(start) && !target.isAfter(end);
    }
  }

  Future<void> _selectPeriod() async {
    final result = await showMenu<_PeriodFilter>(
      context: context,
      position: const RelativeRect.fromLTRB(16, 120, 16, 0),
      items: const [
        PopupMenuItem(
          value: _PeriodFilter.thisMonth,
          child: Text('今月'),
        ),
        PopupMenuItem(
          value: _PeriodFilter.lastMonth,
          child: Text('先月'),
        ),
        PopupMenuItem(
          value: _PeriodFilter.custom,
          child: Text('カスタム'),
        ),
      ],
    );
    if (result == null) {
      return;
    }
    if (result == _PeriodFilter.custom) {
      final range = await showDateRangePicker(
        context: context,
        initialDateRange: _customRange,
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (range != null) {
        setState(() {
          _customRange = range;
          _period = _PeriodFilter.custom;
        });
      }
    } else {
      setState(() {
        _period = result;
      });
    }
  }

  Future<void> _selectSort() async {
    final result = await showMenu<_SortOption>(
      context: context,
      position: const RelativeRect.fromLTRB(16, 160, 16, 0),
      items: const [
        PopupMenuItem(value: _SortOption.dateDesc, child: Text('日付（新しい順）')),
        PopupMenuItem(value: _SortOption.dateAsc, child: Text('日付（古い順）')),
        PopupMenuItem(value: _SortOption.amountDesc, child: Text('金額（高い順）')),
        PopupMenuItem(value: _SortOption.amountAsc, child: Text('金額（低い順）')),
      ],
    );
    if (result == null) {
      return;
    }
    setState(() {
      _sort = result;
    });
  }

  String _periodLabel() {
    switch (_period) {
      case _PeriodFilter.thisMonth:
        return '今月';
      case _PeriodFilter.lastMonth:
        return '先月';
      case _PeriodFilter.custom:
        final range = _customRange;
        if (range == null) {
          return 'カスタム';
        }
        return '${formatDate(range.start)}〜${formatDate(range.end)}';
    }
  }

  String _sortLabel() {
    switch (_sort) {
      case _SortOption.dateDesc:
        return '日付（新しい順）';
      case _SortOption.dateAsc:
        return '日付（古い順）';
      case _SortOption.amountDesc:
        return '金額（高い順）';
      case _SortOption.amountAsc:
        return '金額（低い順）';
    }
  }

  void _markAsPaid(Expense expense) {
    ref.read(expensesProvider.notifier).markAsPaid(expense.id);
  }

  void _markAsUnpaid(Expense expense) {
    ref.read(expensesProvider.notifier).markAsUnpaid(expense.id);
  }

  void _openDetail(Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(expenseId: expense.id),
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.expenses,
    this.checked = false,
    this.showPlannedBadge = false,
    this.onCheck,
    this.onUncheck,
    required this.onTap,
  });

  final List<Expense> expenses;
  final bool checked;
  final bool showPlannedBadge;
  final ValueChanged<Expense>? onCheck;
  final ValueChanged<Expense>? onUncheck;
  final ValueChanged<Expense> onTap;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(child: Text('該当する明細はありません'));
    }
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final isChecked = checked || expense.status == ExpenseStatus.paid;
        return ListTile(
          leading: Checkbox(
            value: isChecked,
            onChanged: (value) {
              if (value == true && onCheck != null) {
                onCheck!(expense);
              } else if (value == false && onUncheck != null) {
                onUncheck!(expense);
              }
            },
          ),
          title: Text('${formatDate(expense.date)}  ${expense.memo}'),
          subtitle: showPlannedBadge
              ? const Text('[予定]', style: TextStyle(color: Colors.deepPurple))
              : null,
          trailing: Text(formatCurrency(expense.amount)),
          onTap: () => onTap(expense),
        );
      },
    );
  }
}
