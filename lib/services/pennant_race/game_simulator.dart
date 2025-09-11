import 'dart:math';
import '../../models/game/pennant_race.dart';
import '../../models/professional/professional_team.dart';
import '../../models/professional/professional_player.dart';
import '../../models/professional/depth_chart.dart';
import '../../models/professional/player_stats.dart';
import '../depth_chart_service.dart';

/// ペナントレースの試合シミュレーションを担当するクラス
class GameSimulator {
  /// 試合をシミュレート
  static GameResult _simulateGame(GameSchedule game, List<ProfessionalTeam> teams) {
    final homeTeam = teams.firstWhere((t) => t.id == game.homeTeamId);
    final awayTeam = teams.firstWhere((t) => t.id == game.awayTeamId);
    
    // チームの戦力を計算
    final homeStrength = _calculateTeamStrength(homeTeam);
    final awayStrength = _calculateTeamStrength(awayTeam);
    
    // ホームアドバンテージを適用
    final adjustedHomeStrength = (homeStrength * 1.05).round();
    
    // 試合結果を決定
    final random = Random();
    final homeScore = _calculateScore(adjustedHomeStrength, random);
    final awayScore = _calculateScore(awayStrength, random);
    
    // 試合結果を作成
    final result = GameResult(
      homeTeamId: game.homeTeamId,
      awayTeamId: game.awayTeamId,
      homeScore: homeScore,
      awayScore: awayScore,
      inning: 9,
      gameDate: DateTime.now(),
    );
    
    return result;
  }

  /// チームの戦力を計算
  static int _calculateTeamStrength(ProfessionalTeam team) {
    if (team.professionalPlayers == null || team.professionalPlayers!.isEmpty) {
      return 50; // デフォルト戦力
    }
    
    // プロ野球選手の能力値を基に戦力を計算
    double totalStrength = 0;
    int playerCount = 0;
    
    for (final player in team.professionalPlayers!) {
      final playerStrength = _calculatePlayerStrength(player);
      totalStrength += playerStrength;
      playerCount++;
    }
    
    if (playerCount == 0) return 50;
    
    return (totalStrength / playerCount).round();
  }

  /// 選手の戦力を計算
  static int _calculatePlayerStrength(ProfessionalPlayer player) {
    // 技術面、メンタル面、フィジカル面の平均を計算
    double technicalAvg = 0;
    double mentalAvg = 0;
    double physicalAvg = 0;
    
    if (player.player?.technicalAbilities.isNotEmpty == true) {
      technicalAvg = player.player!.technicalAbilities.values.reduce((a, b) => a + b) / player.player!.technicalAbilities.length;
    }
    
    if (player.player?.mentalAbilities.isNotEmpty == true) {
      mentalAvg = player.player!.mentalAbilities.values.reduce((a, b) => a + b) / player.player!.mentalAbilities.length;
    }
    
    if (player.player?.physicalAbilities.isNotEmpty == true) {
      physicalAvg = player.player!.physicalAbilities.values.reduce((a, b) => a + b) / player.player!.physicalAbilities.length;
    }
    
    // ポジション別の重み付け
    double positionWeight = 1.0;
    switch (player.player?.position) {
      case '投手':
        positionWeight = 1.2; // 投手は重要
        break;
      case '捕手':
        positionWeight = 1.1; // 捕手も重要
        break;
      default:
        positionWeight = 1.0; // 野手は標準
        break;
    }
    
    final overallStrength = (technicalAvg + mentalAvg + physicalAvg) / 3 * positionWeight;
    return overallStrength.round().clamp(1, 100);
  }

  /// 得点を計算
  static int _calculateScore(int teamStrength, Random random) {
    // 戦力に基づいて得点を決定
    final baseScore = (teamStrength / 20).round(); // 戦力/20を基本得点
    
    // ランダム変動を追加
    final randomVariation = random.nextInt(7) - 3; // -3から+3の変動
    
    final finalScore = (baseScore + randomVariation).clamp(0, 15);
    return finalScore;
  }

  /// 順位表を更新
  static void _updateStandings(Map<String, TeamStanding> standings, GameResult result, List<ProfessionalTeam> teams) {
    final homeTeam = teams.firstWhere((t) => t.id == result.homeTeamId);
    final awayTeam = teams.firstWhere((t) => t.id == result.awayTeamId);
    
    // ホームチームの順位を更新
    if (!standings.containsKey(result.homeTeamId)) {
      standings[result.homeTeamId] = TeamStanding(
        teamId: result.homeTeamId,
        teamName: result.homeTeamName,
        league: homeTeam.league,
        division: homeTeam.division,
        wins: 0,
        losses: 0,
        ties: 0,
        winningPercentage: 0.0,
        streak: '0',
        last10: '0-0',
        homeRecord: '0-0',
        awayRecord: '0-0',
        runsFor: 0,
        runsAgainst: 0,
        runDifferential: 0,
      );
    }
    
    // アウェイチームの順位を更新
    if (!standings.containsKey(result.awayTeamId)) {
      standings[result.awayTeamId] = TeamStanding(
        teamId: result.awayTeamId,
        teamName: result.awayTeamName,
        league: awayTeam.league,
        division: awayTeam.division,
        wins: 0,
        losses: 0,
        ties: 0,
        winningPercentage: 0.0,
        streak: '0',
        last10: '0-0',
        homeRecord: '0-0',
        awayRecord: '0-0',
        runsFor: 0,
        runsAgainst: 0,
        runDifferential: 0,
      );
    }
    
    final homeStanding = standings[result.homeTeamId]!;
    final awayStanding = standings[result.awayTeamId]!;
    
    // 勝敗を更新
    if (result.homeScore > result.awayScore) {
      // ホームチームの勝利
      homeStanding = homeStanding.copyWith(wins: homeStanding.wins + 1);
      awayStanding = awayStanding.copyWith(losses: awayStanding.losses + 1);
    } else if (result.homeScore < result.awayScore) {
      // アウェイチームの勝利
      homeStanding = homeStanding.copyWith(losses: homeStanding.losses + 1);
      awayStanding = awayStanding.copyWith(wins: awayStanding.wins + 1);
    } else {
      // 引き分け
      homeStanding = homeStanding.copyWith(ties: homeStanding.ties + 1);
      awayStanding = awayStanding.copyWith(ties: awayStanding.ties + 1);
    }
    
    // 得点を更新
    homeStanding = homeStanding.copyWith(
      runsFor: homeStanding.runsFor + result.homeScore,
      runsAgainst: homeStanding.runsAgainst + result.awayScore,
    );
    awayStanding = awayStanding.copyWith(
      runsFor: awayStanding.runsFor + result.awayScore,
      runsAgainst: awayStanding.runsAgainst + result.homeScore,
    );
    
    // 得失点差を更新
    homeStanding = homeStanding.copyWith(
      runDifferential: homeStanding.runsFor - homeStanding.runsAgainst,
    );
    awayStanding = awayStanding.copyWith(
      runDifferential: awayStanding.runsFor - awayStanding.runsAgainst,
    );
    
    // 勝率を更新
    _updateWinningPercentage(homeStanding, standings);
    _updateWinningPercentage(awayStanding, standings);
  }

  /// 勝率を更新
  static void _updateWinningPercentage(TeamStanding standing, Map<String, TeamStanding> standings) {
    final totalGames = standing.wins + standing.losses + standing.ties;
    if (totalGames > 0) {
      standing = standing.copyWith(winningPercentage: standing.wins / totalGames);
    } else {
      standing = standing.copyWith(winningPercentage: 0.0);
    }
  }
}
