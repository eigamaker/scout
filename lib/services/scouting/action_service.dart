import 'dart:math';
import '../../models/scouting/action.dart';
import '../../models/scouting/scout.dart';
import '../../models/scouting/scouting_history.dart';
import 'accuracy_calculator.dart';
import '../../models/school/school.dart';
import '../../models/player/player.dart';
import 'scout_analysis_service.dart';

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
      // 能力値把握度を初期値（20～40%）に
      player.abilityKnowledge.updateAll((k, v) => 20 + Random().nextInt(21));
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
      // 能力値把握度を+10～+20%アップ（最大80%）
      player.abilityKnowledge.updateAll((k, v) => (v + 10 + Random().nextInt(11)).clamp(0, 80));
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

  /// インタビューアクション
  static ScoutActionResult interview({
    required Player targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) {
    // インタビューの具体的な処理
    final knowledgeIncrease = 25 + Random().nextInt(26); // 25-50%増加
    targetPlayer.abilityKnowledge.updateAll((k, v) => (v + knowledgeIncrease).clamp(0, 95));
    
    return ScoutActionResult(
      success: true,
      message: '🎤 「${targetPlayer.name}」へのインタビュー: 選手の本音を聞くことができました',
      discoveredPlayer: null,
      improvedPlayer: targetPlayer,
    );
  }

  /// ビデオ分析アクション
  static ScoutActionResult videoAnalyze({
    required Player targetPlayer,
    required Map<ScoutSkill, int> scoutSkills,
    required int currentWeek,
  }) {
    // ビデオ分析の具体的な処理
    final knowledgeIncrease = 30 + Random().nextInt(21); // 30-50%増加
    targetPlayer.abilityKnowledge.updateAll((k, v) => (v + knowledgeIncrease).clamp(0, 95));
    
    return ScoutActionResult(
      success: true,
      message: '📹 「${targetPlayer.name}」のビデオ分析: 技術的な詳細を分析できました',
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