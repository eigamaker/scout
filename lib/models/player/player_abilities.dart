// Technical（技術面）能力値
enum TechnicalAbility {
  // 打撃技術
  contact('ミート', 'ヒットを打つ能力'),
  power('パワー', '長打力、本塁打能力'),
  plateDiscipline('選球眼', 'ボールを見極める能力'),
  bunt('バント', 'バント技術'),
  oppositeFieldHitting('流し打ち', '逆方向への打撃'),
  pullHitting('プルヒッティング', '引っ張り打撃'),
  batControl('バットコントロール', 'ファールや変化球への対応力'),
  swingSpeed('スイングスピード', 'バットスイングの速度'),
  
  // 守備技術
  fielding('捕球', '守備の基本技術'),
  throwing('送球', '送球の正確性'),
  catcherAbility('捕手リード', '捕手としてのリード能力'),
  
  // 投手技術
  control('コントロール', '投球の制球力'),
  fastball('球速', '直球の球速'),
  breakingBall('変化球', '変化球の質'),
  pitchMovement('球種変化量', '各球種の変化量');

  const TechnicalAbility(this.displayName, this.description);
  final String displayName;
  final String description;
}

// Mental（メンタル面）能力値
enum MentalAbility {
  // 集中力・判断力
  concentration('集中力', '試合中の集中力'),
  anticipation('予測力', '守備時の飛んでくるボールの予測、打撃時の投手の球種予測など、様々な場面で状況を読む能力'),
  vision('視野', '広い視野での判断'),
  composure('冷静さ', 'プレッシャー下での冷静さ'),
  
  // 性格・精神面
  aggression('積極性', '積極的なプレー'),
  bravery('勇敢さ', '危険なプレーへの挑戦'),
  leadership('リーダーシップ', 'チームを引っ張る力'),
  workRate('勤勉さ', '練習への取り組み'),
  selfDiscipline('自己管理', '自己管理能力'),
  ambition('野心', '上昇志向'),
  
  // チームプレー
  teamwork('チームワーク', 'チームプレーへの貢献'),
  positioning('ポジショニング', '守備位置の判断'),
  pressureHandling('プレッシャー耐性', 'プレッシャーへの対応'),
  clutchAbility('勝負強さ', '重要な場面での活躍');

  const MentalAbility(this.displayName, this.description);
  final String displayName;
  final String description;
}

// Physical（フィジカル面）能力値
enum PhysicalAbility {
  // 運動能力
  acceleration('加速力', '瞬発力'),
  agility('敏捷性', '身のこなし'),
  balance('バランス', '体のバランス'),
  pace('走力', '走塁速度'),
  
  // 体力・筋力
  stamina('持久力', '体力の持続性'),
  strength('筋力', '筋力'),
  flexibility('柔軟性', '体の柔軟性'),
  jumpingReach('ジャンプ力', '跳躍力');

  const PhysicalAbility(this.displayName, this.description);
  final String displayName;
  final String description;
}

// 能力値カテゴリ
enum AbilityCategory {
  technical('技術面'),
  mental('メンタル面'),
  physical('フィジカル面');

  const AbilityCategory(this.displayName);
  final String displayName;
}

// 能力値の種類を統合
enum AbilityType {
  // Technical abilities
  contact(TechnicalAbility.contact, AbilityCategory.technical),
  power(TechnicalAbility.power, AbilityCategory.technical),
  plateDiscipline(TechnicalAbility.plateDiscipline, AbilityCategory.technical),
  bunt(TechnicalAbility.bunt, AbilityCategory.technical),
  oppositeFieldHitting(TechnicalAbility.oppositeFieldHitting, AbilityCategory.technical),
  pullHitting(TechnicalAbility.pullHitting, AbilityCategory.technical),
  batControl(TechnicalAbility.batControl, AbilityCategory.technical),
  swingSpeed(TechnicalAbility.swingSpeed, AbilityCategory.technical),
  fielding(TechnicalAbility.fielding, AbilityCategory.technical),
  throwing(TechnicalAbility.throwing, AbilityCategory.technical),
  catcherAbility(TechnicalAbility.catcherAbility, AbilityCategory.technical),
  control(TechnicalAbility.control, AbilityCategory.technical),
  fastball(TechnicalAbility.fastball, AbilityCategory.technical),
  breakingBall(TechnicalAbility.breakingBall, AbilityCategory.technical),
  pitchMovement(TechnicalAbility.pitchMovement, AbilityCategory.technical),
  
  // Mental abilities
  concentration(MentalAbility.concentration, AbilityCategory.mental),
  anticipation(MentalAbility.anticipation, AbilityCategory.mental),
  vision(MentalAbility.vision, AbilityCategory.mental),
  composure(MentalAbility.composure, AbilityCategory.mental),
  aggression(MentalAbility.aggression, AbilityCategory.mental),
  bravery(MentalAbility.bravery, AbilityCategory.mental),
  leadership(MentalAbility.leadership, AbilityCategory.mental),
  workRate(MentalAbility.workRate, AbilityCategory.mental),
  selfDiscipline(MentalAbility.selfDiscipline, AbilityCategory.mental),
  ambition(MentalAbility.ambition, AbilityCategory.mental),
  teamwork(MentalAbility.teamwork, AbilityCategory.mental),
  positioning(MentalAbility.positioning, AbilityCategory.mental),
  pressureHandling(MentalAbility.pressureHandling, AbilityCategory.mental),
  clutchAbility(MentalAbility.clutchAbility, AbilityCategory.mental),
  
  // Physical abilities
  acceleration(PhysicalAbility.acceleration, AbilityCategory.physical),
  agility(PhysicalAbility.agility, AbilityCategory.physical),
  balance(PhysicalAbility.balance, AbilityCategory.physical),
  pace(PhysicalAbility.pace, AbilityCategory.physical),
  stamina(PhysicalAbility.stamina, AbilityCategory.physical),
  strength(PhysicalAbility.strength, AbilityCategory.physical),
  flexibility(PhysicalAbility.flexibility, AbilityCategory.physical),
  jumpingReach(PhysicalAbility.jumpingReach, AbilityCategory.physical);

  const AbilityType(this.ability, this.category);
  final dynamic ability;
  final AbilityCategory category;
  
  String get displayName => ability.displayName;
  String get description => ability.description;
} 