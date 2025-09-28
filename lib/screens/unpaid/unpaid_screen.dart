import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payment_calendar/widgets/radio_option_tile.dart';

import '../../models/expense.dart';
import '../../models/person.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/people_provider.dart';
import '../../utils/date_util.dart';
import '../expense/expense_detail_screen.dart';

class UnpaidScreen extends ConsumerStatefulWidget {
  const UnpaidScreen({super.key, this.initialPersonId});

  final String? initialPersonId;

  @override
  ConsumerState<UnpaidScreen> createState() => _UnpaidScreenState();
}

enum DateFilter { all, thisMonth, lastMonth, custom }

enum SortBy { dateDesc, dateAsc, amountDesc, amountAsc }

enum CategoryFilter { normal, planned, both }

class _UnpaidScreenState extends ConsumerState<UnpaidScreen> {
  static const _defaultDateFilter = DateFilter.thisMonth;
  static const _defaultCategoryFilter = CategoryFilter.normal;
  static const _defaultSortBy = SortBy.dateDesc;

  String? selectedPersonId;
  DateFilter dateFilter = _defaultDateFilter;
  CategoryFilter categoryFilter = _defaultCategoryFilter;
  SortBy sortBy = _defaultSortBy;
  DateTimeRange? customDateRange;
  late final TextEditingController _searchController;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selectedPersonId = widget.initialPersonId;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider);
    final peopleMap = {for (final person in people) person.id: person};
    final expenses = ref.watch(expensesProvider);

    final candidates =
        expenses.where((e) => e.status != ExpenseStatus.paid).toList();
    final filteredExpenses = candidates
        .where((expense) => _matchesFilters(expense, peopleMap))
        .toList()
      ..sort(_sortComparator);

    final total =
        filteredExpenses.fold<int>(0, (sum, expense) => sum + expense.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: const Text('未払い一覧'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'メモや人名で検索...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showFilterDialog(people),
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('フィルタ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[700],
                        elevation: 0,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredExpenses.length}件',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (_hasActiveFilters())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildActiveFilters(peopleMap),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          Expanded(
            child: filteredExpenses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      final person = peopleMap[expense.personId];
                      return _buildExpenseListItem(expense, person);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFFFAF0),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Text(
            '未払い合計（全体）: ${formatCurrency(total)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  bool _matchesFilters(Expense expense, Map<String, Person> peopleMap) {
    if (selectedPersonId != null && expense.personId != selectedPersonId) {
      return false;
    }

    if (categoryFilter == CategoryFilter.normal &&
        expense.status != ExpenseStatus.unpaid) {
      return false;
    }
    if (categoryFilter == CategoryFilter.planned &&
        expense.status != ExpenseStatus.planned) {
      return false;
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final memo = expense.memo.toLowerCase();
      final personName =
          peopleMap[expense.personId]?.name.toLowerCase() ?? '';
      if (!memo.contains(query) && !personName.contains(query)) {
        return false;
      }
    }

    final dateOnly = DateUtils.dateOnly(expense.date);
    switch (dateFilter) {
      case DateFilter.thisMonth:
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end =
            DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
        if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) {
          return false;
        }
        break;
      case DateFilter.lastMonth:
        final now = DateTime.now();
        final prev = DateTime(now.year, now.month - 1, 1);
        final start = DateTime(prev.year, prev.month, 1);
        final end = DateTime(prev.year, prev.month + 1, 1)
            .subtract(const Duration(days: 1));
        if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) {
          return false;
        }
        break;
      case DateFilter.custom:
        final range = customDateRange;
        if (range != null) {
          final start = DateUtils.dateOnly(range.start);
          final end = DateUtils.dateOnly(range.end);
          if (dateOnly.isBefore(start) || dateOnly.isAfter(end)) {
            return false;
          }
        }
        break;
      case DateFilter.all:
        break;
    }

    return true;
  }

  int _sortComparator(Expense a, Expense b) {
    switch (sortBy) {
      case SortBy.dateAsc:
        return a.date.compareTo(b.date);
      case SortBy.dateDesc:
        return b.date.compareTo(a.date);
      case SortBy.amountAsc:
        return a.amount.compareTo(b.amount);
      case SortBy.amountDesc:
        return b.amount.compareTo(a.amount);
    }
  }

  void _showFilterDialog(List<Person> people) {
    final initialPersonId = selectedPersonId;
    final initialDateFilter = dateFilter;
    final initialCategory = categoryFilter;
    final initialSort = sortBy;
    final initialRange = customDateRange;

    showDialog<void>(
      context: context,
      builder: (context) {
        var tempPersonId = initialPersonId;
        var tempDateFilter = initialDateFilter;
        var tempCategory = initialCategory;
        var tempSort = initialSort;
        var tempRange = initialRange;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickRange() async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: tempRange,
              );
              if (range != null) {
                setDialogState(() {
                  tempDateFilter = DateFilter.custom;
                  tempRange = range;
                });
              }
            }

              final selectedRange = tempRange;
              return AlertDialog(
              title: const Text('フィルタ・並び替え'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '人',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('全員'),
                          selected: tempPersonId == null,
                          onSelected: (selected) {
                            setDialogState(() => tempPersonId = null);
                          },
                        ),
                        ...people.map(
                          (person) => FilterChip(
                            label: Text(person.name),
                            selected: tempPersonId == person.id,
                            onSelected: (selected) {
                              setDialogState(() {
                                tempPersonId = selected ? person.id : null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      '区分',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                      RadioOptionTile<CategoryFilter>(
                        title: const Text('通常'),
                        value: CategoryFilter.normal,
                        groupValue: tempCategory,
                        onSelected: (value) {
                          setDialogState(() => tempCategory = value);
                        },
                      ),
                      RadioOptionTile<CategoryFilter>(
                        title: const Text('予定'),
                        value: CategoryFilter.planned,
                        groupValue: tempCategory,
                        onSelected: (value) {
                          setDialogState(() => tempCategory = value);
                        },
                      ),
                      RadioOptionTile<CategoryFilter>(
                        title: const Text('両方'),
                        value: CategoryFilter.both,
                        groupValue: tempCategory,
                        onSelected: (value) {
                          setDialogState(() => tempCategory = value);
                        },
                      ),
                    const Divider(),
                    const Text(
                      '期間',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                      RadioOptionTile<DateFilter>(
                        title: const Text('全期間'),
                        value: DateFilter.all,
                        groupValue: tempDateFilter,
                        onSelected: (value) {
                          setDialogState(() {
                            tempDateFilter = value;
                            tempRange = null;
                          });
                        },
                      ),
                      RadioOptionTile<DateFilter>(
                        title: const Text('今月'),
                        value: DateFilter.thisMonth,
                        groupValue: tempDateFilter,
                        onSelected: (value) {
                          setDialogState(() {
                            tempDateFilter = value;
                            tempRange = null;
                          });
                        },
                      ),
                      RadioOptionTile<DateFilter>(
                        title: const Text('先月'),
                        value: DateFilter.lastMonth,
                        groupValue: tempDateFilter,
                        onSelected: (value) {
                          setDialogState(() {
                            tempDateFilter = value;
                            tempRange = null;
                          });
                        },
                      ),
                      RadioOptionTile<DateFilter>(
                        title: const Text('カスタム'),
                        value: DateFilter.custom,
                        groupValue: tempDateFilter,
                        onSelected: (value) {
                          if (value == DateFilter.custom) {
                            pickRange();
                          } else {
                            setDialogState(() {
                              tempDateFilter = value;
                              tempRange = null;
                            });
                          }
                        },
                      ),
                      if (tempDateFilter == DateFilter.custom && selectedRange != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            '${formatDate(selectedRange.start)} 〜 ${formatDate(selectedRange.end)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                    const Divider(),
                    const Text(
                      '並び替え',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                      RadioOptionTile<SortBy>(
                        title: const Text('日付（降順）'),
                        value: SortBy.dateDesc,
                        groupValue: tempSort,
                        onSelected: (value) {
                          setDialogState(() => tempSort = value);
                        },
                      ),
                      RadioOptionTile<SortBy>(
                        title: const Text('日付（昇順）'),
                        value: SortBy.dateAsc,
                        groupValue: tempSort,
                        onSelected: (value) {
                          setDialogState(() => tempSort = value);
                        },
                      ),
                      RadioOptionTile<SortBy>(
                        title: const Text('金額（降順）'),
                        value: SortBy.amountDesc,
                        groupValue: tempSort,
                        onSelected: (value) {
                          setDialogState(() => tempSort = value);
                        },
                      ),
                      RadioOptionTile<SortBy>(
                        title: const Text('金額（昇順）'),
                        value: SortBy.amountAsc,
                        groupValue: tempSort,
                        onSelected: (value) {
                          setDialogState(() => tempSort = value);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedPersonId = tempPersonId;
                      dateFilter = tempDateFilter;
                      categoryFilter = tempCategory;
                      sortBy = tempSort;
                      customDateRange = tempDateFilter == DateFilter.custom
                          ? tempRange
                          : null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('適用'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActiveFilters(Map<String, Person> peopleMap) {
    final chips = <Widget>[];

    if (selectedPersonId != null) {
      final person = peopleMap[selectedPersonId];
      if (person != null) {
        chips.add(
          Chip(
            label: Text(person.name),
            onDeleted: () => setState(() => selectedPersonId = null),
            deleteIcon: const Icon(Icons.close, size: 16),
          ),
        );
      }
    }

    if (categoryFilter != _defaultCategoryFilter) {
      chips.add(
        Chip(
          label: Text(_getCategoryFilterName(categoryFilter)),
          onDeleted: () =>
              setState(() => categoryFilter = _defaultCategoryFilter),
          deleteIcon: const Icon(Icons.close, size: 16),
        ),
      );
    }

    if (dateFilter != _defaultDateFilter) {
      chips.add(
        Chip(
          label: Text(_getDateFilterLabel()),
          onDeleted: () => setState(() {
            dateFilter = _defaultDateFilter;
            customDateRange = null;
          }),
          deleteIcon: const Icon(Icons.close, size: 16),
        ),
      );
    }

    if (searchQuery.isNotEmpty) {
      chips.add(
        Chip(
          label: Text('検索: $searchQuery'),
          onDeleted: () {
            setState(() {
              searchQuery = '';
              _searchController.clear();
            });
          },
          deleteIcon: const Icon(Icons.close, size: 16),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildEmptyState() {
    final message = _hasActiveFilters()
        ? 'フィルタ条件に一致する記録がありません'
        : '未払いの記録がありません';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          if (_hasActiveFilters()) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('フィルタをクリア'),
            ),
          ],
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      selectedPersonId = null;
      dateFilter = _defaultDateFilter;
      categoryFilter = _defaultCategoryFilter;
      sortBy = _defaultSortBy;
      customDateRange = null;
      searchQuery = '';
      _searchController.clear();
    });
  }

  Widget _buildExpenseListItem(Expense expense, Person? person) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: const Color(0xFFFFFFFF),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: const Color(0xFFFFFFFF),
        leading: Checkbox(
          value: false,
          onChanged: (_) => _markExpenseAsPaid(expense),
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        title: Row(
          children: [
            Text(
              _formatListDate(expense.date),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                expense.memo.isEmpty ? '記録' : expense.memo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatCurrency(expense.amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            _buildSmallAvatar(person),
            if (expense.status == ExpenseStatus.planned) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ],
        ),
        subtitle: expense.photoPaths.isNotEmpty
            ? Row(
                children: [
                  Icon(Icons.camera_alt, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${expense.photoPaths.length}枚',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              )
            : null,
        onTap: () => _navigateToExpenseDetail(expense),
      ),
    );
  }

  void _navigateToExpenseDetail(Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(expenseId: expense.id),
      ),
    );
  }

  void _markExpenseAsPaid(Expense expense) {
    final notifier = ref.read(expensesProvider.notifier);
    notifier.markAsPaid(expense.id);

    final memo = expense.memo.isEmpty ? '記録' : expense.memo;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$memoを支払い済みにしました'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => notifier.markAsUnpaid(expense.id),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSmallAvatar(Person? person) {
    const double radius = 16;
    if (person == null) {
      return const CircleAvatar(
        radius: radius,
        child: Text('?', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    final photoPath = person.photoPath;
    if (photoPath != null && File(photoPath).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(photoPath)),
      );
    }

    final display = person.emoji ??
        (person.name.characters.isNotEmpty
            ? person.name.characters.first
            : '?');
    return CircleAvatar(
      radius: radius,
      child: Text(
        display,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  bool _hasActiveFilters() {
    return selectedPersonId != null ||
        searchQuery.isNotEmpty ||
        categoryFilter != _defaultCategoryFilter ||
        dateFilter != _defaultDateFilter ||
        (dateFilter == DateFilter.custom && customDateRange != null);
  }

  String _formatListDate(DateTime date) {
    final target = DateUtils.dateOnly(date);
    return '${target.month}/${target.day}';
  }

  String _getCategoryFilterName(CategoryFilter filter) {
    switch (filter) {
      case CategoryFilter.normal:
        return '通常';
      case CategoryFilter.planned:
        return '予定';
      case CategoryFilter.both:
        return '両方';
    }
  }

  String _getDateFilterLabel() {
    if (dateFilter == DateFilter.custom && customDateRange != null) {
      return '${formatDate(customDateRange!.start)} 〜 ${formatDate(customDateRange!.end)}';
    }
    return _getDateFilterName(dateFilter);
  }

  String _getDateFilterName(DateFilter filter) {
    switch (filter) {
      case DateFilter.all:
        return '全期間';
      case DateFilter.thisMonth:
        return '今月';
      case DateFilter.lastMonth:
        return '先月';
      case DateFilter.custom:
        return 'カスタム';
    }
  }
}
