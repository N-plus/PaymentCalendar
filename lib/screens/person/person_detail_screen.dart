import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_check/widgets/radio_option_tile.dart';

import '../../models/expense.dart';
import '../../models/person.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/people_provider.dart';
import '../../utils/date_util.dart';
import '../expense/expense_detail_screen.dart';
import '../../widgets/person_avatar.dart';

enum _DateFilter { all, thisMonth, lastMonth, custom }

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
  _DateFilter _dateFilter = _DateFilter.thisMonth;
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
    final List<Expense> expenses = ref.watch(expensesProvider);
    final List<Person> people = ref.watch(peopleProvider);
    final Map<String, Person> peopleMap = {
      for (final person in people) person.id: person
    };
    final String? personId = widget.person.id;
    final List<Expense> personExpenses = (personId == null || personId.isEmpty)
        ? <Expense>[]
        : expenses
            .where((expense) => expense.payeeId == personId)
            .toList();
    final currentStatus = _statusForIndex(_tabController.index);
    final List<Expense> filteredExpenses = personExpenses.isEmpty
        ? <Expense>[]
        : _filteredExpenses(personExpenses, currentStatus);
    final double currentTotal = filteredExpenses.fold<double>(
      0.0,
      (sum, expense) {
        final num? amount = expense.amount;
        return sum + (amount ?? 0).toDouble();
      },
    );
    final double unpaidTotal = personExpenses
        .where((expense) => expense.status == ExpenseStatus.unpaid)
        .fold<double>(0.0, (sum, expense) {
      final num? amount = expense.amount;
      return sum + (amount ?? 0).toDouble();
    });
    final int currentTotalForDisplay = currentTotal.round();
    final int unpaidTotalForDisplay = unpaidTotal.round();
    final totalLabel = _statusLabel(currentStatus);
    final highlightColor = currentStatus == ExpenseStatus.paid
        ? Colors.grey[700]
        : (currentTotalForDisplay > 0 ? Colors.red[600] : Colors.grey[600]);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Row(
          children: [
            _buildAvatar(widget.person, size: 32),
            const SizedBox(width: 12),
            Text(
              widget.person.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'フィルタ・並び替え',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(currentTotalForDisplay),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: highlightColor,
                  ),
                ),
                if (_dateFilter == _DateFilter.custom && _customRange != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${formatDate(_customRange!.start)}〜${formatDate(_customRange!.end)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: '未払い'),
                Tab(text: '予定'),
                Tab(text: '支払い済み'),
              ],
            ),
          ),
          Expanded(
            child: filteredExpenses.isEmpty
                ? _buildEmptyState(currentStatus)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      final payer = peopleMap[expense.payerId];
                      return _buildExpenseCard(expense, payer);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Text(
            '${widget.person.name}の未払い合計: ${formatCurrency(unpaidTotalForDisplay)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  ExpenseStatus _statusForIndex(int index) {
    switch (index) {
      case 0:
        return ExpenseStatus.unpaid;
      case 1:
        return ExpenseStatus.planned;
      default:
        return ExpenseStatus.paid;
    }
  }

  String _statusLabel(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.unpaid:
        return '未払い合計';
      case ExpenseStatus.planned:
        return '予定合計';
      case ExpenseStatus.paid:
        return '支払い済み合計';
    }
  }

  List<Expense> _filteredExpenses(
    List<Expense> expenses,
    ExpenseStatus status,
  ) {
    final filtered = expenses.where((expense) {
      if (expense.status != status) {
        return false;
      }
      return _matchesDateFilter(expense.date);
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

  bool _matchesDateFilter(DateTime date) {
    final target = DateUtils.dateOnly(date);
    switch (_dateFilter) {
      case _DateFilter.all:
        return true;
      case _DateFilter.thisMonth:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end =
            DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
        return !target.isBefore(start) && !target.isAfter(end);
      case _DateFilter.lastMonth:
        final now = DateTime.now();
        final month = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(month.year, month.month, 1);
        final end =
            DateTime(month.year, month.month + 1, 1).subtract(const Duration(days: 1));
        return !target.isBefore(start) && !target.isAfter(end);
      case _DateFilter.custom:
        final range = _customRange;
        if (range == null) {
          return true;
        }
        final start = DateUtils.dateOnly(range.start);
        final end = DateUtils.dateOnly(range.end);
        return !target.isBefore(start) && !target.isAfter(end);
    }
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('フィルタ・並び替え'),
          backgroundColor: const Color(0xFFFFFAF0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '期間',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                  ..._DateFilter.values.map(
                    (filter) => RadioOptionTile<_DateFilter>(
                      value: filter,
                      groupValue: _dateFilter,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_dateFilterLabel(filter)),
                      onSelected: (value) {
                        if (value == _DateFilter.custom) {
                          Navigator.of(context).pop();
                          _showCustomDatePicker();
                        } else {
                          setState(() {
                            _dateFilter = value;
                            _customRange = null;
                          });
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                const Divider(),
                const Text(
                  '並び替え',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                  ..._SortOption.values.map(
                    (option) => RadioOptionTile<_SortOption>(
                      value: option,
                      groupValue: _sort,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_sortLabel(option)),
                      onSelected: (value) {
                        setState(() {
                          _sort = value;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCustomDatePicker() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _customRange,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (range == null) {
      return;
    }
    setState(() {
      _customRange = range;
      _dateFilter = _DateFilter.custom;
    });
  }

  String _dateFilterLabel(_DateFilter filter) {
    switch (filter) {
      case _DateFilter.all:
        return '全期間';
      case _DateFilter.thisMonth:
        return '今月';
      case _DateFilter.lastMonth:
        return '先月';
      case _DateFilter.custom:
        final range = _customRange;
        if (range == null) {
          return 'カスタム';
        }
        return 'カスタム（${formatDate(range.start)}〜${formatDate(range.end)}）';
    }
  }

  String _sortLabel(_SortOption sort) {
    switch (sort) {
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

  Widget _buildAvatar(Person person, {double size = 32}) {
    return PersonAvatar(
      person: person,
      size: size,
      backgroundColor: kPersonAvatarBackgroundColor,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: size * 0.45,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, Person? payer) {
    final isPaid = expense.status == ExpenseStatus.paid;
    final isPlanned = expense.status == ExpenseStatus.planned;
    final memo = expense.memo.isEmpty ? '記録' : expense.memo;
    final amountColor = isPaid ? Colors.grey[600] : Colors.black87;
    final photos = expense.photoPaths.length;
    final payerName = payer?.name ?? '不明';
    final relationshipText = '$payerName → ${widget.person.name}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFFFFFFFF),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: isPaid
            ? IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: '未払いに戻す',
                onPressed: () => _markAsUnpaid(expense),
              )
            : Checkbox(
                value: false,
                onChanged: (value) {
                  if (value == true) {
                    _markAsPaid(expense);
                  }
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
        title: Row(
          children: [
            Text(
              _formatShortDate(expense.date),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                memo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isPlanned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '予定',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              relationshipText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (photos > 0)
                  Row(
                    children: [
                      Icon(Icons.camera_alt, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '$photos枚',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  formatCurrency(expense.amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _openDetail(expense),
      ),
    );
  }

  Widget _buildEmptyState(ExpenseStatus status) {
    final message = () {
      switch (status) {
        case ExpenseStatus.unpaid:
          return '未払いの明細がありません';
        case ExpenseStatus.planned:
          return '予定の明細がありません';
        case ExpenseStatus.paid:
          return '支払い済みの明細がありません';
      }
    }();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    final target = DateUtils.dateOnly(date);
    return '${target.month}/${target.day}';
  }

  void _markAsPaid(Expense expense) {
    if (expense.status == ExpenseStatus.paid) {
      return;
    }
    ref.read(expensesProvider.notifier).markAsPaid(expense.id);
    final memo = expense.memo.isEmpty ? '記録' : expense.memo;
    _showSnackBarWithUndo(
      '$memoを支払い済みにしました',
      () => ref.read(expensesProvider.notifier).markAsUnpaid(expense.id),
    );
  }

  void _markAsUnpaid(Expense expense) {
    if (expense.status != ExpenseStatus.paid) {
      return;
    }
    ref.read(expensesProvider.notifier).markAsUnpaid(expense.id);
  }

  void _showSnackBarWithUndo(String message, VoidCallback onUndo) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: onUndo,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _openDetail(Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(expenseId: expense.id),
      ),
    );
  }
}
