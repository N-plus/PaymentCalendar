import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/person_avatar.dart';
import '../widgets/person_editor_dialog.dart';

Future<void> showExpenseEditor(
  BuildContext context, {
  Expense? expense,
  String? defaultPersonId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ExpenseEditorSheet(
          expense: expense,
          defaultPersonId: defaultPersonId,
        ),
      );
    },
  );
}

class ExpenseEditorSheet extends StatefulWidget {
  const ExpenseEditorSheet({
    super.key,
    this.expense,
    this.defaultPersonId,
  });

  final Expense? expense;
  final String? defaultPersonId;

  @override
  State<ExpenseEditorSheet> createState() => _ExpenseEditorSheetState();
}

class _ExpenseEditorSheetState extends State<ExpenseEditorSheet> {
  late DateTime _selectedDate;
  String? _personId;
  late TextEditingController _amountController;
  late TextEditingController _memoController;
  late bool _isPlanned;
  final List<String> _photoUris = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    final now = DateTime.now();
    _selectedDate = expense?.date ?? DateTime(now.year, now.month, now.day);
    _personId = expense?.personId ?? widget.defaultPersonId;
    _amountController = TextEditingController(text: expense?.amount.toString() ?? '');
    _memoController = TextEditingController(text: expense?.memo ?? '');
    _isPlanned = expense?.isPlanned ?? _selectedDate.isAfter(_today());
    _photoUris.addAll(expense?.photoUris ?? []);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        if (!_selectedDate.isAfter(_today())) {
          _isPlanned = false;
        } else if (widget.expense == null) {
          _isPlanned = true;
        }
      });
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file == null) return;
    final provider = context.read<ExpenseProvider>();
    final saved = await provider.saveImage(file);
    setState(() {
      _photoUris.add(saved);
    });
  }

  Future<void> _onSave() async {
    final provider = context.read<ExpenseProvider>();
    if (provider.persons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に人を追加してください。')),
      );
      return;
    }
    if (_personId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('人を選択してください。')),
      );
      return;
    }
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金額を正しく入力してください。')),
      );
      return;
    }
    final memo = _memoController.text.trim();
    if (widget.expense == null) {
      await provider.addExpense(
        date: _selectedDate,
        personId: _personId!,
        amount: amount,
        memo: memo.isEmpty ? null : memo,
        photoUris: _photoUris,
        isPlanned: _isPlanned,
      );
    } else {
      final updated = widget.expense!.copyWith(
        date: _selectedDate,
        personId: _personId!,
        amount: amount,
        memo: memo.isEmpty ? null : memo,
        photoUris: List<String>.from(_photoUris),
        isPlanned: _isPlanned,
      );
      await provider.updateExpense(updated);
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _togglePlanned(bool value) {
    setState(() {
      _isPlanned = value;
    });
  }

  Future<void> _addPerson() async {
    final person = await showDialog<Person>(
      context: context,
      builder: (_) => const PersonEditorDialog(),
    );
    if (person != null) {
      setState(() {
        _personId = person.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final persons = provider.persons;
    final formatter = DateFormat('yyyy年M月d日(E)', 'ja_JP');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.expense == null ? '記録を追加' : '記録を編集',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('日付'),
                subtitle: Text(formatter.format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              if (_selectedDate.isAfter(_today()))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '未来日付です。予定として扱われます。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('人を選択', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addPerson,
                    icon: const Icon(Icons.person_add),
                    label: const Text('人を追加'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (persons.isEmpty)
                const Text('人が登録されていません。'),
              if (persons.isNotEmpty)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: persons.map((person) {
                    final selected = _personId == person.id;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PersonAvatar(person: person, size: 32),
                          const SizedBox(width: 8),
                          Text(person.name),
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _personId = person.id;
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '金額 (円)',
                  prefixIcon: Icon(Icons.payments),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'メモ (任意)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _isPlanned,
                onChanged: (value) {
                  if (!_selectedDate.isAfter(_today()) && value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('過去日付は予定にできません。')),
                    );
                    return;
                  }
                  _togglePlanned(value);
                },
                title: const Text('予定として扱う'),
                subtitle: const Text('予定は未払い合計に含めない設定も可能です'),
              ),
              const SizedBox(height: 12),
              Text('写真', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final uri in _photoUris)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(uri),
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _photoUris.remove(uri)),
                        ),
                      ],
                    ),
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: OutlinedButton(
                      onPressed: () => _showPhotoSourceSelector(),
                      child: const Icon(Icons.add_a_photo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _onSave,
                    child: Text(widget.expense == null ? '保存' : '更新'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPhotoSourceSelector() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('写真を撮影'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
