import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/person.dart';
import '../../models/expense_category.dart';
import '../../providers/categories_provider.dart';
import '../../providers/people_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/person_avatar.dart';
import '../../utils/category_visuals.dart';
import '../person/person_edit_dialog.dart';
import 'theme_color_screen.dart';

String _resolveThemeColorName(Color color) {
  for (final option in themeColorOptions) {
    if (option.color.value == color.value) {
      return option.name;
    }
  }
  return 'カスタムカラー';
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final people = ref.watch(peopleProvider);
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _SettingsSection(
            title: 'リマインド設定',
            children: [
              _SettingsSwitchTile(
                title: 'リマインド通知',
                subtitle: '毎日20:00に未払いがある場合に通知します',
                value: settings.reminderEnabled,
                icon: Icons.alarm,
                accentColor: colorScheme.primary,
                onChanged: (value) async {
                  final messenger = ScaffoldMessenger.of(context);
                  await ref
                      .read(settingsProvider.notifier)
                      .toggleReminder(value);
                  if (!messenger.mounted) {
                    return;
                  }
                  if (value) {
                    messenger.showSnackBar(
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
                accentColor: colorScheme.primary,
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
            children: [
              _SettingsSwitchTile(
                title: '全件支払いに予定を含める',
                subtitle: 'ホームの全件支払いボタンで予定も対象にします',
                value: settings.quickPayIncludesPlanned,
                icon: Icons.event,
                accentColor: colorScheme.primary,
                onChanged: (value) => ref
                    .read(settingsProvider.notifier)
                    .setQuickPayIncludesPlanned(value),
              ),
            ],
          ),
          _SettingsSection(
            title: '人の管理',
            children: [
              _SettingsListTile(
                title: '人の追加・編集',
                subtitle: people.isEmpty
                    ? 'まだ人が登録されていません'
                    : '登録済み: ${people.length}人',
                leadingIcon: Icons.person_add,
                accentColor: colorScheme.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _PersonManagementScreen(),
                  ),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'カテゴリー管理',
            children: [
              _SettingsListTile(
                title: 'カテゴリーの追加・編集',
                subtitle: '登録済み: ${categories.length}件',
                leadingIcon: Icons.category,
                accentColor: colorScheme.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _CategoryManagementScreen(),
                  ),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'テーマカラー',
            children: [
              _SettingsListTile(
                title: 'テーマカラー',
                subtitle: '現在: ${_resolveThemeColorName(settings.themeColor)}',
                leadingIcon: Icons.palette,
                accentColor: colorScheme.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ThemeColorScreen(),
                  ),
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: 'その他',
            children: [
              _SettingsListTile(
                title: 'アプリ情報',
                subtitle: 'バージョン情報、ライセンス等',
                leadingIcon: Icons.info_outline,
                accentColor: colorScheme.primary,
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;

        return AlertDialog(
          backgroundColor: const Color(0xFFFFFAF0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 48,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pay Check',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'バージョン 1.0.0',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('家族やグループの支払い予定と精算をまとめて管理できます。'),
              const SizedBox(height: 12),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                showLicensePage(
                  context: context,
                  applicationName: 'Pay Check',
                  applicationVersion: '1.0.0',
                );
              },
              child: const Text('View licenses'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8E8E93),
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.white,
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
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final bool enabled;
  final Color? accentColor;

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
      activeColor: Colors.white,
      activeTrackColor: accentColor ?? Theme.of(context).colorScheme.primary,
      inactiveTrackColor: const Color(0xFFEEEEEE),
      onChanged: enabled ? onChanged : null,
      secondary: icon == null
          ? null
          : Icon(
              icon,
              color: enabled
                  ? (accentColor ?? Theme.of(context).colorScheme.primary)
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
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData trailingIcon;
  final Color? accentColor;

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
          : Icon(
              leadingIcon,
              color: accentColor ?? Theme.of(context).colorScheme.primary,
            ),
      trailing: Icon(trailingIcon, color: Colors.grey.shade600),
      onTap: onTap,
    );
  }
}

class _CategoryManagementScreen extends ConsumerStatefulWidget {
  const _CategoryManagementScreen();

  @override
  ConsumerState<_CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<_CategoryManagementScreen> {
  Future<void> _addCategory() async {
    final name = await _showCategoryDialog();
    if (!mounted || name == null) {
      return;
    }
    final created =
        ref.read(categoriesProvider.notifier).addCategory(name.trim());
    _showFeedback(
      created
          ? 'カテゴリー「$name」を追加しました'
          : '追加に失敗しました（同名のカテゴリーが存在しないか確認してください）',
      isError: !created,
    );
  }

  Future<void> _editCategory(String original) async {
    final name = await _showCategoryDialog(initialValue: original);
    if (!mounted || name == null || name.trim() == original) {
      return;
    }
    final updated = ref
        .read(categoriesProvider.notifier)
        .renameCategory(original, name.trim());
    _showFeedback(
      updated
          ? 'カテゴリーを「$name」に変更しました'
          : '変更に失敗しました（同名のカテゴリーが存在しないか確認してください）',
      isError: !updated,
    );
  }

  Future<void> _deleteCategory(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: Text('カテゴリー「$category」を削除しますか？'),
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

    final removed =
        ref.read(categoriesProvider.notifier).removeCategory(category);
    _showFeedback(
      removed
          ? 'カテゴリー「$category」を削除しました（既存の記録は「${ExpenseCategory.fallback}」になります）'
          : '削除に失敗しました',
      isError: !removed,
    );
  }

  Future<String?> _showCategoryDialog({String? initialValue}) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _CategoryFormDialog(
          initialValue: initialValue,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onSave: (value) => Navigator.of(dialogContext).pop(value),
        );
      },
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('カテゴリー管理'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isFallback = category == ExpenseCategory.fallback;
          final visual = categoryVisualFor(category);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: visual.color.withOpacity(0.15),
                foregroundColor: visual.color,
                child: Icon(visual.icon),
              ),
              title: Text(category,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: isFallback
                  ? const Text('未選択時に自動で設定されます',
                      style: TextStyle(fontSize: 12))
                  : null,
              trailing: isFallback
                  ? const Chip(label: Text('既定'))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: '編集',
                          onPressed: () => _editCategory(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: '削除',
                          onPressed: () => _deleteCategory(category),
                        ),
                      ],
                    ),
              onTap: isFallback ? null : () => _editCategory(category),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({
    this.initialValue,
    required this.onSave,
    required this.onCancel,
  });

  final String? initialValue;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _controller;

  bool get _isEditing => widget.initialValue != null;
  bool get _isInputValid => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSave() {
    if (!_isInputValid) {
      return;
    }
    widget.onSave(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFAF0),
      title: Text(_isEditing ? 'カテゴリーを編集' : 'カテゴリーを追加'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'カテゴリー名'),
        onSubmitted: (_) => _handleSave(),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isInputValid ? _handleSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

class PersonManagementScreen extends StatelessWidget {
  const PersonManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PersonManagementScreen();
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
      builder: (context) {
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

  Future<void> _showPersonDialog({Person? person}) async {
    final result = await showDialog<PersonFormResult>(
      context: context,
      builder: (context) {
        return PersonEditDialog(person: person);
      },   // builder を閉じる
    );   // showDialog を閉じる

    if (!mounted || result == null) {
      return;
    }

    final notifier = ref.read(peopleProvider.notifier);
    if (person == null) {
      final created = notifier.addPerson(
        result.name,
        emoji: result.emoji,
        photoPath: result.photoPath,
        iconAsset: result.iconAsset,
      );
      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${created.name}を追加しました')),
        );
      }
    } else {
      notifier.updatePerson(
        person.copyWith(
          name: result.name,
          emoji: result.emoji,
          photoPath: result.photoPath,
          iconAsset: result.iconAsset,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.name}を更新しました')),
      );
    }
  }

  Widget _buildAvatar(Person person) {
    return PersonAvatar(
      person: person,
      size: 40,
      backgroundColor: kPersonAvatarBackgroundColor,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
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
                      'アプリを使用する人を登録しましょう',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'このアプリを使う家族や同居人を登録してください\n'
                      '右下のボタンから追加できます',
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
                  color: Colors.white,
                  child: ListTile(
                    leading: _buildAvatar(person),
                    title: Text(
                      person.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      (person.photoPath != null && person.photoPath!.isNotEmpty)
                          ? '写真を使用'
                          : (person.iconAsset != null &&
                                  person.iconAsset!.isNotEmpty)
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
        icon: Icon(
          Icons.person_add,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: const Text(
          '人を追加',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
