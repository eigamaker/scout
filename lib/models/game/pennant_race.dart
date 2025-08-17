import 'package:flutter/foundation.dart';
import '../professional/professional_team.dart';
import '../professional/team_history.dart';
import '../professional/professional_player.dart';
import '../professional/player_stats.dart';
import '../professional/depth_chart.dart';
import '../../services/depth_chart_service.dart';
import 'dart:math';

// 試合の種類
enum GameType {
  home,    // ホームゲーム
  away,    // アウェイゲーム
}

// 試合結果
class GameResult {
  final String homeTeamId;
  final String awayTeamId;
  final int homeScore;
  final int awayScore;
  final int inning; // 9回または延長回数
  final bool isExtraInnings;
  final DateTime gameDate;
  final String? winningPitcher;
  final String? losingPitcher;
  final String? savePitcher;
  final Map<String, BatterStats> homeTeamBatterStats; // ホームチーム打者成績
  final Map<String, BatterStats> awayTeamBatterStats; // アウェイチーム打者成績
  final Map<String, PitcherStats> homeTeamPitcherStats; // ホームチーム投手成績
  final Map<String, PitcherStats> awayTeamPitcherStats; // アウェイチーム投手成績

  GameResult({
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.inning,
    this.isExtraInnings = false,
    required this.gameDate,
    this.winningPitcher,
    this.losingPitcher,
    this.savePitcher,
    this.homeTeamBatterStats = const {},
    this.awayTeamBatterStats = const {},
    this.homeTeamPitcherStats = const {},
    this.awayTeamPitcherStats = const {},
  });

  // ホームチームの勝敗
  bool get isHomeWin => homeScore > awayScore;
  bool get isAwayWin => awayScore > homeScore;
  bool get isTie => homeScore == awayScore;

  // 勝者チームID
  String? get winnerId => isHomeWin ? homeTeamId : (isAwayWin ? awayTeamId : null);
  String? get loserId => isAwayWin ? homeTeamId : (isHomeWin ? awayTeamId : null);

  // スコア表示用
  String get scoreDisplay => '$homeScore - $awayScore';

  /// JSON形式に変換
  Map<String, dynamic> toJson() => {
    'homeTeamId': homeTeamId,
    'awayTeamId': awayTeamId,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'inning': inning,
    'isExtraInnings': isExtraInnings,
    'gameDate': gameDate.toIso8601String(),
    'winningPitcher': winningPitcher,
    'losingPitcher': losingPitcher,
    'savePitcher': savePitcher,
    'homeTeamBatterStats': homeTeamBatterStats.map((key, value) => MapEntry(key, value.toJson())),
    'awayTeamBatterStats': awayTeamBatterStats.map((key, value) => MapEntry(key, value.toJson())),
    'homeTeamPitcherStats': homeTeamPitcherStats.map((key, value) => MapEntry(key, value.toJson())),
    'awayTeamPitcherStats': awayTeamPitcherStats.map((key, value) => MapEntry(key, value.toJson())),
  };

  /// JSONから復元
  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      homeTeamId: json['homeTeamId'] as String,
      awayTeamId: json['awayTeamId'] as String,
      homeScore: json['homeScore'] as int,
      awayScore: json['awayScore'] as int,
      inning: json['inning'] as int,
      isExtraInnings: json['isExtraInnings'] as bool? ?? false,
      gameDate: DateTime.parse(json['gameDate'] as String),
      winningPitcher: json['winningPitcher'] as String?,
      losingPitcher: json['losingPitcher'] as String?,
      savePitcher: json['savePitcher'] as String?,
      homeTeamBatterStats: (json['homeTeamBatterStats'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, BatterStats.fromJson(value)),
      ) ?? {},
      awayTeamBatterStats: (json['awayTeamBatterStats'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, BatterStats.fromJson(value)),
      ) ?? {},
      homeTeamPitcherStats: (json['homeTeamPitcherStats'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, PitcherStats.fromJson(value)),
      ) ?? {},
      awayTeamPitcherStats: (json['awayTeamPitcherStats'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, PitcherStats.fromJson(value)),
      ) ?? {},
    );
  }
}

