import 'package:flutter/material.dart';

// 大会の種類
enum TournamentType {
  spring,      // 春の大会（県大会のみ）
  summer,      // 夏の大会（県大会→全国大会）
  autumn,      // 秋の大会（県大会のみ、春の全国大会予選）
  springNational, // 春の全国大会
}

// 大会の段階
enum TournamentStage {
  prefectural, // 県大会
  national,    // 全国大会
}

// 試合の段階
enum GameRound {
  firstRound,      // 1回戦
  secondRound,     // 2回戦
  thirdRound,      // 3回戦
  quarterFinal,    // 準々決勝
  semiFinal,       // 準決勝
  championship,    // 決勝
}

// トーナメント試合結果
class TournamentGameResult {
  final int homeScore;
  final int awayScore;
  final String homeSchoolId;
  final String awaySchoolId;
  final String winnerSchoolId;
  final String loserSchoolId;
  final DateTime createdAt;

  const TournamentGameResult({
    required this.homeScore,
    required this.awayScore,
    required this.homeSchoolId,
    required this.awaySchoolId,
    required this.winnerSchoolId,
    required this.loserSchoolId,
    required this.createdAt,
  });

  // JSON変換
  Map<String, dynamic> toJson() => {
    'homeScore': homeScore,
    'awayScore': awayScore,
    'homeSchoolId': homeSchoolId,
    'awaySchoolId': awaySchoolId,
    'winnerSchoolId': winnerSchoolId,
    'loserSchoolId': loserSchoolId,
    'createdAt': createdAt.toIso8601String(),
  };

