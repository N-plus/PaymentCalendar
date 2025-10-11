import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/person.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/people_provider.dart';
import '../../widgets/person_avatar.dart';
import '../person/person_edit_dialog.dart';

class PeopleOnboardingScreen extends ConsumerStatefulWidget {
  const PeopleOnboardingScreen({super.key});

  @override
  ConsumerState<PeopleOnboardingScreen> createState() =>
      _PeopleOnboardingScreenState();
}

class _PeopleOnboardingScreenState
    extends ConsumerState<PeopleOnboardingScreen> {
  Future<void> _addPerson() async {
    final result = await showDialog<PersonFormResult>(
      context: context,
      builder: (_) => const PersonEditDialog(),
    );

    if (!mounted || result == null) {
      return;
    }

    final created = ref.read(peopleProvider.notifier).addPerson(
          result.name,
          emoji: result.emoji,
          photoPath: result.photoPath,
          iconAsset: result.iconAsset,
        );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.name}を追加しました')),
      );
    }
  }

  Future<void> _editPerson(Person person) async {
    final result = await showDialog<PersonFormResult>(
      context: context,
      builder: (_) => PersonEditDialog(person: person),
    );

    if (!mounted || result == null) {
      return;
    }

    ref.read(peopleProvider.notifier).updatePerson(
          person.copyWith(
            name: result.name,
            emoji: result.emoji,
            photoPath: result.photoPath,
            iconAsset: result.iconAsset,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.name}を更新しました')),
      );
    }
  }

  Future<void> _deletePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('${person.name}を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    ref.read(peopleProvider.notifier).removePerson(person);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.name}を削除しました')),
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(peopleOnboardingProvider.notifier).complete();
  }

  Widget _buildPeopleList(List<Person> people) {
    if (people.isEmpty) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'まだ人が登録されていません',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '「人を追加」ボタンから登録できます',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: people.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final person = people[index];
        return Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          child: ListTile(
            leading: PersonAvatar(
              person: person,
              size: 40,
              backgroundColor: kPersonAvatarBackgroundColor,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            title: Text(
              person.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              (person.photoPath != null && person.photoPath!.isNotEmpty)
                  ? '写真を使用'
                  : (person.iconAsset != null && person.iconAsset!.isNotEmpty)
                      ? 'アイコン画像を使用'
                      : person.emoji == null || person.emoji!.isEmpty
                          ? 'アイコン未設定'
                          : '絵文字アイコンを使用',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: PopupMenuButton<String>(
              color: const Color(0xFFF2F2F2),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editPerson(person);
                    break;
                  case 'delete':
                    _deletePerson(person);
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('編集'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text(
                      '削除',
                      style: TextStyle(color: Colors.red),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            onTap: () => _editPerson(person),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('人を登録'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _addPerson,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text(
                  '人を追加',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPeopleList(people),
              ),
              const SizedBox(height: 16),
              Text(
                '※あとで『設定 ＞ 人の管理』から登録・変更できます',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _completeOnboarding,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('後で設定する'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          people.isEmpty ? null : () => _completeOnboarding(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('完了'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
