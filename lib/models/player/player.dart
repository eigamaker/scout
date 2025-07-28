import 'dart:math';
import 'pitch.dart';
import 'achievement.dart';
import 'player_abilities.dart';

// 選手の種類
enum PlayerType { highSchool, college, social }

// 選手クラス
class Player {
  final String name;
  final String school;
  int grade; // 1年生、2年生、3年生（高校生の場合）
  final String position;
  final String personality;
  final int trustLevel; // 信頼度 0-100
  int fame; // 知名度 0-100
  bool isWatched; // スカウトが注目しているかどうか
  
  // 発掘状態管理
  bool isDiscovered; // 発掘済みかどうか
  bool isPubliclyKnown; // 世間から注目されているかどうか
  bool isScoutFavorite; // 自分が気に入っている選手かどうか
  DateTime? discoveredAt; // 発掘日時
  String? discoveredBy; // 発掘したスカウト（将来的に複数スカウト対応）
  int discoveredCount; // 発掘回数
  List<DateTime> scoutedDates; // 視察履歴
  
  // 能力値の把握度（0-100、100で完全把握）
  Map<String, int> abilityKnowledge; // 各能力値の把握度
  
  // 選手の種類と卒業後の年数
  PlayerType type;
  int yearsAfterGraduation; // 卒業後の年数（大学生・社会人用）
  
  // 投手能力値（投手のみ）
  int? fastballVelo; // 球速 110-170 km/h
  int? control; // 制球 0-100
  int? stamina; // スタミナ 0-100
  int? breakAvg; // 変化 0-100
  List<Pitch>? pitches; // 球種
  
  // 野手能力値（野手のみ）
  int? batPower; // パワー 0-100
  int? batControl; // バットコントロール 0-100
  int? run; // 走力 0-100
  int? field; // 守備 0-100
  int? arm; // 肩 0-100
  
  // 新しい能力値システム
  final Map<TechnicalAbility, int> technicalAbilities; // 技術面能力値
  final Map<MentalAbility, int> mentalAbilities; // メンタル面能力値
  final Map<PhysicalAbility, int> physicalAbilities; // フィジカル面能力値
  
  // 隠し能力値
  final double mentalGrit; // 精神力 -0.15〜+0.15
  final double growthRate; // 成長スピード 0.85-1.15
  final int peakAbility; // ポテンシャル 80-150
  final Map<String, int> positionFit; // ポジション適性
  final int talent; // 才能ランク 1-5
  final String growthType; // 成長タイプ
  final Map<String, int>? individualPotentials; // 個別能力値ポテンシャル
  final Map<TechnicalAbility, int>? technicalPotentials; // 技術面能力値ポテンシャル
  final Map<MentalAbility, int>? mentalPotentials; // メンタル面能力値ポテンシャル
  final Map<PhysicalAbility, int>? physicalPotentials; // フィジカル面能力値ポテンシャル
  
  // スカウトの評価（個人評価）
  String? scoutEvaluation; // スカウトの個人評価
  String? scoutNotes; // スカウトのメモ
  
  // 実績システム
  final List<Achievement> achievements; // 実績リスト
  final int totalFamePoints; // 総知名度ポイント
  
