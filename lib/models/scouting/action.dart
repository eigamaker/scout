import 'skill.dart';

enum ActionType {
  pracWatch,      // 練習視察
  teamVisit,      // 球団訪問
  infoSwap,       // 情報交換
  newsCheck,      // ニュース確認
  gameWatch,      // 試合観戦
  scrimmage,      // 練習試合観戦
  interview,      // インタビュー
  videoAnalyze,   // ビデオ分析
  reportWrite,    // レポート作成
}

class Action {
  final ActionType type;
  final String name;
  final int actionPoints;
  final int cost;
  final String? prerequisite;
  final List<String> obtainableInfo;
  final double baseSuccessRate;
  final Skill primarySkill;
  final double skillCoefficient;
  final String intuitionEffect;

  const Action({
    required this.type,
    required this.name,
    required this.actionPoints,
    required this.cost,
    this.prerequisite,
    required this.obtainableInfo,
    required this.baseSuccessRate,
    required this.primarySkill,
    required this.skillCoefficient,
    required this.intuitionEffect,
  });

  // アクション定義
  static const Map<ActionType, Action> actions = {
    ActionType.pracWatch: Action(
      type: ActionType.pracWatch,
      name: '練習視察',
      actionPoints: 2,
      cost: 20000,
      obtainableInfo: ['基本情報', '簡易能力値', '才能ランク'],
      baseSuccessRate: 0.60,
      primarySkill: Skill.exploration,
      skillCoefficient: 0.08,
      intuitionEffect: '隠れた才能発見',
    ),
    ActionType.teamVisit: Action(
      type: ActionType.teamVisit,
      name: '球団訪問',
      actionPoints: 1,
      cost: 0,
      obtainableInfo: ['球団ニーズ', '指名候補'],
      baseSuccessRate: 0.90,
      primarySkill: Skill.negotiation,
      skillCoefficient: 0.01,
      intuitionEffect: '内部情報の取得',
    ),
    ActionType.infoSwap: Action(
      type: ActionType.infoSwap,
      name: '情報交換',
      actionPoints: 1,
      cost: 0,
      obtainableInfo: ['他地域評価', '噂話'],
      baseSuccessRate: 0.70,
      primarySkill: Skill.insight,
      skillCoefficient: 0.02,
      intuitionEffect: '予期しない情報',
    ),
    ActionType.newsCheck: Action(
      type: ActionType.newsCheck,
      name: 'ニュース確認',
      actionPoints: 0,
      cost: 0,
      obtainableInfo: ['ニュース情報'],
      baseSuccessRate: 1.0, // 自動成功
      primarySkill: Skill.intuition,
      skillCoefficient: 0.0,
      intuitionEffect: '特別なニュース発見',
    ),
    ActionType.gameWatch: Action(
      type: ActionType.gameWatch,
      name: '試合観戦',
      actionPoints: 3,
      cost: 50000,
      prerequisite: '試合週',
      obtainableInfo: ['現在の能力値', 'ポジション適性'],
      baseSuccessRate: 0.55,
      primarySkill: Skill.observation,
      skillCoefficient: 0.04,
      intuitionEffect: '重要な瞬間を捉える',
    ),
    ActionType.scrimmage: Action(
      type: ActionType.scrimmage,
      name: '練習試合観戦',
      actionPoints: 2,
      cost: 30000,
      prerequisite: '試合情報',
      obtainableInfo: ['現在の能力値', '成長スピード'],
      baseSuccessRate: 0.50,
      primarySkill: Skill.observation,
      skillCoefficient: 0.04,
      intuitionEffect: '隠れた実力発見',
    ),
    ActionType.interview: Action(
      type: ActionType.interview,
      name: 'インタビュー',
      actionPoints: 1,
      cost: 10000,
      prerequisite: '信頼度≥50',
      obtainableInfo: ['性格', '精神力', '動機・目標'],
      baseSuccessRate: 0.65,
      primarySkill: Skill.communication,
      skillCoefficient: 0.04,
      intuitionEffect: '本音を引き出す',
    ),
    ActionType.videoAnalyze: Action(
      type: ActionType.videoAnalyze,
      name: 'ビデオ分析',
      actionPoints: 2,
      cost: 0,
      prerequisite: '映像あり',
      obtainableInfo: ['成長タイプ', '怪我リスク', 'ポテンシャル'],
      baseSuccessRate: 0.70,
      primarySkill: Skill.analysis,
      skillCoefficient: 0.03,
      intuitionEffect: '技術的発見',
    ),
    ActionType.reportWrite: Action(
      type: ActionType.reportWrite,
      name: 'レポート作成',
      actionPoints: 2,
      cost: 0,
      prerequisite: '情報量≥3',
      obtainableInfo: ['総合評価', '将来予測'],
      baseSuccessRate: 1.0,
      primarySkill: Skill.negotiation,
      skillCoefficient: 0.0,
      intuitionEffect: '洞察力による質向上',
    ),
  };

  static Action get(ActionType type) {
    return actions[type]!;
  }

  static List<Action> getAll() {
    return actions.values.toList();
  }
} 