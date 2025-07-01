// スカウトの能力クラス
class ScoutSkills {
  int exploration; // 探索 (0-100)
  int observation; // 観察 (0-100)
  int analysis; // 分析 (0-100)
  int insight; // 洞察 (0-100)
  int communication; // コミュニケーション (0-100)
  int negotiation; // 交渉 (0-100)
  int stamina; // 体力 (0-100)
  
  ScoutSkills({
    this.exploration = 50,
    this.observation = 50,
    this.analysis = 50,
    this.insight = 50,
    this.communication = 50,
    this.negotiation = 50,
    this.stamina = 50,
  });
  
  // スキルを取得
  int getSkill(String skillName) {
    switch (skillName) {
      case 'exploration': return exploration;
      case 'observation': return observation;
      case 'analysis': return analysis;
      case 'insight': return insight;
      case 'communication': return communication;
      case 'negotiation': return negotiation;
      case 'stamina': return stamina;
      default: return 50;
    }
  }
  
  // スキルを設定
  void setSkill(String skillName, int value) {
    final clampedValue = value.clamp(0, 100);
    switch (skillName) {
      case 'exploration': exploration = clampedValue; break;
      case 'observation': observation = clampedValue; break;
      case 'analysis': analysis = clampedValue; break;
      case 'insight': insight = clampedValue; break;
      case 'communication': communication = clampedValue; break;
      case 'negotiation': negotiation = clampedValue; break;
      case 'stamina': stamina = clampedValue; break;
    }
  }
  
  // スキルを上昇
  void improveSkill(String skillName, int amount) {
    final currentSkill = getSkill(skillName);
    setSkill(skillName, currentSkill + amount);
  }
  
  Map<String, dynamic> toJson() => {
    'exploration': exploration,
    'observation': observation,
    'analysis': analysis,
    'insight': insight,
    'communication': communication,
    'negotiation': negotiation,
    'stamina': stamina,
  };
  
  factory ScoutSkills.fromJson(Map<String, dynamic> json) => ScoutSkills(
    exploration: json['exploration'] ?? 50,
    observation: json['observation'] ?? 50,
    analysis: json['analysis'] ?? 50,
    insight: json['insight'] ?? 50,
    communication: json['communication'] ?? 50,
    negotiation: json['negotiation'] ?? 50,
    stamina: json['stamina'] ?? 50,
  );
} 