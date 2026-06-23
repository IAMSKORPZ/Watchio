import 'dart:io';

import 'package:flutter/services.dart';

class ApkInstallerService {
  static const _channel = MethodChannel('watchio/update_installer');

  Future<bool> canInstallPackages() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
  }

  Future<void> openUnknownSourcesSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openUnknownSourcesSettings');
  }

  Future<void> installApk(String path) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Auto install is only supported on Android.');
    }
    await _channel.invokeMethod<void>('installApk', {'path': path});
  }
}
