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
  final FootballTeam homeTeam;
  final FootballTeam awayTeam;
  final FootballScore score;

  FootballMatch({
    required this.id,
    required this.status,
    required this.utcDate,
    required this.competitionName,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
  });

  factory FootballMatch.fromJson(Map<String, dynamic> json) {
    return FootballMatch(
      id: json['id'],
      status: json['status'],
      utcDate: DateTime.parse(json['utcDate']),
      competitionName: json['competition']['name'],
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
