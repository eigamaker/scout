import 'dart:math';
import '../../models/game/pennant_race.dart';
import '../../models/professional/professional_team.dart';
import '../../models/professional/professional_player.dart';
import '../../models/professional/depth_chart.dart';
import '../../models/professional/player_stats.dart';
import '../depth_chart_service.dart';
import '../stats_calculation_service.dart';

/// ペナントレースの試合シミュレーションを担当するクラス
class GameSimulator {
  /// 試合をシミュレート
  static GameResult simulateGame(GameSchedule game, List<ProfessionalTeam> teams) {
    final homeTeam = teams.firstWhere((t) => t.id == game.homeTeamId);
    final awayTeam = teams.firstWhere((t) => t.id == game.awayTeamId);
    
    final random = Random();
    
    // 攻撃力と守備力を別々に計算
    final homeOffense = _calculateTeamOffense(homeTeam, random);
    final homeDefense = _calculateTeamDefense(homeTeam, random);
    final awayOffense = _calculateTeamOffense(awayTeam, random);
    final awayDefense = _calculateTeamDefense(awayTeam, random);
    
    // ホームアドバンテージを適用（攻撃力+5%、守備力+3%）
    final adjustedHomeOffense = (homeOffense * 1.05).round();
    final adjustedHomeDefense = (homeDefense * 1.03).round();
    
    // 得点を計算（攻撃力 vs 相手の守備力）
    final homeScore = _calculateScore(adjustedHomeOffense, awayDefense, random);
    final awayScore = _calculateScore(awayOffense, adjustedHomeDefense, random);
    
    // 先発投手を特定
    final homeStartingPitcher = _getStartingPitcher(homeTeam);
    final awayStartingPitcher = _getStartingPitcher(awayTeam);
    
    // 試合結果をログ出力
    print('=== 試合シミュレーション ===');
    print('${homeTeam.name} vs ${awayTeam.name}');
    print('ホーム攻撃力: $homeOffense → $adjustedHomeOffense (調整後)');
    print('ホーム守備力: $homeDefense → $adjustedHomeDefense (調整後)');
    print('アウェイ攻撃力: $awayOffense');
    print('アウェイ守備力: $awayDefense');
    print('結果: ${homeTeam.name} $homeScore - $awayScore ${awayTeam.name}');
    
    // 試合結果を作成
    final result = GameResult(
      homeTeamId: game.homeTeamId,
      awayTeamId: game.awayTeamId,
      homeScore: homeScore,
      awayScore: awayScore,
      inning: 9,
      gameDate: DateTime.now(),
    );
    
    // 先発投手の勝敗を記録
    _recordPitcherWinLoss(result, homeStartingPitcher, awayStartingPitcher);
    
    return result;
  }

  /// 先発投手を取得
  static ProfessionalPlayer? _getStartingPitcher(ProfessionalTeam team) {
    if (team.professionalPlayers == null) return null;
    
    final pitchers = team.professionalPlayers!.where((p) => p.player?.position == '投手').toList();
    if (pitchers.isEmpty) return null;
    
    // 能力値順にソートして最上位を先発投手とする
    pitchers.sort((a, b) => (b.player?.trueTotalAbility ?? 0).compareTo(a.player?.trueTotalAbility ?? 0));
    return pitchers.first;
  }

  /// 投手の勝敗を記録
  static void _recordPitcherWinLoss(GameResult result, ProfessionalPlayer? homePitcher, ProfessionalPlayer? awayPitcher) {
    // 勝敗を決定
    final homeWins = result.homeScore > result.awayScore;
    final awayWins = result.awayScore > result.homeScore;
    
    // 先発投手の勝敗を記録（実際の実装では、ここでデータベースに保存）
    if (homePitcher != null) {
      if (homeWins) {
        print('先発投手勝利: ${homePitcher.player?.name} (${result.homeTeamId})');
      } else if (awayWins) {
        print('先発投手敗戦: ${homePitcher.player?.name} (${result.homeTeamId})');
      }
    }
    
    if (awayPitcher != null) {
      if (awayWins) {
        print('先発投手勝利: ${awayPitcher.player?.name} (${result.awayTeamId})');
      } else if (homeWins) {
        print('先発投手敗戦: ${awayPitcher.player?.name} (${result.awayTeamId})');
      }
    }
  }

