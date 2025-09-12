import 'dart:math';
import '../models/professional/player_stats.dart';
import '../models/professional/professional_player.dart';
import '../models/professional/depth_chart.dart';
import '../models/game/pennant_race.dart';

/// 成績計算サービス
class StatsCalculationService {
  static final Random _random = Random();

  /// 試合結果に基づいて選手の成績を計算・更新
  static Map<String, PlayerSeasonStats> calculateGameStats({
    required GameResult gameResult,
    required Map<String, List<ProfessionalPlayer>> teamPlayers,
    required Map<String, TeamDepthChart> teamDepthCharts,
    required Map<String, PlayerSeasonStats> currentPlayerStats,
    required int season,
  }) {
    final updatedStats = Map<String, PlayerSeasonStats>.from(currentPlayerStats);
    
    // ホームチームとアウェイチームの成績を計算
    _calculateTeamGameStats(
      gameResult.homeTeamId,
      gameResult.homeScore,
      gameResult.awayScore,
      teamPlayers[gameResult.homeTeamId] ?? [],
      teamDepthCharts[gameResult.homeTeamId],
      updatedStats,
      season,
      isHomeTeam: true,
    );
    
    _calculateTeamGameStats(
      gameResult.awayTeamId,
      gameResult.awayScore,
      gameResult.homeScore,
      teamPlayers[gameResult.awayTeamId] ?? [],
      teamDepthCharts[gameResult.awayTeamId],
      updatedStats,
      season,
      isHomeTeam: false,
    );
    
    return updatedStats;
  }

  /// チームの試合成績を計算
  static void _calculateTeamGameStats(
    String teamId,
    int teamScore,
    int opponentScore,
    List<ProfessionalPlayer> players,
    TeamDepthChart? depthChart,
    Map<String, PlayerSeasonStats> updatedStats,
    int season,
    {required bool isHomeTeam}
  ) {
    if (depthChart == null) return;

    // 打者成績を計算
    _calculateBatterStats(
      teamId,
      teamScore,
      players,
      depthChart,
      updatedStats,
      season,
    );

    // 投手成績を計算
    _calculatePitcherStats(
      teamId,
      teamScore,
      opponentScore,
      players,
      depthChart,
      updatedStats,
      season,
    );
  }

  /// 打者成績を計算
  static void _calculateBatterStats(
    String teamId,
    int teamScore,
    List<ProfessionalPlayer> players,
    TeamDepthChart depthChart,
    Map<String, PlayerSeasonStats> updatedStats,
    int season,
  ) {
    // 各ポジションの打者を取得
    for (final entry in depthChart.positionCharts.entries) {
      final position = entry.key;
      final chart = entry.value;
      
      // 投手以外のポジションのみ
      if (position == '投手') continue;
      
      // 1番手と2番手の選手を取得
      final firstPlayerId = chart.playerIds.isNotEmpty ? chart.playerIds[0] : null;
      final secondPlayerId = chart.playerIds.length > 1 ? chart.playerIds[1] : null;
      
      // 出場選手を決定（90% vs 10%）
      final playingPlayerId = _determinePlayingPlayer(firstPlayerId, secondPlayerId);
      if (playingPlayerId == null) continue;
      
      final player = players.firstWhere(
        (p) => 'player_${p.playerId}' == playingPlayerId,
        orElse: () => players.first,
      );
      
      // 打者成績を計算
      final batterStats = _generateBatterGameStats(player, teamScore);
      
      // 成績を更新
      _updatePlayerBatterStats(
        'player_${player.playerId}',
        teamId,
        season,
        batterStats,
        updatedStats,
      );
    }
  }

