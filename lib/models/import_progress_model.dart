class ImportProgressModel {
  final String currentItem;
  final int processedItems;
  final int? totalItems;
  final DateTime startedAt;

  const ImportProgressModel({
    required this.currentItem,
    required this.processedItems,
    required this.startedAt,
    this.totalItems,
  });

  double? get percentage {
    final total = totalItems;
    if (total == null || total <= 0) return null;
    return (processedItems / total).clamp(0, 1).toDouble();
  }

  Duration get elapsedTime => DateTime.now().difference(startedAt);

  Duration? get estimatedRemainingTime {
    final percent = percentage;
    if (percent == null || percent <= 0) return null;
    final totalMs = elapsedTime.inMilliseconds / percent;
    return Duration(milliseconds: (totalMs - elapsedTime.inMilliseconds).round());
  }

  ImportProgressModel copyWith({
    String? currentItem,
    int? processedItems,
    int? totalItems,
  }) {
    return ImportProgressModel(
      currentItem: currentItem ?? this.currentItem,
      processedItems: processedItems ?? this.processedItems,
      totalItems: totalItems ?? this.totalItems,
      startedAt: startedAt,
    );
  }
}

typedef ImportProgressCallback = void Function(ImportProgressModel progress);

class ImportCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const ImportCancelledException();
    }
  }
}

class ImportCancelledException implements Exception {
  const ImportCancelledException();

  @override
  String toString() => 'Import cancelled';
}
