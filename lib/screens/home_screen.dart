import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/expense_provider.dart';
import 'expense_input_screen.dart';
import 'day_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DayDetailScreen(day: selectedDay)),
          );
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final expenses = provider.expensesOn(date);
            if (expenses.isEmpty) return const SizedBox();
            final total =
                expenses.fold<int>(0, (prev, e) => prev + e.amount);
            final icons =
                expenses.map((e) => e.person).toSet().join();
            final paid = expenses.every((e) => e.isPaid);
            return Column(
              children: [
                Text('¥$total', style: const TextStyle(fontSize: 10)),
                Text(icons, style: const TextStyle(fontSize: 12)),
                Icon(
                  paid ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 12,
                ),
              ],
            );
          },
        ),
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
}
