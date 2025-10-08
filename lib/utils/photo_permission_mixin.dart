import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

mixin PhotoPermissionMixin<T extends StatefulWidget> on State<T> {
  Future<bool> ensurePhotoAccessPermission() async {
    if (Platform.isAndroid) {
      final int? sdkInt = await _getAndroidSdkInt();
      if (sdkInt != null && sdkInt >= 33) {
        // Android 13 以降ではフォトピッカーを使用するため権限は不要。
        return true;
      }

      final PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      if (!mounted) {
        return false;
      }

      await _showPermissionDialog(
        permanentlyDenied: status.isPermanentlyDenied,
        onOpenSettings: () async {
          await openAppSettings();
        },
      );
      return false;
    }

    if (!Platform.isIOS) {
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

    await _showPermissionDialog(
      permanentlyDenied: permanentlyDenied,
      onOpenSettings: PhotoManager.openSetting,
    );
    return false;
  }

  Future<bool> shouldUseAndroidPhotoPicker() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final int? sdkInt = await _getAndroidSdkInt();
    return sdkInt != null && sdkInt >= 33;
  }

  Future<int?> _getAndroidSdkInt() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _showPermissionDialog({
    required bool permanentlyDenied,
    required Future<void> Function() onOpenSettings,
  }) async {
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
                await onOpenSettings();
              },
              child: const Text('設定を開く'),
            ),
          ],
        );
      },
    );
  }
}
