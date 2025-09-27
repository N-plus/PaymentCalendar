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
      appBar: AppBar(
        title: const Text('設定'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SettingsSection(
            title: 'リマインド設定',
            icon: Icons.notifications,
            children: [
              _SettingsSwitchTile(
                title: 'リマインド通知',
                subtitle: '毎日20:00に未払いがある場合に通知します',
                value: settings.reminderEnabled,
                icon: Icons.alarm,
                onChanged: (value) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .toggleReminder(value);
                  if (value && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('リマインド通知を有効にしました'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              _SettingsSwitchTile(
                title: '予定前日通知',
                subtitle: '予定の前日20:00にも通知します',
                value: settings.plannedReminderEnabled,
                icon: Icons.schedule,
                enabled: settings.reminderEnabled,
                onChanged: (value) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .togglePlannedReminder(value);
                },
              ),
            ],
          ),
          _SettingsSection(
            title: '支払い設定',
            icon: Icons.payment,
            children: [
              _SettingsSwitchTile(
                title: '全件支払いに予定を含める',
                subtitle: 'ホームの全件支払いボタンで予定も対象にします',
                value: settings.quickPayIncludesPlanned,
                icon: Icons.event,
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setQuickPayIncludesPlanned(value),
              ),
            ],
          ),
          _SettingsSection(
            title: '人の管理',
            icon: Icons.people,
            children: [
              _SettingsListTile(
                title: '人の追加・編集',
                subtitle: people.isEmpty
                    ? 'まだ人が登録されていません'
                    : '登録済み: ${people.length}人',
                leadingIcon: Icons.person_add,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _PersonManagementScreen(),
                  ),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'その他',
            icon: Icons.more_horiz,
            children: [
              _SettingsListTile(
                title: 'アプリ情報',
                subtitle: 'バージョン情報、ライセンス等',
                leadingIcon: Icons.info_outline,
                onTap: () => _showAppInfo(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAppInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Payment Calendar',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet),
      children: const [
        SizedBox(height: 8),
        Text('家族やグループの支払い予定と精算をまとめて管理できます。'),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tile = SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      value: enabled ? value : false,
      onChanged: enabled ? onChanged : null,
      secondary: icon == null
          ? null
          : Icon(
              icon,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade400,
            ),
    );

    return tile;
  }
}

class _SettingsListTile extends StatelessWidget {
  const _SettingsListTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leadingIcon,
    this.trailingIcon = Icons.chevron_right,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      leading: leadingIcon == null
          ? null
          : Icon(leadingIcon, color: Theme.of(context).colorScheme.primary),
      trailing: Icon(trailingIcon, color: Colors.grey.shade600),
      onTap: onTap,
    );
  }
}

class _PersonManagementScreen extends ConsumerStatefulWidget {
  const _PersonManagementScreen();

  @override
  ConsumerState<_PersonManagementScreen> createState() =>
      _PersonManagementScreenState();
}

class _PersonManagementScreenState
    extends ConsumerState<_PersonManagementScreen> {
  static const _emptyEmojiPlaceholder = '？';

  void _addPerson() {
    _showPersonDialog();
  }

  void _editPerson(Person person) {
    _showPersonDialog(person: person);
  }

  Future<void> _deletePerson(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(peopleProvider.notifier).removePerson(person);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${person.name}を削除しました'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: () {
              ref.read(peopleProvider.notifier).restorePerson(person);
            },
          ),
        ),
      );
    }
  }

  Future<void> _showPersonDialog({Person? person}) async {
    final result = await showDialog<_PersonFormResult>(
      context: context,
      builder: (context) => _PersonEditDialog(person: person),
    );

    if (!mounted || result == null) {
      return;
    }

    final notifier = ref.read(peopleProvider.notifier);
    if (person == null) {
      final created = notifier.addPerson(result.name,
          emoji: result.emoji, photoPath: result.photoPath);
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${created.name}を追加しました')),
        );
      }
    } else {
      notifier.updatePerson(
        person.copyWith(name: result.name, emoji: result.emoji),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.name}を更新しました')),
      );
    }
  }

  Widget _buildAvatar(Person person) {
    if (person.emoji != null && person.emoji!.isNotEmpty) {
      return CircleAvatar(child: Text(person.emoji!));
    }
    final display = person.name.characters.isNotEmpty
        ? person.name.characters.first
        : _emptyEmojiPlaceholder;
    return CircleAvatar(child: Text(display));
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('人の管理'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: people.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      '登録されている人がいません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '右下のボタンから人を追加できます',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: people.length,
              itemBuilder: (context, index) {
                final person = people[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: _buildAvatar(person),
                    title: Text(
                      person.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      person.emoji == null || person.emoji!.isEmpty
                          ? '絵文字アイコン未設定'
                          : '絵文字アイコンを使用',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
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
                            title: Text('削除',
                                style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _editPerson(person),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPerson,
        icon: const Icon(Icons.person_add),
        label: const Text('人を追加'),
      ),
    );
  }
}

class _PersonFormResult {
  _PersonFormResult({
    required this.name,
    this.emoji,
    this.photoPath,
  });

  final String name;
  final String? emoji;
  final String? photoPath;
}

class _PersonEditDialog extends StatefulWidget {
  const _PersonEditDialog({this.person});

  final Person? person;

  @override
  State<_PersonEditDialog> createState() => _PersonEditDialogState();
}

class _PersonEditDialogState extends State<_PersonEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;
  final _formKey = GlobalKey<FormState>();

  final List<String> _suggestedEmojis = const [
    '😀',
    '👩',
    '👨',
    '🧒',
    '👵',
    '🐶',
    '🐱',
    '🎓',
    '💼',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _emojiController =
        TextEditingController(text: widget.person?.emoji ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _selectEmoji(String emoji) {
    setState(() {
      _emojiController.text = emoji;
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    Navigator.of(context).pop(
      _PersonFormResult(
        name: _nameController.text.trim(),
        emoji: _emojiController.text.trim().isEmpty
            ? null
            : _emojiController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.person == null ? '人を追加' : '人を編集',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '名前',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '名前を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emojiController,
                  decoration: const InputDecoration(
                    labelText: 'アイコン（絵文字）',
                    hintText: '例: 😀',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: const [],
                ),
                const SizedBox(height: 12),
                Text(
                  '候補から選択する',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedEmojis
                      .map(
                        (emoji) => ChoiceChip(
                          label: Text(emoji, style: const TextStyle(fontSize: 20)),
                          selected: _emojiController.text == emoji,
                          onSelected: (_) => _selectEmoji(emoji),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('保存'),
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
