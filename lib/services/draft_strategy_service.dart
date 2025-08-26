import 'dart:math';
import '../models/professional/professional_team.dart';
import '../models/professional/professional_player.dart';
import '../models/player/player.dart';
import '../models/game/pennant_race.dart';

/// ドラフト戦略サービス
/// 球団のニーズ分析と選手選択ロジックを管理
class DraftStrategyService {
  static final Random _random = Random();

  /// 球団のニーズを分析
  static Map<String, dynamic> analyzeTeamNeeds(
    ProfessionalTeam team,
    Map<String, TeamStanding> standings,
    List<ProfessionalPlayer> currentPlayers,
  ) {
    final needs = <String, dynamic>{};
    
    // 現在の戦力状況を分析
    final currentStrength = _analyzeCurrentTeamStrength(currentPlayers);
    needs['currentStrength'] = currentStrength;
    
    // 成績に基づくニーズを分析
    final standing = standings[team.id];
    if (standing != null) {
      needs['performanceBased'] = _analyzePerformanceBasedNeeds(standing);
    }
    
    // 選手層のバランスを分析
    needs['depthBalance'] = _analyzeDepthBalance(currentPlayers);
    
    // 引退予定選手の分析
    needs['retirementRisk'] = _analyzeRetirementRisk(currentPlayers);
    
    // 総合的なニーズ優先度を決定
    needs['priorityNeeds'] = _determinePriorityNeeds(needs);
    
    return needs;
  }

  /// 現在のチーム戦力を分析
  static Map<String, int> _analyzeCurrentTeamStrength(List<ProfessionalPlayer> players) {
    final strength = <String, int>{};
    final positions = <String, List<ProfessionalPlayer>>{};
    
    // ポジション別に選手を分類
    for (final player in players) {
      final position = player.player?.position ?? '投手';
      positions.putIfAbsent(position, () => []).add(player);
    }
    
    // 各ポジションの戦力を評価
    for (final entry in positions.entries) {
      final position = entry.key;
      final positionPlayers = entry.value;
      
      if (positionPlayers.isEmpty) {
        strength[position] = 0; // 選手がいない
        continue;
      }
      
      // 平均能力値を計算
      double totalAbility = 0;
      for (final player in positionPlayers) {
        totalAbility += player.player?.trueTotalAbility ?? 0;
      }
      final averageAbility = totalAbility / positionPlayers.length;
      
      // 戦力レベルを0-100で評価
      strength[position] = (averageAbility / 2).round().clamp(0, 100);
    }
    
    return strength;
  }

  /// 成績に基づくニーズを分析
  static Map<String, dynamic> _analyzePerformanceBasedNeeds(TeamStanding standing) {
    final needs = <String, dynamic>{};
    
    // 勝率に基づく即戦力ニーズ
    if (standing.winningPercentage < 0.400) {
      needs['immediateImpact'] = 'high'; // 即戦力が必要
      needs['rebuilding'] = true; // 再建が必要
    } else if (standing.winningPercentage < 0.500) {
      needs['immediateImpact'] = 'medium'; // 中程度の即戦力が必要
      needs['rebuilding'] = false;
    } else {
      needs['immediateImpact'] = 'low'; // 即戦力は不要
      needs['rebuilding'] = false;
    }
    
    // 得失点差に基づくポジション別ニーズ
    if (standing.runDifferential < -50) {
      needs['pitchingNeeds'] = 'high'; // 投手力が必要
      needs['hittingNeeds'] = 'medium'; // 打撃力も必要
    } else if (standing.runDifferential < 0) {
      needs['pitchingNeeds'] = 'medium';
      needs['hittingNeeds'] = 'medium';
    } else {
      needs['pitchingNeeds'] = 'low';
      needs['hittingNeeds'] = 'low';
    }
    
    return needs;
  }

