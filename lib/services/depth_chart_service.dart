import 'dart:math';
import '../models/professional/depth_chart.dart';
import '../models/professional/professional_player.dart';
import '../models/professional/player_stats.dart';

// depth chartとローテーションを管理するサービス
class DepthChartService {
  // チームのdepth chartを初期化
  static TeamDepthChart initializeTeamDepthChart(
    String teamId,
    List<ProfessionalPlayer> players,
  ) {
    final positionCharts = <String, PositionDepthChart>{};

    // ポジション別に選手を分類
    final positionGroups = <String, List<ProfessionalPlayer>>{};
    for (final player in players) {
      final position = player.player?.position ?? '投手';
      positionGroups.putIfAbsent(position, () => []).add(player);
    }

    // 各ポジションのdepth chartを作成
    for (final entry in positionGroups.entries) {
      final position = entry.key;
      final positionPlayers = entry.value;

      // 能力値順にソート
      positionPlayers.sort((a, b) => 
        (b.player?.trueTotalAbility ?? 0).compareTo(a.player?.trueTotalAbility ?? 0)
      );

      // 選手IDリストを作成（ProfessionalPlayerのIDを使用）
      final playerIds = positionPlayers.map((p) => 'player_${p.playerId}').toList();

      // 出場時間割合を計算
      final playingTimePercentages = <String, double>{};
      for (int i = 0; i < positionPlayers.length; i++) {
        final player = positionPlayers[i];
        final basePercentage = _calculateBasePlayingTime(i, positionPlayers.length);
        final abilityBonus = (player.player?.trueTotalAbility ?? 0) / 100.0;
        final playerId = 'player_${player.playerId}';
        playingTimePercentages[playerId] = basePercentage + abilityBonus;
      }

      // 正規化（合計が100%になるように）
      final totalPercentage = playingTimePercentages.values.reduce((a, b) => a + b);
      for (final key in playingTimePercentages.keys) {
        playingTimePercentages[key] = (playingTimePercentages[key]! / totalPercentage) * 100.0;
      }

      positionCharts[position] = PositionDepthChart(
        position: position,
        playerIds: playerIds,
        playingTimePercentages: playingTimePercentages,
      );
    }

    // 投手ローテーションを作成
    final pitcherRotation = _createPitcherRotation(players);

    return TeamDepthChart(
      teamId: teamId,
      positionCharts: positionCharts,
      pitcherRotation: pitcherRotation,
      lastUpdated: DateTime.now(),
    );
  }

  // チームのポジション強さを計算（1番手90% + 2番手10%）
  static Map<String, int> calculateTeamPositionStrength(TeamDepthChart depthChart, List<ProfessionalPlayer> players) {
    final positionStrengths = <String, int>{};
    
    for (final entry in depthChart.positionCharts.entries) {
      final position = entry.key;
      final chart = entry.value;
      
      if (chart.playerIds.isEmpty) {
        positionStrengths[position] = 50; // デフォルト値
        continue;
      }
      
      // 1番手と2番手の選手を取得
      final firstPlayerId = chart.playerIds.isNotEmpty ? chart.playerIds[0] : null;
      final secondPlayerId = chart.playerIds.length > 1 ? chart.playerIds[1] : null;
      
      // 選手の能力値を取得
      int firstPlayerAbility = 50; // デフォルト値
      int secondPlayerAbility = 50; // デフォルト値
      
      if (firstPlayerId != null) {
        final firstPlayer = players.firstWhere(
          (p) => 'player_${p.playerId}' == firstPlayerId,
          orElse: () => players.first,
        );
        firstPlayerAbility = firstPlayer.player?.trueTotalAbility ?? 50;
      }
      
      if (secondPlayerId != null) {
        final secondPlayer = players.firstWhere(
          (p) => 'player_${p.playerId}' == secondPlayerId,
          orElse: () => players.first,
        );
        secondPlayerAbility = secondPlayer.player?.trueTotalAbility ?? 50;
      }
      
      // 1番手90% + 2番手10%で計算
      final positionStrength = (firstPlayerAbility * 0.9 + secondPlayerAbility * 0.1).round();
      positionStrengths[position] = positionStrength;
    }
    
    return positionStrengths;
  }

  // 基本出場時間割合を計算
  static double _calculateBasePlayingTime(int rank, int totalPlayers) {
    if (totalPlayers == 1) return 100.0;
    
    // 1番手: 90%, 2番手: 10%, 3番手以降: 0%
    switch (rank) {
      case 0: // 1番手
        return 90.0;
      case 1: // 2番手
        return 10.0;
      default: // 3番手以降
        return 0.0;
    }
  }

