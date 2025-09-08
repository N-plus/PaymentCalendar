import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'expense_input_screen.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({Key? key, required this.day}) : super(key: key);

  final DateTime day;

  String _formatDate(DateTime date) {
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return '${date.year}年${date.month}月${date.day}日（${weekdays[date.weekday % 7]}）';
  }

  Map<String, List<Expense>> _groupByCategory(List<Expense> expenses) {
    final Map<String, List<Expense>> grouped = {};
    for (final e in expenses) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }
    return grouped;
  }

  String _personIcon(String person) {
    return person.length >= 2 ? person.substring(0, 2) : person;
  }

  String _personName(String person) {
    return person.length >= 2 ? person.substring(2) : '';
  }

  void _togglePaymentStatus(BuildContext context, Expense expense) {
    context.read<ExpenseProvider>().togglePaid(expense);
  }

  void _deleteExpense(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: const Text('この支出を削除しますか？'),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('削除'),
              onPressed: () {
                context.read<ExpenseProvider>().removeExpense(expense);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('支出を削除しました'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
      String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'この日の支出はありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '右下の＋ボタンから追加できます',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, Expense expense) {
    final icon = _personIcon(expense.person);
    final name = _personName(expense.person);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _togglePaymentStatus(context, expense),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      expense.isPaid ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: expense.isPaid
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            expense.isPaid ? '支払済' : '未払い',
                            style: TextStyle(
                              fontSize: 10,
                              color: expense.isPaid
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$name • ${expense.category}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _togglePaymentStatus(context, expense),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        expense.isPaid ? '☑️' : '□',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _deleteExpense(context, expense),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red[600],
                      ),
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

  String _categoryIcon(String category) {
    switch (category) {
      case '食費':
        return '🍽️';
      case '交通費':
        return '🚃';
      case '娯楽費':
        return '🎮';
      case '医療費':
        return '🏥';
      case '日用品':
        return '🧽';
      case '光熱費':
        return '💡';
      default:
        return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.expensesOn(day);

    final totalAmount =
        expenses.fold<int>(0, (total, e) => total + e.amount);
    final paidAmount = expenses
        .where((e) => e.isPaid)
        .fold<int>(0, (total, e) => total + e.amount);
    final unpaidAmount = totalAmount - paidAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細'),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExpenseInputScreen(initialDate: day),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[600]!, Colors.white],
            stops: const [0.0, 0.25],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _formatDate(day),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          '合計',
                          '¥$totalAmount',
                          Colors.blue[700]!,
                          Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          '支払済',
                          '¥$paidAmount',
                          Colors.green[600]!,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          '未払い',
                          '¥$unpaidAmount',
                          Colors.red[600]!,
                          Icons.pending,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: expenses.isEmpty
                  ? _buildEmptyState()
                  : _buildExpenseList(context, expenses),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseInputScreen(initialDate: day),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  Widget _buildExpenseList(BuildContext context, List<Expense> expenses) {
    final grouped = _groupByCategory(expenses);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        for (final entry in grouped.entries) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  _categoryIcon(entry.key),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '¥${entry.value.fold<int>(0, (t, e) => t + e.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          for (final e in entry.value) _buildExpenseCard(context, e),
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}