  /// 選手層のバランスを分析
  static Map<String, dynamic> _analyzeDepthBalance(List<ProfessionalPlayer> players) {
    final balance = <String, dynamic>{};
    
    // 年齢分布を分析
    final ageGroups = <String, int>{
      'young': 0,    // 25歳以下
      'prime': 0,    // 26-32歳
      'veteran': 0,  // 33歳以上
    };
    
    for (final player in players) {
      final age = player.player?.age ?? 25;
      if (age <= 25) {
        ageGroups['young'] = (ageGroups['young'] ?? 0) + 1;
      } else if (age <= 32) {
        ageGroups['prime'] = (ageGroups['prime'] ?? 0) + 1;
      } else {
        ageGroups['veteran'] = (ageGroups['veteran'] ?? 0) + 1;
      }
    }
    
    balance['ageDistribution'] = ageGroups;
    
    // 将来性のニーズを判断
    if ((ageGroups['veteran'] ?? 0) > (ageGroups['young'] ?? 0)) {
      balance['futureNeeds'] = 'high'; // 将来性が必要
    } else if ((ageGroups['young'] ?? 0) > (ageGroups['veteran'] ?? 0)) {
      balance['futureNeeds'] = 'low'; // 将来性は不要
    } else {
      balance['futureNeeds'] = 'medium'; // 中程度
    }
    
    return balance;
  }

  /// 引退リスクを分析
  static Map<String, dynamic> _analyzeRetirementRisk(List<ProfessionalPlayer> players) {
    final risk = <String, dynamic>{};
    
    // 35歳以上の選手を特定
    final retirementRiskPlayers = players.where((p) => 
      (p.player?.age ?? 25) >= 35
    ).toList();
    
    risk['highRiskCount'] = retirementRiskPlayers.length;
    risk['highRiskPositions'] = retirementRiskPlayers
        .map((p) => p.player?.position ?? '不明')
        .toSet()
        .toList();
    
    // 引退リスクの評価
    if (retirementRiskPlayers.length >= 5) {
      risk['overallRisk'] = 'high';
    } else if (retirementRiskPlayers.length >= 2) {
      risk['overallRisk'] = 'medium';
    } else {
      risk['overallRisk'] = 'low';
    }
    
    return risk;
  }

  /// 優先ニーズを決定
  static List<String> _determinePriorityNeeds(Map<String, dynamic> needs) {
    final priorities = <String>[];
    
    // 即戦力ニーズ
    final immediateImpact = needs['performanceBased']?['immediateImpact'] ?? 'low';
    if (immediateImpact == 'high') {
      priorities.add('immediate_pitcher');
      priorities.add('immediate_hitter');
    } else if (immediateImpact == 'medium') {
      priorities.add('immediate_pitcher');
    }
    
    // 投手ニーズ
    final pitchingNeeds = needs['performanceBased']?['pitchingNeeds'] ?? 'low';
    if (pitchingNeeds == 'high') {
      priorities.add('ace_pitcher');
      priorities.add('relief_pitcher');
    } else if (pitchingNeeds == 'medium') {
      priorities.add('starting_pitcher');
    }
    
    // 将来性ニーズ
    final futureNeeds = needs['depthBalance']?['futureNeeds'] ?? 'low';
    if (futureNeeds == 'high') {
      priorities.add('future_ace');
      priorities.add('future_cleanup');
    }
    
    // 引退リスク対応
    final retirementRisk = needs['retirementRisk']?['overallRisk'] ?? 'low';
    if (retirementRisk == 'high') {
      priorities.add('replacement_player');
    }
    
    return priorities;
  }

  /// 球団のニーズに基づいて選手を選択
  static Map<String, dynamic> selectPlayerForTeam(
    ProfessionalTeam team,
    Map<String, dynamic> teamNeeds,
    List<Player> availablePlayers,
  ) {
    if (availablePlayers.isEmpty) {
      return {'error': '選択可能な選手がいません'};
    }
    
    // 優先ニーズを取得
    final priorities = teamNeeds['priorityNeeds'] as List<String>? ?? [];
    
    // 各優先ニーズに基づいて選手を評価
    final playerScores = <Player, double>{};
    
    for (final player in availablePlayers) {
      double score = 0;
      
      for (final priority in priorities) {
        score += _calculatePlayerScoreForNeed(player, priority);
      }
      
      // fameの影響を大きくする（1.0-2.0倍）
      final fameFactor = 1.0 + (player.fame ?? 0) / 100.0;
      score *= fameFactor;
      
      // ランダム要素を追加（0.8-1.2倍）
      final randomFactor = 0.8 + _random.nextDouble() * 0.4;
      score *= randomFactor;
      
      playerScores[player] = score;
    }
    
    // 最高スコアの選手を選択
    final bestPlayer = playerScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final selectionReason = _explainSelectionReason(bestPlayer, priorities);
    
    return {
      'selectedPlayer': bestPlayer,
      'score': playerScores[bestPlayer],
      'reason': selectionReason,
      'teamNeeds': priorities,
    };
  }

