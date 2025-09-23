import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(locale: 'ja_JP', symbol: '¥');
final _dateFormat = DateFormat('yyyy/MM/dd');

String formatCurrency(int amount) => _currencyFormat.format(amount);

String formatDate(DateTime date) => _dateFormat.format(date);
