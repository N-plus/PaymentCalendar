import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_category.dart';
import 'expenses_provider.dart';

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<String>>((ref) {
  return CategoriesNotifier(ref);
});

class CategoriesNotifier extends StateNotifier<List<String>> {
  CategoriesNotifier(this._ref)
      : super(List<String>.from(ExpenseCategory.defaults));

  final Ref _ref;

  bool addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) {
      return false;
    }
    final updated = [...state];
    final fallbackIndex = updated.indexOf(ExpenseCategory.fallback);
    if (fallbackIndex >= 0) {
      updated.insert(fallbackIndex, trimmed);
    } else {
      updated.add(trimmed);
    }
    state = updated;
    return true;
  }

  bool renameCategory(String original, String updatedName) {
    if (original == ExpenseCategory.fallback) {
      return false;
    }
    final trimmed = updatedName.trim();
    if (trimmed.isEmpty || trimmed == original || state.contains(trimmed)) {
      return false;
    }
    state = [
      for (final category in state)
        if (category == original) trimmed else category,
    ];
    _ref
        .read(expensesProvider.notifier)
        .replaceCategory(original, trimmed);
    return true;
  }

  bool removeCategory(String name) {
    if (name == ExpenseCategory.fallback) {
      return false;
    }
    state = state.where((category) => category != name).toList();
    _ref
        .read(expensesProvider.notifier)
        .replaceCategory(name, ExpenseCategory.fallback);
    return true;
  }
}
