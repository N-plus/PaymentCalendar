import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/expense.dart';
import '../models/person.dart';

class StorageState {
  StorageState({
    required this.persons,
    required this.expenses,
    required this.remindDaily,
    required this.remindPlanned,
  });

  final List<Person> persons;
  final List<Expense> expenses;
  final bool remindDaily;
  final bool remindPlanned;
}

class LocalStorageService {
  static const _fileName = 'payment_calendar.json';

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode({
        'persons': [],
        'expenses': [],
        'reminders': {
          'daily': false,
          'planned': false,
        },
      }));
    }
    return file;
  }

  Future<StorageState> load() async {
    try {
      final file = await _getStorageFile();
      final content = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(content) as Map<String, dynamic>;
      final persons = (jsonMap['persons'] as List<dynamic>? ?? const [])
          .map((dynamic e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
      final expenses = (jsonMap['expenses'] as List<dynamic>? ?? const [])
          .map((dynamic e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
      final reminders = jsonMap['reminders'] as Map<String, dynamic>? ?? const {};
      return StorageState(
        persons: persons,
        expenses: expenses,
        remindDaily: reminders['daily'] as bool? ?? false,
        remindPlanned: reminders['planned'] as bool? ?? false,
      );
    } catch (e) {
      return StorageState(
        persons: [],
        expenses: [],
        remindDaily: false,
        remindPlanned: false,
      );
    }
  }

  Future<void> save({
    required List<Person> persons,
    required List<Expense> expenses,
    required bool remindDaily,
    required bool remindPlanned,
  }) async {
    final file = await _getStorageFile();
    final data = {
      'persons': persons.map((p) => p.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'reminders': {
        'daily': remindDaily,
        'planned': remindPlanned,
      },
    };
    await file.writeAsString(jsonEncode(data));
  }
}
