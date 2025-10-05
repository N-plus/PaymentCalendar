import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/person.dart';
import '../../providers/people_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/person_avatar.dart';
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
      builder: (_) {
        return const AboutDialog(
          applicationName: 'Pay Check',
          applicationVersion: '1.0.0',
          applicationIcon: Icon(Icons.account_balance_wallet),
          children: [
            SizedBox(height: 8),
            Text('家族やグループの支払い予定と精算をまとめて管理できます。'),
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
    final result = await showDialog<_PersonFormResult>(
      context: context,
      builder: (context) {
        return _PersonEditDialog(person: person);
      },   // builder を閉じる
    );   // showDialog を閉じる

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
        person.copyWith(
          name: result.name,
          emoji: result.emoji,
          photoPath: result.photoPath,
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
                          : person.emoji == null || person.emoji!.isEmpty
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
  final ImagePicker _picker = ImagePicker();

  final List<String> _suggestedEmojis = const [
    '😀',
    '👩',
    '👨',
    '🧒',
    '👵',
    '🐶',
    '🐱',
    '👨‍🏫',
    '👴',
  ];

  XFile? _selectedPhoto;
  String? _existingPhotoPath;
  bool _usePhoto = false;
  bool _submitting = false;
  bool _showPhotoError = false;

  String? get _currentPhotoPath => _selectedPhoto?.path ?? _existingPhotoPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _emojiController =
        TextEditingController(text: widget.person?.emoji ?? '');
    _existingPhotoPath = widget.person?.photoPath;
    _usePhoto = (_existingPhotoPath != null && _existingPhotoPath!.isNotEmpty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _selectEmoji(String emoji) {
    _setUsePhoto(false);
    setState(() {
      _emojiController.text = emoji;
    });
  }

  void _setUsePhoto(bool value) {
    if (_usePhoto == value) {
      return;
    }
    setState(() {
      _usePhoto = value;
      _showPhotoError = false;
      if (!value) {
        _selectedPhoto = null;
        _existingPhotoPath = null;
      }
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) {
        return;
      }
      setState(() {
        _selectedPhoto = picked;
        _existingPhotoPath = null;
        _usePhoto = true;
        _showPhotoError = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真の取得に失敗しました')),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhoto = null;
      _existingPhotoPath = null;
      _showPhotoError = false;
    });
  }

  Future<String?> _saveFile(XFile file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final newPath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final saved = await File(file.path).copy(newPath);
      return saved.path;
    } catch (_) {
      return null;
    }
  }

  ImageProvider? _buildPhotoPreview() {
    final path = _currentPhotoPath;
    if (path == null || path.isEmpty) {
      return null;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return FileImage(file);
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _submitting = true;
      _showPhotoError = false;
    });

    final name = _nameController.text.trim();
    String? emoji;
    String? photoPath;

    if (_usePhoto) {
      if (_selectedPhoto != null) {
        final saved = await _saveFile(_selectedPhoto!);
        if (saved == null) {
          if (mounted) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('写真の保存に失敗しました')),
            );
          }
          return;
        }
        photoPath = saved;
      } else if (_existingPhotoPath != null && _existingPhotoPath!.isNotEmpty) {
        photoPath = _existingPhotoPath;
      } else {
        if (mounted) {
          setState(() {
            _showPhotoError = true;
            _submitting = false;
          });
        }
        return;
      }
    } else {
      emoji = _emojiController.text.trim().isEmpty
          ? null
          : _emojiController.text.trim();
      photoPath = null;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      _PersonFormResult(
        name: name,
        emoji: emoji,
        photoPath: photoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoPreview = _buildPhotoPreview();
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: const Color(0xFFFFFAF0),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + viewInsetsBottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                              labelStyle: TextStyle(color: Colors.black87),
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
                          Text(
                            'アイコンの種類',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('絵文字'),
                                selected: !_usePhoto,
                                selectedColor: Colors.white,
                                labelStyle: const TextStyle(color: Colors.black),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: !_usePhoto
                                        ? Colors.black26
                                        : Colors.transparent,
                                  ),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    _setUsePhoto(false);
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text('写真'),
                                selected: _usePhoto,
                                selectedColor: Colors.white,
                                labelStyle: const TextStyle(color: Colors.black),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: _usePhoto
                                        ? Colors.black26
                                        : Colors.transparent,
                                  ),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    _setUsePhoto(true);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_usePhoto) ...[
                            Center(
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor:
                                    _usePhoto ? Colors.white : null,
                                backgroundImage: photoPreview,
                                child: photoPreview == null
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                              ),
                            ),
                            if (_showPhotoError) ...[
                              const SizedBox(height: 8),
                              Text(
                                '写真を選択してください',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _submitting
                                      ? null
                                      : () => _pickPhoto(ImageSource.gallery),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                  ),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('アルバムから選択'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _submitting
                                      ? null
                                      : () => _pickPhoto(ImageSource.camera),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                  ),
                                  icon: const Icon(Icons.photo_camera),
                                  label: const Text('カメラで撮影'),
                                ),
                                if (_currentPhotoPath != null)
                                  OutlinedButton.icon(
                                    onPressed: _submitting ? null : _removePhoto,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      side: const BorderSide(color: Colors.black),
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('写真を削除'),
                                  ),
                              ],
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _emojiController,
                              decoration: const InputDecoration(
                                labelText: 'アイコン（絵文字）',
                                hintText: '例: 😀',
                                border: OutlineInputBorder(),
                                labelStyle: TextStyle(color: Colors.black),
                              ),
                              style: const TextStyle(color: Colors.black),
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
                                    (emoji) {
                                      final isSelected =
                                          _emojiController.text == emoji;
                                      return ChoiceChip(
                                        label: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        selected: isSelected,
                                        selectedColor: Colors.white,
                                        labelStyle:
                                            const TextStyle(color: Colors.black),
                                        shape: StadiumBorder(
                                          side: BorderSide(
                                            color: isSelected
                                                ? Colors.black26
                                                : Colors.transparent,
                                          ),
                                        ),
                                        onSelected: (_) => _selectEmoji(emoji),
                                      );
                                    },
                                  )
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'キャンセル',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
