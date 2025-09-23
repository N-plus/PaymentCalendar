import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/person.dart';
import '../../providers/people_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final people = ref.watch(peopleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('リマインド通知'),
            subtitle: const Text('毎日20:00に未払い件数がある場合に通知します'),
            value: settings.reminderEnabled,
            onChanged: (value) async {
              await ref.read(settingsProvider.notifier).toggleReminder(value);
            },
          ),
          SwitchListTile(
            title: const Text('予定前日20:00にも通知'),
            value: settings.plannedReminderEnabled,
            onChanged: settings.reminderEnabled
                ? (value) async {
                    await ref
                        .read(settingsProvider.notifier)
                        .togglePlannedReminder(value);
                  }
                : null,
          ),
          SwitchListTile(
            title: const Text('クイック支払いで予定も対象にする'),
            subtitle: const Text('ホームで「予定を含める」がONのときに予定も一括支払い'),
            value: settings.quickPayIncludesPlanned,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .setQuickPayIncludesPlanned(value),
          ),
          const SizedBox(height: 24),
          Text('人の管理',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final person in people)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    person.emoji ??
                        (person.name.characters.isNotEmpty
                            ? person.name.characters.first
                            : '?'),
                  ),
                ),
                title: Text(person.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editPerson(context, ref, person),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePerson(context, ref, person),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => _addPerson(context, ref),
            icon: const Icon(Icons.person_add),
            label: const Text('人を追加'),
          ),
          const SizedBox(height: 24),
          Text('アプリ情報',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Payment Calendar v1.0.0'),
        ],
      ),
    );
  }

  Future<void> _addPerson(BuildContext context, WidgetRef ref) async {
    final result = await _showPersonDialog(context);
    if (result != null) {
      ref
          .read(peopleProvider.notifier)
          .addPerson(result.name, emoji: result.emoji);
    }
  }

  Future<void> _editPerson(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    final result = await _showPersonDialog(context, person: person);
    if (result != null) {
      ref
          .read(peopleProvider.notifier)
          .updatePerson(person.copyWith(name: result.name, emoji: result.emoji));
    }
  }

  Future<void> _deletePerson(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除'),
        content: Text('${person.name}を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(peopleProvider.notifier).removePerson(person);
    }
  }

  Future<_PersonInput?> _showPersonDialog(BuildContext context,
      {Person? person}) async {
    final nameController = TextEditingController(text: person?.name ?? '');
    final emojiController = TextEditingController(text: person?.emoji ?? '');
    final result = await showDialog<_PersonInput>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(person == null ? '人を追加' : '人を編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '名前'),
              ),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(labelText: 'アイコン（絵文字）'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  _PersonInput(
                    name: nameController.text.trim(),
                    emoji: emojiController.text.trim().isEmpty
                        ? null
                        : emojiController.text.trim(),
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    return result;
  }
}

class _PersonInput {
  _PersonInput({required this.name, this.emoji});

  final String name;
  final String? emoji;
}
