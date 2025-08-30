import 'package:scout_game/models/player/player.dart';

/// 将来性評価の5段階
enum FuturePotential {
  A, // 将来性抜群、大リーグ級の可能性
  B, // 高く期待できる、メジャー級の可能性
  C, // 一定の期待値、一軍レベル
  D, // 限定的な期待値、二軍レベル
  E, // 期待値低い、育成枠レベル
}

/// 想定ドラフト順位
enum ExpectedDraftPosition {
  first,      // 1位
  second,     // 2位
  third,      // 3位
  fourth,     // 4位
  fifth,      // 5位
  sixthOrLater, // 6位以下
}

/// 選手タイプ分類
enum PlayerType {
  // 投手
  startingPitcher,    // 先発型
  reliefPitcher,      // 中継ぎ型
  closer,             // 抑え型
  utilityPitcher,     // ユーティリティ型
  
  // 野手
  powerHitter,        // 長距離型
  contactHitter,      // 巧打型
  speedster,          // 俊足型
  defensiveSpecialist, // 守備型
  utilityPlayer,      // ユーティリティ型
}

/// スカウトレポート
class ScoutReport {
  final String id;
  final String playerId;
  final String playerName;
  final String scoutId;
  final String scoutName;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 基本評価
  final FuturePotential futurePotential;
  final double overallRating;
  final ExpectedDraftPosition expectedDraftPosition;
  final PlayerType playerType;
  
  // 詳細評価
  final String positionSuitability; // 適性ポジション
  final double mentalStrength;      // 精神力
  final double injuryRisk;          // 怪我リスク
  final int yearsToMLB;             // メジャー到達年数
  
  // コメント
  final String strengths;            // 長所
  final String weaknesses;           // 短所
  final String developmentPlan;      // 育成方針
  final String additionalNotes;      // その他特記事項
  
  // 分析完了フラグ
  final bool isAnalysisComplete;
  
  const ScoutReport({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.scoutId,
    required this.scoutName,
    required this.createdAt,
    required this.updatedAt,
    required this.futurePotential,
    required this.overallRating,
    required this.expectedDraftPosition,
    required this.playerType,
    required this.positionSuitability,
    required this.mentalStrength,
    required this.injuryRisk,
    required this.yearsToMLB,
    required this.strengths,
    required this.weaknesses,
    required this.developmentPlan,
    required this.additionalNotes,
    required this.isAnalysisComplete,
  });
  
  /// コピー作成
  ScoutReport copyWith({
    String? id,
    String? playerId,
    String? playerName,
    String? scoutId,
    String? scoutName,
    DateTime? createdAt,
    DateTime? updatedAt,
    FuturePotential? futurePotential,
    double? overallRating,
    ExpectedDraftPosition? expectedDraftPosition,
    PlayerType? playerType,
    String? positionSuitability,
    double? mentalStrength,
    double? injuryRisk,
    int? yearsToMLB,
    String? strengths,
    String? weaknesses,
    String? developmentPlan,
    String? additionalNotes,
    bool? isAnalysisComplete,
  }) {
    return ScoutReport(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      scoutId: scoutId ?? this.scoutId,
      scoutName: scoutName ?? this.scoutName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      futurePotential: futurePotential ?? this.futurePotential,
      overallRating: overallRating ?? this.overallRating,
      expectedDraftPosition: expectedDraftPosition ?? this.expectedDraftPosition,
      playerType: playerType ?? this.playerType,
      positionSuitability: positionSuitability ?? this.positionSuitability,
      mentalStrength: mentalStrength ?? this.mentalStrength,
      injuryRisk: injuryRisk ?? this.injuryRisk,
      yearsToMLB: yearsToMLB ?? this.yearsToMLB,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      developmentPlan: developmentPlan ?? this.developmentPlan,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      isAnalysisComplete: isAnalysisComplete ?? this.isAnalysisComplete,
    );
  }
  
  /// 将来性評価の文字列表現
  String get futurePotentialText {
    switch (futurePotential) {
      case FuturePotential.A:
        return 'A - 将来性抜群';
      case FuturePotential.B:
        return 'B - 高く期待できる';
      case FuturePotential.C:
        return 'C - 一定の期待値';
      case FuturePotential.D:
        return 'D - 限定的な期待値';
      case FuturePotential.E:
        return 'E - 期待値低い';
    }
  }
  
  /// ドラフト順位の文字列表現
  String get expectedDraftPositionText {
    switch (expectedDraftPosition) {
      case ExpectedDraftPosition.first:
        return '1位';
      case ExpectedDraftPosition.second:
        return '2位';
      case ExpectedDraftPosition.third:
        return '3位';
      case ExpectedDraftPosition.fourth:
        return '4位';
      case ExpectedDraftPosition.fifth:
        return '5位';
      case ExpectedDraftPosition.sixthOrLater:
        return '6位以下';
    }
  }
  
  /// 選手タイプの文字列表現
  String get playerTypeText {
    switch (playerType) {
      case PlayerType.startingPitcher:
        return '先発投手';
      case PlayerType.reliefPitcher:
        return '中継ぎ投手';
      case PlayerType.closer:
        return '抑え投手';
      case PlayerType.utilityPitcher:
        return 'ユーティリティ投手';
      case PlayerType.powerHitter:
        return '長距離打者';
      case PlayerType.contactHitter:
        return '巧打者';
      case PlayerType.speedster:
        return '俊足野手';
      case PlayerType.defensiveSpecialist:
        return '守備専門';
      case PlayerType.utilityPlayer:
        return 'ユーティリティ野手';
    }
  }
  
  /// 怪我リスクの文字列表現
  String get injuryRiskText {
    if (injuryRisk <= 20) return '低い';
    if (injuryRisk <= 40) return 'やや低い';
    if (injuryRisk <= 60) return '普通';
    if (injuryRisk <= 80) return 'やや高い';
    return '高い';
  }
  
  /// 精神力の文字列表現
  String get mentalStrengthText {
    if (mentalStrength >= 80) return '非常に高い';
    if (mentalStrength >= 60) return '高い';
    if (mentalStrength >= 40) return '普通';
    if (mentalStrength >= 20) return 'やや低い';
    return '低い';
  }
  
  /// メジャー到達年数の文字列表現
  String get yearsToMLBText {
    if (yearsToMLB <= 2) return '2年以内';
    if (yearsToMLB <= 4) return '3-4年';
    if (yearsToMLB <= 6) return '5-6年';
    if (yearsToMLB <= 8) return '7-8年';
    return '8年以上';
  }
  
  /// 総合評価の文字列表現
  String get overallRatingText {
    if (overallRating >= 90) return 'S級';
    if (overallRating >= 80) return 'A級';
    if (overallRating >= 70) return 'B級';
    if (overallRating >= 60) return 'C級';
    if (overallRating >= 50) return 'D級';
    return 'E級';
  }
}
