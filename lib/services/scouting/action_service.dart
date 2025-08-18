import 'dart:math';
import '../../models/scouting/action.dart';
import '../../models/scouting/scout.dart';
import '../../models/scouting/scouting_history.dart';
import 'accuracy_calculator.dart';
import '../../models/school/school.dart';
import '../../models/player/player.dart';
import '../../models/player/player_abilities.dart';
import '../data_service.dart';

import '../../models/scouting/team_request.dart';

class SchoolScoutResult {
  final Player? discoveredPlayer;
  final Player? improvedPlayer;
  final String message;
  SchoolScoutResult({this.discoveredPlayer, this.improvedPlayer, required this.message});
}

class MultipleScoutResult {
  final List<Player> discoveredPlayers;
  final Player? improvedPlayer;
  final String message;
  MultipleScoutResult({required this.discoveredPlayers, this.improvedPlayer, required this.message});
}

class ScoutActionResult {
  final bool success;
  final String message;
  final Player? discoveredPlayer;
  final Player? improvedPlayer;

  ScoutActionResult({
    required this.success,
    required this.message,
    this.discoveredPlayer,
    this.improvedPlayer,
  });
}

class ActionService {
  static final Random _random = Random();

  /// アクションを実行
  static ActionResult executeAction({
    required Action action,
    required Scout scout,
    required String targetId,
    required String targetType,
    required ScoutingHistory? history,
    required int currentWeek,
  }) {
    // 前提条件チェック
    final prerequisiteCheck = _checkPrerequisites(action, scout);
    if (!prerequisiteCheck.isValid) {
      return ActionResult.failure(
        action: action,
        scout: scout,
        reason: prerequisiteCheck.reason ?? '前提条件を満たしていません',
      );
    }

    // リソース消費
    final updatedScout = scout
        .consumeActionPoints(action.actionPoints)
        .consumeStamina(action.actionPoints * 5) // 簡易的な体力消費
        .spendMoney(action.cost);

    // 成功判定
    final successRate = AccuracyCalculator.calculateSuccessRate(
      baseSuccessRate: action.baseSuccessRate,
      primarySkill: action.primarySkill,
      skillCoefficient: action.skillCoefficient,
      scoutSkills: scout.skills,
    );

    final isSuccessful = _random.nextDouble() < successRate;

    // 結果処理
    final result = _processResult(
      action: action,
      scout: updatedScout,
      targetId: targetId,
      targetType: targetType,
      history: history,
      currentWeek: currentWeek,
      isSuccessful: isSuccessful,
    );

    return result;
  }

  /// 学校視察アクション（学校単位で実行）
  static Future<SchoolScoutResult> scoutSchool({
    required School school,
    required int currentWeek,
  }) async {
    // 未発掘選手リスト
    final undiscovered = school.players.where((p) => !p.isDiscovered).toList();
    if (undiscovered.isNotEmpty) {
      // 未発掘選手がいればランダムで1人発掘
      final player = undiscovered[Random().nextInt(undiscovered.length)];
      player.isDiscovered = true;
      player.discoveredAt = DateTime.now();
      player.discoveredCount = 1;
      player.scoutedDates.add(DateTime.now());
      // 知名度に基づく初期情報把握度を設定（性格・精神面は除外）
      final baseKnowledge = _getInitialKnowledgeByFame(player.fameLevel);
      player.abilityKnowledge.updateAll((k, v) {
        // 性格・精神面の情報は除外
        if (k == 'personality' || k == 'mentalStrength' || k == 'motivation') {
          return v; // 変更しない
        }
        // 知名度に基づく初期把握度 + ランダム要素
        final randomVariation = Random().nextInt(21) - 10; // ±10%
        return (baseKnowledge + randomVariation).clamp(0, 100);
      });
      
      // 学校視察で発見した選手のScoutAnalysisデータを生成
      await _generateSchoolScoutAnalysis(player, 1); // デフォルトスカウトID 1
      
      return SchoolScoutResult(
        discoveredPlayer: player,
        improvedPlayer: null,
        message: '🏫 ${school.name}の視察: 新しい選手「${player.name}」を発見しました！',
      );
    } else {
      // すでに全員発掘済み→ランダムで1人の把握度アップ
      final discovered = school.players.where((p) => p.isDiscovered).toList();
      if (discovered.isEmpty) {
        return SchoolScoutResult(
          discoveredPlayer: null,
          improvedPlayer: null,
          message: '🏫 ${school.name}の視察: この学校には選手がいません。',
        );
      }
      final player = discovered[Random().nextInt(discovered.length)];
      player.discoveredCount += 1;
      player.scoutedDates.add(DateTime.now());
      // 能力値把握度を+10～+20%アップ（最大80%）（性格・精神面は除外）
      player.abilityKnowledge.updateAll((k, v) {
        // 性格・精神面の情報は除外
        if (k == 'personality' || k == 'mentalStrength' || k == 'motivation') {
          return v; // 変更しない
        }
        return (v + 10 + Random().nextInt(11)).clamp(0, 80);
      });
      
      // 学校視察で把握度を上げた選手のScoutAnalysisデータを更新
      await _generateSchoolScoutAnalysis(player, 1); // デフォルトスカウトID 1
      
      return SchoolScoutResult(
        discoveredPlayer: null,
        improvedPlayer: player,
        message: '🏫 ${school.name}の視察: 「${player.name}」の能力値の把握度が上がった！',
      );
    }
  }

  /// 練習視察アクション（複数選手発掘版）
  static MultipleScoutResult practiceWatchMultiple({
    required School school,
    required int currentWeek,
  }) {
    // 未発掘選手リスト
    final undiscovered = school.players.where((p) => !p.isDiscovered).toList();
    final discoveredPlayers = <Player>[];
    
    if (undiscovered.isNotEmpty) {
      // 発掘する選手数を決定（1-3人）
      final discoverCount = 1 + Random().nextInt(3); // 1-3人
      final actualCount = discoverCount.clamp(1, undiscovered.length);
      
      // ポテンシャル基準での選手選択
      final potentialPlayers = <Player>[];
      for (final player in undiscovered) {
        // ポテンシャル、才能ランク、成長率を考慮した発見確率
        double discoveryChance = 0.15; // 複数発掘時は基本確率を少し上げる
        
        // ポテンシャルが高いほど発見しやすい
        if (player.peakAbility >= 120) discoveryChance += 0.4;
        else if (player.peakAbility >= 100) discoveryChance += 0.3;
        else if (player.peakAbility >= 90) discoveryChance += 0.2;
        else discoveryChance += 0.1;
        
        // 才能ランクが高いほど発見しやすい
        discoveryChance += (player.talent - 1) * 0.1;
        
        // 成長率が高いほど発見しやすい
        if (player.growthRate > 1.1) discoveryChance += 0.2;
        else if (player.growthRate > 1.05) discoveryChance += 0.1;
        
        // 現在の能力値が低くても発見可能（隠れた才能）
        if (player.trueTotalAbility < 60 && player.peakAbility >= 100) {
          discoveryChance += 0.3; // 隠れた才能ボーナス
        }
        
        if (Random().nextDouble() < discoveryChance) {
          potentialPlayers.add(player);
        }
      }
      
      // 最低1人、最大actualCount人を発掘
      final selectedPlayers = <Player>[];
      if (potentialPlayers.isNotEmpty) {
        // ポテンシャル選手から優先的に選択
        final shuffled = List<Player>.from(potentialPlayers)..shuffle();
        selectedPlayers.addAll(shuffled.take(actualCount));
      }
      
      // 不足分はランダムで補完
      if (selectedPlayers.length < actualCount) {
        final remaining = undiscovered.where((p) => !selectedPlayers.contains(p)).toList();
        if (remaining.isNotEmpty) {
          remaining.shuffle();
          final needed = actualCount - selectedPlayers.length;
          selectedPlayers.addAll(remaining.take(needed));
        }
      }
      
      for (final player in selectedPlayers) {
        player.isDiscovered = true;
        player.discoveredAt = DateTime.now();
        player.discoveredCount = 1;
        player.scoutedDates.add(DateTime.now());
        
        // 練習視察では基本情報のみ取得（詳細な能力値判定はしない）
        // 実際の能力値判定はスカウト分析システムを通じて行う
        // ここでは発掘のみを行い、詳細な能力値は後のアクションで判定する
        
        discoveredPlayers.add(player);
      }
      
      String message;
      if (actualCount == 1) {
        message = '🏃 ${school.name}の練習視察: 「${discoveredPlayers.first.name}」の練習態度が目立ちました';
      } else {
        final names = discoveredPlayers.map((p) => p.name).join('、');
        message = '🏃 ${school.name}の練習視察: ${actualCount}人の選手「${names}」を発見しました！';
      }
      
      return MultipleScoutResult(
        discoveredPlayers: discoveredPlayers,
        improvedPlayer: null,
        message: message,
      );
    } else {
      // すでに全員発掘済み→新たに発掘する選手はいない
      return MultipleScoutResult(
        discoveredPlayers: [],
        improvedPlayer: null,
        message: '🏃 ${school.name}の練習視察: この学校の選手は既に発掘済みです。',
      );
    }
  }