  /// 特定のニーズに対する選手スコアを計算
  static double _calculatePlayerScoreForNeed(Player player, String need) {
    double score = 0;
    
    switch (need) {
      case 'immediate_pitcher':
        if (player.position == '投手') {
          score += (player.trueTotalAbility ?? 0) * 0.8; // 即戦力重視
          score += (player.peakAbility ?? 0) * 0.2; // ポテンシャルも考慮
        }
        break;
        
      case 'immediate_hitter':
        if (player.position != '投手') {
          score += (player.trueTotalAbility ?? 0) * 0.7; // 即戦力重視
          score += (player.peakAbility ?? 0) * 0.3; // ポテンシャルも考慮
        }
        break;
        
      case 'ace_pitcher':
        if (player.position == '投手') {
          score += (player.trueTotalAbility ?? 0) * 0.6; // 現在の能力
          score += (player.peakAbility ?? 0) * 0.4; // ポテンシャル重視
        }
        break;
        
      case 'future_ace':
        if (player.position == '投手') {
          score += (player.trueTotalAbility ?? 0) * 0.3; // 現在の能力
          score += (player.peakAbility ?? 0) * 0.7; // ポテンシャル重視
          score += (player.growthRate ?? 0) * 10; // 成長率重視
        }
        break;
        
      case 'future_cleanup':
        if (player.position != '投手') {
          score += (player.trueTotalAbility ?? 0) * 0.2; // 現在の能力
          score += (player.peakAbility ?? 0) * 0.8; // ポテンシャル重視
          score += (player.growthRate ?? 0) * 10; // 成長率重視
        }
        break;
        
      case 'replacement_player':
        // 引退予定選手のポジションに合致する選手を優先
        score += (player.trueTotalAbility ?? 0) * 0.5;
        score += (player.peakAbility ?? 0) * 0.5;
        break;
        
      default:
        // デフォルトの評価
        score += (player.trueTotalAbility ?? 0) * 0.6;
        score += (player.peakAbility ?? 0) * 0.4;
        break;
    }
    
    return score;
  }

  /// 選択理由を説明
  static String _explainSelectionReason(Player player, List<String> priorities) {
    final reasons = <String>[];
    
    if (priorities.contains('immediate_pitcher') && player.position == '投手') {
      reasons.add('即戦力投手として期待');
    }
    if (priorities.contains('immediate_hitter') && player.position != '投手') {
      reasons.add('即戦力打者として期待');
    }
    if (priorities.contains('future_ace') && player.position == '投手') {
      reasons.add('将来のエース候補');
    }
    if (priorities.contains('future_cleanup') && player.position != '投手') {
      reasons.add('将来の4番候補');
    }
    if (priorities.contains('replacement_player')) {
      reasons.add('引退予定選手の補充');
    }
    
    if (reasons.isEmpty) {
      reasons.add('総合的な能力を評価');
    }
    
    return reasons.join('、');
  }

  /// ドラフト戦略の要約を生成
  static String generateDraftStrategySummary(Map<String, dynamic> teamNeeds) {
    final summary = <String>[];
    
    // 即戦力ニーズ
    final immediateImpact = teamNeeds['performanceBased']?['immediateImpact'] ?? 'low';
    if (immediateImpact == 'high') {
      summary.add('即戦力選手の獲得が最優先');
    } else if (immediateImpact == 'medium') {
      summary.add('中程度の即戦力が必要');
    }
    
    // 投手ニーズ
    final pitchingNeeds = teamNeeds['performanceBased']?['pitchingNeeds'] ?? 'low';
    if (pitchingNeeds == 'high') {
      summary.add('投手力の強化が急務');
    }
    
    // 将来性ニーズ
    final futureNeeds = teamNeeds['depthBalance']?['futureNeeds'] ?? 'low';
    if (futureNeeds == 'high') {
      summary.add('将来性のある選手の確保');
    }
    
    // 引退リスク
    final retirementRisk = teamNeeds['retirementRisk']?['overallRisk'] ?? 'low';
    if (retirementRisk == 'high') {
      summary.add('引退予定選手の補充が必要');
    }
    
    if (summary.isEmpty) {
      summary.add('バランスの取れた選手選択');
    }
    
    return summary.join('。') + '。';
  }
}