  /// チームの攻撃力を計算
  static int _calculateTeamOffense(ProfessionalTeam team, Random random) {
    if (team.professionalPlayers == null || team.professionalPlayers!.isEmpty) {
      return 50; // デフォルト攻撃力
    }
    
    // 野手のみの攻撃力を計算（投手は除外）
    final fielders = team.professionalPlayers!.where((p) => p.player?.position != '投手').toList();
    if (fielders.isEmpty) return 50;
    
    double totalOffense = 0;
    int playerCount = 0;
    
    for (final player in fielders) {
      final playerOffense = _calculatePlayerOffense(player);
      totalOffense += playerOffense;
      playerCount++;
    }
    
    if (playerCount == 0) return 50;
    
    // ランダム要素を追加（±10%）
    final randomFactor = 0.9 + (random.nextDouble() * 0.2);
    return (totalOffense / playerCount * randomFactor).round().clamp(20, 100);
  }

  /// チームの守備力を計算
  static int _calculateTeamDefense(ProfessionalTeam team, Random random) {
    if (team.professionalPlayers == null || team.professionalPlayers!.isEmpty) {
      return 50; // デフォルト守備力
    }
    
    // 投手の守備力を重視
    final pitchers = team.professionalPlayers!.where((p) => p.player?.position == '投手').toList();
    final fielders = team.professionalPlayers!.where((p) => p.player?.position != '投手').toList();
    
    double totalDefense = 0;
    int playerCount = 0;
    
    // 投手の守備力（重み付け2.0）
    for (final pitcher in pitchers) {
      final pitcherDefense = _calculatePlayerDefense(pitcher) * 2.0;
      totalDefense += pitcherDefense;
      playerCount += 2; // 重み付け分
    }
    
    // 野手の守備力
    for (final fielder in fielders) {
      final fielderDefense = _calculatePlayerDefense(fielder);
      totalDefense += fielderDefense;
      playerCount++;
    }
    
    if (playerCount == 0) return 50;
    
    // ランダム要素を追加（±8%）
    final randomFactor = 0.92 + (random.nextDouble() * 0.16);
    return (totalDefense / playerCount * randomFactor).round().clamp(20, 100);
  }

  /// 選手の攻撃力を計算
  static int _calculatePlayerOffense(ProfessionalPlayer player) {
    final playerData = player.player;
    if (playerData == null) return 50;
    
    // 技術能力（打撃技術）と身体能力（パワー）を重視
    final technical = playerData.technical;
    final physical = playerData.physical;
    final mental = playerData.mental;
    
    // 攻撃力の計算（技術40%、身体40%、メンタル20%）
    final offense = (technical * 0.4 + physical * 0.4 + mental * 0.2);
    
    // ポジション別の調整
    double positionMultiplier = 1.0;
    switch (playerData.position) {
      case '一塁手':
      case '外野手':
        positionMultiplier = 1.1; // 攻撃重視ポジション
        break;
      case '捕手':
        positionMultiplier = 0.9; // 守備重視ポジション
        break;
      case '二塁手':
      case '三塁手':
      case '遊撃手':
        positionMultiplier = 1.0; // バランス型
        break;
    }
    
    return (offense * positionMultiplier).round().clamp(20, 100);
  }

  /// 選手の守備力を計算
  static int _calculatePlayerDefense(ProfessionalPlayer player) {
    final playerData = player.player;
    if (playerData == null) return 50;
    
    // 技術能力（守備技術）とメンタル能力（集中力）を重視
    final technical = playerData.technical;
    final physical = playerData.physical;
    final mental = playerData.mental;
    
    // 守備力の計算（技術50%、メンタル30%、身体20%）
    final defense = (technical * 0.5 + mental * 0.3 + physical * 0.2);
    
    // ポジション別の調整
    double positionMultiplier = 1.0;
    switch (playerData.position) {
      case '投手':
        positionMultiplier = 1.3; // 投手は守備力が最重要
        break;
      case '捕手':
        positionMultiplier = 1.2; // 捕手も守備力が重要
        break;
      case '遊撃手':
      case '三塁手':
        positionMultiplier = 1.1; // 内野の要
        break;
      case '二塁手':
        positionMultiplier = 1.05; // 内野手
        break;
      case '一塁手':
        positionMultiplier = 0.9; // 攻撃重視ポジション
        break;
      case '外野手':
        positionMultiplier = 1.0; // 標準
        break;
    }
    
    return (defense * positionMultiplier).round().clamp(20, 100);
  }

