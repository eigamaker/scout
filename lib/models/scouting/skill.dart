enum Skill {
  exploration,    // 探索
  observation,    // 観察
  analysis,       // 分析
  insight,        // 洞察
  communication,  // コミュニケーション
  negotiation,    // 交渉
  stamina,        // 体力
  intuition,      // 直観
}

extension SkillExtension on Skill {
  String get displayName {
    switch (this) {
      case Skill.exploration:
        return '探索';
      case Skill.observation:
        return '観察';
      case Skill.analysis:
        return '分析';
      case Skill.insight:
        return '洞察';
      case Skill.communication:
        return 'コミュニケーション';
      case Skill.negotiation:
        return '交渉';
      case Skill.stamina:
        return '体力';
      case Skill.intuition:
        return '直観';
    }
  }

  String get description {
    switch (this) {
      case Skill.exploration:
        return '隠れた才能・注目選手の発見';
      case Skill.observation:
        return '実パフォ計測精度';
      case Skill.analysis:
        return 'データ統合と将来予測';
      case Skill.insight:
        return '潜在才能・怪我リスク察知';
      case Skill.communication:
        return '面談・信頼構築';
      case Skill.negotiation:
        return '利害調整・提案採用率';
      case Skill.stamina:
        return '遠征疲労耐性';
      case Skill.intuition:
        return '一瞬の判断・予感';
    }
  }
} 