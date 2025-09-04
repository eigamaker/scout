import 'package:flutter/material.dart';

// スカウトスキル定義
enum ScoutSkill {
  exploration,    // 探索
  observation,    // 観察
  analysis,       // 分析
  insight,        // 洞察
  communication,  // コミュニケーション
  negotiation,    // 交渉
  stamina,        // 体力
  intuition,      // 直観
}

// スキル名の日本語マッピング
const Map<ScoutSkill, String> skillNames = {
  ScoutSkill.exploration: '探索',
  ScoutSkill.observation: '観察',
  ScoutSkill.analysis: '分析',
  ScoutSkill.insight: '洞察',
  ScoutSkill.communication: 'コミュニケーション',
  ScoutSkill.negotiation: '交渉',
  ScoutSkill.stamina: '体力',
  ScoutSkill.intuition: '直観',
};

// スキルの説明
const Map<ScoutSkill, String> skillDescriptions = {
  ScoutSkill.exploration: '隠れた才能を持つ選手を発見する能力',
  ScoutSkill.observation: '選手の現在の能力値を正確に評価する能力',
  ScoutSkill.analysis: 'データを統合して将来性を予測する能力',
  ScoutSkill.insight: '選手の内面や潜在的な要素を見抜く能力',
  ScoutSkill.communication: '選手や関係者との対話を通じて情報を引き出す能力',
  ScoutSkill.negotiation: '球団や関係者との調整・提案能力',
  ScoutSkill.stamina: 'スカウト活動の継続性と効率性',
  ScoutSkill.intuition: '一瞬の判断や予期しない発見',
};

// スキルのアイコン
const Map<ScoutSkill, IconData> skillIcons = {
  ScoutSkill.exploration: Icons.explore,
  ScoutSkill.observation: Icons.visibility,
  ScoutSkill.analysis: Icons.analytics,
  ScoutSkill.insight: Icons.lightbulb,
  ScoutSkill.communication: Icons.chat,
  ScoutSkill.negotiation: Icons.handshake,
  ScoutSkill.stamina: Icons.fitness_center,
  ScoutSkill.intuition: Icons.psychology,
};

// スカウトクラス
class Scout {
  final String name;
  final String prefecture;
  final int level;
  final int experience;
  final int maxExperience;
  final Map<ScoutSkill, int> skills;
  final int actionPoints;
  final int maxActionPoints;
  final int stamina;
  final int maxStamina;
  final int money;
  final int trustLevel;
  final int reputation;
  final int totalActions;
  final int successfulActions;
  final double successRate;
  
  const Scout({
    required this.name,
    required this.prefecture,
    required this.level,
    required this.experience,
    required this.maxExperience,
    required this.skills,
    required this.actionPoints,
    required this.maxActionPoints,
    required this.stamina,
    required this.maxStamina,
    required this.money,
    required this.trustLevel,
    required this.reputation,
    required this.totalActions,
    required this.successfulActions,
    required this.successRate,
  });

  // デフォルトスカウト作成
  factory Scout.createDefault(String name, {String prefecture = '未設定'}) {
    return Scout(
      name: name,
      prefecture: prefecture,
      level: 1,
      experience: 0,
      maxExperience: 100,
      skills: {
        ScoutSkill.exploration: 3,
        ScoutSkill.observation: 3,
        ScoutSkill.analysis: 2,
        ScoutSkill.insight: 2,
        ScoutSkill.communication: 3,
        ScoutSkill.negotiation: 2,
        ScoutSkill.stamina: 4,
        ScoutSkill.intuition: 2,
      },
      actionPoints: 15,
      maxActionPoints: 15,
      stamina: 100,
      maxStamina: 100,
      money: 100000,
      trustLevel: 0,
      reputation: 50,
      totalActions: 0,
      successfulActions: 0,
      successRate: 0.0,
    );
  }

  // スキル値を取得
  int getSkill(ScoutSkill skill) {
    return skills[skill] ?? 1;
  }

  // スキル値を設定
  Scout setSkill(ScoutSkill skill, int value) {
    final clampedValue = value.clamp(1, 10);
    final newSkills = Map<ScoutSkill, int>.from(skills);
    newSkills[skill] = clampedValue;
    
    return copyWith(skills: newSkills);
  }

  // スキル値を増加
  Scout increaseSkill(ScoutSkill skill, int amount) {
    final currentValue = getSkill(skill);
    return setSkill(skill, currentValue + amount);
  }

  // 経験値を追加
  Scout addExperience(int amount) {
    final newExperience = experience + amount;
    final newLevel = (newExperience / maxExperience).floor() + 1;
    
    return copyWith(
      experience: newExperience,
      level: newLevel,
    );
  }

  // APを消費
  Scout consumeActionPoints(int amount) {
    final newActionPoints = (actionPoints - amount).clamp(0, maxActionPoints);
    return copyWith(actionPoints: newActionPoints);
  }

  // APを回復
  Scout restoreActionPoints(int amount) {
    final newActionPoints = (actionPoints + amount).clamp(0, maxActionPoints);
    return copyWith(actionPoints: newActionPoints);
  }

