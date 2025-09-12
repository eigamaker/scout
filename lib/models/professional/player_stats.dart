import 'package:flutter/foundation.dart';

// 打者成績
class BatterStats {
  final int games;           // 試合数
  final int atBats;          // 打席数
  final int hits;            // 安打数
  final int doubles;         // 二塁打数
  final int triples;         // 三塁打数
  final int homeRuns;        // 本塁打数
  final int runsBattedIn;   // 打点数
  final int runs;            // 得点数
  final int walks;           // 四球数
  final int strikeouts;      // 三振数
  final int stolenBases;     // 盗塁数
  final int caughtStealing;  // 盗塁死数
  final int sacrificeBunts;  // 犠打数
  final int sacrificeFlies;  // 犠飛数
  final int hitByPitch;      // 死球数
  final int groundIntoDoublePlay; // 併殺打数

  BatterStats({
    this.games = 0,
    this.atBats = 0,
    this.hits = 0,
    this.doubles = 0,
    this.triples = 0,
    this.homeRuns = 0,
    this.runsBattedIn = 0,
    this.runs = 0,
    this.walks = 0,
    this.strikeouts = 0,
    this.stolenBases = 0,
    this.caughtStealing = 0,
    this.sacrificeBunts = 0,
    this.sacrificeFlies = 0,
    this.hitByPitch = 0,
    this.groundIntoDoublePlay = 0,
  });

  // 打率
  double get battingAverage {
    if (atBats == 0) return 0.0;
    return hits / atBats;
  }

  // 出塁率
  double get onBasePercentage {
    final plateAppearances = atBats + walks + hitByPitch + sacrificeFlies;
    if (plateAppearances == 0) return 0.0;
    return (hits + walks + hitByPitch) / plateAppearances;
  }

  // 長打率
  double get sluggingPercentage {
    if (atBats == 0) return 0.0;
    final totalBases = hits + doubles + (triples * 2) + (homeRuns * 3);
    return totalBases / atBats;
  }

  // OPS（出塁率 + 長打率）
  double get ops => onBasePercentage + sluggingPercentage;

  // 単打数
  int get singles => hits - doubles - triples - homeRuns;

  // 総塁打数
  int get totalBases => hits + doubles + (triples * 2) + (homeRuns * 3);

  // 成績を更新
  BatterStats updateStats({
    int? games,
    int? atBats,
    int? hits,
    int? doubles,
    int? triples,
    int? homeRuns,
    int? runsBattedIn,
    int? runs,
    int? walks,
    int? strikeouts,
    int? stolenBases,
    int? caughtStealing,
    int? sacrificeBunts,
    int? sacrificeFlies,
    int? hitByPitch,
    int? groundIntoDoublePlay,
  }) {
    return BatterStats(
      games: games ?? this.games,
      atBats: atBats ?? this.atBats,
      hits: hits ?? this.hits,
      doubles: doubles ?? this.doubles,
      triples: triples ?? this.triples,
      homeRuns: homeRuns ?? this.homeRuns,
      runsBattedIn: runsBattedIn ?? this.runsBattedIn,
      runs: runs ?? this.runs,
      walks: walks ?? this.walks,
      strikeouts: strikeouts ?? this.strikeouts,
      stolenBases: stolenBases ?? this.stolenBases,
      caughtStealing: caughtStealing ?? this.caughtStealing,
      sacrificeBunts: sacrificeBunts ?? this.sacrificeBunts,
      sacrificeFlies: sacrificeFlies ?? this.sacrificeFlies,
      hitByPitch: hitByPitch ?? this.hitByPitch,
      groundIntoDoublePlay: groundIntoDoublePlay ?? this.groundIntoDoublePlay,
    );
  }