  /// 練習視察アクション（単一選手版）
  static Future<ScoutActionResult> practiceWatch({
    required School school,
    required Player? targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) async {
    // 練習視察の具体的な処理
    if (targetPlayer != null) {
      // 特定選手の練習視察
      // 練習視察では詳細な能力値判定は行わない
      // スカウト分析システムを通じて段階的に情報を取得する
      
      return ScoutActionResult(
        success: true,
        message: '🏃 ${school.name}の練習視察: 「${targetPlayer.name}」のフィジカル面を詳しく観察できました',
        discoveredPlayer: null,
        improvedPlayer: targetPlayer,
      );
    } else {
      // 学校全体の練習視察でポテンシャル基準での発掘
      final undiscovered = school.players.where((p) => !p.isDiscovered).toList();
      if (undiscovered.isNotEmpty) {
        // 探索スキルに基づいて発掘可能性を計算
        final explorationSkill = scoutSkills[ScoutSkill.exploration] ?? 1;
        
        // ポテンシャル基準での選手選択（ランダム要素も含む）
        final potentialPlayers = <Player>[];
        for (final player in undiscovered) {
          // ポテンシャル、才能ランク、成長率を考慮した発見確率
          double discoveryChance = 0.1; // 基本確率
          
          // ポテンシャルが高いほど発見しやすい
          if (player.peakAbility >= 120) discoveryChance += 0.4;
          else if (player.peakAbility >= 100) discoveryChance += 0.3;
          else if (player.peakAbility >= 90) discoveryChance += 0.2;
          else discoveryChance += 0.1;
          
          // 才能ランクが高いほど発見しやすい
          discoveryChance += (player.talent - 1) * 0.1;
          
          // 成長率が高いほど発見しやすい
          if (player.growthRate > 1.1) discoveryChance += 0.2;
          else if (player.growthRate > 1.05) discoveryChance += 0.1;
          
          // 探索スキルによる補正
          discoveryChance += (explorationSkill - 1) * 0.05;
          
          // 現在の能力値が低くても発見可能（隠れた才能）
          if (player.trueTotalAbility < 60 && player.peakAbility >= 100) {
            discoveryChance += 0.3; // 隠れた才能ボーナス
          }
          
          if (Random().nextDouble() < discoveryChance) {
            potentialPlayers.add(player);
          }
        }
        
        if (potentialPlayers.isNotEmpty) {
          final player = potentialPlayers[Random().nextInt(potentialPlayers.length)];
          player.isDiscovered = true;
          player.discoveredAt = DateTime.now();
          player.discoveredCount = 1;
          player.scoutedDates.add(DateTime.now());
          
          // フィジカル面の能力値のみ把握度を設定
          player.abilityKnowledge.updateAll((k, v) {
            if (k == 'pace' || k == 'acceleration' || k == 'agility' || 
                k == 'balance' || k == 'jumpingReach' || k == 'naturalFitness' || 
                k == 'stamina' || k == 'strength' || k == 'injuryProneness') {
              return 100; // 完全に把握
            }
            return 0;
          });
          
          // スカウト分析データも生成（フィジカル面の能力値のみ）
          await generateScoutAnalysisForPhysicalAbilities(player, 1); // デフォルトスカウトID 1
          
          // メッセージは選手のポテンシャルに応じて変化
          String message;
          if (player.peakAbility >= 120 && player.trueTotalAbility < 60) {
            message = '🏃 ${school.name}の練習視察: 「${player.name}」は目立たないが、何か光るものを感じました...';
          } else if (player.talent >= 4) {
            message = '🏃 ${school.name}の練習視察: 「${player.name}」の練習態度に才能を感じました';
          } else {
            message = '🏃 ${school.name}の練習視察: 「${player.name}」の練習態度が目立ちました';
          }
          
          return ScoutActionResult(
            success: true,
            message: message,
            discoveredPlayer: player,
            improvedPlayer: null,
          );
        } else {
          // ランダムで1人は必ず発掘（最低保証）
          final player = undiscovered[Random().nextInt(undiscovered.length)];
          player.isDiscovered = true;
          player.discoveredAt = DateTime.now();
          player.discoveredCount = 1;
          player.scoutedDates.add(DateTime.now());
          
          // 練習視察では発掘のみ行い、詳細な能力値判定はスカウト分析システムで処理する
          
          return ScoutActionResult(
            success: true,
            message: '🏃 ${school.name}の練習視察: 「${player.name}」を発見しましたが、特に印象的ではありませんでした',
            discoveredPlayer: player,
            improvedPlayer: null,
          );
        }
      }
      
      return ScoutActionResult(
        success: true,
        message: '🏃 ${school.name}の練習視察: 特に目立った選手はいませんでした',
        discoveredPlayer: null,
        improvedPlayer: null,
      );
    }
  }

  /// 試合観戦アクション
  static Future<ScoutActionResult> gameWatch({
    required School school,
    required Player? targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) async {
    // 試合観戦の具体的な処理
    if (targetPlayer != null) {
      // 特定選手の試合観戦
      // 技術面とフィジカル面の能力値のみ把握度を設定
      targetPlayer.abilityKnowledge.updateAll((k, v) {
        if (k == 'contact' || k == 'power' || k == 'plateDiscipline' || 
            k == 'oppositeFieldHitting' || k == 'pullHitting' || k == 'batControl' || 
            k == 'swingSpeed' || k == 'fielding' || k == 'throwing' || 
            k == 'catcherAbility' || k == 'fastball' || k == 'breakingBall' || 
            k == 'pitchMovement' || k == 'control' || k == 'stamina' ||
            k == 'pace' || k == 'acceleration' || k == 'agility' || 
            k == 'balance' || k == 'jumpingReach' || k == 'naturalFitness' || 
            k == 'strength' || k == 'injuryProneness') {
          return 100; // 完全に把握
        }
        return v;
      });
      
      // スカウト分析データも生成（技術面・フィジカル面の能力値）
      await generateScoutAnalysisForTechnicalAndPhysicalAbilities(targetPlayer, 1); // デフォルトスカウトID 1
      
      return ScoutActionResult(
        success: true,
        message: '⚾ ${school.name}の試合観戦: 「${targetPlayer.name}」の試合での活躍を確認できました',
        discoveredPlayer: null,
        improvedPlayer: targetPlayer,
      );
    } else {
      // 学校全体の試合観戦で高能力値選手を発掘
      final undiscovered = school.players.where((p) => !p.isDiscovered).toList();
      
      // 高能力値選手（レギュラークラス）のみを対象とする
      final regularPlayers = undiscovered.where((p) => p.trueTotalAbility >= 70).toList();
      
      if (regularPlayers.isNotEmpty) {
        // 高能力値選手から発掘
        final player = regularPlayers[Random().nextInt(regularPlayers.length)];
        player.isDiscovered = true;
        player.discoveredAt = DateTime.now();
        player.discoveredCount = 1;
        player.scoutedDates.add(DateTime.now());
        
        // 試合観戦では発掘のみ行い、詳細分析はスカウト分析システムで処理する
        
        return ScoutActionResult(
          success: true,
          message: '⚾ ${school.name}の試合観戦: レギュラーとして出場していた「${player.name}」の実力が印象的でした！',
          discoveredPlayer: player,
          improvedPlayer: null,
        );
      } else {
        // 既に発掘済みの選手から情報を更新
        final allPlayers = school.players.where((p) => p.isDiscovered).toList();
        if (allPlayers.isNotEmpty) {
          final player = allPlayers[Random().nextInt(allPlayers.length)];
          // 技術面とフィジカル面の能力値のみ把握度を設定
          player.abilityKnowledge.updateAll((k, v) {
            if (k == 'contact' || k == 'power' || k == 'plateDiscipline' || 
                k == 'oppositeFieldHitting' || k == 'pullHitting' || k == 'batControl' || 
                k == 'swingSpeed' || k == 'fielding' || k == 'throwing' || 
                k == 'catcherAbility' || k == 'fastball' || k == 'breakingBall' || 
                k == 'pitchMovement' || k == 'control' || k == 'stamina' ||
                k == 'pace' || k == 'acceleration' || k == 'agility' || 
                k == 'balance' || k == 'jumpingReach' || k == 'naturalFitness' || 
                k == 'strength' || k == 'injuryProneness') {
              return 100; // 完全に把握
            }
            return v;
          });
          
          return ScoutActionResult(
            success: true,
            message: '⚾ ${school.name}の試合観戦: 「${player.name}」の試合での印象が強く残りました',
            discoveredPlayer: null,
            improvedPlayer: player,
          );
        }
        
        return ScoutActionResult(
          success: true,
          message: '⚾ ${school.name}の試合観戦: 試合は見応えがありましたが、レギュラークラスの新しい選手は見つかりませんでした',
          discoveredPlayer: null,
          improvedPlayer: null,
        );
      }
    }
  }



  /// ビデオ分析アクション
  static Future<ScoutActionResult> videoAnalyze({
    required Player targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) async {
    // ビデオ分析の具体的な処理
    // 才能、成長タイプとポテンシャルのみ把握度を設定
    
    // 選手を発掘状態にする（まだ発掘されていない場合）
    if (!targetPlayer.isDiscovered) {
      targetPlayer.isDiscovered = true;
      targetPlayer.discoveredAt = DateTime.now();
      targetPlayer.discoveredCount = 1;
      targetPlayer.scoutedDates.add(DateTime.now());
    } else {
      // 既に発掘済みの場合は視察回数を増やす
      targetPlayer.discoveredCount += 1;
      targetPlayer.scoutedDates.add(DateTime.now());
    }
    
    // 成長タイプの分析（既存の成長タイプを詳細化）
    final growthTypeAnalysis = _analyzeGrowthType(targetPlayer);
    
    // 怪我リスクの分析
    final injuryRisk = _analyzeInjuryRisk(targetPlayer);
    
    // ポテンシャルの分析
    final potentialAnalysis = _analyzePotential(targetPlayer);
    
    // 成長履歴の生成（簡易版）
    _generateGrowthHistory(targetPlayer, currentWeek);
    
    // 才能、成長タイプ、ポテンシャル関連の能力値のみ把握度を設定
    targetPlayer.abilityKnowledge.updateAll((k, v) {
      if (k == 'talent' || k == 'growthRate' || k == 'peakAbility' || 
          k == 'potential' || k == 'developmentSpeed') {
        return 100; // 完全に把握
      }
      return v;
    });
    
    // 基本情報分析データを生成・保存
    await _generateBasicInfoAnalysis(targetPlayer, 1, growthTypeAnalysis, injuryRisk, potentialAnalysis);
    
    // ビデオ分析で把握できる能力値のScoutAnalysisデータも生成
    await _generateVideoAnalysisScoutData(targetPlayer, 1); // デフォルトスカウトID 1
    
    return ScoutActionResult(
      success: true,
      message: '📹 ${targetPlayer.name}のビデオ分析: 成長タイプ「${growthTypeAnalysis}」、怪我リスク「${injuryRisk}」、ポテンシャル「${potentialAnalysis}」を分析しました',
      discoveredPlayer: null,
      improvedPlayer: targetPlayer,
    );
  }

  /// 成長タイプの分析
  static String _analyzeGrowthType(Player player) {
    final growthType = player.growthType;
    final growthRate = player.growthRate;
    
    if (growthType == 'early' && growthRate > 1.1) {
      return '早期成長型（優秀）';
    } else if (growthType == 'early') {
      return '早期成長型';
    } else if (growthType == 'late' && growthRate > 1.05) {
      return '遅咲き型（有望）';
    } else if (growthType == 'late') {
      return '遅咲き型';
    } else {
      return '標準成長型';
    }
  }

  /// 怪我リスクの分析
  static String _analyzeInjuryRisk(Player player) {
    final injuryProneness = player.physicalAbilities[PhysicalAbility.injuryProneness] ?? 50;
    
    if (injuryProneness > 70) {
      return '高リスク';
    } else if (injuryProneness > 50) {
      return '中リスク';
    } else {
      return '低リスク';
    }
  }

  /// ポテンシャルの分析
  static String _analyzePotential(Player player) {
    final peakAbility = player.peakAbility;
    
    if (peakAbility >= 130) {
      return '超一流レベル';
    } else if (peakAbility >= 110) {
      return '一流レベル';
    } else if (peakAbility >= 90) {
      return '有望レベル';
    } else {
      return '標準レベル';
    }
  }

  /// 成長履歴の生成（簡易版）
  static Map<String, dynamic> _generateGrowthHistory(Player player, int currentWeek) {
    // 現在の週から過去数週間の成長履歴を生成
    final history = <String, dynamic>{};
    
    // 簡易的な履歴データ（実際の実装では過去のスカウト分析データを使用）
    for (int week = currentWeek - 4; week <= currentWeek; week++) {
      if (week > 0) {
        history['week_$week'] = {
          'contact': (player.technicalAbilities[TechnicalAbility.contact] ?? 50) + Random().nextInt(5),
          'power': (player.technicalAbilities[TechnicalAbility.power] ?? 50) + Random().nextInt(5),
          'growth_rate': player.growthRate,
        };
      }
    }
    
    return history;
  }

  /// レポート作成アクション
  static ScoutActionResult reportWrite({
    required TeamRequest teamRequest,
    required Player selectedPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) {
    // 選手の総合評価を生成
    _generateOverallEvaluation(selectedPlayer, scoutSkills);
    _generateFuturePrediction(selectedPlayer, teamRequest.type);
    _generateRecommendation(selectedPlayer, teamRequest);
    
    // レポートの質を計算（交渉スキルに基づく）
    final reportQuality = _calculateReportQuality(scoutSkills);
    
    return ScoutActionResult(
      success: true,
      message: '📋 レポート作成完了: ${selectedPlayer.name}選手を${teamRequest.title}として推薦しました。レポート品質: ${(reportQuality * 100).toInt()}%',
      discoveredPlayer: null,
      improvedPlayer: selectedPlayer,
    );
  }

  /// 練習試合観戦アクション
  static Future<ScoutActionResult> scrimmage({
    required School school,
    required Player? targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) async {
    // 練習試合観戦の具体的な処理
    if (targetPlayer != null) {
      // 特定選手の練習試合観戦
      // 技術面の能力値のみ把握度を設定
      targetPlayer.abilityKnowledge.updateAll((k, v) {
        if (k == 'contact' || k == 'power' || k == 'plateDiscipline' || 
            k == 'oppositeFieldHitting' || k == 'pullHitting' || k == 'batControl' || 
            k == 'swingSpeed' || k == 'fielding' || k == 'throwing' || 
            k == 'catcherAbility' || k == 'fastball' || k == 'breakingBall' || 
            k == 'pitchMovement' || k == 'control' || k == 'stamina') {
          return 100; // 完全に把握
        }
        return v;
      });
      
      // スカウト分析データも生成（技術面の能力値のみ）
      await _generateScoutAnalysisForTechnicalAbilities(targetPlayer, 1); // デフォルトスカウトID 1
      
      return ScoutActionResult(
        success: true,
        message: '🏟️ ${school.name}の練習試合観戦: 「${targetPlayer.name}」の技術面を詳しく観察できました',
        discoveredPlayer: null,
        improvedPlayer: targetPlayer,
      );
    } else {
      // 学校全体の練習試合観戦で高能力値選手を発掘
      final undiscovered = school.players.where((p) => !p.isDiscovered).toList();
      
      // 高能力値選手（レギュラークラス）のみを対象とする
      final regularPlayers = undiscovered.where((p) => p.trueTotalAbility >= 70).toList();
      
      if (regularPlayers.isNotEmpty) {
        // 高能力値選手から発掘
        final player = regularPlayers[Random().nextInt(regularPlayers.length)];
        player.isDiscovered = true;
        player.discoveredAt = DateTime.now();
        player.discoveredCount = 1;
        player.scoutedDates.add(DateTime.now());
        
        // 練習試合観戦では発掘のみ行い、詳細分析はスカウト分析システムで処理する
        
        return ScoutActionResult(
          success: true,
          message: '🏟️ ${school.name}の練習試合観戦: レギュラーとして出場していた「${player.name}」の技術力が目を引きました！',
          discoveredPlayer: player,
          improvedPlayer: null,
        );
      } else {
        // 既に発掘済みの選手から情報を更新
        final allPlayers = school.players.where((p) => p.isDiscovered).toList();
        if (allPlayers.isNotEmpty) {
          final player = allPlayers[Random().nextInt(allPlayers.length)];
          // 技術面の能力値のみ把握度を設定
          player.abilityKnowledge.updateAll((k, v) {
            if (k == 'contact' || k == 'power' || k == 'plateDiscipline' || 
                k == 'oppositeFieldHitting' || k == 'pullHitting' || k == 'batControl' || 
                k == 'swingSpeed' || k == 'fielding' || k == 'throwing' || 
                k == 'catcherAbility' || k == 'fastball' || k == 'breakingBall' || 
                k == 'pitchMovement' || k == 'control' || k == 'stamina') {
              return 100; // 完全に把握
            }
            return v;
          });
          
          return ScoutActionResult(
            success: true,
            message: '🏟️ ${school.name}の練習試合観戦: 「${player.name}」の技術面の把握度が上がりました',
            discoveredPlayer: null,
            improvedPlayer: player,
          );
        }
        
        return ScoutActionResult(
          success: true,
          message: '🏟️ ${school.name}の練習試合観戦: 練習試合は見応えがありましたが、レギュラークラスの新しい選手は見つかりませんでした',
          discoveredPlayer: null,
          improvedPlayer: null,
        );
      }
    }
  }

  /// インタビューアクション
  static Future<ScoutActionResult> interview({
    required Player targetPlayer,
    required Scout scout,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) async {
    // インタビューの具体的な処理
    // 性格と精神力とメンタル面の能力値のみ把握度を設定
    
    // 選手を発掘状態にする（まだ発掘されていない場合）
    if (!targetPlayer.isDiscovered) {
      targetPlayer.isDiscovered = true;
      targetPlayer.discoveredAt = DateTime.now();
      targetPlayer.discoveredCount = 1;
      targetPlayer.scoutedDates.add(DateTime.now());
    } else {
      // 既に発掘済みの場合は視察回数を増やす
      targetPlayer.discoveredCount += 1;
      targetPlayer.scoutedDates.add(DateTime.now());
    }
    
    // 性格タイプの分析
    final personalityTypes = ['リーダー型', '努力型', '天才型', '冷静型', '情熱型'];
    final personality = personalityTypes[Random().nextInt(personalityTypes.length)];
    
    // 精神力の分析（0-100のスケール）
    final mentalStrength = 30 + Random().nextInt(41); // 30-70の範囲
    
    // 動機・目標の分析
    final motivations = [
      'プロ野球選手になりたい',
      '甲子園で優勝したい',
      '家族を支えたい',
      '野球が好きだから続けたい',
      'チームの勝利に貢献したい'
    ];
    final motivation = motivations[Random().nextInt(motivations.length)];
    
    // 選手の性格・精神情報を更新
    targetPlayer.personality = personality;
    targetPlayer.mentalStrength = mentalStrength;
    targetPlayer.motivation = motivation;
    
    // メンタル面の能力値のみ把握度を設定
    targetPlayer.abilityKnowledge.updateAll((k, v) {
      if (k == 'workRate' || k == 'selfDiscipline' || k == 'pressureHandling' || 
          k == 'clutchAbility' || k == 'leadership' || k == 'teamwork') {
        return 100; // 完全に把握
      }
      return v;
    });
    
    // スカウト分析データも生成（メンタル面の能力値のみ）
    await generateScoutAnalysisForMentalAbilities(targetPlayer, 1); // デフォルトスカウトID 1
    
    // 基本情報分析データも生成（性格・精神力情報）
    try {
      await _generateBasicInfoAnalysisForInterview(targetPlayer, 1, personality, mentalStrength, motivation);
      print('インタビュー基本情報分析データ生成呼び出し完了: プレイヤーID ${targetPlayer.id}');
    } catch (e) {
      print('インタビュー基本情報分析データ生成呼び出しエラー: $e');
    }
    
    // インタビューで把握できる能力値のScoutAnalysisデータも生成
    await _generateInterviewScoutData(targetPlayer, 1); // デフォルトスカウトID 1
    
    return ScoutActionResult(
      success: true,
      message: '💬 ${targetPlayer.name}のインタビュー: 性格「${personality}」、精神力${mentalStrength}、動機「${motivation}」を把握しました',
      discoveredPlayer: null,
      improvedPlayer: targetPlayer,
    );
  }

  /// メンタル面能力値専用のスカウト分析データ生成
  static Future<void> generateScoutAnalysisForMentalAbilities(Player targetPlayer, int scoutId) async {
    try {
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存のスカウト分析データを取得
      final existingData = await db.query(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      Map<String, dynamic> scoutedAbilities = {};
      
      // 既存データがある場合は継承（メンタル面以外の能力値のみ）
      if (existingData.isNotEmpty) {
        final existing = existingData.first;
        final existingMap = Map<String, dynamic>.from(existing);
        existingMap.remove('id');
        existingMap.remove('player_id');
        existingMap.remove('scout_id');
        existingMap.remove('analysis_date');
        existingMap.remove('accuracy');
        
        // メンタル面の能力値以外のみを継承
        final mentalAbilities = [
          'work_rate_scouted', 'self_discipline_scouted', 'pressure_handling_scouted',
          'clutch_ability_scouted', 'leadership_scouted', 'teamwork_scouted',
          'concentration_scouted', 'anticipation_scouted', 'vision_scouted', 'composure_scouted',
          'aggression_scouted', 'bravery_scouted', 'ambition_scouted'
        ];
        
        for (final entry in existingMap.entries) {
          if (!mentalAbilities.contains(entry.key)) {
            scoutedAbilities[entry.key] = entry.value;
          }
        }
      }
      
      // メンタル面の能力値を追加
      final mentalAbilities = [
        {'key': 'work_rate_scouted', 'ability': MentalAbility.workRate},
        {'key': 'self_discipline_scouted', 'ability': MentalAbility.selfDiscipline},
        {'key': 'pressure_handling_scouted', 'ability': MentalAbility.pressureHandling},
        {'key': 'clutch_ability_scouted', 'ability': MentalAbility.clutchAbility},
        {'key': 'leadership_scouted', 'ability': MentalAbility.leadership},
        {'key': 'teamwork_scouted', 'ability': MentalAbility.teamwork},
        {'key': 'concentration_scouted', 'ability': MentalAbility.concentration},
        {'key': 'anticipation_scouted', 'ability': MentalAbility.anticipation},
        {'key': 'vision_scouted', 'ability': MentalAbility.vision},
        {'key': 'composure_scouted', 'ability': MentalAbility.composure},
        {'key': 'aggression_scouted', 'ability': MentalAbility.aggression},
        {'key': 'bravery_scouted', 'ability': MentalAbility.bravery},
        {'key': 'ambition_scouted', 'ability': MentalAbility.ambition}
      ];
      
      for (final abilityInfo in mentalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as MentalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getMentalAbility(ability);
        
        // インタビューは高精度（誤差±3程度）
        final errorRange = 3;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // データベースに保存
      final insertData = {
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 90, // インタビューは高精度
        ...scoutedAbilities,
      };
      
      // 既存データを削除してから新しいデータを挿入
      await db.delete(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
      );
      
      await db.insert('ScoutAnalysis', insertData);
      
      print('メンタル面スカウト分析データ生成完了: プレイヤーID ${targetPlayer.id}');
    } catch (e) {
      print('メンタル面スカウト分析データ生成エラー: $e');
    }
  }

  /// フィジカル面能力値専用のスカウト分析データ生成
  static Future<void> generateScoutAnalysisForPhysicalAbilities(Player targetPlayer, int scoutId) async {
    try {
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存のスカウト分析データを取得
      final existingData = await db.query(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      Map<String, dynamic> scoutedAbilities = {};
      
      // 既存データがある場合は継承（フィジカル面以外の能力値のみ）
      if (existingData.isNotEmpty) {
        final existing = existingData.first;
        final existingMap = Map<String, dynamic>.from(existing);
        existingMap.remove('id');
        existingMap.remove('player_id');
        existingMap.remove('scout_id');
        existingMap.remove('analysis_date');
        existingMap.remove('accuracy');
        
        // フィジカル面の能力値以外のみを継承
        final physicalAbilities = [
          'pace_scouted', 'acceleration_scouted', 'agility_scouted', 'balance_scouted',
          'jumping_reach_scouted', 'stamina_scouted', 'strength_scouted', 'flexibility_scouted'
        ];
        
        for (final entry in existingMap.entries) {
          if (!physicalAbilities.contains(entry.key)) {
            scoutedAbilities[entry.key] = entry.value;
          }
        }
      }
      
      // フィジカル面の能力値を追加
      final physicalAbilities = [
        {'key': 'pace_scouted', 'ability': PhysicalAbility.pace},
        {'key': 'acceleration_scouted', 'ability': PhysicalAbility.acceleration},
        {'key': 'agility_scouted', 'ability': PhysicalAbility.agility},
        {'key': 'balance_scouted', 'ability': PhysicalAbility.balance},
        {'key': 'jumping_reach_scouted', 'ability': PhysicalAbility.jumpingReach},
        {'key': 'stamina_scouted', 'ability': PhysicalAbility.stamina},
        {'key': 'strength_scouted', 'ability': PhysicalAbility.strength},
        {'key': 'flexibility_scouted', 'ability': PhysicalAbility.flexibility}
      ];
      
      for (final abilityInfo in physicalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as PhysicalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getPhysicalAbility(ability);
        
        // 練習視察は中程度の精度（誤差±8程度）
        final errorRange = 8;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // データベースに保存
      final insertData = {
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 75, // 練習視察は中程度の精度
        ...scoutedAbilities,
      };
      
      // 既存データを削除してから新しいデータを挿入
      await db.delete(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
      );
      
      await db.insert('ScoutAnalysis', insertData);
      
      print('フィジカル面スカウト分析データ生成完了: プレイヤーID ${targetPlayer.id}');
    } catch (e) {
      print('フィジカル面スカウト分析データ生成エラー: $e');
    }
  }

  /// 技術面能力値専用のスカウト分析データ生成
  static Future<void> _generateScoutAnalysisForTechnicalAbilities(Player targetPlayer, int scoutId) async {
    try {
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存のスカウト分析データを取得
      final existingData = await db.query(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      Map<String, dynamic> scoutedAbilities = {};
      
      // 既存データがある場合は継承（技術面以外の能力値のみ）
      if (existingData.isNotEmpty) {
        final existing = existingData.first;
        final existingMap = Map<String, dynamic>.from(existing);
        existingMap.remove('id');
        existingMap.remove('player_id');
        existingMap.remove('scout_id');
        existingMap.remove('analysis_date');
        existingMap.remove('accuracy');
        
        // 技術面の能力値以外のみを継承
        final technicalAbilities = [
          'contact_scouted', 'power_scouted', 'plate_discipline_scouted', 'opposite_field_hitting_scouted',
          'pull_hitting_scouted', 'bat_control_scouted', 'swing_speed_scouted', 'fielding_scouted',
          'throwing_scouted', 'fastball_scouted', 'breaking_ball_scouted', 'pitch_movement_scouted', 'control_scouted'
        ];
        
        for (final entry in existingMap.entries) {
          if (!technicalAbilities.contains(entry.key)) {
            scoutedAbilities[entry.key] = entry.value;
          }
        }
      }
      
      // 技術面の能力値を追加
      final technicalAbilities = [
        {'key': 'contact_scouted', 'ability': TechnicalAbility.contact},
        {'key': 'power_scouted', 'ability': TechnicalAbility.power},
        {'key': 'plate_discipline_scouted', 'ability': TechnicalAbility.plateDiscipline},
        {'key': 'opposite_field_hitting_scouted', 'ability': TechnicalAbility.oppositeFieldHitting},
        {'key': 'pull_hitting_scouted', 'ability': TechnicalAbility.pullHitting},
        {'key': 'bat_control_scouted', 'ability': TechnicalAbility.batControl},
        {'key': 'swing_speed_scouted', 'ability': TechnicalAbility.swingSpeed},
        {'key': 'fielding_scouted', 'ability': TechnicalAbility.fielding},
        {'key': 'throwing_scouted', 'ability': TechnicalAbility.throwing},
        {'key': 'fastball_scouted', 'ability': TechnicalAbility.fastball},
        {'key': 'breaking_ball_scouted', 'ability': TechnicalAbility.breakingBall},
        {'key': 'pitch_movement_scouted', 'ability': TechnicalAbility.pitchMovement},
        {'key': 'control_scouted', 'ability': TechnicalAbility.control}
      ];
      
      for (final abilityInfo in technicalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as TechnicalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getTechnicalAbility(ability);
        
        // 試合観戦/練習試合観戦は中程度の精度（誤差±6程度）
        final errorRange = 6;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // データベースに保存
      final insertData = {
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 80, // 試合観戦は高めの精度
        ...scoutedAbilities,
      };
      
      // 既存データを削除してから新しいデータを挿入
      await db.delete(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
      );
      
      await db.insert('ScoutAnalysis', insertData);
      
      print('技術面スカウト分析データ生成完了: プレイヤーID ${targetPlayer.id}');
    } catch (e) {
      print('技術面スカウト分析データ生成エラー: $e');
    }
  }

  /// インタビュー用基本情報分析データ生成・保存
  static Future<void> _generateBasicInfoAnalysisForInterview(Player targetPlayer, int scoutId, String personality, int mentalStrength, String motivation) async {
    try {
      print('インタビュー基本情報分析データ生成開始: プレイヤーID ${targetPlayer.id}');
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存データを削除してから新しいデータを挿入
      final deleteCount = await db.delete(
        'ScoutBasicInfoAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId.toString()],
      );
      print('既存データ削除: ${deleteCount}件削除');
      
      // 基本情報分析データを挿入
      final insertData = {
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId.toString(),
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 90.0, // インタビューは高精度
        'personality_analyzed': personality,
        'talent_analyzed': null, // インタビューでは才能は分析しない
        'growth_analyzed': null, // インタビューでは成長タイプは分析しない
        'mental_grit_analyzed': '精神力${mentalStrength}',
        'potential_analyzed': null, // インタビューではポテンシャルは分析しない
        'personality_accuracy': 90.0,
        'talent_accuracy': null,
        'growth_accuracy': null,
        'mental_grit_accuracy': 90.0,
        'potential_accuracy': null,
      };
      
      print('インタビュー基本情報分析データ挿入: $insertData');
      final insertId = await db.insert('ScoutBasicInfoAnalysis', insertData);
      print('インタビュー基本情報分析データ挿入完了: ID $insertId');
      
      print('インタビュー基本情報分析データ生成完了: プレイヤーID ${targetPlayer.id}');
    } catch (e) {
      print('インタビュー基本情報分析データ生成エラー: $e');
      print('エラースタックトレース: ${StackTrace.current}');
    }
  }

  /// 学校視察用のスカウト分析データ生成・保存
  static Future<void> _generateSchoolScoutAnalysis(Player targetPlayer, int scoutId) async {
    try {
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存データを削除してから新しいデータを挿入
      await db.delete(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
      );
      
      // 学校視察で把握できる能力値を生成（フィジカル面中心、精度は中程度）
      final scoutedAbilities = <String, dynamic>{
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 75, // 学校視察は中程度の精度
      };
      
      // フィジカル面の能力値を追加（学校視察で見える部分）
      final physicalAbilities = [
        {'key': 'acceleration_scouted', 'ability': PhysicalAbility.acceleration},
        {'key': 'agility_scouted', 'ability': PhysicalAbility.agility},
        {'key': 'balance_scouted', 'ability': PhysicalAbility.balance},
        {'key': 'stamina_scouted', 'ability': PhysicalAbility.stamina},
        {'key': 'strength_scouted', 'ability': PhysicalAbility.strength},
        {'key': 'pace_scouted', 'ability': PhysicalAbility.pace},
        {'key': 'flexibility_scouted', 'ability': PhysicalAbility.flexibility},
      ];
      
      for (final abilityInfo in physicalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as PhysicalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getPhysicalAbility(ability);
        
        // 学校視察は中精度（誤差±8程度）
        final errorRange = 8;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // 技術面の一部能力値も追加（学校視察で見える部分）
      final technicalAbilities = [
        {'key': 'fielding_scouted', 'ability': TechnicalAbility.fielding},
        {'key': 'throwing_scouted', 'ability': TechnicalAbility.throwing},
        {'key': 'bat_control_scouted', 'ability': TechnicalAbility.batControl},
      ];
      
      for (final abilityInfo in technicalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as TechnicalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getTechnicalAbility(ability);
        
        // 学校視察は中精度（誤差±8程度）
        final errorRange = 8;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // データベースに保存
      await db.insert('ScoutAnalysis', scoutedAbilities);
      
    } catch (e) {
      print('学校視察スカウト分析データ生成エラー: $e');
    }
  }

  /// インタビュー用のスカウト分析データ生成・保存
  static Future<void> _generateInterviewScoutData(Player targetPlayer, int scoutId) async {
    try {
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存データを削除してから新しいデータを挿入
      await db.delete(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
      );
      
      // インタビューで把握できる能力値を生成（メンタル面中心、精度は高め）
      final scoutedAbilities = <String, dynamic>{
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 90, // インタビューは高精度
      };
      
      // メンタル面の能力値を追加（インタビューで見える部分）
      final mentalAbilities = [
        {'key': 'concentration_scouted', 'ability': MentalAbility.concentration},
        {'key': 'anticipation_scouted', 'ability': MentalAbility.anticipation},
        {'key': 'vision_scouted', 'ability': MentalAbility.vision},
        {'key': 'composure_scouted', 'ability': MentalAbility.composure},
        {'key': 'aggression_scouted', 'ability': MentalAbility.aggression},
        {'key': 'bravery_scouted', 'ability': MentalAbility.bravery},
        {'key': 'leadership_scouted', 'ability': MentalAbility.leadership},
        {'key': 'work_rate_scouted', 'ability': MentalAbility.workRate},
        {'key': 'self_discipline_scouted', 'ability': MentalAbility.selfDiscipline},
        {'key': 'ambition_scouted', 'ability': MentalAbility.ambition},
        {'key': 'teamwork_scouted', 'ability': MentalAbility.teamwork},
        {'key': 'positioning_scouted', 'ability': MentalAbility.positioning},
        {'key': 'pressure_handling_scouted', 'ability': MentalAbility.pressureHandling},
        {'key': 'clutch_ability_scouted', 'ability': MentalAbility.clutchAbility},
      ];
      
      for (final abilityInfo in mentalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as MentalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getMentalAbility(ability);
        
        // インタビューは高精度（誤差±3程度）
        final errorRange = 3;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // データベースに保存
      await db.insert('ScoutAnalysis', scoutedAbilities);
      
    } catch (e) {
      print('インタビュースカウト分析データ生成エラー: $e');
    }
  }

  /// ビデオ分析用のスカウト分析データ生成・保存
  static Future<void> _generateVideoAnalysisScoutData(Player targetPlayer, int scoutId) async {
    try {
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存データを削除してから新しいデータを挿入
      await db.delete(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
      );
      
      // ビデオ分析で把握できる能力値を生成（技術面中心、精度は高め）
      final scoutedAbilities = <String, dynamic>{
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 85, // ビデオ分析は高精度
      };
      
      // 技術面の能力値を追加（ビデオ分析で見える部分）
      final technicalAbilities = [
        {'key': 'contact_scouted', 'ability': TechnicalAbility.contact},
        {'key': 'power_scouted', 'ability': TechnicalAbility.power},
        {'key': 'bat_control_scouted', 'ability': TechnicalAbility.batControl},
        {'key': 'fielding_scouted', 'ability': TechnicalAbility.fielding},
        {'key': 'throwing_scouted', 'ability': TechnicalAbility.throwing},
        {'key': 'control_scouted', 'ability': TechnicalAbility.control},
        {'key': 'fastball_scouted', 'ability': TechnicalAbility.fastball},
        {'key': 'breaking_ball_scouted', 'ability': TechnicalAbility.breakingBall},
      ];
      
      for (final abilityInfo in technicalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as TechnicalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getTechnicalAbility(ability);
        
        // ビデオ分析は高精度（誤差±5程度）
        final errorRange = 5;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // データベースに保存
      await db.insert('ScoutAnalysis', scoutedAbilities);
      
    } catch (e) {
      print('ビデオ分析スカウト分析データ生成エラー: $e');
    }
  }

  /// 基本情報分析データ生成・保存
  static Future<void> _generateBasicInfoAnalysis(Player targetPlayer, int scoutId, String growthTypeAnalysis, String injuryRisk, String potentialAnalysis) async {
    try {
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存データを削除してから新しいデータを挿入
      await db.delete(
        'ScoutBasicInfoAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId.toString()],
      );
      
      // 基本情報分析データを挿入
      final insertData = {
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId.toString(),
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 85.0, // ビデオ分析は高精度
        'personality_analyzed': targetPlayer.personality,
        'talent_analyzed': '才能レベル${targetPlayer.talent}',
        'growth_analyzed': growthTypeAnalysis,
        'mental_grit_analyzed': '精神力${targetPlayer.mentalGrit}',
        'potential_analyzed': potentialAnalysis,
        'personality_accuracy': 85.0,
        'talent_accuracy': 85.0,
        'growth_accuracy': 85.0,
        'mental_grit_accuracy': 85.0,
        'potential_accuracy': 85.0,
      };
      
      await db.insert('ScoutBasicInfoAnalysis', insertData);
      
    } catch (e) {
      print('基本情報分析データ生成エラー: $e');
    }
  }



  /// 前提条件チェック
  static PrerequisiteCheck _checkPrerequisites(Action action, Scout scout) {
    // APチェック
    if (scout.actionPoints < action.actionPoints) {
      return PrerequisiteCheck.invalid('アクションポイントが不足しています');
    }

    // コストチェック
    if (scout.money < action.cost) {
      return PrerequisiteCheck.invalid('資金が不足しています');
    }

    // 体力チェック
    if (scout.stamina < action.actionPoints * 5) {
      return PrerequisiteCheck.invalid('体力が不足しています');
    }

    // 特殊前提条件チェック
    switch (action.type) {
      case ActionType.interview:
        if (scout.trustLevel < 50) {
          return PrerequisiteCheck.invalid('信頼度が50未満です');
        }
        break;
      case ActionType.gameWatch:
        // 試合週のチェック（簡易実装）
        if (_random.nextDouble() > 0.3) { // 30%の確率で試合週
          return PrerequisiteCheck.invalid('試合週ではありません');
        }
        break;
      case ActionType.videoAnalyze:
        // 映像の有無チェック（簡易実装）
        if (_random.nextDouble() > 0.5) { // 50%の確率で映像あり
          return PrerequisiteCheck.invalid('映像がありません');
        }
        break;
      case ActionType.reportWrite:
        // 情報量チェック（簡易実装）
        if (_random.nextDouble() > 0.7) { // 70%の確率で情報量充足
          return PrerequisiteCheck.invalid('情報量が不足しています');
        }
        break;
      default:
        break;
    }

    return PrerequisiteCheck.valid();
  }

  /// 結果処理
  static ActionResult _processResult({
    required Action action,
    required Scout scout,
    required String targetId,
    required String targetType,
    required ScoutingHistory? history,
    required int currentWeek,
    required bool isSuccessful,
  }) {
    // 視察履歴の更新
    final visitCount = history?.totalVisits ?? 0;
    final weeksSinceLastVisit = history?.getWeeksSinceLastVisit(currentWeek) ?? 0;

    // 精度計算
    final accuracy = AccuracyCalculator.calculateAccuracy(
      scoutSkills: scout.skills,
      infoType: action.obtainableInfo.first, // 簡易的に最初の情報タイプを使用
      visitCount: visitCount,
      weeksSinceLastVisit: weeksSinceLastVisit,
    );

    // 取得情報の生成
    final obtainedInfo = _generateObtainedInfo(action, accuracy, isSuccessful);

    // スカウト分析データの保存（成功時のみ）
    if (isSuccessful && targetType == 'player') {
      _saveScoutAnalysis(targetId, scout, accuracy);
    }

    // 視察記録の作成
    final record = ScoutingRecord(
      actionId: action.type.name,
      visitDate: DateTime.now(),
      weekNumber: currentWeek,
      accuracy: accuracy,
      obtainedInfo: obtainedInfo,
      wasSuccessful: isSuccessful,
    );

    // スカウト統計の更新
    final updatedScout = scout.updateActionStats(isSuccessful);

    return ActionResult.success(
      action: action,
      scout: updatedScout,
      record: record,
      accuracy: accuracy,
      obtainedInfo: obtainedInfo,
    );
  }

  /// スカウト分析データを保存
  static Future<void> _saveScoutAnalysis(String playerId, Scout scout, double accuracy) async {
    try {
      print('スカウト分析データ保存開始: プレイヤーID $playerId, 精度 $accuracy');
      
      // DataServiceを取得
      final dataService = DataService();
      final db = await dataService.database;
      
      // プレイヤー情報を取得
      final playerData = await db.query('Player', where: 'id = ?', whereArgs: [int.tryParse(playerId) ?? 0]);
      if (playerData.isEmpty) {
        print('プレイヤーが見つかりません: ID $playerId');
        return;
      }
      
      final player = playerData.first;
      final scoutId = scout.name; // nameプロパティを使用
      
      // 既存のスカウト分析データを削除
      await db.delete(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [int.tryParse(playerId) ?? 0, scoutId],
      );
      
      // スカウト分析データを生成・挿入
      final insertData = {
        'player_id': int.tryParse(playerId) ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': accuracy.round(),
        // 技術的能力値評価（簡易版）
        'contact_evaluation': _generateScoutedValue(player['contact'] as int? ?? 50, accuracy),
        'power_evaluation': _generateScoutedValue(player['power'] as int? ?? 50, accuracy),
        'plate_discipline_evaluation': _generateScoutedValue(player['plate_discipline'] as int? ?? 50, accuracy),
        'bunt_evaluation': _generateScoutedValue(player['bunt'] as int? ?? 50, accuracy),
        'opposite_field_hitting_evaluation': _generateScoutedValue(player['opposite_field_hitting'] as int? ?? 50, accuracy),
        'pull_hitting_evaluation': _generateScoutedValue(player['pull_hitting'] as int? ?? 50, accuracy),
        'bat_control_evaluation': _generateScoutedValue(player['bat_control'] as int? ?? 50, accuracy),
        'swing_speed_evaluation': _generateScoutedValue(player['swing_speed'] as int? ?? 50, accuracy),
        'fielding_evaluation': _generateScoutedValue(player['fielding'] as int? ?? 50, accuracy),
        'throwing_evaluation': _generateScoutedValue(player['throwing'] as int? ?? 50, accuracy),
        'catcher_ability_evaluation': _generateScoutedValue(player['catcher_ability'] as int? ?? 50, accuracy),
        'control_evaluation': _generateScoutedValue(player['control'] as int? ?? 50, accuracy),
        'fastball_evaluation': _generateScoutedValue(player['fastball'] as int? ?? 50, accuracy),
        'breaking_ball_evaluation': _generateScoutedValue(player['breaking_ball'] as int? ?? 50, accuracy),
        'pitch_movement_evaluation': _generateScoutedValue(player['pitch_movement'] as int? ?? 50, accuracy),
        // 精神的能力値評価（簡易版）
        'concentration_evaluation': _generateScoutedValue(player['concentration'] as int? ?? 50, accuracy),
        'anticipation_evaluation': _generateScoutedValue(player['anticipation'] as int? ?? 50, accuracy),
        'vision_evaluation': _generateScoutedValue(player['vision'] as int? ?? 50, accuracy),
        'composure_evaluation': _generateScoutedValue(player['composure'] as int? ?? 50, accuracy),
        'aggression_evaluation': _generateScoutedValue(player['aggression'] as int? ?? 50, accuracy),
        'bravery_evaluation': _generateScoutedValue(player['bravery'] as int? ?? 50, accuracy),
        'leadership_evaluation': _generateScoutedValue(player['leadership'] as int? ?? 50, accuracy),
        'work_rate_evaluation': _generateScoutedValue(player['work_rate'] as int? ?? 50, accuracy),
        'self_discipline_evaluation': _generateScoutedValue(player['self_discipline'] as int? ?? 50, accuracy),
        'ambition_evaluation': _generateScoutedValue(player['ambition'] as int? ?? 50, accuracy),
        'teamwork_evaluation': _generateScoutedValue(player['teamwork'] as int? ?? 50, accuracy),
        'positioning_evaluation': _generateScoutedValue(player['positioning'] as int? ?? 50, accuracy),
        'pressure_handling_evaluation': _generateScoutedValue(player['pressure_handling'] as int? ?? 50, accuracy),
        'clutch_ability_evaluation': _generateScoutedValue(player['clutch_ability'] as int? ?? 50, accuracy),
        'motivation_evaluation': _generateScoutedValue(player['motivation'] as int? ?? 50, accuracy),
        'pressure_evaluation': _generateScoutedValue(player['pressure'] as int? ?? 50, accuracy),
        'adaptability_evaluation': _generateScoutedValue(player['adaptability'] as int? ?? 50, accuracy),
        'consistency_evaluation': _generateScoutedValue(player['consistency'] as int? ?? 50, accuracy),
        'clutch_evaluation': _generateScoutedValue(player['clutch'] as int? ?? 50, accuracy),
        'work_ethic_evaluation': _generateScoutedValue(player['work_ethic'] as int? ?? 50, accuracy),
        // 身体的能力値評価（簡易版）
        'acceleration_evaluation': _generateScoutedValue(player['acceleration'] as int? ?? 50, accuracy),
        'agility_evaluation': _generateScoutedValue(player['agility'] as int? ?? 50, accuracy),
        'balance_evaluation': _generateScoutedValue(player['balance'] as int? ?? 50, accuracy),
        'jumping_reach_evaluation': _generateScoutedValue(player['jumping_reach'] as int? ?? 50, accuracy),
        'natural_fitness_evaluation': _generateScoutedValue(player['natural_fitness'] as int? ?? 50, accuracy),
        'injury_proneness_evaluation': _generateScoutedValue(player['injury_proneness'] as int? ?? 50, accuracy),
        'stamina_evaluation': _generateScoutedValue(player['stamina'] as int? ?? 50, accuracy),
        'strength_evaluation': _generateScoutedValue(player['strength'] as int? ?? 50, accuracy),
        'pace_evaluation': _generateScoutedValue(player['pace'] as int? ?? 50, accuracy),
        'flexibility_evaluation': _generateScoutedValue(player['flexibility'] as int? ?? 50, accuracy),
        'speed_evaluation': _generateScoutedValue(player['speed'] as int? ?? 50, accuracy),
        // 総合評価指標
        'overall_evaluation': _calculateOverallEvaluation(player, accuracy),
        'technical_evaluation': _calculateTechnicalEvaluation(player, accuracy),
        'physical_evaluation': _calculatePhysicalEvaluation(player, accuracy),
        'mental_evaluation': _calculateMentalEvaluation(player, accuracy),
        'is_graduated': player['is_graduated'] as int? ?? 0,
      };
      
      // データベースに挿入
      await db.insert('ScoutAnalysis', insertData);
      
      print('スカウト分析データ保存完了: プレイヤーID $playerId');
      
    } catch (e) {
      print('スカウト分析データ保存エラー: $e');
    }
  }
  
  /// スカウトされた能力値を生成（精度に基づく誤差付き）
  static int _generateScoutedValue(int trueValue, double accuracy) {
    final random = Random();
    final errorRange = ((100 - accuracy) / 10).round(); // 精度が低いほど誤差が大きい
    final error = random.nextInt(errorRange * 2 + 1) - errorRange;
    return (trueValue + error).clamp(0, 100);
  }
  
  /// 総合評価を計算
  static int _calculateOverallEvaluation(Map<String, dynamic> player, double accuracy) {
    final technical = _calculateTechnicalEvaluation(player, accuracy);
    final mental = _calculateMentalEvaluation(player, accuracy);
    final physical = _calculatePhysicalEvaluation(player, accuracy);
    
    // 投手と野手で重み付けを変更
    final position = player['position'] as String? ?? '投手';
    if (position == '投手') {
      return ((technical * 0.5) + (mental * 0.3) + (physical * 0.2)).round();
    } else {
      return ((technical * 0.4) + (mental * 0.25) + (physical * 0.35)).round();
    }
  }
  
  /// 技術的評価を計算
  static int _calculateTechnicalEvaluation(Map<String, dynamic> player, double accuracy) {
    final position = player['position'] as String? ?? '投手';
    
    if (position == '投手') {
      final pitchingAbilities = [
        player['control'] as int? ?? 50,
        player['fastball'] as int? ?? 50,
        player['breaking_ball'] as int? ?? 50,
        player['pitch_movement'] as int? ?? 50,
      ];
      final fieldingAbilities = [
        player['fielding'] as int? ?? 50,
        player['throwing'] as int? ?? 50,
      ];
      final battingAbilities = [
        player['contact'] as int? ?? 50,
        player['power'] as int? ?? 50,
        player['plate_discipline'] as int? ?? 50,
        player['bunt'] as int? ?? 50,
      ];
      
      return (
        (pitchingAbilities.reduce((a, b) => a + b) * 0.6) +
        (fieldingAbilities.reduce((a, b) => a + b) * 0.25) +
        (battingAbilities.reduce((a, b) => a + b) * 0.15)
      ).round();
    } else {
      final battingAbilities = [
        player['contact'] as int? ?? 50,
        player['power'] as int? ?? 50,
        player['plate_discipline'] as int? ?? 50,
        player['bunt'] as int? ?? 50,
        player['opposite_field_hitting'] as int? ?? 50,
        player['pull_hitting'] as int? ?? 50,
        player['bat_control'] as int? ?? 50,
        player['swing_speed'] as int? ?? 50,
      ];
      final fieldingAbilities = [
        player['fielding'] as int? ?? 50,
        player['throwing'] as int? ?? 50,
      ];
      
      return (
        (battingAbilities.reduce((a, b) => a + b) * 0.7) +
        (fieldingAbilities.reduce((a, b) => a + b) * 0.3)
      ).round();
    }
  }
  
  /// 精神的評価を計算
  static int _calculateMentalEvaluation(Map<String, dynamic> player, double accuracy) {
    final mentalAbilities = [
      (player['concentration'] as int? ?? 50) * 1.2,
      (player['anticipation'] as int? ?? 50) * 1.1,
      (player['vision'] as int? ?? 50) * 1.1,
      (player['composure'] as int? ?? 50) * 1.2,
      (player['aggression'] as int? ?? 50) * 1.0,
      (player['bravery'] as int? ?? 50) * 1.0,
      (player['leadership'] as int? ?? 50) * 1.1,
      (player['work_rate'] as int? ?? 50) * 1.2,
      (player['self_discipline'] as int? ?? 50) * 1.1,
      (player['ambition'] as int? ?? 50) * 1.0,
      (player['teamwork'] as int? ?? 50) * 1.1,
      (player['positioning'] as int? ?? 50) * 1.0,
      (player['pressure_handling'] as int? ?? 50) * 1.2,
      (player['clutch_ability'] as int? ?? 50) * 1.2,
      (player['motivation'] as int? ?? 50) * 1.1,
      (player['pressure'] as int? ?? 50) * 1.0,
      (player['adaptability'] as int? ?? 50) * 1.0,
      (player['consistency'] as int? ?? 50) * 1.1,
      (player['clutch'] as int? ?? 50) * 1.2,
      (player['work_ethic'] as int? ?? 50) * 1.2,
    ];
    
    return (mentalAbilities.reduce((a, b) => a + b) / mentalAbilities.length).round();
  }
  
  /// 身体的評価を計算
  static int _calculatePhysicalEvaluation(Map<String, dynamic> player, double accuracy) {
    final position = player['position'] as String? ?? '投手';
    
    if (position == '投手') {
      final staminaAbilities = [
        (player['stamina'] as int? ?? 50) * 1.3,
        (player['strength'] as int? ?? 50) * 1.2,
        (player['natural_fitness'] as int? ?? 50) * 1.1,
      ];
      final otherAbilities = [
        player['speed'] as int? ?? 50,
        player['agility'] as int? ?? 50,
        player['balance'] as int? ?? 50,
        player['jumping_reach'] as int? ?? 50,
        player['injury_proneness'] as int? ?? 50,
        player['pace'] as int? ?? 50,
        player['flexibility'] as int? ?? 50,
      ];
      
      return (
        (staminaAbilities.reduce((a, b) => a + b) * 0.6) +
        (otherAbilities.reduce((a, b) => a + b) * 0.4)
      ).round();
    } else {
      final speedAbilities = [
        (player['speed'] as int? ?? 50) * 1.3,
        (player['agility'] as int? ?? 50) * 1.2,
        (player['acceleration'] as int? ?? 50) * 1.2,
      ];
      final otherAbilities = [
        player['balance'] as int? ?? 50,
        player['jumping_reach'] as int? ?? 50,
        player['natural_fitness'] as int? ?? 50,
        player['injury_proneness'] as int? ?? 50,
        player['stamina'] as int? ?? 50,
        player['strength'] as int? ?? 50,
        player['pace'] as int? ?? 50,
        player['flexibility'] as int? ?? 50,
      ];
      
      return (
        (speedAbilities.reduce((a, b) => a + b) * 0.5) +
        (otherAbilities.reduce((a, b) => a + b) * 0.5)
      ).round();
    }
  }

  /// 取得情報の生成
  static Map<String, dynamic> _generateObtainedInfo(Action action, double accuracy, bool isSuccessful) {
    if (!isSuccessful) {
      return {'error': 'アクションが失敗しました'};
    }

    final info = <String, dynamic>{};
    
    for (final infoType in action.obtainableInfo) {
      info[infoType] = AccuracyCalculator.getAccuracyDisplayExample(infoType, accuracy);
    }

    return info;
  }

  /// 総合評価の生成
  static String _generateOverallEvaluation(Player player, Map<ScoutSkill, int> scoutSkills) {
    
    // 選手の能力値を総合的に評価
    final contact = player.technicalAbilities[TechnicalAbility.contact] ?? 50;
    final power = player.technicalAbilities[TechnicalAbility.power] ?? 50;
    final pace = player.physicalAbilities[PhysicalAbility.pace] ?? 50;
    final throwing = player.technicalAbilities[TechnicalAbility.throwing] ?? 50;
    final fielding = player.technicalAbilities[TechnicalAbility.fielding] ?? 50;
    
    final overallScore = (contact + power + pace + throwing + fielding) / 5;
    
    if (overallScore >= 80) {
      return 'A級（優秀）';
    } else if (overallScore >= 70) {
      return 'B級（良好）';
    } else if (overallScore >= 60) {
      return 'C級（平均）';
    } else {
      return 'D級（要改善）';
    }
  }

  /// 将来予測の生成
  static String _generateFuturePrediction(Player player, TeamRequestType requestType) {
    final growthType = player.growthType;
    
    switch (requestType) {
      case TeamRequestType.immediateImpact:
        return '即座に戦力として期待できる';
      case TeamRequestType.futureCleanup:
        return growthType == 'early' ? '5年後に4番打者として期待' : '成長次第で4番候補';
      case TeamRequestType.futureSecond:
        return '守備力と打撃のバランスが良く、セカンド候補として有望';
      case TeamRequestType.futureAce:
        return growthType == 'late' ? '遅咲き型で5年後にエース候補' : '投手としての成長が期待';
      default:
        return '将来性あり';
    }
  }

  /// 推薦文の生成
  static String _generateRecommendation(Player player, TeamRequest teamRequest) {
    final personality = player.personality.isNotEmpty ? player.personality : '不明';
    final mentalStrength = player.mentalStrength;
    
    return '${player.name}選手は${personality}で精神力${mentalStrength}。${teamRequest.description}';
  }

  /// 知名度に基づく初期情報把握度を取得
  static int _getInitialKnowledgeByFame(int fameLevel) {
    switch (fameLevel) {
      case 5: return 80; // 超有名: 80%の精度で情報把握
      case 4: return 60; // 有名: 60%の精度で情報把握
      case 3: return 40; // 知られている: 40%の精度で情報把握
      case 2: return 20; // 少し知られている: 20%の精度で情報把握
      case 1: return 0;  // 無名: 情報なし
      default: return 0;
    }
  }

  /// レポート品質の計算
  static double _calculateReportQuality(Map<ScoutSkill, int> scoutSkills) {
    final negotiationSkill = scoutSkills[ScoutSkill.negotiation] ?? 50;
    final insightSkill = scoutSkills[ScoutSkill.insight] ?? 50;
    
    // 交渉スキルと洞察力に基づいて品質を計算
    final baseQuality = (negotiationSkill + insightSkill) / 200.0;
    return baseQuality.clamp(0.3, 1.0); // 最低30%、最高100%
  }

  /// 技術面・フィジカル面能力値専用のスカウト分析データ生成（試合観戦用）
  static Future<void> generateScoutAnalysisForTechnicalAndPhysicalAbilities(Player targetPlayer, int scoutId) async {
    try {
      final dataService = DataService();
      final db = await dataService.database;
      
      // 既存のスカウト分析データを取得
      final existingData = await db.query(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      Map<String, dynamic> scoutedAbilities = {};
      
      // 既存データがある場合は継承（技術面・フィジカル面以外の能力値のみ）
      if (existingData.isNotEmpty) {
        final existing = existingData.first;
        final existingMap = Map<String, dynamic>.from(existing);
        existingMap.remove('id');
        existingMap.remove('player_id');
        existingMap.remove('scout_id');
        existingMap.remove('analysis_date');
        existingMap.remove('accuracy');
        
        // 技術面・フィジカル面の能力値以外のみを継承
        final technicalAndPhysicalAbilities = [
          // 技術面
          'contact_scouted', 'power_scouted', 'plate_discipline_scouted', 'opposite_field_hitting_scouted',
          'pull_hitting_scouted', 'bat_control_scouted', 'swing_speed_scouted', 'fielding_scouted',
          'throwing_scouted', 'fastball_scouted', 'breaking_ball_scouted', 'pitch_movement_scouted', 'control_scouted',
          // フィジカル面
          'pace_scouted', 'acceleration_scouted', 'agility_scouted', 'balance_scouted',
          'jumping_reach_scouted', 'stamina_scouted', 'strength_scouted', 'flexibility_scouted'
        ];
        
        for (final entry in existingMap.entries) {
          if (!technicalAndPhysicalAbilities.contains(entry.key)) {
            scoutedAbilities[entry.key] = entry.value;
          }
        }
      }
      
      // 技術面の能力値を追加
      final technicalAbilities = [
        {'key': 'contact_scouted', 'ability': TechnicalAbility.contact},
        {'key': 'power_scouted', 'ability': TechnicalAbility.power},
        {'key': 'plate_discipline_scouted', 'ability': TechnicalAbility.plateDiscipline},
        {'key': 'opposite_field_hitting_scouted', 'ability': TechnicalAbility.oppositeFieldHitting},
        {'key': 'pull_hitting_scouted', 'ability': TechnicalAbility.pullHitting},
        {'key': 'bat_control_scouted', 'ability': TechnicalAbility.batControl},
        {'key': 'swing_speed_scouted', 'ability': TechnicalAbility.swingSpeed},
        {'key': 'fielding_scouted', 'ability': TechnicalAbility.fielding},
        {'key': 'throwing_scouted', 'ability': TechnicalAbility.throwing},
        {'key': 'fastball_scouted', 'ability': TechnicalAbility.fastball},
        {'key': 'breaking_ball_scouted', 'ability': TechnicalAbility.breakingBall},
        {'key': 'pitch_movement_scouted', 'ability': TechnicalAbility.pitchMovement},
        {'key': 'control_scouted', 'ability': TechnicalAbility.control}
      ];
      
      for (final abilityInfo in technicalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as TechnicalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getTechnicalAbility(ability);
        
        // 試合観戦は中程度の精度（誤差±6程度）
        final errorRange = 6;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // フィジカル面の能力値を追加
      final physicalAbilities = [
        {'key': 'pace_scouted', 'ability': PhysicalAbility.pace},
        {'key': 'acceleration_scouted', 'ability': PhysicalAbility.acceleration},
        {'key': 'agility_scouted', 'ability': PhysicalAbility.agility},
        {'key': 'balance_scouted', 'ability': PhysicalAbility.balance},
        {'key': 'jumping_reach_scouted', 'ability': PhysicalAbility.jumpingReach},
        {'key': 'stamina_scouted', 'ability': PhysicalAbility.stamina},
        {'key': 'strength_scouted', 'ability': PhysicalAbility.strength},
        {'key': 'flexibility_scouted', 'ability': PhysicalAbility.flexibility}
      ];
      
      for (final abilityInfo in physicalAbilities) {
        final columnKey = abilityInfo['key'] as String;
        final ability = abilityInfo['ability'] as PhysicalAbility;
        
        // 真の能力値を取得
        final trueValue = targetPlayer.getPhysicalAbility(ability);
        
        // 試合観戦は中程度の精度（誤差±6程度）
        final errorRange = 6;
        final random = Random();
        final error = random.nextInt(errorRange * 2 + 1) - errorRange;
        final scoutedValue = (trueValue + error).clamp(0, 100);
        
        scoutedAbilities[columnKey] = scoutedValue;
      }
      
      // データベースに保存
      final insertData = {
        'player_id': targetPlayer.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(),
        'accuracy': 80, // 試合観戦は高めの精度
        ...scoutedAbilities,
      };
      
      // 既存データを削除してから新しいデータを挿入
      await db.delete(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [targetPlayer.id ?? 0, scoutId],
      );
      
      await db.insert('ScoutAnalysis', insertData);
      
      print('技術面・フィジカル面スカウト分析データ生成完了: プレイヤーID ${targetPlayer.id}');
    } catch (e) {
      print('技術面・フィジカル面スカウト分析データ生成エラー: $e');
    }
  }
}

/// 前提条件チェック結果
class PrerequisiteCheck {
  final bool isValid;
  final String? reason;

  PrerequisiteCheck._({required this.isValid, this.reason});

  factory PrerequisiteCheck.valid() => PrerequisiteCheck._(isValid: true);
  factory PrerequisiteCheck.invalid(String reason) => PrerequisiteCheck._(isValid: false, reason: reason);
}

/// アクション実行結果
class ActionResult {
  final Action action;
  final Scout scout;
  final bool isSuccessful;
  final String? failureReason;
  final ScoutingRecord? record;
  final double? accuracy;
  final Map<String, dynamic>? obtainedInfo;

  ActionResult._({
    required this.action,
    required this.scout,
    required this.isSuccessful,
    this.failureReason,
    this.record,
    this.accuracy,
    this.obtainedInfo,
  });

  factory ActionResult.success({
    required Action action,
    required Scout scout,
    required ScoutingRecord record,
    required double accuracy,
    required Map<String, dynamic> obtainedInfo,
  }) {
    return ActionResult._(
      action: action,
      scout: scout,
      isSuccessful: true,
      record: record,
      accuracy: accuracy,
      obtainedInfo: obtainedInfo,
    );
  }

  factory ActionResult.failure({
    required Action action,
    required Scout scout,
    required String reason,
  }) {
    return ActionResult._(
      action: action,
      scout: scout,
      isSuccessful: false,
      failureReason: reason,
    );
  }
} 