  // お金を消費
  Scout spendMoney(int amount) {
    return copyWith(money: money - amount);
  }

  // お金を獲得
  Scout earnMoney(int amount) {
    return copyWith(money: money + amount);
  }

  // 信頼度を変更
  Scout changeTrustLevel(int amount) {
    final newTrustLevel = (trustLevel + amount).clamp(0, 100);
    return copyWith(trustLevel: newTrustLevel);
  }

  // 評判を変更
  Scout changeReputation(int amount) {
    final newReputation = (reputation + amount).clamp(0, 100);
    return copyWith(reputation: newReputation);
  }

  // 平均スキル値を計算
  double get averageSkill {
    final total = skills.values.reduce((a, b) => a + b);
    return total / skills.length;
  }

  // 最高スキル値を取得
  int get maxSkill {
    return skills.values.reduce((a, b) => a > b ? a : b);
  }

  // 最低スキル値を取得
  int get minSkill {
    return skills.values.reduce((a, b) => a < b ? a : b);
  }

  // スキル成長率を計算（経験値に基づく）
  double get skillGrowthRate {
    return (experience / maxExperience).clamp(0.0, 1.0);
  }

  // 体力消費
  Scout consumeStamina(int amount) {
    return copyWith(stamina: (stamina - amount).clamp(0, maxStamina));
  }

  // アクション統計更新
  Scout updateActionStats(bool isSuccessful) {
    final newTotalActions = totalActions + 1;
    final newSuccessfulActions = successfulActions + (isSuccessful ? 1 : 0);
    final newSuccessRate = newTotalActions > 0 ? newSuccessfulActions / newTotalActions : 0.0;
    
    return copyWith(
      totalActions: newTotalActions,
      successfulActions: newSuccessfulActions,
      successRate: newSuccessRate,
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'name': name,
    'prefecture': prefecture,
    'level': level,
    'experience': experience,
    'maxExperience': maxExperience,
    'skills': skills.map((key, value) => MapEntry(key.name, value)),
    'actionPoints': actionPoints,
    'maxActionPoints': maxActionPoints,
    'stamina': stamina,
    'maxStamina': maxStamina,
    'money': money,
    'trustLevel': trustLevel,
    'reputation': reputation,
    'totalActions': totalActions,
    'successfulActions': successfulActions,
    'successRate': successRate,
  };

  // JSONから復元
  factory Scout.fromJson(Map<String, dynamic> json) {
    final skillsMap = <ScoutSkill, int>{};
    final skillsJson = json['skills'] as Map<String, dynamic>;
    
    for (final entry in skillsJson.entries) {
      final skill = ScoutSkill.values.firstWhere(
        (s) => s.name == entry.key,
        orElse: () => ScoutSkill.exploration,
      );
      skillsMap[skill] = entry.value as int;
    }

    return Scout(
      name: json['name'] as String,
      prefecture: json['prefecture'] as String? ?? '未設定',
      level: json['level'] as int,
      experience: json['experience'] as int,
      maxExperience: json['maxExperience'] as int,
      skills: skillsMap,
      actionPoints: json['actionPoints'] as int,
      maxActionPoints: json['maxActionPoints'] as int,
      stamina: json['stamina'] as int? ?? 100,
      maxStamina: json['maxStamina'] as int? ?? 100,
      money: json['money'] as int,
      trustLevel: json['trustLevel'] as int,
      reputation: json['reputation'] as int,
      totalActions: json['totalActions'] as int? ?? 0,
      successfulActions: json['successfulActions'] as int? ?? 0,
      successRate: json['successRate'] as double? ?? 0.0,
    );
  }

  // コピーメソッド
  Scout copyWith({
    String? name,
    String? prefecture,
    int? level,
    int? experience,
    int? maxExperience,
    Map<ScoutSkill, int>? skills,
    int? actionPoints,
    int? maxActionPoints,
    int? stamina,
    int? maxStamina,
    int? money,
    int? trustLevel,
    int? reputation,
    int? totalActions,
    int? successfulActions,
    double? successRate,
  }) {
    return Scout(
      name: name ?? this.name,
      prefecture: prefecture ?? this.prefecture,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      maxExperience: maxExperience ?? this.maxExperience,
      skills: skills ?? this.skills,
      actionPoints: actionPoints ?? this.actionPoints,
      maxActionPoints: maxActionPoints ?? this.maxActionPoints,
      stamina: stamina ?? this.stamina,
      maxStamina: maxStamina ?? this.maxStamina,
      money: money ?? this.money,
      trustLevel: trustLevel ?? this.trustLevel,
      reputation: reputation ?? this.reputation,
      totalActions: totalActions ?? this.totalActions,
      successfulActions: successfulActions ?? this.successfulActions,
      successRate: successRate ?? this.successRate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scout &&
        other.name == name &&
        other.prefecture == prefecture &&
        other.level == level &&
        other.experience == experience;
  }

  @override
  int get hashCode {
    return name.hashCode ^ prefecture.hashCode ^ level.hashCode ^ experience.hashCode;
  }

  @override
  String toString() {
    return 'Scout(name: $name, level: $level, experience: $experience)';
  }
} 