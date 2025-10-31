import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/person.dart';
import '../../utils/photo_permission_mixin.dart';
import '../custom_photo_picker_screen.dart';

class PersonFormResult {
  PersonFormResult({
    required this.name,
    this.emoji,
    this.photoPath,
    this.iconAsset,
  });

  final String name;
  final String? emoji;
  final String? photoPath;
  final String? iconAsset;
}

class PersonEditDialog extends StatefulWidget {
  const PersonEditDialog({this.person, super.key});

  final Person? person;

  @override
  State<PersonEditDialog> createState() => _PersonEditDialogState();
}

class _PersonEditDialogState extends State<PersonEditDialog>
    with PhotoPermissionMixin<PersonEditDialog> {
  late final TextEditingController _nameController;
  late final ScrollController _scrollController;
  bool _hasScrollableContent = false;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final List<String> _suggestedIconAssets = const [
    'assets/icons/person_icon_01.png',
    'assets/icons/person_icon_02.png',
    'assets/icons/person_icon_03.png',
    'assets/icons/person_icon_04.png',
    'assets/icons/person_icon_05.png',
    'assets/icons/person_icon_06.png',
    'assets/icons/person_icon_07.png',
    'assets/icons/person_icon_08.png',
  ];

  XFile? _selectedPhoto;
  String? _existingPhotoPath;
  String? _selectedIconAsset;
  bool _usePhoto = false;
  bool _submitting = false;
  bool _showPhotoError = false;

  String? get _currentPhotoPath => _selectedPhoto?.path ?? _existingPhotoPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _scrollController = ScrollController()
      ..addListener(_handleScrollMetricsChanged);
    _existingPhotoPath = widget.person?.photoPath;
    _selectedIconAsset = widget.person?.iconAsset;
    _usePhoto = (_existingPhotoPath != null && _existingPhotoPath!.isNotEmpty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController
      ..removeListener(_handleScrollMetricsChanged)
      ..dispose();
    super.dispose();
  }

  void _selectIcon(String assetPath) {
    _setUsePhoto(false);
    setState(() {
      _selectedIconAsset = assetPath;
    });
  }

  void _setUsePhoto(bool value) {
    _unfocusTextField();
    setState(() {
      _usePhoto = value;
      if (!value) {
        _selectedPhoto = null;
        _existingPhotoPath = null;
      }
    });
  }

  void _unfocusTextField() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickPhotoFromGallery() async {
    _unfocusTextField();
    if (await shouldUseAndroidPhotoPicker()) {
      await _pickPhotoWithAndroidPhotoPicker();
      return;
    }

    final hasPermission = await ensurePhotoAccessPermission();
    if (!hasPermission) {
      return;
    }

    try {
      final files = await Navigator.of(context).push<List<XFile>>(
        MaterialPageRoute<List<XFile>>(
          builder: (_) => const CustomPhotoPickerScreen(),
          fullscreenDialog: true,
        ),
      );
      if (files == null || files.isEmpty) {
        return;
      }
      setState(() {
        _selectedPhoto = files.first;
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

  Future<void> _pickPhotoWithAndroidPhotoPicker() async {
    _unfocusTextField();
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      if (!mounted) {
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

  Future<void> _capturePhoto() async {
    _unfocusTextField();
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
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
    _unfocusTextField();
    setState(() {
      _selectedPhoto = null;
      _existingPhotoPath = null;
      _showPhotoError = false;
    });
  }

  void _handleScrollMetricsChanged() {
    _scheduleScrollableExtentCheck();
  }

  void _scheduleScrollableExtentCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final hasScrollable = _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0;
      if (_hasScrollableContent != hasScrollable) {
        setState(() {
          _hasScrollableContent = hasScrollable;
        });
      }
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
    String? photoPath;
    String? iconAsset;

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
      iconAsset = _selectedIconAsset;
      photoPath = null;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      PersonFormResult(
        name: name,
        photoPath: photoPath,
        iconAsset: iconAsset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoPreview = _buildPhotoPreview();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = bottomInset > 0;
    final controller = _scrollController;
    _scheduleScrollableExtentCheck();
    final showScrollbar = keyboardOpen && _hasScrollableContent;

    final formContent = Form(
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
                        label: const Text('アイコン'),
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
                        backgroundColor: _usePhoto ? Colors.white : null,
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
                          onPressed:
                              _submitting ? null : _pickPhotoFromGallery,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('アルバムから選択'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _submitting ? null : _capturePhoto,
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
                    Text(
                      '候補のアイコンから選択する',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _suggestedIconAssets
                          .map(
                            (asset) {
                              final isSelected = _selectedIconAsset == asset;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectIcon(asset),
                                  borderRadius: BorderRadius.circular(40),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.black87
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Container(
                                        color: const Color(0xFFF7F7FA),
                                        child: Image.asset(
                                          asset,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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
        ],
      ),
    );

    final actions = Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        80 + (keyboardOpen ? bottomInset : 0),
      ),
      child: Row(
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
    );

    final scrollableContent = Scrollbar(
      controller: controller,
      thumbVisibility: showScrollbar,
      trackVisibility: showScrollbar,
      interactive: showScrollbar,
      child: SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                formContent,
                actions,
              ],
            ),
          ),
        ),
      ),
    );

    return Dialog(
      backgroundColor: const Color(0xFFFFFAF0),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
            currentFocus.unfocus();
          } else {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: SafeArea(
          child: scrollableContent,
        ),
      ),
    );
  }
}

