import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'expense_input_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  int _totalAmountForDay(List<Expense> expenses) =>
      expenses.fold(0, (sum, e) => sum + e.amount);

  String _iconFor(Expense e) => String.fromCharCode(e.personIcon.runes.first);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final dayExpenses =
        _selectedDay != null ? provider.expensesOn(_selectedDay!) : <Expense>[];
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TableCalendar<Expense>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: provider.expensesOn,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              rowHeight: 60,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 16, color: Colors.white),
                weekendStyle: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle:
                    const TextStyle(color: Colors.white70, fontSize: 18),
                holidayTextStyle:
                    const TextStyle(color: Colors.white70, fontSize: 18),
                defaultTextStyle:
                    const TextStyle(color: Colors.white, fontSize: 18),
                selectedTextStyle:
                    TextStyle(color: Colors.blue[600], fontSize: 18),
                todayTextStyle:
                    TextStyle(color: Colors.blue[600], fontSize: 18),
                selectedDecoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                todayDecoration: const BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                formatButtonTextStyle: TextStyle(color: Colors.blue[600]),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: Colors.white),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, _) {
                  final expenses = provider.expensesOn(date);
                  if (expenses.isEmpty) return null;
                  final total = _totalAmountForDay(expenses);
                  final icons = expenses
                      .map(_iconFor)
                      .toSet()
                      .take(3)
                      .toList();
                  final anyUnpaid = expenses.any((e) => !e.isPaid);
                  return Container(
                    margin: const EdgeInsets.only(top: 5),
                    child: Column(
                      children: [
                        Text('¥$total',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final icon in icons)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                child: Text(icon,
                                    style: const TextStyle(fontSize: 8)),
                              ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              child: Text(
                                anyUnpaid ? '□' : '☑️',
                                style: const TextStyle(fontSize: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: _selectedDay == null
                ? Center(
                    child: Text(
                      '日付を選択して詳細を確認してください',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  )
                : _buildExpenseList(dayExpenses, provider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpenseInputScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses, ExpenseProvider provider) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'この日の支出はありません',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final e = expenses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                _iconFor(e),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text('¥${e.amount}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('${e.category} | ${e.person}'),
            trailing: GestureDetector(
              onTap: () => provider.togglePaid(e),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(e.isPaid ? '☑️' : '□',
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
        );
      },
    );
  }
}