  /// 投手成績を計算
  static void _calculatePitcherStats(
    String teamId,
    int teamScore,
    int opponentScore,
    List<ProfessionalPlayer> players,
    TeamDepthChart depthChart,
    Map<String, PlayerSeasonStats> updatedStats,
    int season,
  ) {
    final pitcherChart = depthChart.positionCharts['投手'];
    if (pitcherChart == null) return;
    
    // 1番手と2番手の投手を取得
    final firstPitcherId = pitcherChart.playerIds.isNotEmpty ? pitcherChart.playerIds[0] : null;
    final secondPitcherId = pitcherChart.playerIds.length > 1 ? pitcherChart.playerIds[1] : null;
    
    // 出場投手を決定（90% vs 10%）
    final playingPitcherId = _determinePlayingPlayer(firstPitcherId, secondPitcherId);
    if (playingPitcherId == null) return;
    
    final pitcher = players.firstWhere(
      (p) => 'player_${p.playerId}' == playingPitcherId,
      orElse: () => players.first,
    );
    
    // 投手成績を計算
    final pitcherStats = _generatePitcherGameStats(
      pitcher,
      teamScore,
      opponentScore,
    );
    
    // 成績を更新
    _updatePlayerPitcherStats(
      'player_${pitcher.playerId}',
      teamId,
      season,
      pitcherStats,
      updatedStats,
    );
  }

  /// 出場選手を決定（90% vs 10%）
  static String? _determinePlayingPlayer(String? firstPlayerId, String? secondPlayerId) {
    if (firstPlayerId == null) return secondPlayerId;
    if (secondPlayerId == null) return firstPlayerId;
    
    // 90%の確率で1番手、10%の確率で2番手
    return _random.nextDouble() < 0.9 ? firstPlayerId : secondPlayerId;
  }

  /// 打者の試合成績を生成
  static BatterStats _generateBatterGameStats(ProfessionalPlayer player, int teamScore) {
    final playerData = player.player;
    if (playerData == null) return BatterStats();
    
    // 能力値に基づいて成績を決定
    final battingAbility = playerData.technical;
    final powerAbility = playerData.physical;
    final mentalAbility = playerData.mental;
    
    // 打席数を決定（能力値に基づく）
    final atBats = _calculateAtBats(battingAbility, teamScore);
    
    // 安打数を決定
    final hits = _calculateHits(atBats, battingAbility, mentalAbility);
    
    // 本塁打数を決定
    final homeRuns = _calculateHomeRuns(hits, powerAbility, mentalAbility);
    
    // 二塁打・三塁打数を決定
    final doubles = _calculateDoubles(hits - homeRuns, battingAbility);
    final triples = _calculateTriples(hits - homeRuns - doubles, battingAbility);
    
    // その他の成績
    final runs = _calculateRuns(hits, teamScore);
    final rbi = _calculateRBI(hits, homeRuns, teamScore);
    final walks = _calculateWalks(atBats, battingAbility);
    final strikeouts = _calculateBatterStrikeouts(atBats, battingAbility, mentalAbility);
    
    return BatterStats(
      games: 1,
      atBats: atBats,
      hits: hits,
      doubles: doubles,
      triples: triples,
      homeRuns: homeRuns,
      runsBattedIn: rbi,
      runs: runs,
      walks: walks,
      strikeouts: strikeouts,
    );
  }

  /// 投手の試合成績を生成
  static PitcherStats _generatePitcherGameStats(
    ProfessionalPlayer pitcher,
    int teamScore,
    int opponentScore,
  ) {
    final playerData = pitcher.player;
    if (playerData == null) return PitcherStats();
    
    // 能力値に基づいて成績を決定
    final pitchingAbility = playerData.technical;
    final staminaAbility = playerData.physical;
    final mentalAbility = playerData.mental;
    
    // 投球回数を決定
    final inningsPitched = _calculateInningsPitched(pitchingAbility, staminaAbility);
    
    // 被安打数を決定
    final hits = _calculateHitsAllowed(inningsPitched, pitchingAbility, mentalAbility);
    
    // 失点・自責点を決定
    final runs = _calculateRunsAllowed(opponentScore, pitchingAbility, mentalAbility);
    final earnedRuns = _calculateEarnedRuns(runs, pitchingAbility);
    
    // 被本塁打数を決定
    final homeRuns = _calculateHomeRunsAllowed(hits, pitchingAbility);
    
    // その他の成績
    final walks = _calculateWalksAllowed(inningsPitched, pitchingAbility, mentalAbility);
    final strikeouts = _calculatePitcherStrikeouts(inningsPitched, pitchingAbility, mentalAbility);
    
    // 勝敗を決定（チームの勝敗と一致させる）
    final isWin = teamScore > opponentScore;
    final isLoss = teamScore < opponentScore;
    
    return PitcherStats(
      games: 1,
      gamesStarted: 1,
      inningsPitched: inningsPitched,
      hits: hits,
      runs: runs,
      earnedRuns: earnedRuns,
      homeRuns: homeRuns,
      walks: walks,
      strikeouts: strikeouts,
      wins: isWin ? 1 : 0,
      losses: isLoss ? 1 : 0,
    );
  }

