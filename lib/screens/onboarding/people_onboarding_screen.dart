import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/person.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/people_provider.dart';
import '../../widgets/person_avatar.dart';
import '../person/person_edit_dialog.dart';

class PeopleOnboardingScreen extends ConsumerStatefulWidget {
  const PeopleOnboardingScreen({
    super.key,
    this.onCompleted,
    this.onLater,
  });

  final Future<void> Function()? onCompleted;
  final Future<void> Function()? onLater;

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

  void _closeIfPossible() {
    if (!mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _defaultComplete() async {
    await ref.read(peopleOnboardingProvider.notifier).complete();
    _closeIfPossible();
  }

  Future<void> _handleCompleted() async {
    if (widget.onCompleted != null) {
      await widget.onCompleted!();
      _closeIfPossible();
      return;
    }
    await _defaultComplete();
  }

  Future<void> _handleLater() async {
    if (widget.onLater != null) {
      await widget.onLater!();
      _closeIfPossible();
      return;
    }
    await _defaultComplete();
  }

  Widget _buildPeopleList(List<Person> people) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (people.isEmpty) {
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
              'アプリを使用する人を登録しましょう',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'このアプリを使う家族を登録してください\n'
              '『人を追加』ボタンから登録できます',
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
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PersonAvatar(
                person: person,
                size: 44,
                backgroundColor: kPersonAvatarBackgroundColor,
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (person.photoPath != null && person.photoPath!.isNotEmpty)
                          ? '写真を使用'
                          : (person.iconAsset != null &&
                                  person.iconAsset!.isNotEmpty)
                              ? 'アイコン画像を使用'
                              : person.emoji == null || person.emoji!.isEmpty
                                  ? 'アイコン未設定'
                                  : '絵文字アイコンを使用',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _editPerson(person),
                tooltip: '編集',
                color: colorScheme.primary,
                icon: const Icon(Icons.edit_outlined),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _deletePerson(person),
                tooltip: '削除',
                color: colorScheme.error,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
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

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addPerson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: Icon(
                    Icons.person_add_alt_1,
                    color: colorScheme.primary,
                  ),
                  label: const Text('人を追加'),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '登録済みの人',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                        onPressed: _handleLater,
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
                            people.isEmpty ? null : () => _handleCompleted(),
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
      ),
    );
  }
}
