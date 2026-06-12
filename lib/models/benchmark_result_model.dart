class BenchmarkResultModel {
  static const pendingRealDeviceTesting = 'PENDING REAL DEVICE TESTING';

  final String id;
  final String category;
  final DateTime capturedAt;
  final Duration? duration;
  final int? memoryBytes;
  final double? fps;
  final int? frameDrops;
  final String device;
  final String notes;

  const BenchmarkResultModel({
    required this.id,
    required this.category,
    required this.capturedAt,
    this.duration,
    this.memoryBytes,
    this.fps,
    this.frameDrops,
    this.device = pendingRealDeviceTesting,
    this.notes = pendingRealDeviceTesting,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'capturedAt': capturedAt.toIso8601String(),
      'durationMs': duration?.inMilliseconds,
      'memoryBytes': memoryBytes,
      'fps': fps,
      'frameDrops': frameDrops,
      'device': device,
      'notes': notes,
    };
  }
}