  // 成績を加算
  BatterStats addStats(BatterStats other) {
    return BatterStats(
      games: games + other.games,
      atBats: atBats + other.atBats,
      hits: hits + other.hits,
      doubles: doubles + other.doubles,
      triples: triples + other.triples,
      homeRuns: homeRuns + other.homeRuns,
      runsBattedIn: runsBattedIn + other.runsBattedIn,
      runs: runs + other.runs,
      walks: walks + other.walks,
      strikeouts: strikeouts + other.strikeouts,
      stolenBases: stolenBases + other.stolenBases,
      caughtStealing: caughtStealing + other.caughtStealing,
      sacrificeBunts: sacrificeBunts + other.sacrificeBunts,
      sacrificeFlies: sacrificeFlies + other.sacrificeFlies,
      hitByPitch: hitByPitch + other.hitByPitch,
      groundIntoDoublePlay: groundIntoDoublePlay + other.groundIntoDoublePlay,
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'games': games,
    'atBats': atBats,
    'hits': hits,
    'doubles': doubles,
    'triples': triples,
    'homeRuns': homeRuns,
    'runsBattedIn': runsBattedIn,
    'runs': runs,
    'walks': walks,
    'strikeouts': strikeouts,
    'stolenBases': stolenBases,
    'caughtStealing': caughtStealing,
    'sacrificeBunts': sacrificeBunts,
    'sacrificeFlies': sacrificeFlies,
    'hitByPitch': hitByPitch,
    'groundIntoDoublePlay': groundIntoDoublePlay,
  };

  factory BatterStats.fromJson(Map<String, dynamic> json) {
    return BatterStats(
      games: json['games'] as int? ?? 0,
      atBats: json['atBats'] as int? ?? 0,
      hits: json['hits'] as int? ?? 0,
      doubles: json['doubles'] as int? ?? 0,
      triples: json['triples'] as int? ?? 0,
      homeRuns: json['homeRuns'] as int? ?? 0,
      runsBattedIn: json['runsBattedIn'] as int? ?? 0,
      runs: json['runs'] as int? ?? 0,
      walks: json['walks'] as int? ?? 0,
      strikeouts: json['strikeouts'] as int? ?? 0,
      stolenBases: json['stolenBases'] as int? ?? 0,
      caughtStealing: json['caughtStealing'] as int? ?? 0,
      sacrificeBunts: json['sacrificeBunts'] as int? ?? 0,
      sacrificeFlies: json['sacrificeFlies'] as int? ?? 0,
      hitByPitch: json['hitByPitch'] as int? ?? 0,
      groundIntoDoublePlay: json['groundIntoDoublePlay'] as int? ?? 0,
    );
  }
}

// 投手成績
class PitcherStats {
  final int games;           // 試合数
  final int gamesStarted;    // 先発数
  final int completeGames;   // 完投数
  final int shutouts;        // 完封数
  final int wins;            // 勝利数
  final int losses;          // 敗戦数
  final int saves;           // セーブ数
  final int holds;           // ホールド数
  final double inningsPitched; // 投球回数
  final int hits;            // 被安打数
  final int runs;            // 失点数
  final int earnedRuns;      // 自責点
  final int homeRuns;        // 被本塁打数
  final int walks;           // 与四球数
  final int strikeouts;      // 奪三振数
  final int hitBatters;      // 与死球数
  final int wildPitches;     // 暴投数
  final int balks;           // ボーク数

  PitcherStats({
    this.games = 0,
    this.gamesStarted = 0,
    this.completeGames = 0,
    this.shutouts = 0,
    this.wins = 0,
    this.losses = 0,
    this.saves = 0,
    this.holds = 0,
    this.inningsPitched = 0.0,
    this.hits = 0,
    this.runs = 0,
    this.earnedRuns = 0,
    this.homeRuns = 0,
    this.walks = 0,
    this.strikeouts = 0,
    this.hitBatters = 0,
    this.wildPitches = 0,
    this.balks = 0,
  });

  // 防御率
  double get earnedRunAverage {
    if (inningsPitched == 0.0) return 0.0;
    return (earnedRuns * 9) / inningsPitched;
  }

  // 勝率
  double get winningPercentage {
    final totalGames = wins + losses;
    if (totalGames == 0) return 0.0;
    return wins / totalGames;
  }

  // WHIP（1回あたりの出塁者数）
  double get whip {
    if (inningsPitched == 0.0) return 0.0;
    return (hits + walks) / inningsPitched;
  }

  // 奪三振率
  double get strikeoutsPerNine {
    if (inningsPitched == 0.0) return 0.0;
    return (strikeouts * 9) / inningsPitched;
  }

  // 与四球率
  double get walksPerNine {
    if (inningsPitched == 0.0) return 0.0;
    return (walks * 9) / inningsPitched;
  }

  // 成績を更新
  PitcherStats updateStats({
    int? games,
    int? gamesStarted,
    int? completeGames,
    int? shutouts,
    int? wins,
    int? losses,
    int? saves,
    int? holds,
    double? inningsPitched,
    int? hits,
    int? runs,
    int? earnedRuns,
    int? homeRuns,
    int? walks,
    int? strikeouts,
    int? hitBatters,
    int? wildPitches,
    int? balks,
  }) {
    return PitcherStats(
      games: games ?? this.games,
      gamesStarted: gamesStarted ?? this.gamesStarted,
      completeGames: completeGames ?? this.completeGames,
      shutouts: shutouts ?? this.shutouts,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      saves: saves ?? this.saves,
      holds: holds ?? this.holds,
      inningsPitched: inningsPitched ?? this.inningsPitched,
      hits: hits ?? this.hits,
      runs: runs ?? this.runs,
      earnedRuns: earnedRuns ?? this.earnedRuns,
      homeRuns: homeRuns ?? this.homeRuns,
      walks: walks ?? this.walks,
      strikeouts: strikeouts ?? this.strikeouts,
      hitBatters: hitBatters ?? this.hitBatters,
      wildPitches: wildPitches ?? this.wildPitches,
      balks: balks ?? this.balks,
    );
  }