// ペナントレースのスケジュール
class PennantRaceSchedule {
  final int year;
  final List<GameSchedule> games;
  final DateTime seasonStart; // 4月1週
  final DateTime seasonEnd;   // 10月2週

  PennantRaceSchedule({
    required this.year,
    required this.games,
    required this.seasonStart,
    required this.seasonEnd,
  });

  // 指定週の試合を取得
  List<GameSchedule> getGamesForWeek(int month, int week) {
    return games.where((game) => 
      game.month == month && game.week == week
    ).toList();
  }

  // 指定チームの指定週の試合を取得
  List<GameSchedule> getTeamGamesForWeek(String teamId, int month, int week) {
    return games.where((game) => 
      (game.month == month && game.week == week) &&
      (game.homeTeamId == teamId || game.awayTeamId == teamId)
    ).toList();
  }

  // 指定チームの全試合を取得
  List<GameSchedule> getTeamGames(String teamId) {
    return games.where((game) => 
      game.homeTeamId == teamId || game.awayTeamId == teamId
    ).toList();
  }

  /// JSON形式に変換
  Map<String, dynamic> toJson() => {
    'year': year,
    'games': games.map((g) => g.toJson()).toList(),
    'seasonStart': seasonStart.toIso8601String(),
    'seasonEnd': seasonEnd.toIso8601String(),
  };

  /// JSONから復元
  factory PennantRaceSchedule.fromJson(Map<String, dynamic> json) {
    return PennantRaceSchedule(
      year: json['year'] as int,
      games: (json['games'] as List)
          .map((g) => GameSchedule.fromJson(g as Map<String, dynamic>))
          .toList(),
      seasonStart: DateTime.parse(json['seasonStart'] as String),
      seasonEnd: DateTime.parse(json['seasonEnd'] as String),
    );
  }

  /// スケジュールを更新
  PennantRaceSchedule copyWith({
    int? year,
    List<GameSchedule>? games,
    DateTime? seasonStart,
    DateTime? seasonEnd,
  }) {
    return PennantRaceSchedule(
      year: year ?? this.year,
      games: games ?? this.games,
      seasonStart: seasonStart ?? this.seasonStart,
      seasonEnd: seasonEnd ?? this.seasonEnd,
    );
  }
}

// 個別の試合スケジュール
class GameSchedule {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int month;
  final int week;
  final int dayOfWeek; // 1-7 (月曜日=1)
  final GameType homeTeamGameType;
  final GameType awayTeamGameType;
  final bool isCompleted;
  final GameResult? result;

  GameSchedule({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.month,
    required this.week,
    required this.dayOfWeek,
    required this.homeTeamGameType,
    required this.awayTeamGameType,
    this.isCompleted = false,
    this.result,
  });

  // 試合完了
  GameSchedule completeGame(GameResult result) {
    return GameSchedule(
      id: id,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      month: month,
      week: week,
      dayOfWeek: dayOfWeek,
      homeTeamGameType: homeTeamGameType,
      awayTeamGameType: awayTeamGameType,
      isCompleted: true,
      result: result,
    );
  }

  // 試合日表示
  String get gameDateDisplay {
    final monthNames = ['', '1月', '2月', '3月', '4月', '5月', '6月', 
                       '7月', '8月', '9月', '10月', '11月', '12月'];
    final dayNames = ['', '月', '火', '水', '木', '金', '土', '日'];
    return '${monthNames[month]}${week}週${dayNames[dayOfWeek]}';
  }

