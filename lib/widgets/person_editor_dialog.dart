import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../providers/expense_provider.dart';

class PersonEditorDialog extends StatefulWidget {
  const PersonEditorDialog({
    super.key,
    this.person,
  });

  final Person? person;

  @override
  State<PersonEditorDialog> createState() => _PersonEditorDialogState();
}

class _PersonEditorDialogState extends State<PersonEditorDialog> {
  late TextEditingController _nameController;
  late AvatarType _avatarType;
  String? _photoUri;
  String? _iconKey;

  final List<String> _iconCandidates = const [
    '👩', '👨', '🧒', '👵', '👴', '🧑‍🍳', '🧑‍💻', '🧑‍🎓', '🐱', '🐶', '🐼', '🦊', '🐧', '🦁'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _avatarType = widget.person?.avatarType ?? AvatarType.icon;
    _photoUri = widget.person?.photoUri;
    _iconKey = widget.person?.iconKey ?? _iconCandidates.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    final provider = context.read<ExpenseProvider>();
    final savedPath = await provider.saveImage(file);
    setState(() {
      _photoUri = savedPath;
    });
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final provider = context.read<ExpenseProvider>();
    final savedPath = await provider.saveImage(file);
    setState(() {
      _photoUri = savedPath;
    });
  }

  void _changeAvatarType(AvatarType? value) {
    if (value == null) return;
    setState(() {
      _avatarType = value;
    });
  }

  Future<void> _submit() async {
    final provider = context.read<ExpenseProvider>();
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前を入力してください。')),
      );
      return;
    }
    if (_avatarType == AvatarType.photo && _photoUri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真を選択してください。')),
      );
      return;
    }
    Person? result;
    if (widget.person == null) {
      result = await provider.addPerson(
        name: _nameController.text.trim(),
        avatarType: _avatarType,
        photoUri: _avatarType == AvatarType.photo ? _photoUri : null,
        iconKey: _avatarType == AvatarType.icon ? _iconKey : null,
      );
    } else {
      final updated = widget.person!.copyWith(
        name: _nameController.text.trim(),
        avatarType: _avatarType,
        photoUri: _avatarType == AvatarType.photo ? _photoUri : null,
        iconKey: _avatarType == AvatarType.icon ? _iconKey : null,
      );
      await provider.updatePerson(updated);
      result = updated;
    }
    if (context.mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.person == null ? '人を追加' : '人を編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名前'),
            ),
            const SizedBox(height: 16),
            Text('表示方法', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<AvatarType>(
                    value: AvatarType.icon,
                    groupValue: _avatarType,
                    title: const Text('アイコン'),
                    onChanged: _changeAvatarType,
                  ),
                ),
                Expanded(
                  child: RadioListTile<AvatarType>(
                    value: AvatarType.photo,
                    groupValue: _avatarType,
                    title: const Text('写真'),
                    onChanged: _changeAvatarType,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_avatarType == AvatarType.icon)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconCandidates.map((icon) {
                  final selected = _iconKey == icon;
                  return ChoiceChip(
                    label: Text(icon, style: const TextStyle(fontSize: 20)),
                    selected: selected,
                    onSelected: (_) => setState(() => _iconKey = icon),
                  );
                }).toList(),
              ),
            if (_avatarType == AvatarType.photo)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_photoUri != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: FileImage(File(_photoUri!)),
                      ),
                    ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('撮影'),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('ギャラリー'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
