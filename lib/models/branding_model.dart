class BrandingModel {
  final String appName;
  final String? logoUrl;
  final String? splashUrl;
  final String? iconUrl;
  final String? supportUrl;
  final String? websiteUrl;
  final String? discordUrl;
  final String? homeBackgroundUrl;
  final String? loginBackgroundUrl;

  const BrandingModel({
    required this.appName,
    this.logoUrl,
    this.splashUrl,
    this.iconUrl,
    this.supportUrl,
    this.websiteUrl,
    this.discordUrl,
    this.homeBackgroundUrl,
    this.loginBackgroundUrl,
  });

  static const defaults = BrandingModel(
    appName: 'Watchio IPTV',
    websiteUrl: 'https://watchioiptv.app',
    discordUrl: 'https://discord.gg/watchioiptv',
    supportUrl: 'https://t.me/watchioiptv_support',
  );

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'logoUrl': logoUrl,
      'splashUrl': splashUrl,
      'iconUrl': iconUrl,
      'supportUrl': supportUrl,
      'websiteUrl': websiteUrl,
      'discordUrl': discordUrl,
      'homeBackgroundUrl': homeBackgroundUrl,
      'loginBackgroundUrl': loginBackgroundUrl,
    };
  }

  factory BrandingModel.fromJson(Map<String, dynamic> json) {
    final appName = (json['appName'] as String?)?.trim();
    return BrandingModel(
      appName: appName == null || appName.isEmpty ? defaults.appName : appName,
      logoUrl: _optionalUrl(json['logoUrl']),
      splashUrl: _optionalUrl(json['splashUrl']),
      iconUrl: _optionalUrl(json['iconUrl']),
      supportUrl: _optionalUrl(json['supportUrl']),
      websiteUrl: _optionalUrl(json['websiteUrl']),
      discordUrl: _optionalUrl(json['discordUrl']),
      homeBackgroundUrl: _optionalUrl(json['homeBackgroundUrl']),
      loginBackgroundUrl: _optionalUrl(json['loginBackgroundUrl']),
    );
  }

  static String? _optionalUrl(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    return value.trim();
  }
}
