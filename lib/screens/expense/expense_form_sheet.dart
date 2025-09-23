import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/expenses_provider.dart';
import '../../providers/people_provider.dart';
import '../../utils/format.dart';

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
  final _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  String? _personId;
  List<String> _photoPaths = [];
  bool _saving = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(peopleProvider);
    _personId ??= people.isNotEmpty ? people.first.id : null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.expenseId == null ? '記録追加' : '記録編集',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('日付'),
                subtitle: Text(formatDate(_selectedDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _personId,
                decoration: const InputDecoration(labelText: '人'),
                items: [
                  for (final person in people)
                    DropdownMenuItem(
                      value: person.id,
                      child: Text(person.name),
                    ),
                ],
                onChanged: (value) => setState(() => _personId = value),
                validator: (value) => value == null ? '人を選択してください' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '金額 (円)',
                  prefixText: '¥',
                ),
                keyboardType: TextInputType.number,
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
              const SizedBox(height: 8),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text('レシート写真',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final path in _photoPaths)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _PhotoPreview(path: path),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(
                            () => _photoPaths.remove(path),
                          ),
                        ),
                      ],
                    ),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('ギャラリー'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('カメラ'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(widget.expenseId == null ? '保存' : '更新'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    final paths = await Future.wait(files.map(_saveFile));
    setState(() {
      _photoPaths.addAll(paths.whereType<String>());
    });
  }

  Future<void> _captureImage() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画像の保存に失敗しました')),
      );
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final personId = _personId;
    if (personId == null) {
      return;
    }
    final amount = int.parse(_amountController.text);
    final memo = _memoController.text.trim();
    setState(() => _saving = true);

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

    if (mounted) {
      Navigator.of(context).pop();
    }
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
        width: 100,
        height: 100,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image),
      );
    }
    return Image.file(
      file,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );
  }
}
