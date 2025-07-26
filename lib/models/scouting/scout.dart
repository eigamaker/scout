import 'skill.dart';

class Scout {
  final String id;
  final String name;
  final int level;
  final int experience;
  
  // スキル値（8項目）
  final Map<Skill, int> skills;
  
  // 行動関連
  final int actionPoints;
  final int maxActionPoints;
  final int stamina;
  final int maxStamina;
  final int money;
  
  // 情報関連
  final int trustLevel;
  
  // 統計
  final int totalActions;
  final int successfulActions;
  final double successRate;

  Scout({
    required this.id,
    required this.name,
    required this.level,
    required this.experience,
    required this.skills,
    required this.actionPoints,
    required this.maxActionPoints,
    required this.stamina,
    required this.maxStamina,
    required this.money,
    required this.trustLevel,
    required this.totalActions,
    required this.successfulActions,
    required this.successRate,
  });

  // スキル値を取得
  int getSkill(Skill skill) {
    return skills[skill] ?? 1;
  }

  // スキル値を設定
  Scout withSkill(Skill skill, int value) {
    final newSkills = Map<Skill, int>.from(skills);
    newSkills[skill] = value.clamp(1, 10);
    return copyWith(skills: newSkills);
  }

  // アクションポイントを消費
  Scout consumeActionPoints(int amount) {
    return copyWith(actionPoints: (actionPoints - amount).clamp(0, maxActionPoints));
  }

  // 体力を消費
  Scout consumeStamina(int amount) {
    return copyWith(stamina: (stamina - amount).clamp(0, maxStamina));
  }

  // お金を消費
  Scout spendMoney(int amount) {
    return copyWith(money: (money - amount).clamp(0, double.infinity).toInt());
  }

  // 経験値を追加
  Scout addExperience(int amount) {
    final newExperience = experience + amount;
    return copyWith(experience: newExperience);
  }

  // アクション統計を更新
  Scout updateActionStats(bool wasSuccessful) {
    final newTotalActions = totalActions + 1;
    final newSuccessfulActions = successfulActions + (wasSuccessful ? 1 : 0);
    final newSuccessRate = newTotalActions > 0 ? newSuccessfulActions / newTotalActions : 0.0;
    
    return copyWith(
      totalActions: newTotalActions,
      successfulActions: newSuccessfulActions,
      successRate: newSuccessRate,
    );
  }

  // デフォルトスカウトを作成
  factory Scout.createDefault({
    required String id,
    required String name,
  }) {
    return Scout(
      id: id,
      name: name,
      level: 1,
      experience: 0,
      skills: {
        Skill.exploration: 3,
        Skill.observation: 4,
        Skill.analysis: 3,
        Skill.insight: 3,
        Skill.communication: 4,
        Skill.negotiation: 3,
        Skill.stamina: 5,
        Skill.intuition: 2,
      },
      actionPoints: 10,
      maxActionPoints: 10,
      stamina: 100,
      maxStamina: 100,
      money: 100000,
      trustLevel: 30,
      totalActions: 0,
      successfulActions: 0,
      successRate: 0.0,
    );
  }

  // コピーメソッド
  Scout copyWith({
    String? id,
    String? name,
    int? level,
    int? experience,
    Map<Skill, int>? skills,
    int? actionPoints,
    int? maxActionPoints,
    int? stamina,
    int? maxStamina,
    int? money,
    int? trustLevel,
    int? totalActions,
    int? successfulActions,
    double? successRate,
  }) {
    return Scout(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      actionPoints: actionPoints ?? this.actionPoints,
      maxActionPoints: maxActionPoints ?? this.maxActionPoints,
      stamina: stamina ?? this.stamina,
      maxStamina: maxStamina ?? this.maxStamina,
      money: money ?? this.money,
      trustLevel: trustLevel ?? this.trustLevel,
      totalActions: totalActions ?? this.totalActions,
      successfulActions: successfulActions ?? this.successfulActions,
      successRate: successRate ?? this.successRate,
    );
  }

  @override
  String toString() {
    return 'Scout(id: $id, name: $name, level: $level, skills: $skills)';
  }
} 