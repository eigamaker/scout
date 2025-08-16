import 'package:flutter/foundation.dart';

// リーグの種類
enum League {
  central,    // セ・リーグ
  pacific,    // パ・リーグ
  minor,      // 二軍
}

// 選手成績クラス
class PlayerStats {
  final int? id;
  final int playerId; // PlayerテーブルのID
  final String? teamId; // ProfessionalTeamテーブルのID
  final int year; // 年度
  final League league; // リーグ
  final int games; // 試合数
  final int atBats; // 打席数
  final int hits; // 安打数
  final int doubles; // 二塁打数
  final int triples; // 三塁打数
  final int homeRuns; // 本塁打数
  final int runsBattedIn; // 打点数
  final int runs; // 得点数
  final int stolenBases; // 盗塁数
  final int caughtStealing; // 盗塁刺数
  final int walks; // 四球数
  final int strikeouts; // 三振数
  final double battingAverage; // 打率
  final double onBasePercentage; // 出塁率
  final double sluggingPercentage; // 長打率
  // 投手成績
  final int wins; // 勝利数
  final int losses; // 敗戦数
  final int saves; // セーブ数
  final int holds; // ホールド数
  final double inningsPitched; // 投球回数
  final int earnedRuns; // 自責点
  final double earnedRunAverage; // 防御率
  final int hitsAllowed; // 被安打数
  final int walksAllowed; // 与四球数
  final int strikeoutsPitched; // 奪三振数
  final int wildPitches; // 暴投数
  final int hitBatters; // 与死球数
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerStats({
    this.id,
    required this.playerId,
    this.teamId,
    required this.year,
    required this.league,
    this.games = 0,
    this.atBats = 0,
    this.hits = 0,
    this.doubles = 0,
    this.triples = 0,
    this.homeRuns = 0,
    this.runsBattedIn = 0,
    this.runs = 0,
    this.stolenBases = 0,
    this.caughtStealing = 0,
    this.walks = 0,
    this.strikeouts = 0,
    this.battingAverage = 0.0,
    this.onBasePercentage = 0.0,
    this.sluggingPercentage = 0.0,
    this.wins = 0,
    this.losses = 0,
    this.saves = 0,
    this.holds = 0,
    this.inningsPitched = 0.0,
    this.earnedRuns = 0,
    this.earnedRunAverage = 0.0,
    this.hitsAllowed = 0,
    this.walksAllowed = 0,
    this.strikeoutsPitched = 0,
    this.wildPitches = 0,
    this.hitBatters = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // リーグの文字列表現
  String get leagueText {
    switch (league) {
      case League.central:
        return 'セ・リーグ';
      case League.pacific:
        return 'パ・リーグ';
      case League.minor:
        return '二軍';
    }
  }

  // 打撃成績の計算
  double get calculatedBattingAverage {
    if (atBats == 0) return 0.0;
    return hits / atBats;
  }

  double get calculatedOnBasePercentage {
    if (atBats + walks == 0) return 0.0;
    return (hits + walks) / (atBats + walks);
  }

  double get calculatedSluggingPercentage {
    if (atBats == 0) return 0.0;
    final totalBases = hits + doubles + (triples * 2) + (homeRuns * 3);
    return totalBases / atBats;
  }

  // 投手成績の計算
  double get calculatedEarnedRunAverage {
    if (inningsPitched == 0) return 0.0;
    return (earnedRuns * 9) / inningsPitched;
  }

  // 打撃成績の評価
  String get battingEvaluation {
    if (battingAverage >= 0.350) return 'S級';
    if (battingAverage >= 0.300) return 'A級';
    if (battingAverage >= 0.250) return 'B級';
    if (battingAverage >= 0.200) return 'C級';
    return 'D級';
  }

  // 投手成績の評価
  String get pitchingEvaluation {
    if (earnedRunAverage <= 2.00) return 'S級';
    if (earnedRunAverage <= 3.00) return 'A級';
    if (earnedRunAverage <= 4.00) return 'B級';
    if (earnedRunAverage <= 5.00) return 'C級';
    return 'D級';
  }

  // 総合評価
  String get overallEvaluation {
    if (league == League.minor) {
      // 二軍の場合は打撃と投手の両方を考慮
      if (atBats > 0 && inningsPitched > 0) {
        // 二刀流
        final battingScore = _getBattingScore();
        final pitchingScore = _getPitchingScore();
        final totalScore = (battingScore + pitchingScore) / 2;
        return _getScoreGrade(totalScore);
      } else if (atBats > 0) {
        // 打者
        return _getScoreGrade(_getBattingScore());
      } else {
        // 投手
        return _getScoreGrade(_getPitchingScore());
      }
    } else {
      // 一軍の場合は打撃と投手の両方を考慮
      if (atBats > 0 && inningsPitched > 0) {
        // 二刀流
        final battingScore = _getBattingScore();
        final pitchingScore = _getPitchingScore();
        final totalScore = (battingScore + pitchingScore) / 2;
        return _getScoreGrade(totalScore);
      } else if (atBats > 0) {
        // 打者
        return _getScoreGrade(_getBattingScore());
      } else {
        // 投手
        return _getScoreGrade(_getPitchingScore());
      }
    }
  }

  // 打撃スコアを計算
  double _getBattingScore() {
    double score = 0.0;
    
    // 打率
    if (battingAverage >= 0.350) score += 20;
    else if (battingAverage >= 0.300) score += 15;
    else if (battingAverage >= 0.250) score += 10;
    else if (battingAverage >= 0.200) score += 5;
    
    // 出塁率
    if (onBasePercentage >= 0.400) score += 15;
    else if (onBasePercentage >= 0.350) score += 10;
    else if (onBasePercentage >= 0.300) score += 5;
    
    // 長打率
    if (sluggingPercentage >= 0.600) score += 15;
    else if (sluggingPercentage >= 0.500) score += 10;
    else if (sluggingPercentage >= 0.400) score += 5;
    
    // 本塁打
    if (homeRuns >= 30) score += 15;
    else if (homeRuns >= 20) score += 10;
    else if (homeRuns >= 10) score += 5;
    
    // 打点
    if (runsBattedIn >= 100) score += 15;
    else if (runsBattedIn >= 80) score += 10;
    else if (runsBattedIn >= 50) score += 5;
    
    return score;
  }

  // 投手スコアを計算
  double _getPitchingScore() {
    double score = 0.0;
    
    // 防御率
    if (earnedRunAverage <= 2.00) score += 25;
    else if (earnedRunAverage <= 3.00) score += 20;
    else if (earnedRunAverage <= 4.00) score += 15;
    else if (earnedRunAverage <= 5.00) score += 10;
    
    // 勝利数
    if (wins >= 15) score += 20;
    else if (wins >= 10) score += 15;
    else if (wins >= 5) score += 10;
    
    // 奪三振
    if (strikeoutsPitched >= 200) score += 15;
    else if (strikeoutsPitched >= 150) score += 10;
    else if (strikeoutsPitched >= 100) score += 5;
    
    // セーブ
    if (saves >= 30) score += 20;
    else if (saves >= 20) score += 15;
    else if (saves >= 10) score += 10;
    
    return score;
  }

  // スコアをグレードに変換
  String _getScoreGrade(double score) {
    if (score >= 80) return 'S級';
    if (score >= 60) return 'A級';
    if (score >= 40) return 'B級';
    if (score >= 20) return 'C級';
    return 'D級';
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'player_id': playerId,
    'team_id': teamId,
    'year': year,
    'league': league.index,
    'games': games,
    'at_bats': atBats,
    'hits': hits,
    'doubles': doubles,
    'triples': triples,
    'home_runs': homeRuns,
    'runs_batted_in': runsBattedIn,
    'runs': runs,
    'stolen_bases': stolenBases,
    'caught_stealing': caughtStealing,
    'walks': walks,
    'strikeouts': strikeouts,
    'batting_average': battingAverage,
    'on_base_percentage': onBasePercentage,
    'slugging_percentage': sluggingPercentage,
    'wins': wins,
    'losses': losses,
    'saves': saves,
    'holds': holds,
    'innings_pitched': inningsPitched,
    'earned_runs': earnedRuns,
    'earned_run_average': earnedRunAverage,
    'hits_allowed': hitsAllowed,
    'walks_allowed': walksAllowed,
    'strikeouts_pitched': strikeoutsPitched,
    'wild_pitches': wildPitches,
    'hit_batters': hitBatters,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      id: json['id'] as int?,
      playerId: json['player_id'] as int,
      teamId: json['team_id'] as String?,
      year: json['year'] as int,
      league: League.values[json['league'] as int],
      games: json['games'] as int? ?? 0,
      atBats: json['at_bats'] as int? ?? 0,
      hits: json['hits'] as int? ?? 0,
      doubles: json['doubles'] as int? ?? 0,
      triples: json['triples'] as int? ?? 0,
      homeRuns: json['home_runs'] as int? ?? 0,
      runsBattedIn: json['runs_batted_in'] as int? ?? 0,
      runs: json['runs'] as int? ?? 0,
      stolenBases: json['stolen_bases'] as int? ?? 0,
      caughtStealing: json['caught_stealing'] as int? ?? 0,
      walks: json['walks'] as int? ?? 0,
      strikeouts: json['strikeouts'] as int? ?? 0,
      battingAverage: (json['batting_average'] as num?)?.toDouble() ?? 0.0,
      onBasePercentage: (json['on_base_percentage'] as num?)?.toDouble() ?? 0.0,
      sluggingPercentage: (json['slugging_percentage'] as num?)?.toDouble() ?? 0.0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      saves: json['saves'] as int? ?? 0,
      holds: json['holds'] as int? ?? 0,
      inningsPitched: (json['innings_pitched'] as num?)?.toDouble() ?? 0.0,
      earnedRuns: json['earned_runs'] as int? ?? 0,
      earnedRunAverage: (json['earned_run_average'] as num?)?.toDouble() ?? 0.0,
      hitsAllowed: json['hits_allowed'] as int? ?? 0,
      walksAllowed: json['walks_allowed'] as int? ?? 0,
      strikeoutsPitched: json['strikeouts_pitched'] as int? ?? 0,
      wildPitches: json['wild_pitches'] as int? ?? 0,
      hitBatters: json['hit_batters'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // コピーメソッド
  PlayerStats copyWith({
    int? id,
    int? playerId,
    String? teamId,
    int? year,
    League? league,
    int? games,
    int? atBats,
    int? hits,
    int? doubles,
    int? triples,
    int? homeRuns,
    int? runsBattedIn,
    int? runs,
    int? stolenBases,
    int? caughtStealing,
    int? walks,
    int? strikeouts,
    double? battingAverage,
    double? onBasePercentage,
    double? sluggingPercentage,
    int? wins,
    int? losses,
    int? saves,
    int? holds,
    double? inningsPitched,
    int? earnedRuns,
    double? earnedRunAverage,
    int? hitsAllowed,
    int? walksAllowed,
    int? strikeoutsPitched,
    int? wildPitches,
    int? hitBatters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerStats(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      year: year ?? this.year,
      league: league ?? this.league,
      games: games ?? this.games,
      atBats: atBats ?? this.atBats,
      hits: hits ?? this.hits,
      doubles: doubles ?? this.doubles,
      triples: triples ?? this.triples,
      homeRuns: homeRuns ?? this.homeRuns,
      runsBattedIn: runsBattedIn ?? this.runsBattedIn,
      runs: runs ?? this.runs,
      stolenBases: stolenBases ?? this.stolenBases,
      caughtStealing: caughtStealing ?? this.caughtStealing,
      walks: walks ?? this.walks,
      strikeouts: strikeouts ?? this.strikeouts,
      battingAverage: battingAverage ?? this.battingAverage,
      onBasePercentage: onBasePercentage ?? this.onBasePercentage,
      sluggingPercentage: sluggingPercentage ?? this.sluggingPercentage,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      saves: saves ?? this.saves,
      holds: holds ?? this.holds,
      inningsPitched: inningsPitched ?? this.inningsPitched,
      earnedRuns: earnedRuns ?? this.earnedRuns,
      earnedRunAverage: earnedRunAverage ?? this.earnedRunAverage,
      hitsAllowed: hitsAllowed ?? this.hitsAllowed,
      walksAllowed: walksAllowed ?? this.walksAllowed,
      strikeoutsPitched: strikeoutsPitched ?? this.strikeoutsPitched,
      wildPitches: wildPitches ?? this.wildPitches,
      hitBatters: hitBatters ?? this.hitBatters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 成績を更新
  PlayerStats updateStats({
    int? games,
    int? atBats,
    int? hits,
    int? doubles,
    int? triples,
    int? homeRuns,
    int? runsBattedIn,
    int? runs,
    int? stolenBases,
    int? caughtStealing,
    int? walks,
    int? strikeouts,
    int? wins,
    int? losses,
    int? saves,
    int? holds,
    double? inningsPitched,
    int? earnedRuns,
    int? hitsAllowed,
    int? walksAllowed,
    int? strikeoutsPitched,
    int? wildPitches,
    int? hitBatters,
  }) {
    return copyWith(
      games: games ?? this.games,
      atBats: atBats ?? this.atBats,
      hits: hits ?? this.hits,
      doubles: doubles ?? this.doubles,
      triples: triples ?? this.triples,
      homeRuns: homeRuns ?? this.homeRuns,
      runsBattedIn: runsBattedIn ?? this.runsBattedIn,
      runs: runs ?? this.runs,
      stolenBases: stolenBases ?? this.stolenBases,
      caughtStealing: caughtStealing ?? this.caughtStealing,
      walks: walks ?? this.walks,
      strikeouts: strikeouts ?? this.strikeouts,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      saves: saves ?? this.saves,
      holds: holds ?? this.holds,
      inningsPitched: inningsPitched ?? this.inningsPitched,
      earnedRuns: earnedRuns ?? this.earnedRuns,
      hitsAllowed: hitsAllowed ?? this.hitsAllowed,
      walksAllowed: walksAllowed ?? this.walksAllowed,
      strikeoutsPitched: strikeoutsPitched ?? this.strikeoutsPitched,
      wildPitches: wildPitches ?? this.wildPitches,
      hitBatters: hitBatters ?? this.hitBatters,
      updatedAt: DateTime.now(),
    );
  }
}

// 選手成績管理クラス
class PlayerStatsManager {
  final List<PlayerStats> stats;
  
  PlayerStatsManager({List<PlayerStats>? stats}) : stats = stats ?? [];

  // 全成績を取得
  List<PlayerStats> getAllStats() => stats;

  // 特定の選手の成績を取得
  List<PlayerStats> getStatsByPlayer(int playerId) {
    return stats.where((stat) => stat.playerId == playerId).toList();
  }

  // 特定の球団の成績を取得
  List<PlayerStats> getStatsByTeam(String teamId) {
    return stats.where((stat) => stat.teamId == teamId).toList();
  }

  // 特定の年度の成績を取得
  List<PlayerStats> getStatsByYear(int year) {
    return stats.where((stat) => stat.year == year).toList();
  }

  // 特定のリーグの成績を取得
  List<PlayerStats> getStatsByLeague(League league) {
    return stats.where((stat) => stat.league == league).toList();
  }

  // 選手の年度別成績を取得
  List<PlayerStats> getPlayerYearlyStats(int playerId) {
    final playerStats = getStatsByPlayer(playerId);
    playerStats.sort((a, b) => b.year.compareTo(a.year));
    return playerStats;
  }

  // 選手の通算成績を計算
  PlayerStats getPlayerCareerStats(int playerId) {
    final playerStats = getStatsByPlayer(playerId);
    if (playerStats.isEmpty) {
      return PlayerStats(
        playerId: playerId,
        year: 0,
        league: League.central,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // 通算成績を計算
    int totalGames = 0;
    int totalAtBats = 0;
    int totalHits = 0;
    int totalDoubles = 0;
    int totalTriples = 0;
    int totalHomeRuns = 0;
    int totalRunsBattedIn = 0;
    int totalRuns = 0;
    int totalStolenBases = 0;
    int totalCaughtStealing = 0;
    int totalWalks = 0;
    int totalStrikeouts = 0;
    int totalWins = 0;
    int totalLosses = 0;
    int totalSaves = 0;
    int totalHolds = 0;
    double totalInningsPitched = 0.0;
    int totalEarnedRuns = 0;
    int totalHitsAllowed = 0;
    int totalWalksAllowed = 0;
    int totalStrikeoutsPitched = 0;
    int totalWildPitches = 0;
    int totalHitBatters = 0;

    for (final stat in playerStats) {
      totalGames += stat.games;
      totalAtBats += stat.atBats;
      totalHits += stat.hits;
      totalDoubles += stat.doubles;
      totalTriples += stat.triples;
      totalHomeRuns += stat.homeRuns;
      totalRunsBattedIn += stat.runsBattedIn;
      totalRuns += stat.runs;
      totalStolenBases += stat.stolenBases;
      totalCaughtStealing += stat.caughtStealing;
      totalWalks += stat.walks;
      totalStrikeouts += stat.strikeouts;
      totalWins += stat.wins;
      totalLosses += stat.losses;
      totalSaves += stat.saves;
      totalHolds += stat.holds;
      totalInningsPitched += stat.inningsPitched;
      totalEarnedRuns += stat.earnedRuns;
      totalHitsAllowed += stat.hitsAllowed;
      totalWalksAllowed += stat.walksAllowed;
      totalStrikeoutsPitched += stat.strikeoutsPitched;
      totalWildPitches += stat.wildPitches;
      totalHitBatters += stat.hitBatters;
    }

    return PlayerStats(
      playerId: playerId,
      year: 0, // 通算は0年
      league: League.central, // デフォルト
      games: totalGames,
      atBats: totalAtBats,
      hits: totalHits,
      doubles: totalDoubles,
      triples: totalTriples,
      homeRuns: totalHomeRuns,
      runsBattedIn: totalRunsBattedIn,
      runs: totalRuns,
      stolenBases: totalStolenBases,
      caughtStealing: totalCaughtStealing,
      walks: totalWalks,
      strikeouts: totalStrikeouts,
      wins: totalWins,
      losses: totalLosses,
      saves: totalSaves,
      holds: totalHolds,
      inningsPitched: totalInningsPitched,
      earnedRuns: totalEarnedRuns,
      hitsAllowed: totalHitsAllowed,
      walksAllowed: totalWalksAllowed,
      strikeoutsPitched: totalStrikeoutsPitched,
      wildPitches: totalWildPitches,
      hitBatters: totalHitBatters,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // 成績を追加
  void addStats(PlayerStats stat) {
    stats.add(stat);
  }

  // 成績を更新
  void updateStats(PlayerStats updatedStat) {
    final index = stats.indexWhere((stat) => stat.id == updatedStat.id);
    if (index != -1) {
      stats[index] = updatedStat;
    }
  }

  // 成績を削除
  void removeStats(int statId) {
    stats.removeWhere((stat) => stat.id == statId);
  }
}
