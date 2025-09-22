import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  ImageStorageService();

  final _uuid = const Uuid();

  Future<String> saveImage(XFile file) async {
    final directory = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(directory.path, 'receipts'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final extension = p.extension(file.path);
    final targetPath = p.join(targetDir.path, '${_uuid.v4()}$extension');
    final savedFile = await File(file.path).copy(targetPath);
    return savedFile.path;
  }
}
