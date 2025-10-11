import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

final peopleOnboardingProvider =
    StateNotifierProvider<PeopleOnboardingNotifier, bool>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return PeopleOnboardingNotifier(preferences);
});

class PeopleOnboardingNotifier extends StateNotifier<bool> {
  PeopleOnboardingNotifier(this._preferences)
      : super(_preferences.getBool(_onboardingKey) ?? false);

  static const _onboardingKey = 'onboarding_people_done';

  final SharedPreferences _preferences;

  Future<void> complete() async {
    state = true;
    await _preferences.setBool(_onboardingKey, true);
  }
}
