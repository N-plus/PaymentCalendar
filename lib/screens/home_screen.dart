import 'package:flutter/material.dart';

class ExpenseItem {
  final String personIcon;
  final int amount;
  bool isPaid;

  ExpenseItem({
    required this.personIcon,
    required this.amount,
    required this.isPaid,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime currentDate = DateTime.now();
  int selectedNavIndex = 0;

  // サンプルデータ
  Map<int, List<ExpenseItem>> expenseData = {
    2: [
      ExpenseItem(personIcon: '👩', amount: 1200, isPaid: false),
    ],
    5: [
      ExpenseItem(personIcon: '👨', amount: 800, isPaid: true),
    ],
    8: [
      ExpenseItem(personIcon: '🐱', amount: 500, isPaid: false),
    ],
    12: [
      ExpenseItem(personIcon: '👩', amount: 2500, isPaid: true),
      ExpenseItem(personIcon: '👨', amount: 300, isPaid: false),
    ],
  };

  void _changeMonth(int direction) {
    setState(() {
      currentDate = DateTime(
        currentDate.year,
        currentDate.month + direction,
        1,
      );
    });
  }

  void _togglePaymentStatus(int day, int index) {
    setState(() {
      expenseData[day]![index].isPaid = !expenseData[day]![index].isPaid;
    });
  }

  void _onNavTapped(int index) {
    setState(() {
      selectedNavIndex = index;
    });
    // TODO: 他の画面への遷移処理
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 2,
        toolbarHeight: 100,
        title: Column(
          children: [
            const Text(
              '家計簿',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMonthNavButton(Icons.arrow_back_ios, () => _changeMonth(-1)),
                const SizedBox(width: 20),
                SizedBox(
                  width: 120,
                  child: Text(
                    '${currentDate.year}年${currentDate.month}月',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 20),
                _buildMonthNavButton(Icons.arrow_forward_ios, () => _changeMonth(1)),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              _buildDayHeaders(),
              Expanded(child: _buildCalendarGrid()),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: _addExpense,
          backgroundColor: const Color(0xFF28A745),
          child: const Icon(
            Icons.add,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildMonthNavButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Widget _buildDayHeaders() {
    const dayHeaders = ['日', '月', '火', '水', '木', '金', '土'];
    return SizedBox(
      height: 50,
      child: Row(
        children: dayHeaders
            .map((day) => Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    margin: const EdgeInsets.all(4),
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF495057),
                        ),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _getDaysInMonth(),
      itemBuilder: (context, index) {
        return _buildCalendarDay(index);
      },
    );
  }

  int _getDaysInMonth() {
    DateTime firstDay = DateTime(currentDate.year, currentDate.month, 1);
    DateTime lastDay = DateTime(currentDate.year, currentDate.month + 1, 0);
    int daysInMonth = lastDay.day;
    int firstWeekday = firstDay.weekday % 7;

    return daysInMonth + firstWeekday;
  }

  Widget _buildCalendarDay(int index) {
    DateTime firstDay = DateTime(currentDate.year, currentDate.month, 1);
    int firstWeekday = firstDay.weekday % 7;

    if (index < firstWeekday) {
      DateTime lastDayPrevMonth = DateTime(currentDate.year, currentDate.month, 0);
      int day = lastDayPrevMonth.day - (firstWeekday - index - 1);

      return _buildDayContainer(
        day: day,
        isCurrentMonth: false,
        isToday: false,
        expenses: [],
      );
    }

    int day = index - firstWeekday + 1;
    DateTime lastDay = DateTime(currentDate.year, currentDate.month + 1, 0);

    if (day > lastDay.day) {
      int nextMonthDay = day - lastDay.day;
      return _buildDayContainer(
        day: nextMonthDay,
        isCurrentMonth: false,
        isToday: false,
        expenses: [],
      );
    }

    DateTime today = DateTime.now();
    bool isToday = currentDate.year == today.year &&
        currentDate.month == today.month &&
        day == today.day;

    List<ExpenseItem> dayExpenses = expenseData[day] ?? [];

    return _buildDayContainer(
      day: day,
      isCurrentMonth: true,
      isToday: isToday,
      expenses: dayExpenses,
    );
  }

  Widget _buildDayContainer({
    required int day,
    required bool isCurrentMonth,
    required bool isToday,
    required List<ExpenseItem> expenses,
  }) {
    return GestureDetector(
      onTap: isCurrentMonth ? () => _onDayTapped(day) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentMonth
              ? (isToday ? const Color(0xFFFFF5F5) : Colors.white)
              : const Color(0xFFF8F9FA),
          border: Border.all(
            color: isToday
                ? const Color(0xFFDC3545)
                : const Color(0xFFE9ECEF),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCurrentMonth ? Colors.black : const Color(0xFFADB5BD),
              ),
            ),
            const SizedBox(height: 5),
            ...expenses.map((expense) => _buildExpenseItem(
                  expense,
                  day,
                  expenses.indexOf(expense),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(ExpenseItem expense, int day, int index) {
    return GestureDetector(
      onTap: () => _togglePaymentStatus(day, index),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: expense.isPaid
                  ? const Color(0xFF28A745)
                  : const Color(0xFFDC3545),
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(
              expense.personIcon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${expense.amount}円',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF495057),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              expense.isPaid ? '☑️' : '□',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9ECEF), width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedNavIndex,
        onTap: _onNavTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A90E2),
        unselectedItemColor: const Color(0xFF6C757D),
        selectedFontSize: 14,
        unselectedFontSize: 14,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(
            icon: Text('🏠', style: TextStyle(fontSize: 24)),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Text('❗', style: TextStyle(fontSize: 24)),
            label: '未払い',
          ),
          BottomNavigationBarItem(
            icon: Text('📊', style: TextStyle(fontSize: 24)),
            label: 'サマリー',
          ),
          BottomNavigationBarItem(
            icon: Text('⚙️', style: TextStyle(fontSize: 24)),
            label: '設定',
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    // TODO: 支出入力画面への遷移
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('支出入力画面に移動します')),
    );
  }

  void _onDayTapped(int day) {
    // TODO: 日付詳細画面への遷移
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${day}日の詳細画面に移動します')),
    );
  }
}