  // 投手ローテーションを作成
  static PitcherRotation _createPitcherRotation(List<ProfessionalPlayer> players) {
    final pitchers = players.where((p) => 
      p.player?.position == '投手'
    ).toList();

    // 能力値順にソート
    pitchers.sort((a, b) => 
      (b.player?.trueTotalAbility ?? 0).compareTo(a.player?.trueTotalAbility ?? 0)
    );

    // 先発投手（上位5名）
    final startingPitchers = pitchers.take(5).map((p) => 'player_${p.playerId}').toList();
    
    // リリーフ投手（6-10番目）
    final reliefPitchers = pitchers.skip(5).take(5).map((p) => 'player_${p.playerId}').toList();
    
    // クローザー（最上位1名）
    final closers = startingPitchers.isNotEmpty ? <String>[startingPitchers.first] : <String>[];

    // 使用回数を初期化
    final pitcherUsage = <String, int>{};
    for (final pitcher in pitchers) {
      final playerId = 'player_${pitcher.playerId}';
      pitcherUsage[playerId] = 0;
    }

    return PitcherRotation(
      startingPitcherIds: startingPitchers,
      reliefPitcherIds: reliefPitchers,
      closerPitcherIds: closers,
      currentRotationIndex: 0,
      pitcherUsage: pitcherUsage,
    );
  }

  // 試合に出場する選手を決定
  static Map<String, String> determineGameLineup(
    TeamDepthChart depthChart,
    List<ProfessionalPlayer> players,
    Random random,
  ) {
    final lineup = <String, String>{};
    
    for (final entry in depthChart.positionCharts.entries) {
      final position = entry.key;
      final positionChart = entry.value;
      
      // 投手の場合は特別処理
      if (position == '投手') {
        final startingPitcherId = depthChart.pitcherRotation.getNextStartingPitcher();
        if (startingPitcherId.isNotEmpty) {
          lineup[position] = startingPitcherId;
        }
        continue;
      }

      // 出場選手を決定
      final playingPlayerId = positionChart.determinePlayingPlayer(players, random);
      if (playingPlayerId.isNotEmpty) {
        lineup[position] = playingPlayerId;
      }
    }

    return lineup;
  }

  // 投手ローテーションを進める
  static TeamDepthChart advancePitcherRotation(TeamDepthChart depthChart) {
    return depthChart.advancePitcherRotation();
  }

  // 投手の使用回数を更新
  static TeamDepthChart updatePitcherUsage(
    TeamDepthChart depthChart,
    String pitcherId,
  ) {
    return depthChart.updatePitcherUsage(pitcherId);
  }

  // 試合結果に基づいて選手の成績を更新
  static PlayerSeasonStats updatePlayerStats(
    PlayerSeasonStats currentStats,
    String playerId,
    String teamId,
    int season,
    Map<String, dynamic> gameStats,
  ) {
    // 打者成績の更新
    if (gameStats.containsKey('batting')) {
      final battingStats = gameStats['batting'] as Map<String, dynamic>;
      final newBatterStats = BatterStats(
        games: battingStats['games'] ?? 0,
        atBats: battingStats['atBats'] ?? 0,
        hits: battingStats['hits'] ?? 0,
        doubles: battingStats['doubles'] ?? 0,
        triples: battingStats['triples'] ?? 0,
        homeRuns: battingStats['homeRuns'] ?? 0,
        runsBattedIn: battingStats['runsBattedIn'] ?? 0,
        runs: battingStats['runs'] ?? 0,
        walks: battingStats['walks'] ?? 0,
        strikeouts: battingStats['strikeouts'] ?? 0,
        stolenBases: battingStats['stolenBases'] ?? 0,
        caughtStealing: battingStats['caughtStealing'] ?? 0,
        sacrificeBunts: battingStats['sacrificeBunts'] ?? 0,
        sacrificeFlies: battingStats['sacrificeFlies'] ?? 0,
        hitByPitch: battingStats['hitByPitch'] ?? 0,
        groundIntoDoublePlay: battingStats['groundIntoDoublePlay'] ?? 0,
      );

      return currentStats.updateBatterStats(newBatterStats);
    }

    // 投手成績の更新
    if (gameStats.containsKey('pitching')) {
      final pitchingStats = gameStats['pitching'] as Map<String, dynamic>;
      final newPitcherStats = PitcherStats(
        games: pitchingStats['games'] ?? 0,
        gamesStarted: pitchingStats['gamesStarted'] ?? 0,
        completeGames: pitchingStats['completeGames'] ?? 0,
        shutouts: pitchingStats['shutouts'] ?? 0,
        wins: pitchingStats['wins'] ?? 0,
        losses: pitchingStats['losses'] ?? 0,
        saves: pitchingStats['saves'] ?? 0,
        holds: pitchingStats['holds'] ?? 0,
        inningsPitched: (pitchingStats['inningsPitched'] as num?)?.toDouble() ?? 0.0,
        hits: pitchingStats['hits'] ?? 0,
        runs: pitchingStats['runs'] ?? 0,
        earnedRuns: pitchingStats['earnedRuns'] ?? 0,
        homeRuns: pitchingStats['homeRuns'] ?? 0,
        walks: pitchingStats['walks'] ?? 0,
        strikeouts: pitchingStats['strikeouts'] ?? 0,
        hitBatters: pitchingStats['hitBatters'] ?? 0,
        wildPitches: pitchingStats['wildPitches'] ?? 0,
        balks: pitchingStats['balks'] ?? 0,
      );

      return currentStats.updatePitcherStats(newPitcherStats);
    }

    return currentStats;
  }

