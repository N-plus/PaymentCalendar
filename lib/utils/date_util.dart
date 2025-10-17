import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
final _dateFormat = DateFormat('yyyy/MM/dd');
final _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

DateTime startOfTodayLocal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime endOfTodayLocal() =>
    startOfTodayLocal().add(const Duration(days: 1)).subtract(
          const Duration(milliseconds: 1),
        );

bool isFutureDate(DateTime date) => date.toLocal().isAfter(endOfTodayLocal());

String formatCurrency(int amount) => _currencyFormat.format(amount);

String formatDate(DateTime date) => _dateFormat.format(date);

String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