  /// 打席数を計算
  static int _calculateAtBats(int battingAbility, int teamScore) {
    // 基本打席数（3-5打席）
    final baseAtBats = 3 + _random.nextInt(3);
    
    // チーム得点による調整
    final scoreBonus = (teamScore * 0.3).round();
    
    // 能力値による調整
    final abilityBonus = (battingAbility - 50) ~/ 20;
    
    return (baseAtBats + scoreBonus + abilityBonus).clamp(1, 6);
  }

  /// 安打数を計算
  static int _calculateHits(int atBats, int battingAbility, int mentalAbility) {
    // 基本安打率（能力値に基づく）
    final baseHitRate = (battingAbility + mentalAbility) / 200.0;
    
    // ランダム要素
    final randomFactor = _random.nextDouble() * 0.3;
    
    final hitRate = (baseHitRate + randomFactor).clamp(0.1, 0.8);
    
    int hits = 0;
    for (int i = 0; i < atBats; i++) {
      if (_random.nextDouble() < hitRate) {
        hits++;
      }
    }
    
    return hits;
  }

  /// 本塁打数を計算
  static int _calculateHomeRuns(int hits, int powerAbility, int mentalAbility) {
    // 基本本塁打率（パワー能力に基づく）
    final baseHomeRunRate = (powerAbility + mentalAbility) / 400.0;
    
    // ランダム要素
    final randomFactor = _random.nextDouble() * 0.1;
    
    final homeRunRate = (baseHomeRunRate + randomFactor).clamp(0.01, 0.3);
    
    int homeRuns = 0;
    for (int i = 0; i < hits; i++) {
      if (_random.nextDouble() < homeRunRate) {
        homeRuns++;
      }
    }
    
    return homeRuns;
  }

  /// 二塁打数を計算
  static int _calculateDoubles(int hits, int battingAbility) {
    final doubleRate = (battingAbility / 200.0).clamp(0.1, 0.4);
    
    int doubles = 0;
    for (int i = 0; i < hits; i++) {
      if (_random.nextDouble() < doubleRate) {
        doubles++;
      }
    }
    
    return doubles;
  }

  /// 三塁打数を計算
  static int _calculateTriples(int hits, int battingAbility) {
    final tripleRate = (battingAbility / 400.0).clamp(0.01, 0.1);
    
    int triples = 0;
    for (int i = 0; i < hits; i++) {
      if (_random.nextDouble() < tripleRate) {
        triples++;
      }
    }
    
    return triples;
  }

  /// 得点数を計算
  static int _calculateRuns(int hits, int teamScore) {
    // チーム得点に基づいて個人得点を決定
    final baseRuns = (teamScore * 0.2).round();
    final hitBonus = (hits * 0.3).round();
    
    return (baseRuns + hitBonus + _random.nextInt(2)).clamp(0, teamScore);
  }

  /// 打点数を計算
  static int _calculateRBI(int hits, int homeRuns, int teamScore) {
    // 本塁打は確実に打点
    int rbi = homeRuns;
    
    // その他の安打による打点
    final otherHits = hits - homeRuns;
    final rbiRate = (teamScore / 10.0).clamp(0.2, 0.8);
    
    for (int i = 0; i < otherHits; i++) {
      if (_random.nextDouble() < rbiRate) {
        rbi++;
      }
    }
    
    return rbi;
  }

  /// 四球数を計算
  static int _calculateWalks(int atBats, int battingAbility) {
    final walkRate = ((100 - battingAbility) / 200.0).clamp(0.05, 0.3);
    
    int walks = 0;
    for (int i = 0; i < atBats; i++) {
      if (_random.nextDouble() < walkRate) {
        walks++;
      }
    }
    
    return walks;
  }

  /// 打者三振数を計算
  static int _calculateBatterStrikeouts(int atBats, int battingAbility, int mentalAbility) {
    final strikeoutRate = ((100 - battingAbility - mentalAbility) / 200.0).clamp(0.1, 0.6);
    
    int strikeouts = 0;
    for (int i = 0; i < atBats; i++) {
      if (_random.nextDouble() < strikeoutRate) {
        strikeouts++;
      }
    }
    
    return strikeouts;
  }

