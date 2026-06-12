import 'package:another_iptv_player/models/announcement_model.dart';
import 'package:another_iptv_player/models/branding_model.dart';
import 'package:another_iptv_player/models/maintenance_model.dart';
import 'package:another_iptv_player/models/theme_model.dart';
import 'package:another_iptv_player/models/update_info_model.dart';

abstract class RemoteConfigProvider {
  String get sourceName;

  Future<BrandingModel?> fetchBranding();
  Future<RemoteThemeModel?> fetchTheme();
  Future<List<AnnouncementModel>?> fetchAnnouncements();
  Future<MaintenanceModel?> fetchMaintenance();
  Future<UpdateInfoModel?> fetchUpdateInfo();
}
