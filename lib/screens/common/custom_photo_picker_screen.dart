import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class CustomPhotoPickerScreen extends StatefulWidget {
  const CustomPhotoPickerScreen({
    super.key,
    this.allowMultiple = false,
    this.maxSelection,
    this.title = '写真を選択',
  });

  final bool allowMultiple;
  final int? maxSelection;
  final String title;

  @override
  State<CustomPhotoPickerScreen> createState() => _CustomPhotoPickerScreenState();
}

class _CustomPhotoPickerScreenState extends State<CustomPhotoPickerScreen> {
  final List<AssetEntity> _assets = <AssetEntity>[];
  final LinkedHashMap<String, AssetEntity> _selectedAssets =
      LinkedHashMap<String, AssetEntity>();

  bool _loading = true;
  bool _permissionDenied = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });

    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() {
        _permissionDenied = true;
        _loading = false;
      });
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (!mounted) {
      return;
    }

    if (paths.isEmpty) {
      setState(() {
        _assets.clear();
        _loading = false;
      });
      return;
    }

    // Load the latest photos first.
    final AssetPathEntity path = paths.first;
    final List<AssetEntity> assets = await path.getAssetListPaged(
      page: 0,
      size: 200,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _assets
        ..clear()
        ..addAll(assets);
      _loading = false;
    });
  }

  void _toggleSelection(AssetEntity asset) {
    final String id = asset.id;
    if (_selectedAssets.containsKey(id)) {
      setState(() {
        _selectedAssets.remove(id);
      });
      return;
    }

    final int? maxSelection = widget.maxSelection;
    if (maxSelection != null && _selectedAssets.length >= maxSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('写真は最大${maxSelection}枚まで選択できます')),
      );
      return;
    }

    setState(() {
      _selectedAssets[id] = asset;
    });
  }

  Future<void> _onAssetTap(AssetEntity asset) async {
    if (!widget.allowMultiple) {
      await _returnSelection(<AssetEntity>[asset]);
      return;
    }
    _toggleSelection(asset);
  }

  Future<void> _confirmSelection() async {
    if (_selectedAssets.isEmpty || _confirming) {
      return;
    }
    await _returnSelection(_selectedAssets.values.toList(growable: false));
  }

  Future<void> _returnSelection(List<AssetEntity> assets) async {
    setState(() {
      _confirming = true;
    });

    final List<XFile> files = <XFile>[];
    for (final AssetEntity asset in assets) {
      final File? file = await asset.file;
      if (file != null) {
        files.add(XFile(file.path));
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _confirming = false;
    });

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真の取得に失敗しました')),
      );
      return;
    }

    Navigator.of(context).pop<List<XFile>>(files);
  }

  Future<void> _openAppSettings() async {
    await PhotoManager.openSetting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
      bottomNavigationBar: widget.allowMultiple
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ElevatedButton(
                  onPressed:
                      _selectedAssets.isEmpty || _confirming ? null : _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                  ),
                  child: Text(_confirming
                      ? '読み込み中...'
                      : '決定（${_selectedAssets.length}${_selectionLimitLabel}）'),
                ),
              ),
            )
          : null,
    );
  }

  String get _selectionLimitLabel {
    if (widget.maxSelection == null) {
      return '';
    }
    return '/${widget.maxSelection}';
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 48, color: Colors.black54),
          const SizedBox(height: 16),
          const Text(
            '写真へのアクセス権限がありません。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            '設定からアクセスを許可してください。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _openAppSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
            ),
            child: const Text('設定を開く'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadAssets,
            child: const Text('再読み込み'),
          ),
        ],
      );
    }

    if (_assets.isEmpty) {
      return const Center(
        child: Text(
          '写真が見つかりませんでした。',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return GridView.builder(
      itemCount: _assets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (BuildContext context, int index) {
        final AssetEntity asset = _assets[index];
        final bool isSelected = _selectedAssets.containsKey(asset.id);
        return GestureDetector(
          onTap: () => _onAssetTap(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AssetEntityImage(
                  asset,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(300),
                  fit: BoxFit.cover,
                ),
              ),
              if (widget.allowMultiple)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black54, width: 1),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
