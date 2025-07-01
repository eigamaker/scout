// スカウトアクション関連のデータモデル
import 'dart:math';
import 'scout_skills.dart';

// スカウトアクションクラス
class ScoutingAction {
  final String id;
  final String name;
  final int apCost;
  final int budgetCost;
  final String description;
  final String category;
  final List<String> requiredSkills; // 必要なスキル
  final List<String> primarySkills; // 主に使用するスキル
  final double baseSuccessRate; // 基本成功率
  final Map<String, double> skillModifiers; // スキル補正
  
  ScoutingAction({
    required this.id,
    required this.name,
    required this.apCost,
    required this.budgetCost,
    required this.description,
    required this.category,
    required this.requiredSkills,
    required this.primarySkills,
    required this.baseSuccessRate,
    required this.skillModifiers,
  });
  
  // 成功判定を計算
  bool calculateSuccess(ScoutSkills skills) {
    final random = Random();
    double successRate = baseSuccessRate;
    
    // スキル補正を適用
    for (final skillName in skillModifiers.keys) {
      final skillValue = skills.getSkill(skillName);
      final modifier = skillModifiers[skillName]!;
      successRate += (skillValue / 100.0) * modifier;
    }
    
    // 体力による疲労ペナルティ
    final staminaPenalty = (100 - skills.stamina) * 0.001; // 体力が低いほど成功率が下がる
    successRate -= staminaPenalty;
    
    return random.nextDouble() < successRate;
  }
  
  // アクションが実行可能かチェック
  bool canExecute(ScoutSkills skills, int currentAp, int currentBudget) {
    if (currentAp < apCost) return false;
    if (currentBudget < budgetCost) return false;
    
    // 必要なスキルをチェック（最低20に緩和）
    for (final skillName in requiredSkills) {
      if (skills.getSkill(skillName) < 20) return false; // 最低20は必要
    }
    
    return true;
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'apCost': apCost,
    'budgetCost': budgetCost,
    'description': description,
    'category': category,
    'requiredSkills': requiredSkills,
    'primarySkills': primarySkills,
    'baseSuccessRate': baseSuccessRate,
    'skillModifiers': skillModifiers,
  };
  
  factory ScoutingAction.fromJson(Map<String, dynamic> json) => ScoutingAction(
    id: json['id'],
    name: json['name'],
    apCost: json['apCost'],
    budgetCost: json['budgetCost'],
    description: json['description'],
    category: json['category'],
    requiredSkills: List<String>.from(json['requiredSkills']),
    primarySkills: List<String>.from(json['primarySkills']),
    baseSuccessRate: json['baseSuccessRate'].toDouble(),
    skillModifiers: Map<String, double>.from(json['skillModifiers']),
  );
}

// スカウトアクションの対象クラス
class ScoutingTarget {
  final String type; // 'school', 'player', 'region', 'team'
  final String name;
  final String? description;
  final Map<String, dynamic>? metadata;
  
  ScoutingTarget({
    required this.type,
    required this.name,
    this.description,
    this.metadata,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'description': description,
    'metadata': metadata,
  };
  
  factory ScoutingTarget.fromJson(Map<String, dynamic> json) => ScoutingTarget(
    type: json['type'],
    name: json['name'],
    description: json['description'],
    metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
  );
}

// スカウトアクションの結果クラス
class ActionResult {
  final String actionName;
  final String result;
  final String school;
  final String? player;
  final int apUsed;
  final int budgetUsed;
  final DateTime timestamp;
  final bool success;
  final Map<String, dynamic>? additionalData; // 追加データ（発見した選手、得た情報など）
  
  ActionResult({
    required this.actionName,
    required this.result,
    required this.school,
    this.player,
    required this.apUsed,
    required this.budgetUsed,
    required this.timestamp,
    required this.success,
    this.additionalData,
  });
  
  Map<String, dynamic> toJson() => {
    'actionName': actionName,
    'result': result,
    'school': school,
    'player': player,
    'apUsed': apUsed,
    'budgetUsed': budgetUsed,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'additionalData': additionalData,
  };
  