  // JSONから復元
  factory TournamentGameResult.fromJson(Map<String, dynamic> json) {
    return TournamentGameResult(
      homeScore: json['homeScore'] as int,
      awayScore: json['awayScore'] as int,
      homeSchoolId: json['homeSchoolId'] as String,
      awaySchoolId: json['awaySchoolId'] as String,
      winnerSchoolId: json['winnerSchoolId'] as String,
      loserSchoolId: json['loserSchoolId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

// 高校野球大会クラス
class HighSchoolTournament {
  final String id;
  final int year;
  final TournamentType type;
  final TournamentStage stage;
  final List<TournamentGame> games;
  final List<TournamentGame> completedGames;
  final Map<String, SchoolStanding> standings;
  final List<String> participatingSchools;
  final List<String> eliminatedSchools;
  final String? championSchoolId;
  final String? runnerUpSchoolId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HighSchoolTournament({
    required this.id,
    required this.year,
    required this.type,
    required this.stage,
    required this.games,
    required this.completedGames,
    required this.standings,
    required this.participatingSchools,
    required this.eliminatedSchools,
    this.championSchoolId,
    this.runnerUpSchoolId,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  // コピーメソッド
  HighSchoolTournament copyWith({
    String? id,
    int? year,
    TournamentType? type,
    TournamentStage? stage,
    List<TournamentGame>? games,
    List<TournamentGame>? completedGames,
    Map<String, SchoolStanding>? standings,
    List<String>? participatingSchools,
    List<String>? eliminatedSchools,
    String? championSchoolId,
    String? runnerUpSchoolId,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HighSchoolTournament(
      id: id ?? this.id,
      year: year ?? this.year,
      type: type ?? this.type,
      stage: stage ?? this.stage,
      games: games ?? this.games,
      completedGames: completedGames ?? this.completedGames,
      standings: standings ?? this.standings,
      participatingSchools: participatingSchools ?? this.participatingSchools,
      eliminatedSchools: eliminatedSchools ?? this.eliminatedSchools,
      championSchoolId: championSchoolId ?? this.championSchoolId,
      runnerUpSchoolId: runnerUpSchoolId ?? this.runnerUpSchoolId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 指定週の試合を取得
  List<TournamentGame> getGamesForWeek(int month, int week) {
    return games.where((game) => 
      game.month == month && game.week == week
    ).toList();
  }

  // 指定週の未完了試合を取得
  List<TournamentGame> getUncompletedGamesForWeek(int month, int week) {
    return getGamesForWeek(month, week)
        .where((game) => !game.isCompleted)
        .toList();
  }

  // 大会が進行中かチェック
  bool get isInProgress {
    return !isCompleted && games.any((game) => !game.isCompleted);
  }

  // 現在の段階を取得
  GameRound? get currentRound {
    if (games.isEmpty) return null;
    
    final uncompletedGames = games.where((game) => !game.isCompleted).toList();
    if (uncompletedGames.isEmpty) return null;
    
    return uncompletedGames.first.round;
  }

  // 優勝校名を取得
  String? get championSchoolName {
    if (championSchoolId == null) return null;
    final standing = standings[championSchoolId];
    return standing?.schoolName;
  }

  // 準優勝校名を取得
  String? get runnerUpSchoolName {
    if (runnerUpSchoolId == null) return null;
    final standing = standings[runnerUpSchoolId];
    return standing?.schoolName;
  }

  // JSON変換メソッド
  Map<String, dynamic> toJson() => {
    'id': id,
    'year': year,
    'type': type.name,
    'stage': stage.name,
    'games': games.map((g) => g.toJson()).toList(),
    'completedGames': completedGames.map((g) => g.toJson()).toList(),
    'standings': standings.map((k, v) => MapEntry(k, v.toJson())),
    'participatingSchools': participatingSchools,
    'eliminatedSchools': eliminatedSchools,
    'championSchoolId': championSchoolId,
    'runnerUpSchoolId': runnerUpSchoolId,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory HighSchoolTournament.fromJson(Map<String, dynamic> json) {
    return HighSchoolTournament(
      id: json['id'],
      year: json['year'],
      type: TournamentType.values.firstWhere((t) => t.name == json['type']),
      stage: TournamentStage.values.firstWhere((s) => s.name == json['stage']),
      games: (json['games'] as List).map((g) => TournamentGame.fromJson(g)).toList(),
      completedGames: (json['completedGames'] as List).map((g) => TournamentGame.fromJson(g)).toList(),
      standings: (json['standings'] as Map<String, dynamic>).map((k, v) => MapEntry(k, SchoolStanding.fromJson(v))),
      participatingSchools: List<String>.from(json['participatingSchools']),
      eliminatedSchools: List<String>.from(json['eliminatedSchools']),
      championSchoolId: json['championSchoolId'],
      runnerUpSchoolId: json['runnerUpSchoolId'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// 高校野球大会の試合クラス
class TournamentGame {
  final String id;
  final String homeSchoolId;
  final String awaySchoolId;
  final GameRound round;
  final int month;
  final int week;
  final int dayOfWeek;
  final bool isCompleted;
  final dynamic result; // GameResult or TournamentGameResult
  final DateTime createdAt;
  final DateTime updatedAt;

  const TournamentGame({
    required this.id,
    required this.homeSchoolId,
    required this.awaySchoolId,
    required this.round,
    required this.month,
    required this.week,
    required this.dayOfWeek,
    required this.isCompleted,
    this.result,
    required this.createdAt,
    required this.updatedAt,
  });

  // コピーメソッド
  TournamentGame copyWith({
    String? id,
    String? homeSchoolId,
    String? awaySchoolId,
    GameRound? round,
    int? month,
    int? week,
    int? dayOfWeek,
    bool? isCompleted,
    dynamic result,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentGame(
      id: id ?? this.id,
      homeSchoolId: homeSchoolId ?? this.homeSchoolId,
      awaySchoolId: awaySchoolId ?? this.awaySchoolId,
      round: round ?? this.round,
      month: month ?? this.month,
      week: week ?? this.week,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isCompleted: isCompleted ?? this.isCompleted,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 試合を完了させる
  TournamentGame completeGame(GameResult result) {
    return copyWith(
      isCompleted: true,
      result: result,
      updatedAt: DateTime.now(),
    );
  }

  // トーナメント試合を完了させる
  TournamentGame completeTournamentGame(TournamentGameResult result) {
    return copyWith(
      isCompleted: true,
      result: result,
      updatedAt: DateTime.now(),
    );
  }

  // 勝者校IDを取得
  String? get winnerSchoolId {
    if (result == null) return null;
    if (result is TournamentGameResult) {
      return (result as TournamentGameResult).winnerSchoolId;
    } else if (result is GameResult) {
      return (result as GameResult).isHomeWin ? homeSchoolId : awaySchoolId;
    }
    return null;
  }

  // 敗者校IDを取得
  String? get loserSchoolId {
    if (result == null) return null;
    if (result is TournamentGameResult) {
      return (result as TournamentGameResult).loserSchoolId;
    } else if (result is GameResult) {
      return (result as GameResult).isHomeWin ? awaySchoolId : homeSchoolId;
    }
    return null;
  }

  // JSON変換メソッド
  Map<String, dynamic> toJson() => {
    'id': id,
    'homeSchoolId': homeSchoolId,
    'awaySchoolId': awaySchoolId,
    'round': round.name,
    'month': month,
    'week': week,
    'dayOfWeek': dayOfWeek,
    'isCompleted': isCompleted,
    'result': result?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TournamentGame.fromJson(Map<String, dynamic> json) {
    dynamic result;
    if (json['result'] != null) {
      // TournamentGameResultかGameResultかを判定して適切に復元
      if (json['result'].containsKey('winnerSchoolId')) {
        result = TournamentGameResult.fromJson(json['result']);
      } else {
        result = GameResult.fromJson(json['result']);
      }
    }
    
    return TournamentGame(
      id: json['id'],
      homeSchoolId: json['homeSchoolId'],
      awaySchoolId: json['awaySchoolId'],
      round: GameRound.values.firstWhere((r) => r.name == json['round']),
      month: json['month'],
      week: json['week'],
      dayOfWeek: json['dayOfWeek'],
      isCompleted: json['isCompleted'],
      result: result,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// 試合結果クラス
class GameResult {
  final String homeSchoolId;
  final String awaySchoolId;
  final int homeScore;
  final int awayScore;
  final bool isHomeWin;
  final int homeHits;
  final int awayHits;
  final int homeErrors;
  final int awayErrors;
  final List<String> homeHighlights;
  final List<String> awayHighlights;
  final DateTime createdAt;

  const GameResult({
    required this.homeSchoolId,
    required this.awaySchoolId,
    required this.homeScore,
    required this.awayScore,
    required this.isHomeWin,
    required this.homeHits,
    required this.awayHits,
    required this.homeErrors,
    required this.awayErrors,
    required this.homeHighlights,
    required this.awayHighlights,
    required this.createdAt,
  });

  // コピーメソッド
  GameResult copyWith({
    String? homeSchoolId,
    String? awaySchoolId,
    int? homeScore,
    int? awayScore,
    bool? isHomeWin,
    int? homeHits,
    int? awayHits,
    int? homeErrors,
    int? awayErrors,
    List<String>? homeHighlights,
    List<String>? awayHighlights,
    DateTime? createdAt,
  }) {
    return GameResult(
      homeSchoolId: homeSchoolId ?? this.homeSchoolId,
      awaySchoolId: awaySchoolId ?? this.awaySchoolId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      isHomeWin: isHomeWin ?? this.isHomeWin,
      homeHits: homeHits ?? this.homeHits,
      awayHits: awayHits ?? this.awayHits,
      homeErrors: homeErrors ?? this.homeErrors,
      awayErrors: awayErrors ?? this.awayErrors,
      homeHighlights: homeHighlights ?? this.homeHighlights,
      awayHighlights: awayHighlights ?? this.awayHighlights,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 得点差を取得
  int get scoreDifference {
    return (homeScore - awayScore).abs();
  }

  // 試合が接戦かチェック
  bool get isCloseGame {
    return scoreDifference <= 2;
  }

  // 試合が大差かチェック
  bool get isBlowout {
    return scoreDifference >= 5;
  }

  // 勝者校IDを取得
  String get winnerSchoolId {
    return isHomeWin ? homeSchoolId : awaySchoolId;
  }

  // 敗者校IDを取得
  String get loserSchoolId {
    return isHomeWin ? awaySchoolId : homeSchoolId;
  }

  // JSON変換メソッド
  Map<String, dynamic> toJson() => {
    'homeSchoolId': homeSchoolId,
    'awaySchoolId': awaySchoolId,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'isHomeWin': isHomeWin,
    'homeHits': homeHits,
    'awayHits': awayHits,
    'homeErrors': homeErrors,
    'awayErrors': awayErrors,
    'homeHighlights': homeHighlights,
    'awayHighlights': awayHighlights,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      homeSchoolId: json['homeSchoolId'],
      awaySchoolId: json['awaySchoolId'],
      homeScore: json['homeScore'],
      awayScore: json['awayScore'],
      isHomeWin: json['isHomeWin'],
      homeHits: json['homeHits'],
      awayHits: json['awayHits'],
      homeErrors: json['homeErrors'],
      awayErrors: json['awayErrors'],
      homeHighlights: List<String>.from(json['homeHighlights']),
      awayHighlights: List<String>.from(json['awayHighlights']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// 学校の戦績クラス
class SchoolStanding {
  final String schoolId;
  final String schoolName;
  final String schoolShortName;
  final int games;
  final int wins;
  final int losses;
  final double winningPercentage;
  final int runsScored;
  final int runsAllowed;
  final int runDifferential;
  final GameRound? bestResult;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SchoolStanding({
    required this.schoolId,
    required this.schoolName,
    required this.schoolShortName,
    required this.games,
    required this.wins,
    required this.losses,
    required this.winningPercentage,
    required this.runsScored,
    required this.runsAllowed,
    required this.runDifferential,
    this.bestResult,
    required this.createdAt,
    required this.updatedAt,
  });

  // コピーメソッド
  SchoolStanding copyWith({
    String? schoolId,
    String? schoolName,
    String? schoolShortName,
    int? games,
    int? wins,
    int? losses,
    double? winningPercentage,
    int? runsScored,
    int? runsAllowed,
    int? runDifferential,
    GameRound? bestResult,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolStanding(
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      schoolShortName: schoolShortName ?? this.schoolShortName,
      games: games ?? this.games,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      winningPercentage: winningPercentage ?? this.winningPercentage,
      runsScored: runsScored ?? this.runsScored,
      runsAllowed: runsAllowed ?? this.runsAllowed,
      runDifferential: runDifferential ?? this.runDifferential,
      bestResult: bestResult ?? this.bestResult,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 勝率を更新
  SchoolStanding updateWinningPercentage() {
    final totalGames = wins + losses;
    final newWinningPercentage = totalGames > 0 ? wins / totalGames : 0.0;
    return copyWith(
      winningPercentage: newWinningPercentage,
      updatedAt: DateTime.now(),
    );
  }

  // 得失点差を更新
  SchoolStanding updateRunDifferential() {
    final newRunDifferential = runsScored - runsAllowed;
    return copyWith(
      runDifferential: newRunDifferential,
      updatedAt: DateTime.now(),
    );
  }

  // JSON変換メソッド
  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    'schoolName': schoolName,
    'schoolShortName': schoolShortName,
    'games': games,
    'wins': wins,
    'losses': losses,
    'winningPercentage': winningPercentage,
    'runsScored': runsScored,
    'runsAllowed': runsAllowed,
    'runDifferential': runDifferential,
    'bestResult': bestResult?.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SchoolStanding.fromJson(Map<String, dynamic> json) {
    return SchoolStanding(
      schoolId: json['schoolId'],
      schoolName: json['schoolName'],
      schoolShortName: json['schoolShortName'],
      games: json['games'],
      wins: json['wins'],
      losses: json['losses'],
      winningPercentage: json['winningPercentage'],
      runsScored: json['runsScored'],
      runsAllowed: json['runsAllowed'],
      runDifferential: json['runDifferential'],
      bestResult: json['bestResult'] != null ? GameRound.values.firstWhere((r) => r.name == json['bestResult']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// 大会スケジュールクラス
class TournamentSchedule {
  final String id;
  final int year;
  final TournamentType type;
  final TournamentStage stage;
  final List<TournamentGame> games;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TournamentSchedule({
    required this.id,
    required this.year,
    required this.type,
    required this.stage,
    required this.games,
    required this.createdAt,
    required this.updatedAt,
  });

  // コピーメソッド
  TournamentSchedule copyWith({
    String? id,
    int? year,
    TournamentType? type,
    TournamentStage? stage,
    List<TournamentGame>? games,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentSchedule(
      id: id ?? this.id,
      year: year ?? this.year,
      type: type ?? this.type,
      stage: stage ?? this.stage,
      games: games ?? this.games,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 指定週の試合を取得
  List<TournamentGame> getGamesForWeek(int month, int week) {
    return games.where((game) => 
      game.month == month && game.week == week
    ).toList();
  }

  // 指定段階の試合を取得
  List<TournamentGame> getGamesForRound(GameRound round) {
    return games.where((game) => game.round == round).toList();
  }

  // 未完了の試合数を取得
  int get uncompletedGameCount {
    return games.where((game) => !game.isCompleted).length;
  }

  // 完了した試合数を取得
  int get completedGameCount {
    return games.where((game) => game.isCompleted).length;
  }

  // JSON変換メソッド
  Map<String, dynamic> toJson() => {
    'id': id,
    'year': year,
    'type': type.name,
    'stage': stage.name,
    'games': games.map((g) => g.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TournamentSchedule.fromJson(Map<String, dynamic> json) {
    return TournamentSchedule(
      id: json['id'],
      year: json['year'],
      type: TournamentType.values.firstWhere((t) => t.name == json['type']),
      stage: TournamentStage.values.firstWhere((s) => s.name == json['stage']),
      games: (json['games'] as List).map((g) => TournamentGame.fromJson(g)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// ラウンドの進行状況を表すクラス
class RoundProgress {
  final GameRound round;
  final int totalGames;
  final int completedGames;
  final bool isCompleted;
  final int remainingGames;

  const RoundProgress({
    required this.round,
    required this.totalGames,
    required this.completedGames,
    required this.isCompleted,
    required this.remainingGames,
  });

  /// 進行率を取得（0.0 ~ 1.0）
  double get progressRate {
    if (totalGames == 0) return 0.0;
    return completedGames / totalGames;
  }

  /// 進行率をパーセンテージで取得
  int get progressPercentage {
    return (progressRate * 100).round();
  }

  /// ラウンド名を日本語で取得
  String get roundName {
    switch (round) {
      case GameRound.firstRound:
        return '1回戦';
      case GameRound.secondRound:
        return '2回戦';
      case GameRound.thirdRound:
        return '3回戦';
      case GameRound.quarterFinal:
        return '準々決勝';
      case GameRound.semiFinal:
        return '準決勝';
      case GameRound.championship:
        return '決勝';
    }
  }

  /// 進行状況の説明文を取得
  String get progressDescription {
    if (isCompleted) {
      return '$roundName完了';
    }
    return '$roundName: $completedGames/$totalGames試合完了';
  }
}

/// トーナメント全体の進行状況を表すクラス
class TournamentProgress {
  final GameRound? currentRound;
  final GameRound? nextRound;
  final int totalGames;
  final int completedGames;
  final int remainingGames;
  final Map<GameRound, RoundProgress> roundProgress;
  final List<TournamentGame> nextGames;
  final bool isCompleted;
  final String? championSchoolId;
  final String? runnerUpSchoolId;

  const TournamentProgress({
    this.currentRound,
    this.nextRound,
    required this.totalGames,
    required this.completedGames,
    required this.remainingGames,
    required this.roundProgress,
    required this.nextGames,
    required this.isCompleted,
    this.championSchoolId,
    this.runnerUpSchoolId,
  });

  /// 全体の進行率を取得（0.0 ~ 1.0）
  double get overallProgressRate {
    if (totalGames == 0) return 0.0;
    return completedGames / totalGames;
  }

  /// 全体の進行率をパーセンテージで取得
  int get overallProgressPercentage {
    return (overallProgressRate * 100).round();
  }

  /// 現在のラウンド名を日本語で取得
  String get currentRoundName {
    if (currentRound == null) return '未開始';
    return _getRoundName(currentRound!);
  }

  /// 次のラウンド名を日本語で取得
  String get nextRoundName {
    if (nextRound == null) return 'なし';
    return _getRoundName(nextRound!);
  }

  /// 進行状況の概要説明を取得
  String get progressSummary {
    if (isCompleted) {
      return '大会完了';
    }
    if (currentRound == null) {
      return '大会未開始';
    }
    return '現在: $currentRoundName (${overallProgressPercentage}%完了)';
  }

  /// 次の試合予定の説明を取得
  String get nextGamesDescription {
    if (nextGames.isEmpty) {
      return '次の試合予定なし';
    }
    if (nextGames.length == 1) {
      final game = nextGames.first;
      return '次戦: ${game.month}月${game.week}週';
    }
    return '次戦: ${nextGames.first.month}月${nextGames.first.week}週 (他${nextGames.length - 1}試合予定)';
  }

  /// ラウンド名を日本語で取得（内部用）
  String _getRoundName(GameRound round) {
    switch (round) {
      case GameRound.firstRound:
        return '1回戦';
      case GameRound.secondRound:
        return '2回戦';
      case GameRound.thirdRound:
        return '3回戦';
      case GameRound.quarterFinal:
        return '準々決勝';
      case GameRound.semiFinal:
        return '準決勝';
      case GameRound.championship:
        return '決勝';
    }
  }

  /// 指定ラウンドの進行状況を取得
  RoundProgress? getRoundProgress(GameRound round) {
    return roundProgress[round];
  }

  /// 完了したラウンドのリストを取得
  List<GameRound> get completedRounds {
    return roundProgress.entries
        .where((entry) => entry.value.isCompleted)
        .map((entry) => entry.key)
        .toList();
  }

  /// 進行中のラウンドのリストを取得
  List<GameRound> get inProgressRounds {
    return roundProgress.entries
        .where((entry) => !entry.value.isCompleted && entry.value.completedGames > 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// 未開始のラウンドのリストを取得
  List<GameRound> get notStartedRounds {
    return roundProgress.entries
        .where((entry) => entry.value.completedGames == 0)
        .map((entry) => entry.key)
        .toList();
  }
}

/// トーナメント進行の予測情報を表すクラス
class TournamentProgressPrediction {
  final int estimatedCompletionMonth;
  final int estimatedCompletionWeek;
  final int estimatedRemainingWeeks;
  final bool isOnSchedule;
  final List<String> recommendedActions;

  const TournamentProgressPrediction({
    required this.estimatedCompletionMonth,
    required this.estimatedCompletionWeek,
    required this.estimatedRemainingWeeks,
    required this.isOnSchedule,
    required this.recommendedActions,
  });

  /// 完了予定日を文字列で取得
  String get estimatedCompletionDate {
    return '${estimatedCompletionMonth}月${estimatedCompletionWeek}週';
  }

  /// 残り週数を文字列で取得
  String get remainingWeeksText {
    if (estimatedRemainingWeeks == 0) return '今週完了予定';
    if (estimatedRemainingWeeks < 0) return '${estimatedRemainingWeeks.abs()}週遅延';
    return 'あと${estimatedRemainingWeeks}週';
  }

  /// スケジュール状況を文字列で取得
  String get scheduleStatus {
    if (isOnSchedule) return 'スケジュール通り';
    return 'スケジュール遅延';
  }

  /// 推奨アクションを文字列で取得
  String get recommendationsText {
    if (recommendedActions.isEmpty) return '特になし';
    return recommendedActions.join(', ');
  }
}

/// トーナメントの効率性評価を表すクラス
class TournamentEfficiencyRating {
  final double efficiencyScore;
  final String efficiencyLevel;
  final int overallProgressRate;
  final bool isOnSchedule;
  final int estimatedRemainingWeeks;
  final List<String> recommendations;

  const TournamentEfficiencyRating({
    required this.efficiencyScore,
    required this.efficiencyLevel,
    required this.overallProgressRate,
    required this.isOnSchedule,
    required this.estimatedRemainingWeeks,
    required this.recommendations,
  });

  /// 効率性スコアをパーセンテージで取得
  int get efficiencyScorePercentage {
    return (efficiencyScore * 100).round();
  }

  /// 効率性レベルの色を取得
  Color get efficiencyLevelColor {
    switch (efficiencyLevel) {
      case '優秀':
        return Colors.green;
      case '良好':
        return Colors.blue;
      case '普通':
        return Colors.orange;
      case '要改善':
        return Colors.red;
      case '問題あり':
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }

  /// 効率性の説明文を取得
  String get efficiencyDescription {
    return '$efficiencyLevel (${efficiencyScorePercentage}点)';
  }

  /// 推奨アクションを文字列で取得
  String get recommendationsText {
    if (recommendations.isEmpty) return '特になし';
    return recommendations.join(', ');
  }

  /// 効率性の詳細分析を取得
  String get detailedAnalysis {
    final analysis = <String>[];
    
    analysis.add('進行率: ${overallProgressRate}%');
    analysis.add('スケジュール: ${isOnSchedule ? "順調" : "遅延"}');
    analysis.add('残り週数: ${estimatedRemainingWeeks}週');
    analysis.add('効率性: $efficiencyLevel');
    
    return analysis.join(' | ');
  }
}