  // 選手の能力値に基づいて出場確率を調整
  static double calculatePlayingProbability(
    ProfessionalPlayer player,
    int rank,
    int totalPlayers,
  ) {
    final baseProbability = _calculateBasePlayingTime(rank, totalPlayers);
    final abilityBonus = (player.player?.trueTotalAbility ?? 0) / 100.0;
    
    // メンタル面の影響を考慮
    final mentalBonus = _calculateMentalBonus(player);
    
    return (baseProbability + abilityBonus + mentalBonus).clamp(5.0, 95.0);
  }

  // メンタル面のボーナスを計算
  static double _calculateMentalBonus(ProfessionalPlayer player) {
    final playerData = player.player;
    if (playerData == null) return 0.0;

    double bonus = 0.0;

    // 精神力によるボーナス
    final mentalStrength = playerData.mentalAbilities['精神力'] ?? 0;
    bonus += mentalStrength * 0.1;

    // 集中力によるボーナス
    final concentration = playerData.mentalAbilities['集中力'] ?? 0;
    bonus += concentration * 0.05;

    // プレッシャー耐性によるボーナス
    final pressureResistance = playerData.mentalAbilities['プレッシャー耐性'] ?? 0;
    bonus += pressureResistance * 0.08;

    return bonus;
  }

  // depth chartの評価を取得
  static Map<String, String> evaluateDepthChart(TeamDepthChart depthChart) {
    final evaluation = <String, String>{};
    
    for (final entry in depthChart.positionCharts.entries) {
      final position = entry.key;
      final chart = entry.value;
      
      if (chart.playerIds.isEmpty) {
        evaluation[position] = '選手不足';
        continue;
      }

      // スタメル選手の能力を評価
      final starterId = chart.starterPlayerId;
      if (starterId != null) {
        final starterPercentage = chart.getPlayingTimePercentage(starterId);
        if (starterPercentage >= 80) {
          evaluation[position] = '優秀';
        } else if (starterPercentage >= 60) {
          evaluation[position] = '良好';
        } else if (starterPercentage >= 40) {
          evaluation[position] = '普通';
        } else {
          evaluation[position] = '不安定';
        }
      } else {
        evaluation[position] = '選手不足';
      }
    }

    return evaluation;
  }

  // 投手ローテーションの評価を取得
  static String evaluatePitcherRotation(TeamDepthChart depthChart) {
    final rotation = depthChart.pitcherRotation;
    
    if (rotation.startingPitcherIds.length < 3) {
      return '先発投手不足';
    }
    
    if (rotation.reliefPitcherIds.length < 3) {
      return 'リリーフ投手不足';
    }
    
    if (rotation.closerPitcherIds.isEmpty) {
      return 'クローザー不足';
    }

    // 疲労度をチェック
    final highFatiguePitchers = rotation.pitcherUsage.values.where((usage) => usage > 2).length;
    if (highFatiguePitchers > rotation.startingPitcherIds.length * 0.6) {
      return '投手陣疲労';
    }

    return '良好';
  }
}
