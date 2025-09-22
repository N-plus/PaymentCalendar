import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/expense_provider.dart';
import '../widgets/person_avatar.dart';
import '../widgets/person_editor_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  Future<void> _deletePerson(BuildContext context, Person person) async {
    final provider = context.read<ExpenseProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除しますか？'),
          content: Text('${person.name} を削除すると関連する記録も消えます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await provider.deletePerson(person.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('リマインド', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                title: const Text('毎日20:00に通知'),
                subtitle: const Text('未払いがある場合のみ通知されます'),
                value: provider.remindDaily,
                onChanged: (value) async {
                  await provider.setDailyReminder(value);
                },
              ),
              SwitchListTile.adaptive(
                title: const Text('予定の前日20:00にも通知'),
                subtitle: const Text('日次リマインドがONのときに有効'),
                value: provider.remindPlanned,
                onChanged: provider.remindDaily
                    ? (value) async {
                        await provider.setPlannedReminder(value);
                      }
                    : null,
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Text('人の管理', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await showDialog<Person>(
                        context: context,
                        builder: (_) => const PersonEditorDialog(),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('追加'),
                  ),
                ],
              ),
              if (provider.persons.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('まだ人が登録されていません。'),
                ),
              ...provider.persons.map(
                (person) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: PersonAvatar(person: person, size: 40),
                    title: Text(person.name),
                    subtitle: Text(
                      person.avatarType == AvatarType.photo ? '写真' : 'アイコン',
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await showDialog<Person>(
                              context: context,
                              builder: (_) => PersonEditorDialog(person: person),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deletePerson(context, person),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const AboutListTile(
                applicationName: 'Payment Calendar',
                applicationVersion: '1.0.0',
                applicationLegalese: 'プライバシー重視のローカル家計簿',
              ),
            ],
          );
        },
      ),
    );
  }
}