  /// JSON形式に変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'homeTeamId': homeTeamId,
    'awayTeamId': awayTeamId,
    'month': month,
    'week': week,
    'dayOfWeek': dayOfWeek,
    'homeTeamGameType': homeTeamGameType.index,
    'awayTeamGameType': awayTeamGameType.index,
    'isCompleted': isCompleted,
    'result': result?.toJson(),
  };

  /// JSONから復元
  factory GameSchedule.fromJson(Map<String, dynamic> json) {
    return GameSchedule(
      id: json['id'] as String,
      homeTeamId: json['homeTeamId'] as String,
      awayTeamId: json['awayTeamId'] as String,
      month: json['month'] as int,
      week: json['week'] as int,
      dayOfWeek: json['dayOfWeek'] as int,
      homeTeamGameType: GameType.values[json['homeTeamGameType'] as int],
      awayTeamGameType: GameType.values[json['awayTeamGameType'] as int],
      isCompleted: json['isCompleted'] as bool? ?? false,
      result: json['result'] != null 
          ? GameResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ペナントレースの状態管理
class PennantRace {
  final int year;
  final PennantRaceSchedule schedule;
  final List<GameResult> completedGames;
  final Map<String, TeamStanding> standings;
  final int currentMonth;
  final int currentWeek;
  final bool isSeasonComplete;
  final Map<String, TeamDepthChart> teamDepthCharts; // チーム別depth chart
  final Map<String, PlayerSeasonStats> playerStats; // 選手別シーズン成績

  PennantRace({
    required this.year,
    required this.schedule,
    required this.completedGames,
    required this.standings,
    required this.currentMonth,
    required this.currentWeek,
    this.isSeasonComplete = false,
    this.teamDepthCharts = const {},
    this.playerStats = const {},
  });

  // 指定週の試合を実行
  PennantRace executeWeekGames(int month, int week, List<ProfessionalTeam> teams) {
    print('PennantRace.executeWeekGames: 開始 - ${month}月${week}週');
    
    final weekGames = schedule.getGamesForWeek(month, week);
    print('PennantRace.executeWeekGames: 今週の試合数: ${weekGames.length}試合');
    
    final newCompletedGames = <GameResult>[];
    final newStandings = Map<String, TeamStanding>.from(standings);
    
    // 全試合スケジュールをコピー（他の週の試合を保持）
    final allGames = List<GameSchedule>.from(schedule.games);
    
    // 今週の試合のインデックスを見つけて更新
    for (int i = 0; i < allGames.length; i++) {
      final game = allGames[i];
      if (game.month == month && game.week == week) {
        if (!game.isCompleted) {
          print('PennantRace.executeWeekGames: 試合実行中 - ${game.homeTeamId} vs ${game.awayTeamId}');
          final result = _simulateGame(game, teams);
          newCompletedGames.add(result);
          
          // 試合完了後のスケジュールを作成
          final completedGame = game.completeGame(result);
          allGames[i] = completedGame; // 既存のリストを更新
          
          // 順位表を更新
          _updateStandings(newStandings, result);
          print('PennantRace.executeWeekGames: 試合完了 - ${game.homeTeamId} ${result.homeScore}-${result.awayScore} ${game.awayTeamId}');
        } else {
          print('PennantRace.executeWeekGames: 試合は既に完了済み - ${game.homeTeamId} vs ${game.awayTeamId}');
        }
      }
    }

    print('PennantRace.executeWeekGames: 今週完了試合数: ${newCompletedGames.length}試合');
    print('PennantRace.executeWeekGames: 更新前の総試合数: ${schedule.games.length}試合');
    print('PennantRace.executeWeekGames: 更新後の総試合数: ${allGames.length}試合');
    
    // スケジュールを更新（全試合を保持）
    final updatedSchedule = schedule.copyWith(games: allGames);
    
    final result = PennantRace(
      year: year,
      schedule: updatedSchedule,
      completedGames: [...completedGames, ...newCompletedGames],
      standings: newStandings,
      currentMonth: month,
      currentWeek: week,
      isSeasonComplete: month == 10 && week == 2,
    );
    
    print('PennantRace.executeWeekGames: 完了');
    return result;
  }

  // 試合をシミュレート
  GameResult _simulateGame(GameSchedule game, List<ProfessionalTeam> teams) {
    final homeTeam = teams.firstWhere((t) => t.id == game.homeTeamId);
    final awayTeam = teams.firstWhere((t) => t.id == game.awayTeamId);
    
    // depth chartから出場選手を決定
    final homeDepthChart = teamDepthCharts[game.homeTeamId];
    final awayDepthChart = teamDepthCharts[game.awayTeamId];
    
    if (homeDepthChart == null || awayDepthChart == null) {
      // depth chartが存在しない場合は従来の方法で計算
      return _simulateGameSimple(game, teams);
    }
    
    // 出場選手を決定
    final random = Random();
    final homeLineup = DepthChartService.determineGameLineup(
      homeDepthChart, 
      homeTeam.professionalPlayers ?? [], 
      random
    );
    final awayLineup = DepthChartService.determineGameLineup(
      awayDepthChart, 
      awayTeam.professionalPlayers ?? [], 
      random
    );
    
    // 選手の能力値をベースにスコアを計算
    final homeScore = _calculateTeamScoreWithPlayers(homeTeam, homeLineup, true);
    final awayScore = _calculateTeamScoreWithPlayers(awayTeam, awayLineup, false);
    
    // 延長戦の判定（同点の場合）
    int inning = 9;
    bool isExtraInnings = false;
    if (homeScore == awayScore) {
      // 同点の場合は延長戦（最大12回）
      inning = 12;
      isExtraInnings = true;
      
      // 延長戦での得点を追加
      final extraHomeScore = _calculateExtraInningScoreWithPlayers(homeTeam, homeLineup);
      final extraAwayScore = _calculateExtraInningScoreWithPlayers(awayTeam, awayLineup);
      
      // 選手成績を生成
      final homeBatterStats = _generateBatterStats(homeLineup, homeScore + extraHomeScore);
      final awayBatterStats = _generateBatterStats(awayLineup, awayScore + extraAwayScore);
      final homePitcherStats = _generatePitcherStats(homeLineup, awayScore + extraAwayScore, true);
      final awayPitcherStats = _generatePitcherStats(awayLineup, homeScore + extraHomeScore, false);
      
      return GameResult(
        homeTeamId: game.homeTeamId,
        awayTeamId: game.awayTeamId,
        homeScore: homeScore + extraHomeScore,
        awayScore: awayScore + extraAwayScore,
        inning: inning,
        isExtraInnings: true,
        gameDate: DateTime.now(),
        homeTeamBatterStats: homeBatterStats,
        awayTeamBatterStats: awayBatterStats,
        homeTeamPitcherStats: homePitcherStats,
        awayTeamPitcherStats: awayPitcherStats,
      );
    }

    // 選手成績を生成
    final homeBatterStats = _generateBatterStats(homeLineup, homeScore);
    final awayBatterStats = _generateBatterStats(awayLineup, awayScore);
    final homePitcherStats = _generatePitcherStats(homeLineup, awayScore, true);
    final awayPitcherStats = _generatePitcherStats(awayLineup, homeScore, false);

    return GameResult(
      homeTeamId: game.homeTeamId,
      awayTeamId: game.awayTeamId,
      homeScore: homeScore,
      awayScore: awayScore,
      inning: inning,
      gameDate: DateTime.now(),
      homeTeamBatterStats: homeBatterStats,
      awayTeamBatterStats: awayBatterStats,
      homeTeamPitcherStats: homePitcherStats,
      awayTeamPitcherStats: awayPitcherStats,
    );
  }

  // 従来のシンプルな試合シミュレーション（depth chartがない場合）
  GameResult _simulateGameSimple(GameSchedule game, List<ProfessionalTeam> teams) {
    final homeTeam = teams.firstWhere((t) => t.id == game.homeTeamId);
    final awayTeam = teams.firstWhere((t) => t.id == game.awayTeamId);
    
    // チーム戦力をベースにスコアを計算
    final homeScore = _calculateTeamScore(homeTeam, true);
    final awayScore = _calculateTeamScore(awayTeam, false);
    
    // 延長戦の判定（同点の場合）
    int inning = 9;
    bool isExtraInnings = false;
    if (homeScore == awayScore) {
      // 同点の場合は延長戦（最大12回）
      inning = 12;
      isExtraInnings = true;
      
      // 延長戦での得点を追加
      final extraHomeScore = _calculateExtraInningScore(homeTeam);
      final extraAwayScore = _calculateExtraInningScore(awayTeam);
      
      return GameResult(
        homeTeamId: game.homeTeamId,
        awayTeamId: game.awayTeamId,
        homeScore: homeScore + extraHomeScore,
        awayScore: awayScore + extraAwayScore,
        inning: inning,
        isExtraInnings: true,
        gameDate: DateTime.now(),
      );
    }

    return GameResult(
      homeTeamId: game.homeTeamId,
      awayTeamId: game.awayTeamId,
      homeScore: homeScore,
      awayScore: awayScore,
      inning: inning,
      gameDate: DateTime.now(),
    );
  }

  // チームスコアを計算
  int _calculateTeamScore(ProfessionalTeam team, bool isHome) {
    final baseScore = team.totalStrength ~/ 10; // 基本スコア
    final homeBonus = isHome ? 1 : 0; // ホームアドバンテージ
    
    // ランダム要素を追加（±2点）
    final random = DateTime.now().millisecondsSinceEpoch % 5 - 2;
    
    return (baseScore + homeBonus + random).clamp(0, 15);
  }

  // 延長戦での得点を計算
  int _calculateExtraInningScore(ProfessionalTeam team) {
    final baseScore = team.totalStrength ~/ 15; // 延長戦では得点しにくい
    final random = DateTime.now().millisecondsSinceEpoch % 3;
    
    return (baseScore + random).clamp(0, 3);
  }

  // 選手の能力値をベースにチームスコアを計算
  int _calculateTeamScoreWithPlayers(ProfessionalTeam team, Map<String, String> lineup, bool isHome) {
    double totalScore = 0.0;
    final random = Random();
    
    // 各ポジションの選手の能力値を合計
    for (final entry in lineup.entries) {
      final position = entry.key;
      final playerId = entry.value;
      
      if (position == '投手') continue; // 投手は守備のみ
      
      final player = team.professionalPlayers?.firstWhere((p) => p.id.toString() == playerId);
      if (player != null) {
        final ability = player.player?.trueTotalAbility ?? 0;
        totalScore += ability * 0.01; // 能力値を0.01倍してスコアに変換
      }
    }
    
    // ホームアドバンテージ
    final homeBonus = isHome ? 1.0 : 0.0;
    
    // ランダム要素（±2点）
    final randomBonus = random.nextDouble() * 4 - 2;
    
    return (totalScore + homeBonus + randomBonus).round().clamp(0, 15);
  }

  // 選手の能力値をベースに延長戦スコアを計算
  int _calculateExtraInningScoreWithPlayers(ProfessionalTeam team, Map<String, String> lineup) {
    double totalScore = 0.0;
    final random = Random();
    
    // 各ポジションの選手の能力値を合計（延長戦では得点しにくい）
    for (final entry in lineup.entries) {
      final position = entry.key;
      final playerId = entry.value;
      
      if (position == '投手') continue;
      
      final player = team.professionalPlayers?.firstWhere((p) => p.id.toString() == playerId);
      if (player != null) {
        final ability = player.player?.trueTotalAbility ?? 0;
        totalScore += ability * 0.005; // 延長戦では能力値の影響を半分に
      }
    }
    
    // ランダム要素（0-2点）
    final randomBonus = random.nextDouble() * 2;
    
    return (totalScore + randomBonus).round().clamp(0, 3);
  }

  // 打者成績を生成
  Map<String, BatterStats> _generateBatterStats(Map<String, String> lineup, int teamScore) {
    final stats = <String, BatterStats>{};
    final random = Random();
    
    for (final entry in lineup.entries) {
      final position = entry.key;
      final playerId = entry.value;
      
      if (position == '投手') continue;
      
      // チームスコアに基づいて打席数を決定
      final atBats = (teamScore * 0.8 + random.nextDouble() * 2).round().clamp(1, 5);
      final hits = (atBats * 0.3 + random.nextDouble() * 0.4).round().clamp(0, atBats);
      
      stats[playerId] = BatterStats(
        games: 1,
        atBats: atBats,
        hits: hits,
        doubles: (hits * 0.2).round(),
        triples: (hits * 0.05).round(),
        homeRuns: (hits * 0.1).round(),
        runs: (hits * 0.4).round(),
        runsBattedIn: (hits * 0.3).round(),
        walks: (atBats * 0.1).round(),
        strikeouts: (atBats * 0.2).round(),
      );
    }
    
    return stats;
  }

  // 投手成績を生成
  Map<String, PitcherStats> _generatePitcherStats(Map<String, String> lineup, int opponentScore, bool isHome) {
    final stats = <String, PitcherStats>{};
    final random = Random();
    
    for (final entry in lineup.entries) {
      final position = entry.key;
      final playerId = entry.value;
      
      if (position != '投手') continue;
      
      // 投手の役割を判定
      final isStartingPitcher = true; // 簡易実装
      
      stats[playerId] = PitcherStats(
        games: 1,
        gamesStarted: isStartingPitcher ? 1 : 0,
        inningsPitched: isStartingPitcher ? 6.0 + random.nextDouble() * 3 : 1.0 + random.nextDouble() * 2,
        hits: (opponentScore * 0.6).round(),
        runs: opponentScore,
        earnedRuns: (opponentScore * 0.9).round(),
        walks: (opponentScore * 0.3).round(),
        strikeouts: (opponentScore * 0.8).round(),
        wins: isHome ? 1 : 0, // 簡易実装
        losses: isHome ? 0 : 1,
      );
    }
    
    return stats;
  }

  // 順位表を更新
  void _updateStandings(Map<String, TeamStanding> standings, GameResult result) {
    if (result.isTie) return; // 引き分けは順位に影響しない
    
    final winnerId = result.winnerId!;
    final loserId = result.loserId!;
    
    // 勝者チームの更新
    if (standings.containsKey(winnerId)) {
      final winner = standings[winnerId]!;
      standings[winnerId] = winner.addWin(
        runsScored: result.homeTeamId == winnerId ? result.homeScore : result.awayScore,
        runsAllowed: result.homeTeamId == winnerId ? result.awayScore : result.homeScore,
      );
    }
    
    // 敗者チームの更新
    if (standings.containsKey(loserId)) {
      final loser = standings[loserId]!;
      standings[loserId] = loser.addLoss(
        runsScored: result.homeTeamId == loserId ? result.homeScore : result.awayScore,
        runsAllowed: result.homeTeamId == loserId ? result.awayScore : result.homeScore,
      );
    }
  }

  // 順位表を取得（勝率順）
  List<TeamStanding> getSortedStandings() {
    final standingsList = standings.values.toList();
    standingsList.sort((a, b) => b.winningPercentage.compareTo(a.winningPercentage));
    
    // 順位を設定
    for (int i = 0; i < standingsList.length; i++) {
      standingsList[i] = standingsList[i].copyWith(rank: i + 1);
    }
    
    return standingsList;
  }

  // 指定リーグの順位表を取得
  List<TeamStanding> getLeagueStandings(League league) {
    return getSortedStandings()
        .where((standing) => standing.league == league)
        .toList();
  }

  /// JSON形式に変換
  Map<String, dynamic> toJson() => {
    'year': year,
    'schedule': schedule.toJson(),
    'completedGames': completedGames.map((g) => g.toJson()).toList(),
    'standings': standings.map((k, v) => MapEntry(k, v.toJson())),
    'currentMonth': currentMonth,
    'currentWeek': currentWeek,
    'isSeasonComplete': isSeasonComplete,
    'teamDepthCharts': teamDepthCharts.map((k, v) => MapEntry(k, v.toJson())),
    'playerStats': playerStats.map((k, v) => MapEntry(k, v.toJson())),
  };

  /// ペナントレースを更新
  PennantRace copyWith({
    int? year,
    PennantRaceSchedule? schedule,
    List<GameResult>? completedGames,
    Map<String, TeamStanding>? standings,
    int? currentMonth,
    int? currentWeek,
    bool? isSeasonComplete,
    Map<String, TeamDepthChart>? teamDepthCharts,
    Map<String, PlayerSeasonStats>? playerStats,
  }) {
    return PennantRace(
      year: year ?? this.year,
      schedule: schedule ?? this.schedule,
      completedGames: completedGames ?? this.completedGames,
      standings: standings ?? this.standings,
      currentMonth: currentMonth ?? this.currentMonth,
      currentWeek: currentWeek ?? this.currentWeek,
      isSeasonComplete: isSeasonComplete ?? this.isSeasonComplete,
      teamDepthCharts: teamDepthCharts ?? this.teamDepthCharts,
      playerStats: playerStats ?? this.playerStats,
    );
  }

  /// JSONから復元
  factory PennantRace.fromJson(Map<String, dynamic> json) {
    return PennantRace(
      year: json['year'] as int,
      schedule: PennantRaceSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
      completedGames: (json['completedGames'] as List)
          .map((g) => GameResult.fromJson(g as Map<String, dynamic>))
          .toList(),
      standings: (json['standings'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, TeamStanding.fromJson(v as Map<String, dynamic>))),
      currentMonth: json['currentMonth'] as int,
      currentWeek: json['currentWeek'] as int,
      isSeasonComplete: json['isSeasonComplete'] as bool? ?? false,
      teamDepthCharts: (json['teamDepthCharts'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, TeamDepthChart.fromJson(v as Map<String, dynamic>))
      ) ?? {},
      playerStats: (json['playerStats'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, PlayerSeasonStats.fromJson(v as Map<String, dynamic>))
      ) ?? {},
    );
  }
}

// チームの順位情報
class TeamStanding {
  final String teamId;
  final String teamName;
  final String teamShortName;
  final League league;
  final Division division;
  final int games;
  final int wins;
  final int losses;
  final int ties;
  final double winningPercentage;
  final double gamesBehind;
  final int rank;
  final int runsScored;
  final int runsAllowed;
  final int runDifferential;
  final int homeWins;
  final int homeLosses;
  final int awayWins;
  final int awayLosses;

  TeamStanding({
    required this.teamId,
    required this.teamName,
    required this.teamShortName,
    required this.league,
    required this.division,
    this.games = 0,
    this.wins = 0,
    this.losses = 0,
    this.ties = 0,
    this.winningPercentage = 0.0,
    this.gamesBehind = 0.0,
    this.rank = 0,
    this.runsScored = 0,
    this.runsAllowed = 0,
    this.runDifferential = 0,
    this.homeWins = 0,
    this.homeLosses = 0,
    this.awayWins = 0,
    this.awayLosses = 0,
  });

  // 勝利を追加
  TeamStanding addWin({
    int runsScored = 0,
    int runsAllowed = 0,
    bool isHome = false,
  }) {
    final newWins = wins + 1;
    final newGames = games + 1;
    final newRunsScored = this.runsScored + runsScored;
    final newRunsAllowed = this.runsAllowed + runsAllowed;
    
    return copyWith(
      games: newGames,
      wins: newWins,
      winningPercentage: newWins / newGames,
      runsScored: newRunsScored,
      runsAllowed: newRunsAllowed,
      runDifferential: newRunsScored - newRunsAllowed,
      homeWins: isHome ? homeWins + 1 : homeWins,
      awayWins: !isHome ? awayWins + 1 : awayWins,
    );
  }

  // 敗戦を追加
  TeamStanding addLoss({
    int runsScored = 0,
    int runsAllowed = 0,
    bool isHome = false,
  }) {
    final newLosses = losses + 1;
    final newGames = games + 1;
    final newRunsScored = this.runsScored + runsScored;
    final newRunsAllowed = this.runsAllowed + runsAllowed;
    
    return copyWith(
      games: newGames,
      losses: newLosses,
      winningPercentage: wins / newGames,
      runsScored: newRunsScored,
      runsAllowed: newRunsAllowed,
      runDifferential: newRunsScored - newRunsAllowed,
      homeLosses: isHome ? homeLosses + 1 : homeLosses,
      awayLosses: !isHome ? awayLosses + 1 : awayLosses,
    );
  }

  // 引き分けを追加
  TeamStanding addTie({
    int runsScored = 0,
    int runsAllowed = 0,
  }) {
    final newTies = ties + 1;
    final newGames = games + 1;
    final newRunsScored = this.runsScored + runsScored;
    final newRunsAllowed = this.runsAllowed + runsAllowed;
    
    return copyWith(
      games: newGames,
      ties: newTies,
      winningPercentage: wins / newGames,
      runsScored: newRunsScored,
      runsAllowed: newRunsAllowed,
      runDifferential: newRunsScored - newRunsAllowed,
    );
  }

  // ゲーム差を計算
  TeamStanding calculateGamesBehind(double leaderWinningPercentage) {
    if (games == 0) return this;
    
    final gamesBehind = ((leaderWinningPercentage - winningPercentage) * games) / 2;
    return copyWith(gamesBehind: gamesBehind);
  }

  TeamStanding copyWith({
    String? teamId,
    String? teamName,
    String? teamShortName,
    League? league,
    Division? division,
    int? games,
    int? wins,
    int? losses,
    int? ties,
    double? winningPercentage,
    double? gamesBehind,
    int? rank,
    int? runsScored,
    int? runsAllowed,
    int? runDifferential,
    int? homeWins,
    int? homeLosses,
    int? awayWins,
    int? awayLosses,
  }) {
    return TeamStanding(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamShortName: teamShortName ?? this.teamShortName,
      league: league ?? this.league,
      division: division ?? this.division,
      games: games ?? this.games,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      ties: ties ?? this.ties,
      winningPercentage: winningPercentage ?? this.winningPercentage,
      gamesBehind: gamesBehind ?? this.gamesBehind,
      rank: rank ?? this.rank,
      runsScored: runsScored ?? this.runsScored,
      runsAllowed: runsAllowed ?? this.runsAllowed,
      runDifferential: runDifferential ?? this.runDifferential,
      homeWins: homeWins ?? this.homeWins,
      homeLosses: homeLosses ?? this.homeLosses,
      awayWins: awayWins ?? this.awayWins,
      awayLosses: awayLosses ?? this.awayLosses,
    );
  }

  /// JSON形式に変換
  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'teamName': teamName,
    'teamShortName': teamShortName,
    'league': league.index,
    'division': division.index,
    'games': games,
    'wins': wins,
    'losses': losses,
    'ties': ties,
    'winningPercentage': winningPercentage,
    'gamesBehind': gamesBehind,
    'rank': rank,
    'runsScored': runsScored,
    'runsAllowed': runsAllowed,
    'runDifferential': runDifferential,
    'homeWins': homeWins,
    'homeLosses': homeLosses,
    'awayWins': awayWins,
    'awayLosses': awayLosses,
  };

  /// JSONから復元
  factory TeamStanding.fromJson(Map<String, dynamic> json) {
    return TeamStanding(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      teamShortName: json['teamShortName'] as String,
      league: League.values[json['league'] as int],
      division: Division.values[json['division'] as int],
      games: json['games'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      ties: json['ties'] as int? ?? 0,
      winningPercentage: json['winningPercentage'] as double? ?? 0.0,
      gamesBehind: json['gamesBehind'] as double? ?? 0.0,
      rank: json['rank'] as int? ?? 0,
      runsScored: json['runsScored'] as int? ?? 0,
      runsAllowed: json['runsAllowed'] as int? ?? 0,
      runDifferential: json['runDifferential'] as int? ?? 0,
      homeWins: json['homeWins'] as int? ?? 0,
      homeLosses: json['homeLosses'] as int? ?? 0,
      awayWins: json['awayWins'] as int? ?? 0,
      awayLosses: json['awayLosses'] as int? ?? 0,
    );
  }
}
