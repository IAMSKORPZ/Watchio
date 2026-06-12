class AnnouncementV2Model {
  final int id;
  final String title;
  final String message;
  final String date;

  AnnouncementV2Model({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
  });

  factory AnnouncementV2Model.fromJson(Map<String, dynamic> json) {
    return AnnouncementV2Model(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'date': date,
      };
}
