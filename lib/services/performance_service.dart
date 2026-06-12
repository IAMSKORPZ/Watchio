import 'package:flutter/foundation.dart';

class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime capturedAt;
  final Map<String, Object?> metadata;

  const PerformanceMetric({
    required this.name,
    required this.duration,
    required this.capturedAt,
    this.metadata = const {},
  });
}

class PerformanceService {
  static final List<PerformanceMetric> _metrics = [];

  static List<PerformanceMetric> get metrics => List.unmodifiable(_metrics);

  static Future<T> track<T>(
    String name,
    Future<T> Function() action, {
    Map<String, Object?> metadata = const {},
  }) async {
    if (!kDebugMode) return action();

    final stopwatch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      stopwatch.stop();
      _metrics.add(
        PerformanceMetric(
          name: name,
          duration: stopwatch.elapsed,
          capturedAt: DateTime.now(),
          metadata: metadata,
        ),
      );
      if (_metrics.length > 200) {
        _metrics.removeRange(0, _metrics.length - 200);
      }
      debugPrint('[perf] $name ${stopwatch.elapsedMilliseconds}ms $metadata');
    }
  }

  static void clear() {
    _metrics.clear();
  }
}