  Player({
    required this.name,
    required this.school,
    required this.grade,
    required this.position,
    required this.personality,
    this.trustLevel = 0,
    this.fame = 0,
    this.isWatched = false,
    this.isDiscovered = false,
    this.isPubliclyKnown = false,
    this.isScoutFavorite = false,
    this.discoveredAt,
    this.discoveredBy,
    this.discoveredCount = 0,
    List<DateTime>? scoutedDates,
    this.type = PlayerType.highSchool,
    this.yearsAfterGraduation = 0,
    this.fastballVelo,
    this.control,
    this.stamina,
    this.breakAvg,
    this.pitches,
    this.batPower,
    this.batControl,
    this.run,
    this.field,
    this.arm,
    Map<TechnicalAbility, int>? technicalAbilities,
    Map<MentalAbility, int>? mentalAbilities,
    Map<PhysicalAbility, int>? physicalAbilities,
    required this.mentalGrit,
    required this.growthRate,
    required this.peakAbility,
    required this.positionFit,
    required this.talent,
    required this.growthType,
          this.individualPotentials,
      Map<TechnicalAbility, int>? technicalPotentials,
      Map<MentalAbility, int>? mentalPotentials,
      Map<PhysicalAbility, int>? physicalPotentials,
    this.scoutEvaluation,
    this.scoutNotes,
    Map<String, int>? abilityKnowledge,
    List<Achievement>? achievements,
  }) :
    scoutedDates = scoutedDates ?? [],
    abilityKnowledge = abilityKnowledge ?? _initializeAbilityKnowledge(),
    achievements = achievements ?? [],
    technicalAbilities = technicalAbilities ?? _initializeTechnicalAbilities(),
    mentalAbilities = mentalAbilities ?? _initializeMentalAbilities(),
    physicalAbilities = physicalAbilities ?? _initializePhysicalAbilities(),
    technicalPotentials = technicalPotentials ?? _initializeTechnicalPotentials(),
    mentalPotentials = mentalPotentials ?? _initializeMentalPotentials(),
    physicalPotentials = physicalPotentials ?? _initializePhysicalPotentials(),
    totalFamePoints = (achievements ?? []).fold(0, (sum, achievement) => sum + achievement.famePoints);
  
  // 能力値把握度の初期化
  static Map<String, int> _initializeAbilityKnowledge() {
    return {
      'fastballVelo': 0,
      'control': 0,
      'stamina': 0,
      'breakAvg': 0,
      'batPower': 0,
      'batControl': 0,
      'run': 0,
      'field': 0,
      'arm': 0,
      'mentalGrit': 0,
      'growthRate': 0,
      'peakAbility': 0,
    };
  }
  
  // 技術面能力値の初期化
  static Map<TechnicalAbility, int> _initializeTechnicalAbilities() {
    return {
      for (var ability in TechnicalAbility.values)
        ability: 25, // 基本値25
    };
  }
  
  // メンタル面能力値の初期化
  static Map<MentalAbility, int> _initializeMentalAbilities() {
    return {
      for (var ability in MentalAbility.values)
        ability: 25, // 基本値25
    };
  }
  
  // フィジカル面能力値の初期化
  static Map<PhysicalAbility, int> _initializePhysicalAbilities() {
    return {
      for (var ability in PhysicalAbility.values)
        ability: 25, // 基本値25
    };
  }
  
  // 技術面能力値ポテンシャルの初期化
  static Map<TechnicalAbility, int> _initializeTechnicalPotentials() {
    return {
      for (var ability in TechnicalAbility.values)
        ability: 50, // 基本ポテンシャル50
    };
  }
  
  // メンタル面能力値ポテンシャルの初期化
  static Map<MentalAbility, int> _initializeMentalPotentials() {
    return {
      for (var ability in MentalAbility.values)
        ability: 50, // 基本ポテンシャル50
    };
  }
  
  // フィジカル面能力値ポテンシャルの初期化
  static Map<PhysicalAbility, int> _initializePhysicalPotentials() {
    return {
      for (var ability in PhysicalAbility.values)
        ability: 50, // 基本ポテンシャル50
    };
  }
  
  // 投手かどうか
  bool get isPitcher => position == '投手';
  
  // 高校生かどうか
  bool get isHighSchoolStudent => type == PlayerType.highSchool;
  
  // 大学生かどうか
  bool get isCollegeStudent => type == PlayerType.college;
  
  // 社会人かどうか
  bool get isSocialPlayer => type == PlayerType.social;
  
  // ドラフト対象かどうか
  bool get isDraftEligible {
    if (isHighSchoolStudent) {
      return grade == 3; // 高校3年生
    } else if (isCollegeStudent) {
      return yearsAfterGraduation == 3; // 大学4年生相当
    } else if (isSocialPlayer) {
      return yearsAfterGraduation >= 1; // 社会人2年目以降
    }
    return false;
  }
  