  factory ActionResult.fromJson(Map<String, dynamic> json) => ActionResult(
    actionName: json['actionName'],
    result: json['result'],
    school: json['school'],
    player: json['player'],
    apUsed: json['apUsed'],
    budgetUsed: json['budgetUsed'],
    timestamp: DateTime.parse(json['timestamp']),
    success: json['success'],
    additionalData: json['additionalData'] != null ? Map<String, dynamic>.from(json['additionalData']) : null,
  );
}

// アクション結果クラス
class ActionResultData {
  final String message;
  final Map<String, dynamic>? additionalData;
  
  ActionResultData(this.message, [this.additionalData]);
}

// 利用可能なスカウトアクション
final List<ScoutingAction> availableActions = [
  ScoutingAction(
    id: 'PRAC_WATCH',
    name: '練習視察',
    apCost: 2,
    budgetCost: 20000,
    description: '地元校の練習を見学し、選手の基本能力を確認',
    category: '視察',
    requiredSkills: ['observation'],
    primarySkills: ['observation', 'exploration'],
    baseSuccessRate: 0.60,
    skillModifiers: {'observation': 0.3},
  ),
  ScoutingAction(
    id: 'TEAM_VISIT',
    name: '球団訪問',
    apCost: 1,
    budgetCost: 0,
    description: '球団を訪問し、ニーズと指名候補を確認',
    category: '交渉',
    requiredSkills: ['negotiation'],
    primarySkills: ['negotiation', 'communication'],
    baseSuccessRate: 0.90,
    skillModifiers: {'negotiation': 0.1},
  ),
  ScoutingAction(
    id: 'INFO_SWAP',
    name: '情報交換',
    apCost: 1,
    budgetCost: 0,
    description: '他地域のスカウトと情報交換',
    category: '情報収集',
    requiredSkills: ['communication'],
    primarySkills: ['communication', 'insight'],
    baseSuccessRate: 0.70,
    skillModifiers: {'insight': 0.2},
  ),
  ScoutingAction(
    id: 'NEWS_CHECK',
    name: 'ニュース確認',
    apCost: 0,
    budgetCost: 0,
    description: '最新のニュースを確認',
    category: '情報収集',
    requiredSkills: [],
    primarySkills: ['exploration'],
    baseSuccessRate: 1.0,
    skillModifiers: {},
  ),
  ScoutingAction(
    id: 'GAME_WATCH',
    name: '試合観戦',
    apCost: 3,
    budgetCost: 50000,
    description: '強豪校の試合を観戦し、詳細なパフォーマンスを確認',
    category: '視察',
    requiredSkills: ['observation'],
    primarySkills: ['observation', 'analysis'],
    baseSuccessRate: 0.55,
    skillModifiers: {'observation': 0.4},
  ),
  ScoutingAction(
    id: 'SCRIMMAGE',
    name: '練習試合観戦',
    apCost: 2,
    budgetCost: 30000,
    description: '練習試合を観戦し、実戦での傾向を確認',
    category: '視察',
    requiredSkills: ['observation'],
    primarySkills: ['observation', 'analysis'],
    baseSuccessRate: 0.50,
    skillModifiers: {'observation': 0.4},
  ),
  ScoutingAction(
    id: 'INTERVIEW',
    name: 'インタビュー',
    apCost: 1,
    budgetCost: 10000,
    description: '選手にインタビューし、性格と動機を確認',
    category: '面談',
    requiredSkills: ['communication'],
    primarySkills: ['communication', 'insight'],
    baseSuccessRate: 0.65,
    skillModifiers: {'communication': 0.4},
  ),
  ScoutingAction(
    id: 'VIDEO_ANALYZE',
    name: 'ビデオ分析',
    apCost: 2,
    budgetCost: 0,
    description: '映像を分析し、技術的なメカニクスを確認',
    category: '分析',
    requiredSkills: ['analysis'],
    primarySkills: ['analysis', 'insight'],
    baseSuccessRate: 0.70,
    skillModifiers: {'analysis': 0.3},
  ),
  ScoutingAction(
    id: 'REPORT_WRITE',
    name: 'レポート作成',
    apCost: 2,
    budgetCost: 0,
    description: '球団提出用の詳細レポートを作成',
    category: '報告',
    requiredSkills: ['analysis'],
    primarySkills: ['analysis', 'negotiation'],
    baseSuccessRate: 1.0,
    skillModifiers: {'negotiation': 0.2},
  ),
]; 