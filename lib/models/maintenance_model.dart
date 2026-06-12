class MaintenanceModel {
  final bool enabled;
  final String title;
  final String message;
  final bool allowPlayback;
  final bool allowLogin;

  const MaintenanceModel({
    required this.enabled,
    required this.title,
    required this.message,
    this.allowPlayback = true,
    this.allowLogin = true,
  });

  static const defaults = MaintenanceModel(
    enabled: false,
    title: 'Maintenance',
    message: '',
    allowPlayback: true,
    allowLogin: true,
  );

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'title': title,
      'message': message,
      'allowPlayback': allowPlayback,
      'allowLogin': allowLogin,
    };
  }

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceModel(
      enabled: json['enabled'] == true,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : defaults.title,
      message: (json['message'] as String?)?.trim() ?? '',
      allowPlayback: json['allowPlayback'] as bool? ?? true,
      allowLogin: json['allowLogin'] as bool? ?? true,
    );
  }
}
