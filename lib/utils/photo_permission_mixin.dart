import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

mixin PhotoPermissionMixin<T extends StatefulWidget> on State<T> {
  Future<bool> ensurePhotoAccessPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    final PermissionState result = await PhotoManager.requestPermissionExtend();

    if (result.isAuth) {
      return true;
    }

    // Treat any non-authorized result as a permanently denied state so that
    // we instruct the user to enable the permission from settings.
    final bool permanentlyDenied = !result.isAuth;

    if (!mounted) {
      return false;
    }

    await _showPermissionDialog(permanentlyDenied: permanentlyDenied);
    return false;
  }

  Future<void> _showPermissionDialog({required bool permanentlyDenied}) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('写真へのアクセス権限が必要です'),
          content: Text(
            permanentlyDenied
                ? '写真を選択するには、設定画面から写真へのアクセスを許可してください。'
                : '写真を選択するには、写真へのアクセス権限を許可してください。',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await PhotoManager.openSetting();
              },
              child: const Text('設定を開く'),
            ),
          ],
        );
      },
    );
  }
}
