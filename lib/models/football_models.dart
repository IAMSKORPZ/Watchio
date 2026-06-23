class FootballCompetition {
  final int id;
  final String name;
  final String code;
  final String emblem;

  FootballCompetition({
    required this.id,
    required this.name,
    required this.code,
    required this.emblem,
  });

  factory FootballCompetition.fromJson(Map<String, dynamic> json) {
    return FootballCompetition(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      emblem: json['emblem'] ?? '',
    );
  }
}

class FootballTeam {
  final int id;
  final String name;
  final String shortName;
  final String tla;
  final String crest;

  FootballTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.tla,
    required this.crest,
  });

  factory FootballTeam.fromJson(Map<String, dynamic> json) {
    return FootballTeam(
      id: json['id'],
      name: json['name'],
      shortName: json['shortName'] ?? '',
      tla: json['tla'] ?? '',
      crest: json['crest'] ?? '',
    );
  }
}

class FootballMatch {
  final int id;
  final String status;
  final DateTime utcDate;
  final String competitionName;
  final String competitionCode;
  final String competitionEmblem;
  final String areaName;
  final String? stage;
  final String? group;
  final int? matchday;
  final DateTime? lastUpdated;
  final String? winner;
  final String? duration;
  final int? halfTimeHomeScore;
  final int? halfTimeAwayScore;
  final String? refereeName;
  final String? refereeNationality;
  final FootballTeam homeTeam;
  final FootballTeam awayTeam;
  final FootballScore score;

  FootballMatch({
    required this.id,
    required this.status,
    required this.utcDate,
    required this.competitionName,
    this.competitionCode = '',
    this.competitionEmblem = '',
    this.areaName = '',
    this.stage,
    this.group,
    this.matchday,
    this.lastUpdated,
    this.winner,
    this.duration,
    this.halfTimeHomeScore,
    this.halfTimeAwayScore,
    this.refereeName,
    this.refereeNationality,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
  });

  factory FootballMatch.fromJson(Map<String, dynamic> json) {
    String compName = 'Unknown Competition';
    if (json['competition'] != null) {
      compName = json['competition']['name'] ?? 'Unknown Competition';
    }
    final competition = json['competition'] as Map<String, dynamic>?;
    final area = json['area'] as Map<String, dynamic>?;
    final score = json['score'] as Map<String, dynamic>?;
    final halfTime = score?['halfTime'] as Map<String, dynamic>?;
    final referees = json['referees'] is List ? json['referees'] as List : [];
    final typedReferees = referees.whereType<Map<String, dynamic>>();
    final referee = typedReferees.isEmpty ? null : typedReferees.first;

    return FootballMatch(
      id: json['id'],
      status: json['status'],
      utcDate: DateTime.parse(json['utcDate']),
      competitionName: compName,
      competitionCode: competition?['code'] ?? '',
      competitionEmblem: competition?['emblem'] ?? '',
      areaName: area?['name'] ?? '',
      stage: json['stage'],
      group: json['group'],
      matchday: json['matchday'],
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? ''),
      winner: score?['winner'],
      duration: score?['duration'],
      halfTimeHomeScore: halfTime?['home'],
      halfTimeAwayScore: halfTime?['away'],
      refereeName: referee?['name'],
      refereeNationality: referee?['nationality'],
      homeTeam: FootballTeam.fromJson(json['homeTeam']),
      awayTeam: FootballTeam.fromJson(json['awayTeam']),
      score: FootballScore.fromJson(json['score']),
    );
  }

  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED';
  bool get isFinished => status == 'FINISHED';
}

class FootballScore {
  final int? homeScore;
  final int? awayScore;

  FootballScore({this.homeScore, this.awayScore});

  factory FootballScore.fromJson(Map<String, dynamic> json) {
    final fullTime = json['fullTime'];
    return FootballScore(
      homeScore: fullTime['home'],
      awayScore: fullTime['away'],
    );
  }
}
