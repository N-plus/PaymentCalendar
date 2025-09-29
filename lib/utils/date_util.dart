import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
final _dateFormat = DateFormat('yyyy/MM/dd');
final _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

String formatCurrency(int amount) => _currencyFormat.format(amount);

String formatDate(DateTime date) => _dateFormat.format(date);

String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
