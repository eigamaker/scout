import 'dart:math';
import '../../models/scouting/action.dart';
import '../../models/scouting/scout.dart';
import '../../models/scouting/scouting_history.dart';
import 'accuracy_calculator.dart';
import '../../models/school/school.dart';
import '../../models/player/player.dart';
import '../../models/player/player_abilities.dart';
import 'scout_analysis_service.dart';
import '../../models/scouting/team_request.dart';

class SchoolScoutResult {
  final Player? discoveredPlayer;
  final Player? improvedPlayer;
  final String message;
  SchoolScoutResult({this.discoveredPlayer, this.improvedPlayer, required this.message});
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
  static SchoolScoutResult scoutSchool({
    required School school,
    required int currentWeek,
  }) {
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
      return SchoolScoutResult(
        discoveredPlayer: null,
        improvedPlayer: player,
        message: '🏫 ${school.name}の視察: 「${player.name}」の能力値の把握度が上がった！',
      );
    }
  }

  /// 練習視察アクション
  static ScoutActionResult practiceWatch({
    required School school,
    required Player? targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) {
    // 練習視察の具体的な処理
    if (targetPlayer != null) {
      // 特定選手の練習視察
      final knowledgeIncrease = 15 + Random().nextInt(16); // 15-30%増加
      targetPlayer.abilityKnowledge.updateAll((k, v) => (v + knowledgeIncrease).clamp(0, 90));
      
      return ScoutActionResult(
        success: true,
        message: '🏃 ${school.name}の練習視察: 「${targetPlayer.name}」の技術面を詳しく観察できました',
        discoveredPlayer: null,
        improvedPlayer: targetPlayer,
      );
    } else {
      // 学校全体の練習視察
      final undiscovered = school.players.where((p) => !p.isDiscovered).toList();
      if (undiscovered.isNotEmpty) {
        final player = undiscovered[Random().nextInt(undiscovered.length)];
        player.isDiscovered = true;
        player.discoveredAt = DateTime.now();
        player.discoveredCount = 1;
        player.scoutedDates.add(DateTime.now());
        player.abilityKnowledge.updateAll((k, v) => 25 + Random().nextInt(16)); // 25-40%
        
        return ScoutActionResult(
          success: true,
          message: '🏃 ${school.name}の練習視察: 「${player.name}」の練習態度が目立ちました',
          discoveredPlayer: player,
          improvedPlayer: null,
        );
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
  static ScoutActionResult gameWatch({
    required School school,
    required Player? targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) {
    // 試合観戦の具体的な処理
    if (targetPlayer != null) {
      // 特定選手の試合観戦
      final knowledgeIncrease = 20 + Random().nextInt(21); // 20-40%増加
      targetPlayer.abilityKnowledge.updateAll((k, v) => (v + knowledgeIncrease).clamp(0, 95));
      
      return ScoutActionResult(
        success: true,
        message: '⚾ ${school.name}の試合観戦: 「${targetPlayer.name}」の試合での活躍を確認できました',
        discoveredPlayer: null,
        improvedPlayer: targetPlayer,
      );
    } else {
      // 学校全体の試合観戦
      final allPlayers = school.players.where((p) => p.isDiscovered).toList();
      if (allPlayers.isNotEmpty) {
        final player = allPlayers[Random().nextInt(allPlayers.length)];
        final knowledgeIncrease = 10 + Random().nextInt(11); // 10-20%増加
        player.abilityKnowledge.updateAll((k, v) => (v + knowledgeIncrease).clamp(0, 85));
        
        return ScoutActionResult(
          success: true,
          message: '⚾ ${school.name}の試合観戦: 「${player.name}」の試合での印象が強く残りました',
          discoveredPlayer: null,
          improvedPlayer: player,
        );
      }
      
      return ScoutActionResult(
        success: true,
        message: '⚾ ${school.name}の試合観戦: 試合は見応えがありましたが、特に印象的な選手はいませんでした',
        discoveredPlayer: null,
        improvedPlayer: null,
      );
    }
  }



  /// ビデオ分析アクション
  static ScoutActionResult videoAnalyze({
    required Player targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) {
    // ビデオ分析の具体的な処理
    // 成長履歴の分析と成長タイプの判定
    
    // 成長タイプの分析（既存の成長タイプを詳細化）
    final growthTypeAnalysis = _analyzeGrowthType(targetPlayer);
    
    // 怪我リスクの分析
    final injuryRisk = _analyzeInjuryRisk(targetPlayer);
    
    // ポテンシャルの分析
    final potentialAnalysis = _analyzePotential(targetPlayer);
    
    // 成長履歴の生成（簡易版）
    final growthHistory = _generateGrowthHistory(targetPlayer, currentWeek);
    
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
    final overallEvaluation = _generateOverallEvaluation(selectedPlayer, scoutSkills);
    final futurePrediction = _generateFuturePrediction(selectedPlayer, teamRequest.type);
    final recommendation = _generateRecommendation(selectedPlayer, teamRequest);
    
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
  static ScoutActionResult scrimmage({
    required School school,
    required Player? targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) {
    // 練習試合観戦の具体的な処理
    if (targetPlayer != null) {
      // 特定選手の練習試合観戦
      final knowledgeIncrease = 25 + Random().nextInt(21); // 25-45%増加
      targetPlayer.abilityKnowledge.updateAll((k, v) => (v + knowledgeIncrease).clamp(0, 95));
      
      // 成長スピードの情報も取得
      final growthSpeed = 10 + Random().nextInt(21); // 10-30%の成長スピード情報
      
      return ScoutActionResult(
        success: true,
        message: '🏟️ ${school.name}の練習試合観戦: 「${targetPlayer.name}」の成長スピードを確認できました',
        discoveredPlayer: null,
        improvedPlayer: targetPlayer,
      );
    } else {
      // 学校全体の練習試合観戦
      final allPlayers = school.players.where((p) => p.isDiscovered).toList();
      if (allPlayers.isNotEmpty) {
        final player = allPlayers[Random().nextInt(allPlayers.length)];
        final knowledgeIncrease = 15 + Random().nextInt(16); // 15-30%増加
        player.abilityKnowledge.updateAll((k, v) => (v + knowledgeIncrease).clamp(0, 90));
        
        return ScoutActionResult(
          success: true,
          message: '🏟️ ${school.name}の練習試合観戦: 「${player.name}」の練習試合での成長を確認できました',
          discoveredPlayer: null,
          improvedPlayer: player,
        );
      }
      
      return ScoutActionResult(
        success: true,
        message: '🏟️ ${school.name}の練習試合観戦: 練習試合は見応えがありましたが、特に印象的な選手はいませんでした',
        discoveredPlayer: null,
        improvedPlayer: null,
      );
    }
  }

  /// インタビューアクション
  static ScoutActionResult interview({
    required Player targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) {
    // インタビューの具体的な処理
    // 性格・精神面の情報を取得
    
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
    
    // インタビューによる信頼度向上
    final trustIncrease = 5 + Random().nextInt(11); // 5-15の信頼度向上
    
    return ScoutActionResult(
      success: true,
      message: '💬 ${targetPlayer.name}のインタビュー: 性格「${personality}」、精神力${mentalStrength}、動機「${motivation}」を把握しました',
      discoveredPlayer: null,
      improvedPlayer: targetPlayer,
    );
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
  static void _saveScoutAnalysis(String playerId, Scout scout, double accuracy) {
    // プレイヤーIDからプレイヤーオブジェクトを取得する必要がある
    // この実装では、GameManagerからプレイヤー情報を取得する必要がある
    // 簡易的な実装として、後でGameManagerから呼び出される際にプレイヤー情報を渡す
    print('スカウト分析データ保存: プレイヤーID $playerId, 精度 $accuracy');
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
    final analysisSkill = scoutSkills[ScoutSkill.analysis] ?? 50;
    final insightSkill = scoutSkills[ScoutSkill.insight] ?? 50;
    
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
    final growthRate = player.growthRate;
    final peakAbility = player.peakAbility;
    
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