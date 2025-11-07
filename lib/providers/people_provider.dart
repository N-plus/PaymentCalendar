import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_check/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';

final peopleProvider = StateNotifierProvider<PeopleNotifier, List<Person>>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return PeopleNotifier(preferences);
});

class PeopleNotifier extends StateNotifier<List<Person>> {
  PeopleNotifier(this._preferences) : super(const []) {
    _initialization = _restoreInitialPeople();
  }

  static const _storageKey = 'people_data';
  final _uuid = const Uuid();
  final SharedPreferences _preferences;
  late final Future<void> _initialization;

  Future<void> _restoreInitialPeople() async {
    final jsonString = _preferences.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      state = const [];
      return;
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      state = [
        for (final dynamic item in decoded)
          Person.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      state = const [];
    }
  }

  Future<void> ensureInitialized() => _initialization;

  Future<void> _savePeople() async {
    final encoded = jsonEncode([
      for (final person in state) person.toJson(),
    ]);
    await _preferences.setString(_storageKey, encoded);
  }

  int get count => state.length;

  Person? addPerson(
    String name, {
    String? emoji,
    String? photoPath,
    String? iconAsset,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final newPerson = Person(
      id: _uuid.v4(),
      name: trimmed,
      emoji: emoji,
      photoPath: photoPath,
      iconAsset: iconAsset,
    );
    state = [...state, newPerson];
    unawaited(_savePeople());
    return newPerson;
  }

  void updatePerson(Person updated) {
    state = [
      for (final person in state)
        if (person.id == updated.id) updated else person,
    ];
    unawaited(_savePeople());
  }

  void removePerson(Person target) {
    state = state.where((person) => person.id != target.id).toList();
    unawaited(_savePeople());
  }

  void restorePerson(Person person) {
    state = [...state, person];
    unawaited(_savePeople());
  }
}
