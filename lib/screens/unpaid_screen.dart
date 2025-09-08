import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

class UnpaidScreen extends StatefulWidget {
  const UnpaidScreen({Key? key}) : super(key: key);

  @override
  State<UnpaidScreen> createState() => _UnpaidScreenState();
}

class _UnpaidScreenState extends State<UnpaidScreen> {
  String _sortBy = 'date';
  bool _isAscending = false;
  String _filterCategory = 'all';

  List<Expense> get _sortedAndFilteredExpenses {
    final provider = context.watch<ExpenseProvider>();
    List<Expense> filtered = provider.unpaidExpenses();
    if (_filterCategory != 'all') {
      filtered =
          filtered.where((e) => e.category == _filterCategory).toList();
    }
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'category':
          comparison = a.category.compareTo(b.category);
          break;
        case 'person':
          comparison = a.person.compareTo(b.person);
          break;
        case 'date':
        default:
          comparison = a.date.compareTo(b.date);
          break;
      }
      return _isAscending ? comparison : -comparison;
    });
    return filtered;
  }

  int get _totalUnpaidAmount =>
      _sortedAndFilteredExpenses.fold(0, (t, e) => t + e.amount);

  Map<String, int> get _categoryTotals {
    final Map<String, int> totals = {};
    for (final e in _sortedAndFilteredExpenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Set<String> get _availableCategories {
    final provider = context.read<ExpenseProvider>();
    return provider.categories.toSet();
  }

  void _togglePaymentStatus(Expense expense) {
    final provider = context.read<ExpenseProvider>();
    provider.togglePaid(expense);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「${expense.category}」を支払い済みにしました'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: '元に戻す',
          textColor: Colors.white,
          onPressed: () => provider.togglePaid(expense),
        ),
      ),
    );
  }

  void _markAllAsPaid() {
    final items = List<Expense>.from(_sortedAndFilteredExpenses);
    final provider = context.read<ExpenseProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('一括支払い確認'),
        content: Text(
            '表示中の未払い項目をすべて支払い済みにしますか？\n\n合計: ¥$_totalUnpaidAmount'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              for (final e in items) {
                provider.togglePaid(e);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${items.length}件を支払い済みにしました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('すべて支払い済みにする'),
          ),
        ],
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case '食費':
        return '🍽️';
      case '交通費':
        return '🚃';
      case '娯楽費':
        return '🎮';
      default:
        return '📝';
    }
  }

  String _getPersonIcon(String person) {
    final provider = context.read<ExpenseProvider>();
    final member = provider.members.firstWhere(
      (m) => m.name == person,
      orElse: () => Member(name: person, icon: '👤'),
    );
    return member.icon;
  }

  String _formatDate(DateTime date) => DateFormat.Md().format(date);

  String _getDaysAgo(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return '今日';
    if (diff == 1) return '1日前';
    if (diff < 7) return '$diff日前';
    if (diff < 30) return '${(diff / 7).floor()}週間前';
    return '${(diff / 30).floor()}ヶ月前';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final allUnpaid = provider.unpaidExpenses();
    return Scaffold(
main
            ),
            textAlign: TextAlign.center,
          ),
          if (!hasUnpaid) ...[
            const SizedBox(height: 8),
            Text(
              'すべての支払いが完了しています',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    final expenses = _sortedAndFilteredExpenses;
    final Map<String, List<Expense>> grouped = {};
    for (final e in expenses) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_filterCategory == 'all' && _categoryTotals.length > 1)
          _buildCategorySummary(),
        if (_filterCategory != 'all')
          ...expenses.map(_buildExpenseCard)
        else
          ...grouped.entries.map((entry) {
            final category = entry.key;
            final categoryExpenses = entry.value;
            final categoryTotal =
                categoryExpenses.fold(0, (t, e) => t + e.amount);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(width: 4, color: Colors.red[600]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_getCategoryIcon(category),
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '¥$categoryTotal',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...categoryExpenses.map(_buildExpenseCard),
              ],
            );
          }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCategorySummary() {
    final entries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カテゴリ別未払い額',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...entries.map((entry) {
              final percent =
                  _totalUnpaidAmount == 0
                      ? 0
                      : (entry.value / _totalUnpaidAmount) * 100;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(_getCategoryIcon(entry.key),
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '¥${entry.value}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final daysAgo = _getDaysAgo(expense.date);
    final isOverdue = DateTime.now().difference(expense.date).inDays > 7;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOverdue ? Colors.orange[300]! : Colors.transparent,
          width: isOverdue ? 2 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _togglePaymentStatus(expense),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color:
                        isOverdue ? Colors.orange[600]! : Colors.red[300]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getPersonIcon(expense.person),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '¥${expense.amount}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '要確認',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expense.person} • ${expense.category}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(expense.date)} ($daysAgo)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue
                            ? Colors.orange[600]
                            : Colors.grey[500],
                        fontWeight:
                            isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _togglePaymentStatus(expense),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.green[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '支払済',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