  /// 投球回数を計算
  static double _calculateInningsPitched(int pitchingAbility, int staminaAbility) {
    // 基本投球回数（5-9回）
    final baseInnings = 5.0 + _random.nextDouble() * 4.0;
    
    // 能力値による調整
    final abilityBonus = (pitchingAbility + staminaAbility - 100) / 50.0;
    
    return (baseInnings + abilityBonus).clamp(1.0, 9.0);
  }

  /// 被安打数を計算
  static int _calculateHitsAllowed(double inningsPitched, int pitchingAbility, int mentalAbility) {
    final baseHitsPerInning = (100 - pitchingAbility - mentalAbility) / 200.0;
    final hitsPerInning = baseHitsPerInning.clamp(0.5, 2.0);
    
    return (inningsPitched * hitsPerInning).round();
  }

  /// 失点数を計算
  static int _calculateRunsAllowed(int opponentScore, int pitchingAbility, int mentalAbility) {
    // 相手チームの得点に基づく
    final baseRuns = (opponentScore * 0.8).round();
    
    // 能力値による調整
    final abilityAdjustment = (100 - pitchingAbility - mentalAbility) / 100.0;
    
    return (baseRuns * abilityAdjustment).round().clamp(0, opponentScore);
  }

  /// 自責点を計算
  static int _calculateEarnedRuns(int runs, int pitchingAbility) {
    // 自責点率（能力値に基づく）
    final earnedRunRate = (pitchingAbility / 100.0).clamp(0.7, 1.0);
    
    return (runs * earnedRunRate).round();
  }

  /// 被本塁打数を計算
  static int _calculateHomeRunsAllowed(int hits, int pitchingAbility) {
    final homeRunRate = ((100 - pitchingAbility) / 200.0).clamp(0.05, 0.3);
    
    int homeRuns = 0;
    for (int i = 0; i < hits; i++) {
      if (_random.nextDouble() < homeRunRate) {
        homeRuns++;
      }
    }
    
    return homeRuns;
  }

  /// 与四球数を計算
  static int _calculateWalksAllowed(double inningsPitched, int pitchingAbility, int mentalAbility) {
    final walksPerInning = ((100 - pitchingAbility - mentalAbility) / 200.0).clamp(0.2, 1.0);
    
    return (inningsPitched * walksPerInning).round();
  }

  /// 投手奪三振数を計算
  static int _calculatePitcherStrikeouts(double inningsPitched, int pitchingAbility, int mentalAbility) {
    final strikeoutsPerInning = (pitchingAbility + mentalAbility) / 200.0;
    final adjustedStrikeoutsPerInning = strikeoutsPerInning.clamp(0.3, 2.0);
    
    return (inningsPitched * adjustedStrikeoutsPerInning).round();
  }

  /// 選手の打者成績を更新
  static void _updatePlayerBatterStats(
    String playerId,
    String teamId,
    int season,
    BatterStats gameStats,
    Map<String, PlayerSeasonStats> updatedStats,
  ) {
    final currentStats = updatedStats[playerId] ?? PlayerSeasonStats(
      playerId: playerId,
      teamId: teamId,
      season: season,
      lastUpdated: DateTime.now(),
    );
    
    final updatedBatterStats = currentStats.batterStats?.addStats(gameStats) ?? gameStats;
    updatedStats[playerId] = currentStats.copyWith(
      batterStats: updatedBatterStats,
      lastUpdated: DateTime.now(),
    );
  }

  /// 選手の投手成績を更新
  static void _updatePlayerPitcherStats(
    String playerId,
    String teamId,
    int season,
    PitcherStats gameStats,
    Map<String, PlayerSeasonStats> updatedStats,
  ) {
    final currentStats = updatedStats[playerId] ?? PlayerSeasonStats(
      playerId: playerId,
      teamId: teamId,
      season: season,
      lastUpdated: DateTime.now(),
    );
    
    final updatedPitcherStats = currentStats.pitcherStats?.addStats(gameStats) ?? gameStats;
    updatedStats[playerId] = currentStats.copyWith(
      pitcherStats: updatedPitcherStats,
      lastUpdated: DateTime.now(),
    );
  }
}
