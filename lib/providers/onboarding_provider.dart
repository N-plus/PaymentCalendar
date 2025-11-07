import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_check/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> reset() async {
    state = false;
    await _preferences.remove(_onboardingKey);
  }
}
