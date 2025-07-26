import 'dart:math';
import '../../models/scouting/action.dart';
import '../../models/scouting/scout.dart';
import '../../models/scouting/scouting_history.dart';
import 'accuracy_calculator.dart';
import '../../models/school/school.dart';
import '../../models/player/player.dart';

class SchoolScoutResult {
  final Player? discoveredPlayer;
  final Player? improvedPlayer;
  final String message;
  SchoolScoutResult({this.discoveredPlayer, this.improvedPlayer, required this.message});
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
        message: '新しい選手「${player.name}」が気になりました！',
      );
    } else {
      // すでに全員発掘済み→ランダムで1人の把握度アップ
      final discovered = school.players.where((p) => p.isDiscovered).toList();
      if (discovered.isEmpty) {
        return SchoolScoutResult(
          discoveredPlayer: null,
          improvedPlayer: null,
          message: 'この学校には選手がいません。',
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
        message: '「${player.name}」の能力値の把握度が上がった！',
      );
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