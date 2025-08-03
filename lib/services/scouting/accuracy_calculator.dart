import 'dart:math';
import '../../models/scouting/scout.dart';

class AccuracyCalculator {
  // 選手情報とスキルの関連性マップ
  static const Map<String, Map<String, dynamic>> _infoSkillMapping = {
    '現在の能力値': {'primary': ScoutSkill.observation, 'primaryCoef': 0.7, 'sub': ScoutSkill.analysis, 'subCoef': 0.3},
    '成長スピード': {'primary': ScoutSkill.analysis, 'primaryCoef': 0.6, 'sub': ScoutSkill.observation, 'subCoef': 0.4},
    '成長タイプ': {'primary': ScoutSkill.analysis, 'primaryCoef': 0.5, 'sub': ScoutSkill.insight, 'subCoef': 0.5},
    'ポテンシャル': {'primary': ScoutSkill.insight, 'primaryCoef': 0.6, 'sub': ScoutSkill.analysis, 'subCoef': 0.4},
    '才能ランク': {'primary': ScoutSkill.exploration, 'primaryCoef': 0.5, 'sub': ScoutSkill.insight, 'subCoef': 0.5},
    '性格': {'primary': ScoutSkill.communication, 'primaryCoef': 0.7, 'sub': ScoutSkill.insight, 'subCoef': 0.3},
    '精神力': {'primary': ScoutSkill.insight, 'primaryCoef': 0.6, 'sub': ScoutSkill.communication, 'subCoef': 0.4},
    'ポジション適性': {'primary': ScoutSkill.observation, 'primaryCoef': 0.6, 'sub': ScoutSkill.insight, 'subCoef': 0.4},
    '怪我リスク': {'primary': ScoutSkill.insight, 'primaryCoef': 0.7, 'sub': ScoutSkill.observation, 'subCoef': 0.3},
    '動機・目標': {'primary': ScoutSkill.communication, 'primaryCoef': 0.8, 'sub': ScoutSkill.insight, 'subCoef': 0.2},
  };

  /// 情報判別精度を計算
  static double calculateAccuracy({
    required Map<ScoutSkill, int> scoutSkills,
    required String infoType,
    required int visitCount,
    required int weeksSinceLastVisit,
  }) {
    // 基本精度計算
    double baseAccuracy = _calculateBaseAccuracy(scoutSkills, infoType);
    
    // 視察回数ボーナス
    double visitBonus = min(visitCount * 2, 20);
    
    // 直観補正
    double intuitionBonus = (scoutSkills[ScoutSkill.intuition] ?? 1) * 0.8;
    
    // 時間補正
    double timePenalty = _calculateTimePenalty(weeksSinceLastVisit);
    
    // 最終精度
    double finalAccuracy = baseAccuracy + visitBonus + intuitionBonus - timePenalty;
    
    return min(finalAccuracy, 80);  // 最大80%に制限
  }

  /// 基本精度を計算
  static double _calculateBaseAccuracy(Map<ScoutSkill, int> scoutSkills, String infoType) {
    final mapping = _infoSkillMapping[infoType];
    if (mapping == null) return 0.0;

    final primarySkill = mapping['primary'] as ScoutSkill;
    final primaryCoef = mapping['primaryCoef'] as double;
    final subSkill = mapping['sub'] as ScoutSkill;
    final subCoef = mapping['subCoef'] as double;

    final primaryValue = scoutSkills[primarySkill] ?? 1;
    final subValue = scoutSkills[subSkill] ?? 1;

    return (primaryValue * primaryCoef + subValue * subCoef) * 8;
  }

  /// 時間経過による精度低下を計算
  static double _calculateTimePenalty(int weeksSinceLastVisit) {
    if (weeksSinceLastVisit <= 52) {
      return 0;  // 1年以内は精度維持
    } else {
      return min((weeksSinceLastVisit - 52) * 0.5, 20);  // 最大20%の低下
    }
  }

  /// アクション成功判定を計算
  static double calculateSuccessRate({
    required double baseSuccessRate,
    required ScoutSkill primarySkill,
    required double skillCoefficient,
    required Map<ScoutSkill, int> scoutSkills,
  }) {
    final skillValue = scoutSkills[primarySkill] ?? 1;
    final skillBonus = skillValue * skillCoefficient;
    final intuitionBonus = (scoutSkills[ScoutSkill.intuition] ?? 1) * 0.008; // 0.8%

    return (baseSuccessRate + skillBonus + intuitionBonus).clamp(0.0, 1.0);
  }

  /// 精度レベルを取得
  static String getAccuracyLevel(double accuracy) {
    if (accuracy <= 30) {
      return '非常に不正確';
    } else if (accuracy <= 50) {
      return '不正確';
    } else if (accuracy <= 70) {
      return 'やや正確';
    } else if (accuracy <= 80) {
      return '正確';
    } else {
      return '非常に正確';
    }
  }

  /// 能力値の表示範囲を計算
  static String getAbilityDisplayRange(int actualValue, double accuracy) {
    int errorRange;
    
    if (accuracy < 30) {
      errorRange = 20;  // 非常に曖昧
    } else if (accuracy < 50) {
      errorRange = 15;  // 曖昧
    } else if (accuracy < 70) {
      errorRange = 10;  // やや正確
    } else {
      errorRange = 5;   // 正確
    }

    final minValue = (actualValue - errorRange).clamp(1, 100);
    final maxValue = (actualValue + errorRange).clamp(1, 100);
    
    return '$minValue-$maxValue';
  }

  /// 精度に応じた表示例を取得
  static String getAccuracyDisplayExample(String infoType, double accuracy) {
    switch (infoType) {
      case '現在の能力値':
        return '能力値: ${getAbilityDisplayRange(80, accuracy)}';
      case '才能ランク':
        return '才能ランク: A-B（推定）';
      case '性格':
        return '性格: 積極的（推定）';
      case '成長タイプ':
        return '成長タイプ: 早期型（推定）';
      default:
        return '$infoType: 情報取得済み（精度: ${accuracy.toStringAsFixed(1)}%）';
    }
  }
} 