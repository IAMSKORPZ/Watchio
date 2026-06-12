import 'package:another_iptv_player/models/update_info_model.dart';
import 'package:another_iptv_player/services/github_release_service.dart';
import 'package:another_iptv_player/services/update_service.dart';
import 'package:flutter/material.dart';

class UpdateController extends ChangeNotifier {
  final UpdateService service;

  UpdateController({UpdateService? service})
      : service = service ?? UpdateService();

  UpdateCheckResult? result;
  UpdateChannel channel = UpdateChannel.stable;
  String? currentVersion;
  DateTime? lastCheckTime;
  String? lastKnownVersion;
  String? downloadedInstallerPath;
  bool isChecking = false;
  bool isDownloading = false;
  String? error;

  bool get updateAvailable => result?.updateAvailable ?? false;
  bool get forceRequired => result?.forceRequired ?? false;

  Future<void> loadState() async {
    channel = await service.getChannel();
    currentVersion = await service.getCurrentVersion();
    lastCheckTime = await service.getLastCheckTime();
    lastKnownVersion = await service.getLastKnownVersion();
    notifyListeners();
  }

  Future<void> setChannel(UpdateChannel value) async {
    channel = value;
    await service.setChannel(value);
    notifyListeners();
  }

  Future<void> checkForUpdates({
    UpdateInfoModel? remoteUpdateInfo,
    bool isStartup = false,
    bool scheduledOnly = false,
  }) async {
    if (scheduledOnly && !await service.shouldRunScheduledCheck()) return;

    isChecking = true;
    error = null;
    notifyListeners();

    try {
      result = await service.checkForUpdates(
        remoteUpdateInfo: remoteUpdateInfo,
        allowCache: true,
      );
      currentVersion = result!.currentVersion;
      lastCheckTime = result!.checkedAt;
      lastKnownVersion = result!.updateInfo.latestVersion;
    } catch (e) {
      error = e.toString();
    } finally {
      isChecking = false;
      notifyListeners();
    }
  }

  Future<void> downloadUpdate() async {
    final release = result?.release;
    if (release == null) {
      error = 'No release asset available.';
      notifyListeners();
      return;
    }

    isDownloading = true;
    error = null;
    notifyListeners();

    try {
      downloadedInstallerPath = await service.downloadInstaller(release);
    } catch (e) {
      error = e.toString();
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }
}
