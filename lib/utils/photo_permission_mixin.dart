import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

mixin PhotoPermissionMixin<T extends StatefulWidget> on State<T> {
  Future<bool> ensurePhotoAccessPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    final List<Permission> permissions = <Permission>[
      if (Platform.isAndroid) Permission.photos,
      if (Platform.isAndroid) Permission.storage,
      if (Platform.isIOS) Permission.photos,
    ];

    final List<PermissionStatus> currentStatuses = <PermissionStatus>[];
    for (final Permission permission in permissions) {
      currentStatuses.add(await permission.status);
    }

    if (_hasSufficientPermission(currentStatuses)) {
      return true;
    }

    final Map<Permission, PermissionStatus> requestedStatuses =
        await permissions.request();
    final Iterable<PermissionStatus> results = requestedStatuses.values;

    if (_hasSufficientPermission(results)) {
      return true;
    }

    final bool permanentlyDenied = results.any(
      (PermissionStatus status) => status.isPermanentlyDenied,
    );

    if (!mounted) {
      return false;
    }

    await _showPermissionDialog(permanentlyDenied: permanentlyDenied);
    return false;
  }

  bool _hasSufficientPermission(Iterable<PermissionStatus> statuses) {
    return statuses.any(
      (PermissionStatus status) =>
          status.isGranted || status == PermissionStatus.limited,
    );
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
                await openAppSettings();
              },
              child: const Text('設定を開く'),
            ),
          ],
        );
      },
    );
  }
}
