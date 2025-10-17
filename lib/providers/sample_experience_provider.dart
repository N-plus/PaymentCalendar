import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

final sampleExperienceProvider =
    StateNotifierProvider<SampleExperienceNotifier, bool>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return SampleExperienceNotifier(preferences);
});

class SampleExperienceNotifier extends StateNotifier<bool> {
  SampleExperienceNotifier(this._preferences)
      : super(_preferences.getBool(_hasAddedRealExpenseKey) ?? false);

  static const _hasAddedRealExpenseKey = 'sample_experience_has_real_expense';

  final SharedPreferences _preferences;

  Future<void> markCompleted() async {
    if (state) {
      return;
    }
    state = true;
    await _preferences.setBool(_hasAddedRealExpenseKey, true);
  }
}
