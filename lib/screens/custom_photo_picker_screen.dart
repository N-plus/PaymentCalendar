import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final LinkedHashMap<String, AssetEntity> _selectedAssets =
      LinkedHashMap<String, AssetEntity>();

  List<AssetPathEntity> _albums = <AssetPathEntity>[];
  List<AssetPathEntity> _filteredAlbums = <AssetPathEntity>[];
  final Map<String, List<AssetEntity>> _albumAssetCache =
      <String, List<AssetEntity>>{};

  List<AssetEntity> _currentAlbumAssets = <AssetEntity>[];
  List<AssetEntity> _displayedAssets = <AssetEntity>[];
  AssetPathEntity? _selectedAlbum;

  bool _loading = true;
  bool _permissionDenied = false;
  bool _confirming = false;
  bool _albumLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _searchController.addListener(_onSearchControllerChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchControllerChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });

    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionDenied = true;
        _loading = false;
      });
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    AssetPathEntity? allPath;
    final List<AssetPathEntity> albums = <AssetPathEntity>[];
    for (final AssetPathEntity path in paths) {
      if (path.isAll) {
        allPath = path;
      }
      albums.add(path);
    }

    final List<AssetEntity> recentAssets = allPath == null
        ? <AssetEntity>[]
        : await allPath.getAssetListPaged(
            page: 0,
            size: 200,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _albums = albums;
      _filteredAlbums = List<AssetPathEntity>.from(albums);
      _albumAssetCache.clear();
      _selectedAlbum = albums.isNotEmpty ? albums.first : null;
      _currentAlbumAssets = <AssetEntity>[];
      _displayedAssets = <AssetEntity>[];
      _loading = false;
    });

    if (_selectedAlbum != null) {
      await _loadAlbumAssets(_selectedAlbum!);
    }
  }

  void _onSearchControllerChanged() {
    _applySearchFilter(_searchController.text);
  }

  void _applySearchFilter(String query) {
    final String lowerQuery = query.trim().toLowerCase();

    final List<AssetPathEntity> filteredAlbums = lowerQuery.isEmpty
        ? List<AssetPathEntity>.from(_albums)
        : _albums
            .where((AssetPathEntity album) =>
                album.name.toLowerCase().contains(lowerQuery))
            .toList(growable: false);

    AssetPathEntity? targetAlbum = _selectedAlbum;
    if (targetAlbum != null &&
        filteredAlbums.every((AssetPathEntity album) => album.id != targetAlbum!.id)) {
      targetAlbum = filteredAlbums.isNotEmpty ? filteredAlbums.first : null;
    } else if (targetAlbum == null && filteredAlbums.isNotEmpty) {
      targetAlbum = filteredAlbums.first;
    }

    setState(() {
      _filteredAlbums = filteredAlbums;
      _displayedAssets = _filterAssetsForDisplay(
        _currentAlbumAssets,
        lowerQuery,
      );
    });

    if (targetAlbum?.id != _selectedAlbum?.id) {
      _setSelectedAlbum(targetAlbum);
    } else if (targetAlbum == null) {
      setState(() {
        _currentAlbumAssets = <AssetEntity>[];
        _displayedAssets = <AssetEntity>[];
      });
    } else {
      _ensureAlbumAssetsLoaded(targetAlbum);
    }
  }

  void _ensureAlbumAssetsLoaded(AssetPathEntity album) {
    final List<AssetEntity>? cached = _albumAssetCache[album.id];
    if (cached != null) {
      _setAlbumAssets(album, cached);
      return;
    }
    _loadAlbumAssets(album);
  }

  Future<void> _loadAlbumAssets(AssetPathEntity album) async {
    setState(() {
      _albumLoading = true;
    });

    final List<AssetEntity> assets = await album.getAssetListPaged(
      page: 0,
      size: 200,
    );

    if (!mounted) {
      return;
    }

    _setAlbumAssets(album, assets);
  }

  void _setSelectedAlbum(AssetPathEntity? album) {
    if (album == null) {
      setState(() {
        _selectedAlbum = null;
        _currentAlbumAssets = <AssetEntity>[];
        _displayedAssets = <AssetEntity>[];
        _albumLoading = false;
      });
      return;
    }

    if (_selectedAlbum?.id == album.id) {
      return;
    }

    setState(() {
      _selectedAlbum = album;
    });

    _ensureAlbumAssetsLoaded(album);
  }

  void _setAlbumAssets(AssetPathEntity album, List<AssetEntity> assets) {
    final String lowerQuery = _searchController.text.trim().toLowerCase();
    setState(() {
      _albumAssetCache[album.id] = assets;
      _currentAlbumAssets = assets;
      _displayedAssets = _filterAssetsForDisplay(assets, lowerQuery);
      _albumLoading = false;
    });
  }

  List<AssetEntity> _filterAssetsForDisplay(
    List<AssetEntity> assets,
    String lowerQuery,
  ) {
    if (lowerQuery.isEmpty) {
      return List<AssetEntity>.from(assets);
    }
    return assets
        .where((AssetEntity asset) =>
            (asset.title ?? '').toLowerCase().contains(lowerQuery))
        .toList(growable: false);
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                    child: Text(
                      _confirming
                          ? '読み込み中...'
                          : '決定（${_selectedAssets.length}${_selectionLimitLabel}）',
                    ),
                  ),
                ),
              )
            : null,
      ),
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
      return _buildPermissionDenied();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          child: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: '写真'),
              Tab(text: 'コレクション'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            children: [
              _buildPhotoGrid(_displayedAssets),
              _buildCollectionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF999999),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.search, color: Colors.white, size: 20),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        hintText: '検索',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  Widget _buildPhotoGrid(List<AssetEntity> assets) {
    if (assets.isEmpty) {
      return const Center(
        child: Text(
          '写真が見つかりませんでした。',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return GridView.builder(
      itemCount: assets.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (BuildContext context, int index) {
        final AssetEntity asset = assets[index];
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

  Widget _buildCollectionsTab() {
    if (_filteredAlbums.isEmpty) {
      return const Center(
        child: Text(
          'コレクションが見つかりませんでした。',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final AssetPathEntity? selectedAlbum = _selectedAlbum;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AssetPathEntity>(
          value: selectedAlbum,
          items: _filteredAlbums
              .map(
                (AssetPathEntity album) => DropdownMenuItem<AssetPathEntity>(
                  value: album,
                  child: Text(album.name),
                ),
              )
              .toList(growable: false),
          onChanged: _setSelectedAlbum,
          decoration: InputDecoration(
            labelText: 'コレクションを選択',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _albumLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPhotoGrid(_currentAlbumAssets),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
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
}
