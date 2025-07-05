import 'dart:math';

// スカウトの能力クラス
class ScoutSkills {
  int exploration; // 探索 (0-100) - 未登録校・選手を発見
  int observation; // 観察 (0-100) - 実パフォ計測精度
  int analysis; // 分析 (0-100) - データ統合と将来予測
  int insight; // 洞察 (0-100) - 潜在才能・怪我リスク察知
  int communication; // コミュニケーション (0-100) - 面談・信頼構築
  int negotiation; // 交渉 (0-100) - 利害調整・提案採用率
  int stamina; // 体力 (0-100) - 遠征疲労耐性
  
  ScoutSkills({
    this.exploration = 40,
    this.observation = 45,
    this.analysis = 35,
    this.insight = 30,
    this.communication = 50,
    this.negotiation = 25,
    this.stamina = 60,
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
  
  // アクション実行時にスキルを成長させる
  void growFromAction(String actionId, bool success) {
    final random = Random();
    
    // アクションに応じたスキル成長
    switch (actionId) {
      case 'PRAC_WATCH':
        improveSkill('observation', success ? random.nextInt(3) + 2 : random.nextInt(2) + 1);
        improveSkill('exploration', success ? random.nextInt(2) + 1 : 0);
        break;
      case 'GAME_WATCH':
        improveSkill('observation', success ? random.nextInt(4) + 3 : random.nextInt(2) + 1);
        improveSkill('analysis', success ? random.nextInt(2) + 1 : 0);
        break;
      case 'SCRIMMAGE':
        improveSkill('observation', success ? random.nextInt(3) + 2 : random.nextInt(2) + 1);
        improveSkill('analysis', success ? random.nextInt(2) + 1 : 0);
        break;
      case 'INTERVIEW':
        improveSkill('communication', success ? random.nextInt(4) + 3 : random.nextInt(2) + 1);
        improveSkill('insight', success ? random.nextInt(2) + 1 : 0);
        break;
      case 'VIDEO_ANALYZE':
        improveSkill('analysis', success ? random.nextInt(4) + 3 : random.nextInt(2) + 1);
        improveSkill('insight', success ? random.nextInt(3) + 2 : random.nextInt(1) + 1);
        break;
      case 'TEAM_VISIT':
        improveSkill('negotiation', success ? random.nextInt(4) + 3 : random.nextInt(2) + 1);
        improveSkill('communication', success ? random.nextInt(2) + 1 : 0);
        break;
      case 'INFO_SWAP':
        improveSkill('communication', success ? random.nextInt(3) + 2 : random.nextInt(1) + 1);
        improveSkill('insight', success ? random.nextInt(2) + 1 : 0);
        improveSkill('exploration', success ? random.nextInt(2) + 1 : 0);
        break;
      case 'REPORT_WRITE':
        improveSkill('analysis', success ? random.nextInt(3) + 2 : random.nextInt(2) + 1);
        improveSkill('negotiation', success ? random.nextInt(2) + 1 : 0);
        break;
      case 'NEWS_CHECK':
        improveSkill('exploration', success ? random.nextInt(2) + 1 : 0);
        break;
    }
    
    // 体力は全アクションで少し成長（疲労耐性の向上）
    if (success) {
      improveSkill('stamina', random.nextInt(1) + 1);
    }
  }
  
  // スキルの合計値を取得
  int get totalSkill => exploration + observation + analysis + insight + communication + negotiation + stamina;
  
  // スキルの平均値を取得
  double get averageSkill => totalSkill / 7;
  
  // スキルレベルを取得（文字列）
  String getSkillLevel(String skillName) {
    final skill = getSkill(skillName);
    if (skill >= 90) return 'S';
    if (skill >= 80) return 'A';
    if (skill >= 70) return 'B';
    if (skill >= 60) return 'C';
    if (skill >= 50) return 'D';
    return 'E';
  }
  
  // スキル名を日本語で取得
  String getSkillName(String skillName) {
    switch (skillName) {
      case 'exploration': return '探索';
      case 'observation': return '観察';
      case 'analysis': return '分析';
      case 'insight': return '洞察';
      case 'communication': return 'コミュニケーション';
      case 'negotiation': return '交渉';
      case 'stamina': return '体力';
      default: return skillName;
    }
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