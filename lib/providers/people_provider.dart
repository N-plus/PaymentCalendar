import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/person.dart';

final peopleProvider = StateNotifierProvider<PeopleNotifier, List<Person>>((ref) {
  return PeopleNotifier();
});

class PeopleNotifier extends StateNotifier<List<Person>> {
  PeopleNotifier() : super(const []) {
    _initialization = _restoreInitialPeople();
  }

  final _uuid = const Uuid();
  late final Future<void> _initialization;

  Future<void> _restoreInitialPeople() async {
    // ここで永続化された人の情報を読み込む場合は処理を追加します。
  }

  Future<void> ensureInitialized() => _initialization;

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
    return newPerson;
  }

  void updatePerson(Person updated) {
    state = [
      for (final person in state)
        if (person.id == updated.id) updated else person,
    ];
  }

  void removePerson(Person target) {
    state = state.where((person) => person.id != target.id).toList();
  }

  void restorePerson(Person person) {
    state = [...state, person];
  }
}
