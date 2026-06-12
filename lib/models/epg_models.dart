class EpgChannel {
  final String id;
  final String providerId;
  final String displayName;
  final String? iconUrl;

  const EpgChannel({
    required this.id,
    required this.providerId,
    required this.displayName,
    this.iconUrl,
  });
}

class EpgProgram {
  final String id;
  final String channelId;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String? category;
  final String? iconUrl;

  const EpgProgram({
    required this.id,
    required this.channelId,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.description,
    this.category,
    this.iconUrl,
  });

  bool overlaps(DateTime from, DateTime to) {
    return startAt.isBefore(to) && endAt.isAfter(from);
  }
}

class EpgSchedule {
  final String channelId;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<EpgProgram> programs;
  final DateTime cachedAt;

  const EpgSchedule({
    required this.channelId,
    required this.windowStart,
    required this.windowEnd,
    required this.programs,
    required this.cachedAt,
  });

  EpgProgram? get currentProgram {
    final now = DateTime.now();
    for (final program in programs) {
      if (!program.startAt.isAfter(now) && program.endAt.isAfter(now)) {
        return program;
      }
    }
    return null;
  }

  EpgProgram? get nextProgram {
    final now = DateTime.now();
    final upcoming = programs
        .where((program) => program.startAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