  /// 得点を計算（攻撃力 vs 守備力）
  static int _calculateScore(int offense, int defense, Random random) {
    // 攻撃力と守備力の差を計算
    final powerDifference = offense - defense;
    
    // 基本得点を計算（攻撃力の1/15を基本とし、守備力の差で調整）
    final baseScore = (offense / 15.0) + (powerDifference / 30.0);
    
    // 野球の特性を考慮した得点分布
    int finalScore;
    if (baseScore < 1.0) {
      // 低得点（0-2点）
      finalScore = random.nextDouble() < 0.7 ? 0 : random.nextInt(3);
    } else if (baseScore < 2.0) {
      // 中得点（1-4点）
      finalScore = 1 + random.nextInt(4);
    } else if (baseScore < 3.0) {
      // 高得点（2-6点）
      finalScore = 2 + random.nextInt(5);
    } else {
      // 超高得点（3-8点）
      finalScore = 3 + random.nextInt(6);
    }
    
    // ランダム要素を追加（±1点）
    final randomVariation = random.nextInt(3) - 1;
    finalScore += randomVariation;
    
    return finalScore.clamp(0, 12);
  }

  /// 順位表を更新
  static void updateStandings(Map<String, TeamStanding> standings, GameResult result, List<ProfessionalTeam> teams) {
    final homeTeam = teams.firstWhere((t) => t.id == result.homeTeamId);
    final awayTeam = teams.firstWhere((t) => t.id == result.awayTeamId);
    
    // ホームチームの順位を更新
    if (!standings.containsKey(result.homeTeamId)) {
      standings[result.homeTeamId] = TeamStanding(
        teamId: result.homeTeamId,
        teamName: homeTeam.name,
        teamShortName: homeTeam.shortName,
        league: homeTeam.league,
        division: homeTeam.division,
        wins: 0,
        losses: 0,
        ties: 0,
        winningPercentage: 0.0,
        runsScored: 0,
        runsAllowed: 0,
        runDifferential: 0,
      );
    }
    
    // アウェイチームの順位を更新
    if (!standings.containsKey(result.awayTeamId)) {
      standings[result.awayTeamId] = TeamStanding(
        teamId: result.awayTeamId,
        teamName: awayTeam.name,
        teamShortName: awayTeam.shortName,
        league: awayTeam.league,
        division: awayTeam.division,
        wins: 0,
        losses: 0,
        ties: 0,
        winningPercentage: 0.0,
        runsScored: 0,
        runsAllowed: 0,
        runDifferential: 0,
      );
    }
    
    var homeStanding = standings[result.homeTeamId]!;
    var awayStanding = standings[result.awayTeamId]!;
    
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
      runsScored: homeStanding.runsScored + result.homeScore,
      runsAllowed: homeStanding.runsAllowed + result.awayScore,
    );
    awayStanding = awayStanding.copyWith(
      runsScored: awayStanding.runsScored + result.awayScore,
      runsAllowed: awayStanding.runsAllowed + result.homeScore,
    );
    
    // 得失点差を更新
    homeStanding = homeStanding.copyWith(
      runDifferential: homeStanding.runsScored - homeStanding.runsAllowed,
    );
    awayStanding = awayStanding.copyWith(
      runDifferential: awayStanding.runsScored - awayStanding.runsAllowed,
    );
    
    // 順位表を更新
    standings[homeStanding.teamId] = homeStanding;
    standings[awayStanding.teamId] = awayStanding;
    
    // 勝率を更新
    _updateWinningPercentage(homeStanding, standings);
    _updateWinningPercentage(awayStanding, standings);
  }

  /// 勝率を更新
  static void _updateWinningPercentage(TeamStanding standing, Map<String, TeamStanding> standings) {
    final totalGames = standing.wins + standing.losses + standing.ties;
    if (totalGames > 0) {
      final updatedStanding = standing.copyWith(winningPercentage: standing.wins / totalGames);
      standings[standing.teamId] = updatedStanding;
    } else {
      final updatedStanding = standing.copyWith(winningPercentage: 0.0);
      standings[standing.teamId] = updatedStanding;
    }
  }

  /// 試合をシミュレート（プライベートメソッド）

  /// 順位表を更新（プライベートメソッド）
}
