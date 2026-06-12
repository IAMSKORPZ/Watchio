class AnnouncementModel {
  final String title;
  final String body;
  final DateTime createdAt;
  final int priority;
  final DateTime? expiresAt;

  const AnnouncementModel({
    required this.title,
    required this.body,
    required this.createdAt,
    this.priority = 0,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim();
    final body = (json['body'] as String?)?.trim();
    if (title == null || title.isEmpty || body == null || body.isEmpty) {
      throw const FormatException('Announcement requires title and body.');
    }
    return AnnouncementModel(
      title: title,
      body: body,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      priority: json['priority'] is int ? json['priority'] as int : 0,
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
    );
  }
}
