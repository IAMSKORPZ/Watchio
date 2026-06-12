enum ImportSessionStatus {
  pending,
  running,
  completed,
  cancelled,
  failed,
}

class ImportSessionModel {
  final String id;
  final String providerId;
  final String type;
  final ImportSessionStatus status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? failureReason;

  const ImportSessionModel({
    required this.id,
    required this.providerId,
    required this.type,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.failureReason,
  });

  ImportSessionModel copyWith({
    ImportSessionStatus? status,
    DateTime? finishedAt,
    String? failureReason,
  }) {
    return ImportSessionModel(
      id: id,
      providerId: providerId,
      type: type,
      status: status ?? this.status,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}