  // 球速スコア（0-100に換算）
  int get veloScore {
    if (fastballVelo == null) return 0;
    return ((fastballVelo! - 110) * 1.6).round().clamp(0, 100);
  }
  
  // 新しい能力値システムのゲッター
  int getTechnicalAbility(TechnicalAbility ability) {
    return technicalAbilities[ability] ?? 25;
  }
  
  // 球速を実際のkm/hに変換（新しい能力値システム用）
  int getFastballVelocityKmh() {
    final fastballAbility = getTechnicalAbility(TechnicalAbility.fastball);
    // 100段階の能力値を125-155km/hの範囲に変換
    return 125 + ((fastballAbility - 25) * 30 / 75).round().clamp(0, 30);
  }
  
  int getMentalAbility(MentalAbility ability) {
    return mentalAbilities[ability] ?? 25;
  }
  
  int getPhysicalAbility(PhysicalAbility ability) {
    return physicalAbilities[ability] ?? 25;
  }
  
  // 能力値の平均を取得
  double getAverageTechnicalAbility() {
    if (technicalAbilities.isEmpty) return 25.0;
    return technicalAbilities.values.reduce((a, b) => a + b) / technicalAbilities.length;
  }
  
  double getAverageMentalAbility() {
    if (mentalAbilities.isEmpty) return 25.0;
    return mentalAbilities.values.reduce((a, b) => a + b) / mentalAbilities.length;
  }
  
  double getAveragePhysicalAbility() {
    if (physicalAbilities.isEmpty) return 25.0;
    return physicalAbilities.values.reduce((a, b) => a + b) / physicalAbilities.length;
  }
  
  // 真の総合能力値を計算（0-100）
  int get _trueTotalAbility {
    // 投手能力値の計算
    final veloScore = this.veloScore;
    final controlScore = control ?? 0;
    final staminaScore = stamina ?? 0;
    final breakScore = breakAvg ?? 0;
    final pitcherScore = ((veloScore + controlScore + staminaScore + breakScore) / 4).round();
    
    // 野手能力値の計算
    final powerScore = batPower ?? 0;
    final batControlScore = batControl ?? 0;
    final runScore = run ?? 0;
    final fieldScore = field ?? 0;
    final armScore = arm ?? 0;
    final batterScore = ((powerScore + batControlScore + runScore + fieldScore + armScore) / 5).round();
    
    // 投手と野手の能力値を平均して総合能力値を算出
    return ((pitcherScore + batterScore) / 2).round();
  }
  
  // スカウトスキルに基づく能力値の表示範囲を取得
  int _getVisibleAbilityRange(int scoutSkill) {
    // スカウトスキルが高いほど正確な能力値が見える
    if (scoutSkill >= 80) return 5; // ±5の誤差
    if (scoutSkill >= 60) return 10; // ±10の誤差
    if (scoutSkill >= 40) return 20; // ±20の誤差
    if (scoutSkill >= 20) return 30; // ±30の誤差
    return 50; // ±50の誤差（ほぼ見えない）
  }
  
  // 知名度レベルを取得
  int get fameLevel {
    if (totalFamePoints >= 100) return 5; // 超有名
    if (totalFamePoints >= 80) return 4;  // 有名
    if (totalFamePoints >= 50) return 3;  // 知られている
    if (totalFamePoints >= 20) return 2;  // 少し知られている
    return 1; // 無名
  }

  // 知名度レベルの表示名
  String get fameLevelName {
    switch (fameLevel) {
      case 5: return '超有名';
      case 4: return '有名';
      case 3: return '知られている';
      case 2: return '少し知られている';
      case 1: return '無名';
      default: return '無名';
    }
  }

  // 知名度に基づく初期情報の表示レベルを取得
  int get _initialKnowledgeLevel {
    switch (fameLevel) {
      case 5: return 80; // 超有名: 80%の精度で情報把握
      case 4: return 60; // 有名: 60%の精度で情報把握
      case 3: return 40; // 知られている: 40%の精度で情報把握
      case 2: return 20; // 少し知られている: 20%の精度で情報把握
      case 1: return 0;  // 無名: 情報なし
      default: return 0;
    }
  }

