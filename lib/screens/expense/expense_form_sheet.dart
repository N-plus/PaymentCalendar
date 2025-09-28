import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:payment_calendar/utils/color_utils.dart';

import '../../models/person.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/people_provider.dart';
import '../../utils/date_util.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({super.key, this.expenseId});

  final String? expenseId;

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _newPersonNameController = TextEditingController();
  final _newPersonEmojiController = TextEditingController();
  final _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  String? _personId;
  List<String> _photoPaths = [];
  bool _saving = false;

  bool _showNewPersonForm = false;
  bool _newPersonUsesPhoto = false;
  XFile? _newPersonPhoto;
  bool _addingPerson = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expenseId == null
        ? null
        : ref
            .read(expensesProvider)
            .firstWhere((element) => element.id == widget.expenseId);
    if (expense != null) {
      _selectedDate = expense.date;
      _personId = expense.personId;
      _amountController.text = expense.amount.toString();
      _memoController.text = expense.memo;
      _photoPaths = List<String>.from(expense.photoPaths);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _newPersonNameController.dispose();
    _newPersonEmojiController.dispose();
    super.dispose();
  }

  bool get _isPlanned {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = DateUtils.dateOnly(_selectedDate);
    return selected.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider);
    if (_personId == null && !_showNewPersonForm && people.isNotEmpty) {
      _personId = people.first.id;
    }

    return Container(
      color: const Color(0xFFFFFAF0),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildDateSection(context),
                  const SizedBox(height: 24),
                  _buildPersonSection(context, people),
                  const SizedBox(height: 24),
                  _buildAmountSection(context),
                  const SizedBox(height: 24),
                  _buildMemoSection(context),
                  const SizedBox(height: 24),
                  _buildPhotoSection(context),
                  const SizedBox(height: 32),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          widget.expenseId == null ? '記録追加' : '記録編集',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: '閉じる',
        ),
      ],
    );
  }

  Widget _buildDateSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '日付',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatDate(_selectedDate),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (_isPlanned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '予定',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonSection(BuildContext context, List<Person> people) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '人',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final person in people) _buildPersonOption(person),
            _buildAddPersonOption(theme),
          ],
        ),
        if (_showNewPersonForm) ...[
          const SizedBox(height: 16),
          _buildNewPersonForm(context),
        ],
      ],
    );
  }

  Widget _buildPersonOption(Person person) {
    final isSelected = _personId == person.id;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _selectPerson(person.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: 2,
          ),
            color: isSelected
                ? theme.colorScheme.primaryContainer.withOpacityValue(0.4)
                : theme.colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPersonAvatar(person, size: 40),
            const SizedBox(width: 8),
            Text(
              person.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPersonOption(ThemeData theme) {
    return GestureDetector(
      onTap: _toggleNewPersonForm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary, width: 2),
            color: _showNewPersonForm
                ? theme.colorScheme.primaryContainer.withOpacityValue(0.4)
                : theme.colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 6),
            Text(
              '新しい人を追加',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPersonForm(BuildContext context) {
    final theme = Theme.of(context);
    final preview = !_newPersonUsesPhoto
        ? _newPersonEmojiController.text.characters.isNotEmpty
            ? _newPersonEmojiController.text.characters.first
            : _newPersonNameController.text.characters.isNotEmpty
                ? _newPersonNameController.text.characters.first
                : '人'
        : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacityValue(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _newPersonNameController,
            decoration: const InputDecoration(
              labelText: '名前',
              hintText: '例: 母',
            ),
            maxLength: 10,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            'アバタータイプ',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAvatarTypeButton('アイコン', false),
              const SizedBox(width: 8),
              _buildAvatarTypeButton('写真', true),
            ],
          ),
          const SizedBox(height: 16),
          if (_newPersonUsesPhoto)
            _buildNewPersonPhotoPicker()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    preview ?? '人',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _newPersonEmojiController,
                    decoration: const InputDecoration(
                      labelText: 'アイコン',
                      hintText: '例: 😀',
                      helperText: '1文字の絵文字など',
                    ),
                    maxLength: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: _addingPerson ? null : _cancelNewPerson,
                child: const Text('キャンセル'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addingPerson ? null : _addNewPerson,
                child: _addingPerson
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('追加'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarTypeButton(String label, bool usesPhoto) {
    final isSelected = _newPersonUsesPhoto == usesPhoto;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _setNewPersonAvatarType(usesPhoto),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildNewPersonPhotoPicker() {
    if (_newPersonPhoto != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_newPersonPhoto!.path),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          IconButton(
            onPressed: _addingPerson ? null : _removeNewPersonPhoto,
            icon: const Icon(Icons.close),
            splashRadius: 18,
          ),
        ],
      );
    }
    return OutlinedButton.icon(
      onPressed: _pickNewPersonPhoto,
      icon: const Icon(Icons.photo),
      label: const Text('写真を選択'),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '金額（円）',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: '0',
            suffixText: '円',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '金額を入力してください';
            }
            final amount = int.tryParse(value);
            if (amount == null || amount <= 0) {
              return '正しい金額を入力してください';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMemoSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'メモ（任意）',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _memoController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '詳細を入力…',
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = _photoPaths.length < 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'レシート写真（任意）',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: canAddMore ? _captureImage : null,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('カメラ'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: canAddMore ? _pickImages : null,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('ギャラリー'),
                  ),
                ],
              ),
              if (_photoPaths.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _photoPaths
                        .map((path) => _buildPhotoThumbnail(path))
                        .toList(),
                  ),
                ),
              ],
              if (!canAddMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '写真は最大5枚まで添付できます',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(String path) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _PhotoPreview(path: path),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => setState(() => _photoPaths.remove(path)),
            child: Container(
              width: 24,
              height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacityValue(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(widget.expenseId == null ? '保存' : '更新'),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonAvatar(Person person, {double size = 56}) {
    final theme = Theme.of(context);
    final photoPath = person.photoPath;
    if (photoPath != null && File(photoPath).existsSync()) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacityValue(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(photoPath),
          fit: BoxFit.cover,
        ),
      );
    }
    final emoji = person.emoji;
    final text = emoji?.isNotEmpty == true
        ? emoji!
        : person.name.characters.isNotEmpty
            ? person.name.characters.first
            : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _selectPerson(String personId) {
    setState(() {
      _personId = personId;
      _showNewPersonForm = false;
      _resetNewPersonForm();
    });
  }

  void _toggleNewPersonForm() {
    setState(() {
      _showNewPersonForm = !_showNewPersonForm;
      if (_showNewPersonForm) {
        _personId = null;
      } else {
        _resetNewPersonForm();
      }
    });
  }

  void _setNewPersonAvatarType(bool usesPhoto) {
    setState(() {
      _newPersonUsesPhoto = usesPhoto;
      if (!usesPhoto) {
        _newPersonPhoto = null;
      }
    });
  }

  Future<void> _pickNewPersonPhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _newPersonPhoto = picked);
      }
    } catch (error) {
      _showMessage('写真の選択に失敗しました');
    }
  }

  void _removeNewPersonPhoto() {
    setState(() => _newPersonPhoto = null);
  }

  void _cancelNewPerson() {
    setState(() {
      _showNewPersonForm = false;
      _resetNewPersonForm();
    });
  }

  Future<void> _addNewPerson() async {
    final name = _newPersonNameController.text.trim();
    if (name.isEmpty) {
      _showMessage('名前を入力してください');
      return;
    }
    if (_newPersonUsesPhoto && _newPersonPhoto == null) {
      _showMessage('写真を選択してください');
      return;
    }

    setState(() => _addingPerson = true);

    String? photoPath;
    if (_newPersonUsesPhoto && _newPersonPhoto != null) {
      photoPath = await _saveFile(_newPersonPhoto!);
      if (photoPath == null) {
        if (mounted) {
          setState(() => _addingPerson = false);
        }
        return;
      }
    }

    final emoji = _newPersonUsesPhoto
        ? null
        : _newPersonEmojiController.text.characters.isNotEmpty
            ? _newPersonEmojiController.text.characters.first
            : name.characters.isNotEmpty
                ? name.characters.first
                : null;

    final newPerson = ref
        .read(peopleProvider.notifier)
        .addPerson(name, emoji: emoji, photoPath: photoPath);

    if (!mounted) {
      return;
    }

    setState(() {
      _personId = newPerson?.id ?? _personId;
      _showNewPersonForm = false;
      _addingPerson = false;
      _resetNewPersonForm();
    });

    if (newPerson != null) {
      _showMessage('${newPerson.name}を追加しました');
    }
  }

  void _resetNewPersonForm() {
    _newPersonNameController.clear();
    _newPersonEmojiController.clear();
    _newPersonPhoto = null;
    _newPersonUsesPhoto = false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImages() async {
    if (_photoPaths.length >= 5) {
      _showMessage('写真は最大5枚まで添付できます');
      return;
    }
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    final available = 5 - _photoPaths.length;
    final limited = files.take(available);
    final paths = await Future.wait(limited.map(_saveFile));
    setState(() {
      _photoPaths.addAll(paths.whereType<String>());
    });
    if (files.length > available) {
      _showMessage('写真は最大5枚まで添付できます');
    }
  }

  Future<void> _captureImage() async {
    if (_photoPaths.length >= 5) {
      _showMessage('写真は最大5枚まで添付できます');
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) {
      return;
    }
    final saved = await _saveFile(file);
    if (saved != null) {
      setState(() => _photoPaths.add(saved));
    }
  }

  Future<String?> _saveFile(XFile file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final newPath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final saved = await File(file.path).copy(newPath);
      return saved.path;
    } catch (error) {
      if (mounted) {
        _showMessage('画像の保存に失敗しました');
      }
      return null;
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final personId = _personId;
    if (personId == null) {
      _showMessage('人を選択してください');
      return;
    }

    setState(() => _saving = true);

    final amount = int.parse(_amountController.text);
    final memo = _memoController.text.trim();

    if (widget.expenseId == null) {
      ref.read(expensesProvider.notifier).addExpense(
            personId: personId,
            date: _selectedDate,
            amount: amount,
            memo: memo,
            photoPaths: _photoPaths,
          );
    } else {
      final original = ref
          .read(expensesProvider)
          .firstWhere((expense) => expense.id == widget.expenseId);
      final updated = original.copyWith(
        personId: personId,
        date: _selectedDate,
        amount: amount,
        memo: memo,
        photoPaths: _photoPaths,
      );
      ref.read(expensesProvider.notifier).updateExpense(updated);
    }

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        width: 96,
        height: 96,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image),
      );
    }
    return Image.file(
      file,
      width: 96,
      height: 96,
      fit: BoxFit.cover,
    );
  }
}