  // 成績を加算
  PitcherStats addStats(PitcherStats other) {
    return PitcherStats(
      games: games + other.games,
      gamesStarted: gamesStarted + other.gamesStarted,
      completeGames: completeGames + other.completeGames,
      shutouts: shutouts + other.shutouts,
      wins: wins + other.wins,
      losses: losses + other.losses,
      saves: saves + other.saves,
      holds: holds + other.holds,
      inningsPitched: inningsPitched + other.inningsPitched,
      hits: hits + other.hits,
      runs: runs + other.runs,
      earnedRuns: earnedRuns + other.earnedRuns,
      homeRuns: homeRuns + other.homeRuns,
      walks: walks + other.walks,
      strikeouts: strikeouts + other.strikeouts,
      hitBatters: hitBatters + other.hitBatters,
      wildPitches: wildPitches + other.wildPitches,
      balks: balks + other.balks,
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'games': games,
    'gamesStarted': gamesStarted,
    'completeGames': completeGames,
    'shutouts': shutouts,
    'wins': wins,
    'losses': losses,
    'saves': saves,
    'holds': holds,
    'inningsPitched': inningsPitched,
    'hits': hits,
    'runs': runs,
    'earnedRuns': earnedRuns,
    'homeRuns': homeRuns,
    'walks': walks,
    'strikeouts': strikeouts,
    'hitBatters': hitBatters,
    'wildPitches': wildPitches,
    'balks': balks,
  };

  factory PitcherStats.fromJson(Map<String, dynamic> json) {
    return PitcherStats(
      games: json['games'] as int? ?? 0,
      gamesStarted: json['gamesStarted'] as int? ?? 0,
      completeGames: json['completeGames'] as int? ?? 0,
      shutouts: json['shutouts'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      holds: json['holds'] as int? ?? 0,
      inningsPitched: (json['inningsPitched'] as num?)?.toDouble() ?? 0.0,
      hits: json['hits'] as int? ?? 0,
      runs: json['runs'] as int? ?? 0,
      earnedRuns: json['earnedRuns'] as int? ?? 0,
      homeRuns: json['homeRuns'] as int? ?? 0,
      walks: json['walks'] as int? ?? 0,
      strikeouts: json['strikeouts'] as int? ?? 0,
      hitBatters: json['hitBatters'] as int? ?? 0,
      wildPitches: json['wildPitches'] as int? ?? 0,
      balks: json['balks'] as int? ?? 0,
    );
  }
}

// 選手の総合成績
class PlayerSeasonStats {
  final String playerId;
  final String teamId;
  final int season;
  final BatterStats? batterStats;
  final PitcherStats? pitcherStats;
  final DateTime lastUpdated;

  PlayerSeasonStats({
    required this.playerId,
    required this.teamId,
    required this.season,
    this.batterStats,
    this.pitcherStats,
    required this.lastUpdated,
  });

  // 打者としての成績があるか
  bool get isBatter => batterStats != null;

  // 投手としての成績があるか
  bool get isPitcher => pitcherStats != null;

  // 打者成績を更新
  PlayerSeasonStats updateBatterStats(BatterStats newStats) {
    final updatedBatterStats = batterStats?.addStats(newStats) ?? newStats;
    return copyWith(
      batterStats: updatedBatterStats,
      lastUpdated: DateTime.now(),
    );
  }

  // 投手成績を更新
  PlayerSeasonStats updatePitcherStats(PitcherStats newStats) {
    final updatedPitcherStats = pitcherStats?.addStats(newStats) ?? newStats;
    return copyWith(
      pitcherStats: updatedPitcherStats,
      lastUpdated: DateTime.now(),
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'teamId': teamId,
    'season': season,
    'batterStats': batterStats?.toJson(),
    'pitcherStats': pitcherStats?.toJson(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory PlayerSeasonStats.fromJson(Map<String, dynamic> json) {
    return PlayerSeasonStats(
      playerId: json['playerId'] as String,
      teamId: json['teamId'] as String,
      season: json['season'] as int,
      batterStats: json['batterStats'] != null 
        ? BatterStats.fromJson(json['batterStats']) 
        : null,
      pitcherStats: json['pitcherStats'] != null 
        ? PitcherStats.fromJson(json['pitcherStats']) 
        : null,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  // コピーメソッド
  PlayerSeasonStats copyWith({
    String? playerId,
    String? teamId,
    int? season,
    BatterStats? batterStats,
    PitcherStats? pitcherStats,
    DateTime? lastUpdated,
  }) {
    return PlayerSeasonStats(
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      season: season ?? this.season,
      batterStats: batterStats ?? this.batterStats,
      pitcherStats: pitcherStats ?? this.pitcherStats,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}