  // スカウトスキルに基づく表示能力値を取得
  int getVisibleAbility(String abilityName, int scoutSkill) {
    final trueValue = _getAbilityValue(abilityName);
    if (trueValue == null) return 0;
    
    // 知名度による初期情報とスカウトスキルを組み合わせ
    final baseKnowledge = _initialKnowledgeLevel;
    final scoutKnowledge = scoutSkill;
    final combinedKnowledge = (baseKnowledge + scoutKnowledge) / 2;
    
    final range = _getVisibleAbilityRange(combinedKnowledge.round());
    final error = Random().nextInt(range * 2 + 1) - range;
    return (trueValue + error).clamp(0, 100);
  }
  
  // 真の能力値を取得
  int? _getAbilityValue(String abilityName) {
    switch (abilityName) {
      case 'fastballVelo':
        return fastballVelo != null ? veloScore : null;
      case 'control':
        return control;
      case 'stamina':
        return stamina;
      case 'breakAvg':
        return breakAvg;
      case 'batPower':
        return batPower;
      case 'batControl':
        return batControl;
      case 'run':
        return run;
      case 'field':
        return field;
      case 'arm':
        return arm;
      default:
        return null;
    }
  }
  
  // 投手評価を取得（スカウトスキルに基づく）
  int getPitcherEvaluation(int scoutSkill) {
    final veloScore = getVisibleAbility('fastballVelo', scoutSkill);
    final controlScore = getVisibleAbility('control', scoutSkill);
    final staminaScore = getVisibleAbility('stamina', scoutSkill);
    final breakScore = getVisibleAbility('breakAvg', scoutSkill);
    
    return ((veloScore + controlScore + staminaScore + breakScore) / 4).round();
  }
  
  // 野手評価を取得（スカウトスキルに基づく）
  int getBatterEvaluation(int scoutSkill) {
    final powerScore = getVisibleAbility('batPower', scoutSkill);
    final controlScore = getVisibleAbility('batControl', scoutSkill);
    final runScore = getVisibleAbility('run', scoutSkill);
    final fieldScore = getVisibleAbility('field', scoutSkill);
    final armScore = getVisibleAbility('arm', scoutSkill);
    
    return ((powerScore + controlScore + runScore + fieldScore + armScore) / 5).round();
  }
  
  // 総合評価を取得
  int getTotalEvaluation(int scoutSkill) {
    final pitcherEval = getPitcherEvaluation(scoutSkill);
    final batterEval = getBatterEvaluation(scoutSkill);
    return ((pitcherEval + batterEval) / 2).round();
  }
  
  // 知名度を計算
  void calculateInitialFame() {
    final baseFame = _getBaseFame();
    final schoolFame = _getSchoolFame();
    final performanceFame = _getPerformanceFame();
    
    fame = ((baseFame + schoolFame + performanceFame) / 3).round().clamp(0, 100);
  }
  
  // 基本知名度を計算
  int _getBaseFame() {
    final totalAbility = _trueTotalAbility;
    if (totalAbility >= 90) return 80;
    if (totalAbility >= 80) return 60;
    if (totalAbility >= 70) return 40;
    if (totalAbility >= 60) return 20;
    return 10;
  }
  
  // 学校の知名度を取得
  int _getSchoolFame() {
    // 実際の実装では学校クラスに知名度フィールドを追加する
    // ここでは学校名から簡易的に計算
    final schoolNames = ['甲子園高校', '野球名門校', '強豪校', '中堅校', '弱小校'];
    final schoolFameMap = {
      '甲子園高校': 90,
      '野球名門校': 70,
      '強豪校': 50,
      '中堅校': 30,
      '弱小校': 10,
    };
    
    // 学校名に含まれるキーワードで判定
    for (final key in schoolFameMap.keys) {
      if (school.contains(key)) {
        return schoolFameMap[key]!;
      }
    }
    
    // デフォルトは中堅校レベル
    return 30;
  }
  
