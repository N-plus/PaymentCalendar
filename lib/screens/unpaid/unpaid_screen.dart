import 'dart:io';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense.dart';
import '../../models/person.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/people_provider.dart';
import '../../utils/format.dart';
import '../expense/expense_detail_screen.dart';

class UnpaidScreen extends ConsumerStatefulWidget {
  const UnpaidScreen({super.key, this.initialPersonId});

  final String? initialPersonId;

  @override
  ConsumerState<UnpaidScreen> createState() => _UnpaidScreenState();
}

enum _PeriodFilter { thisMonth, lastMonth, custom }

enum _SortOption { dateDesc, dateAsc, amountDesc, amountAsc }

enum _TypeFilter { normal, planned, both }

class _UnpaidScreenState extends ConsumerState<UnpaidScreen> {
  _PeriodFilter _period = _PeriodFilter.thisMonth;
  DateTimeRange? _customRange;
  _SortOption _sort = _SortOption.dateDesc;
  _TypeFilter _type = _TypeFilter.normal;
  String? _personId;
  bool _isSearching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _personId = widget.initialPersonId;
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider);
    final expenses = ref.watch(expensesProvider);
    final filtered = expenses.where(_applyFilters).toList()
      ..sort(_sortComparator);
    final total = filtered.fold<int>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('未払い一覧'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _query = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _openFilters(people),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _openSortMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'メモで検索',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('該当する明細はありません'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final expense = filtered[index];
                      final person = people.firstWhere(
                        (element) => element.id == expense.personId,
                        orElse: () =>
                            const Person(id: 'unknown', name: '不明', emoji: '❓'),
                      );
                      return _UnpaidListTile(
                        expense: expense,
                        person: person,
                        onCheck: () =>
                            ref.read(expensesProvider.notifier).markAsPaid(
                                  expense.id,
                                ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ExpenseDetailScreen(expenseId: expense.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Text(
              '未払い合計: ${formatCurrency(total)}',
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

  bool _applyFilters(Expense expense) {
    if (expense.status == ExpenseStatus.paid) {
      return false;
    }
    if (_personId != null && expense.personId != _personId) {
      return false;
    }
    switch (_type) {
      case _TypeFilter.normal:
        if (expense.status != ExpenseStatus.unpaid) {
          return false;
        }
        break;
      case _TypeFilter.planned:
        if (expense.status != ExpenseStatus.planned) {
          return false;
        }
        break;
      case _TypeFilter.both:
        break;
    }
    if (!_isWithinPeriod(expense.date)) {
      return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty &&
        !expense.memo.toLowerCase().contains(query)) {
      return false;
    }
    return true;
  }

  bool _isWithinPeriod(DateTime date) {
    final target = DateUtils.dateOnly(date);
    switch (_period) {
      case _PeriodFilter.thisMonth:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(days: 1));
        return !target.isBefore(start) && !target.isAfter(end);
      case _PeriodFilter.lastMonth:
        final now = DateTime.now();
        final prev = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(prev.year, prev.month, 1);
        final end =
            DateTime(prev.year, prev.month + 1, 1).subtract(const Duration(days: 1));
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

  int _sortComparator(Expense a, Expense b) {
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
  }

  Future<void> _openFilters(List<Person> people) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    value: _personId,
                    decoration: const InputDecoration(
                      labelText: '人',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('すべて'),
                      ),
                      ...people.map(
                        (person) => DropdownMenuItem<String?>(
                          value: person.id,
                          child: Text(person.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() => _personId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_PeriodFilter>(
                    value: _period,
                    decoration: const InputDecoration(labelText: '期間'),
                    items: const [
                      DropdownMenuItem(
                        value: _PeriodFilter.thisMonth,
                        child: Text('今月'),
                      ),
                      DropdownMenuItem(
                        value: _PeriodFilter.lastMonth,
                        child: Text('先月'),
                      ),
                      DropdownMenuItem(
                        value: _PeriodFilter.custom,
                        child: Text('カスタム'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == null) {
                        return;
                      }
                      if (value == _PeriodFilter.custom) {
                        final range = await showDateRangePicker(
                          context: context,
                          initialDateRange: _customRange,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (range != null) {
                          setModalState(() {
                            _period = value;
                            _customRange = range;
                          });
                        }
                      } else {
                        setModalState(() => _period = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_TypeFilter>(
                    value: _type,
                    decoration: const InputDecoration(labelText: '区分'),
                    items: const [
                      DropdownMenuItem(
                        value: _TypeFilter.normal,
                        child: Text('通常'),
                      ),
                      DropdownMenuItem(
                        value: _TypeFilter.planned,
                        child: Text('予定'),
                      ),
                      DropdownMenuItem(
                        value: _TypeFilter.both,
                        child: Text('両方'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => _type = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                      child: const Text('適用'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }

  Future<void> _openSortMenu() async {
    final result = await showMenu<_SortOption>(
      context: context,
      position: const RelativeRect.fromLTRB(16, 80, 16, 0),
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
}

class _UnpaidListTile extends StatelessWidget {
  const _UnpaidListTile({
    required this.expense,
    required this.person,
    required this.onCheck,
    required this.onTap,
  });

  final Expense expense;
  final Person person;
  final VoidCallback onCheck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photoPath = person.photoPath;
    final avatar = photoPath != null && File(photoPath).existsSync()
        ? CircleAvatar(backgroundImage: FileImage(File(photoPath)))
        : CircleAvatar(
            child: Text(
              person.emoji ??
                  (person.name.characters.isNotEmpty
                      ? person.name.characters.first
                      : '?'),
            ),
          );
    return ListTile(
      leading: Checkbox(
        value: false,
        onChanged: (_) => onCheck(),
      ),
      title: Text('${formatDate(expense.date)}  ${expense.memo}'),
      subtitle: Row(
        children: [
          avatar,
          const SizedBox(width: 8),
          Text(person.name),
          if (expense.status == ExpenseStatus.planned)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Chip(
                label: Text('予定'),
                backgroundColor: Color(0xFFEDE7F6),
              ),
            ),
        ],
      ),
      trailing: Text(formatCurrency(expense.amount)),
      onTap: onTap,
    );
  }
}
