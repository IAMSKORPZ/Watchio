class UpdateInfoModel {
  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final String? updateUrl;
  final String? releaseNotes;

  const UpdateInfoModel({
    required this.latestVersion,
    required this.minimumVersion,
    this.forceUpdate = false,
    this.updateUrl,
    this.releaseNotes,
  });

  static const defaults = UpdateInfoModel(
    latestVersion: '0.0.1',
    minimumVersion: '0.0.1',
    forceUpdate: false,
  );

  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      'minimumVersion': minimumVersion,
      'forceUpdate': forceUpdate,
      'updateUrl': updateUrl,
      'releaseNotes': releaseNotes,
    };
  }

  factory UpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return UpdateInfoModel(
      latestVersion: _version(json['latestVersion']) ?? defaults.latestVersion,
      minimumVersion:
          _version(json['minimumVersion']) ?? defaults.minimumVersion,
      forceUpdate: json['forceUpdate'] == true,
      updateUrl: _optionalUrl(json['updateUrl']),
      releaseNotes: json['releaseNotes'] as String?,
    );
  }

  static String? _version(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static String? _optionalUrl(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    return value.trim();
  }
}