  // 成績による知名度を計算
  int _getPerformanceFame() {
    // 実際の成績データに基づいて計算
    // ここでは簡易的に能力値から推定
    return _getBaseFame();
  }
  
  // 選手の成長
  void grow() {
    final growthChance = (mentalGrit + 0.15) * growthRate * 0.1;
    
    if (Random().nextDouble() < growthChance) {
      if (isPitcher) {
        _growPitcher();
      } else {
        _growBatter();
      }
      
      // 成長に伴う知名度上昇
      if (fame < 100) {
        fame = (fame + Random().nextInt(3) + 1).clamp(0, 100);
      }
    }
  }
  
  void _growPitcher() {
    if (control != null && control! < peakAbility) {
      control = (control! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (stamina != null && stamina! < peakAbility) {
      stamina = (stamina! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (breakAvg != null && breakAvg! < peakAbility) {
      breakAvg = (breakAvg! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    // 球速は高校生では成長しにくい
    if (fastballVelo != null && Random().nextDouble() < 0.1) {
      fastballVelo = (fastballVelo! + Random().nextInt(2) + 1).clamp(110, 155);
    }
  }
  
  void _growBatter() {
    if (batPower != null && batPower! < peakAbility) {
      batPower = (batPower! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (batControl != null && batControl! < peakAbility) {
      batControl = (batControl! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (run != null && run! < peakAbility) {
      run = (run! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (field != null && field! < peakAbility) {
      field = (field! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (arm != null && arm! < peakAbility) {
      arm = (arm! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'school': school,
    'grade': grade,
    'position': position,
    'personality': personality,
    'trustLevel': trustLevel,
    'fame': fame,
    'isWatched': isWatched,
    'isDiscovered': isDiscovered,
    'isPubliclyKnown': isPubliclyKnown,
    'isScoutFavorite': isScoutFavorite,
    'discoveredAt': discoveredAt?.toIso8601String(),
    'discoveredBy': discoveredBy,
    'discoveredCount': discoveredCount,
    'scoutedDates': scoutedDates.map((d) => d.toIso8601String()).toList(),
    'abilityKnowledge': abilityKnowledge,
    'type': type.index,
    'yearsAfterGraduation': yearsAfterGraduation,
    'fastballVelo': fastballVelo,
    'control': control,
    'stamina': stamina,
    'breakAvg': breakAvg,
    'pitches': pitches?.map((p) => p.toJson()).toList(),
    'batPower': batPower,
    'batControl': batControl,
    'run': run,
    'field': field,
    'arm': arm,
    'mentalGrit': mentalGrit,
    'growthRate': growthRate,
    'peakAbility': peakAbility,
    'positionFit': positionFit,
    'talent': talent,
    'growthType': growthType,
    'individualPotentials': individualPotentials,
    'scoutEvaluation': scoutEvaluation,
    'scoutNotes': scoutNotes,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    name: json['name'],
    school: json['school'],
    grade: json['grade'],
    position: json['position'],
    personality: json['personality'],
    trustLevel: json['trustLevel'] ?? 0,
    fame: json['fame'] ?? 0,
    isWatched: json['isWatched'] ?? false,
    isDiscovered: json['isDiscovered'] ?? false,
    isPubliclyKnown: json['isPubliclyKnown'] ?? false,
    isScoutFavorite: json['isScoutFavorite'] ?? false,
    discoveredAt: json['discoveredAt'] != null ? DateTime.parse(json['discoveredAt']) : null,
    discoveredBy: json['discoveredBy'],
    discoveredCount: json['discoveredCount'] ?? 0,
    scoutedDates: json['scoutedDates'] != null 
      ? (json['scoutedDates'] as List).map((d) => DateTime.parse(d)).toList()
      : [],
    abilityKnowledge: json['abilityKnowledge'] != null 
      ? Map<String, int>.from(json['abilityKnowledge'])
      : null,
    type: PlayerType.values[json['type'] ?? 0],
    yearsAfterGraduation: json['yearsAfterGraduation'] ?? 0,
    fastballVelo: json['fastballVelo'],
    control: json['control'],
    stamina: json['stamina'],
    breakAvg: json['breakAvg'],
    pitches: json['pitches'] != null 
      ? (json['pitches'] as List).map((p) => Pitch.fromJson(p)).toList()
      : null,
    batPower: json['batPower'],
    batControl: json['batControl'],
    run: json['run'],
    field: json['field'],
    arm: json['arm'],
    mentalGrit: (json['mentalGrit'] as num).toDouble(),
    growthRate: (json['growthRate'] as num).toDouble(),
    peakAbility: json['peakAbility'],
    positionFit: Map<String, int>.from(json['positionFit']),
    talent: json['talent'],
    growthType: json['growthType'],
    individualPotentials: json['individualPotentials'] != null
      ? Map<String, int>.from(json['individualPotentials'])
      : null,
    scoutEvaluation: json['scoutEvaluation'],
    scoutNotes: json['scoutNotes'],
  );

  Player copyWith({
    String? name,
    String? school,
    int? grade,
    String? position,
    String? personality,
    int? trustLevel,
    int? fame,
    bool? isWatched,
    bool? isDiscovered,
    bool? isPubliclyKnown,
    bool? isScoutFavorite,
    DateTime? discoveredAt,
    String? discoveredBy,
    int? discoveredCount,
    List<DateTime>? scoutedDates,
    Map<String, int>? abilityKnowledge,
    PlayerType? type,
    int? yearsAfterGraduation,
    int? fastballVelo,
    int? control,
    int? stamina,
    int? breakAvg,
    List<Pitch>? pitches,
    int? batPower,
    int? batControl,
    int? run,
    int? field,
    int? arm,
    double? mentalGrit,
    double? growthRate,
    int? peakAbility,
    Map<String, int>? positionFit,
    int? talent,
    String? growthType,
    Map<String, int>? individualPotentials,
    String? scoutEvaluation,
    String? scoutNotes,
  }) {
    return Player(
      name: name ?? this.name,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      position: position ?? this.position,
      personality: personality ?? this.personality,
      trustLevel: trustLevel ?? this.trustLevel,
      fame: fame ?? this.fame,
      isWatched: isWatched ?? this.isWatched,
      isDiscovered: isDiscovered ?? this.isDiscovered,
      isPubliclyKnown: isPubliclyKnown ?? this.isPubliclyKnown,
      isScoutFavorite: isScoutFavorite ?? this.isScoutFavorite,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      discoveredBy: discoveredBy ?? this.discoveredBy,
      discoveredCount: discoveredCount ?? this.discoveredCount,
      scoutedDates: scoutedDates ?? this.scoutedDates,
      abilityKnowledge: abilityKnowledge ?? Map<String, int>.from(this.abilityKnowledge),
      type: type ?? this.type,
      yearsAfterGraduation: yearsAfterGraduation ?? this.yearsAfterGraduation,
      fastballVelo: fastballVelo ?? this.fastballVelo,
      control: control ?? this.control,
      stamina: stamina ?? this.stamina,
      breakAvg: breakAvg ?? this.breakAvg,
      pitches: pitches ?? this.pitches,
      batPower: batPower ?? this.batPower,
      batControl: batControl ?? this.batControl,
      run: run ?? this.run,
      field: field ?? this.field,
      arm: arm ?? this.arm,
      mentalGrit: mentalGrit ?? this.mentalGrit,
      growthRate: growthRate ?? this.growthRate,
      peakAbility: peakAbility ?? this.peakAbility,
      positionFit: positionFit ?? Map<String, int>.from(this.positionFit),
      talent: talent ?? this.talent,
      growthType: growthType ?? this.growthType,
      individualPotentials: individualPotentials ?? this.individualPotentials,
      scoutEvaluation: scoutEvaluation ?? this.scoutEvaluation,
      scoutNotes: scoutNotes ?? this.scoutNotes,
    );
  }
} 