import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:payment_calendar/screens/custom_photo_picker_screen.dart';
import '../../models/person.dart';
import '../../models/expense_category.dart';
import '../../providers/categories_provider.dart';
import '../../providers/expenses_provider.dart';
import '../../providers/people_provider.dart';
import '../../utils/category_visuals.dart';
import '../../utils/date_picker_theme.dart';
import '../../utils/date_util.dart';
import '../../widgets/person_avatar.dart';

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
  String? _selectedCategory;
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
      _selectedCategory = expense.category;
      _photoPaths = List<String>.from(expense.photoPaths);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
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
    final categories = ref.watch(categoriesProvider);
    if (_personId == null && people.isNotEmpty) {
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
                  _buildCategorySection(context, categories),
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
          ],
        ),
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
            color: isSelected ? Colors.black : theme.dividerColor,
            width: 2,
          ),
          color: isSelected ? Colors.white : theme.colorScheme.surface,
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
                color: isSelected ? Colors.black : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
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
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '詳細を入力…',
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, List<String> categories) {
    final theme = Theme.of(context);
    final effectiveValue =
        categories.contains(_selectedCategory) ? _selectedCategory : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カテゴリー',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: effectiveValue,
          items: [
              for (final category in categories)
                DropdownMenuItem<String>(
                  value: category,
                  child: Builder(
                    builder: (context) {
                      final visual = categoryVisualFor(category);
                      return Row(
                        children: [
                          Icon(
                            visual.icon,
                            color: visual.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      );
                    },
                  ),
                ),
          ],
          decoration: const InputDecoration(
            hintText: '選択しない場合は「その他」になります',
          ),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          isExpanded: true,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('カメラ'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: canAddMore
                        ? () async {
                            final PermissionState ps =
                                await PhotoManager.requestPermissionExtend();
                            if (!ps.isAuth) {
                              if (!mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('写真へのアクセス権限を有効にしてください'),
                                ),
                              );
                              await PhotoManager.openSetting();
                              return;
                            }

                            final int available = 5 - _photoPaths.length;
                            final List<XFile>? picked =
                                await Navigator.of(context).push<List<XFile>>(
                              MaterialPageRoute<List<XFile>>(
                                builder: (_) => CustomPhotoPickerScreen(
                                  allowMultiple: true,
                                  maxSelection: available,
                                  title: '写真を選択',
                                ),
                              ),
                            );

                            if (picked == null || picked.isEmpty) {
                              return;
                            }

                            if (!mounted) {
                              return;
                            }

                            setState(() {
                              _photoPaths.addAll(picked.map((XFile x) => x.path));
                            });
                          }
                        : null,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('ギャラリー'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // 背景色（任意）
                      foregroundColor: Colors.black, // 文字とアイコン色
                    ),
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
                color: Colors.black.withOpacity(0.6),
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
          child: ElevatedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('キャンセル'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: Text(widget.expenseId == null ? '保存' : '更新'),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonAvatar(Person person, {double size = 56}) {
    return PersonAvatar(
      person: person,
      size: size,
      showShadow: true,
      backgroundColor: kPersonAvatarBackgroundColor,
      textStyle: TextStyle(
        fontSize: size * 0.45,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  void _selectPerson(String personId) {
    setState(() {
      _personId = personId;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: whiteDatePickerBuilder,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
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
    final category = (_selectedCategory == null || _selectedCategory!.isEmpty)
        ? ExpenseCategory.fallback
        : _selectedCategory!;

    if (widget.expenseId == null) {
      ref.read(expensesProvider.notifier).addExpense(
            personId: personId,
            date: _selectedDate,
            amount: amount,
            memo: memo,
            category: category,
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
        category: category,
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
