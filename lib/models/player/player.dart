import 'dart:math';
import 'pitch.dart';

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
  
  // 隠し能力値
  final double mentalGrit; // 精神力 -0.15〜+0.15
  final double growthRate; // 成長スピード 0.85-1.15
  final int peakAbility; // ポテンシャル 80-150
  final Map<String, int> positionFit; // ポジション適性
  
  // スカウトの評価（個人評価）
  String? scoutEvaluation; // スカウトの個人評価
  String? scoutNotes; // スカウトのメモ
  
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
    required this.mentalGrit,
    required this.growthRate,
    required this.peakAbility,
    required this.positionFit,
    this.scoutEvaluation,
    this.scoutNotes,
    Map<String, int>? abilityKnowledge,
  }) : abilityKnowledge = abilityKnowledge ?? _initializeAbilityKnowledge();
  
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
  
  // 投手の球速スコア（0-100に換算）
  int get veloScore {
    if (!isPitcher || fastballVelo == null) return 0;
    return ((fastballVelo! - 110) * 1.6).round().clamp(0, 100);
  }
  
  // 真の総合能力値を計算（0-100）
  int get _trueTotalAbility {
    if (isPitcher) {
      final veloScore = this.veloScore;
      final controlScore = control ?? 0;
      final staminaScore = stamina ?? 0;
      final breakScore = breakAvg ?? 0;
      return ((veloScore + controlScore + staminaScore + breakScore) / 4).round();
    } else {
      final powerScore = batPower ?? 0;
      final controlScore = batControl ?? 0;
      final runScore = run ?? 0;
      final fieldScore = field ?? 0;
      final armScore = arm ?? 0;
      return ((powerScore + controlScore + runScore + fieldScore + armScore) / 5).round();
    }
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
  
  // スカウトスキルに基づく表示能力値を取得
  int getVisibleAbility(String abilityName, int scoutSkill) {
    final trueValue = _getAbilityValue(abilityName);
    if (trueValue == null) return 0;
    
    final range = _getVisibleAbilityRange(scoutSkill);
    final error = Random().nextInt(range * 2 + 1) - range;
    return (trueValue + error).clamp(0, 100);
  }
  
  // 真の能力値を取得
  int? _getAbilityValue(String abilityName) {
    switch (abilityName) {
      case 'fastballVelo':
        return isPitcher ? veloScore : null;
      case 'control':
        return control;
      case 'stamina':
        return stamina;
      case 'breakAvg':
        return breakAvg;
      case 'batPower':
        return isPitcher ? null : batPower;
      case 'batControl':
        return isPitcher ? null : batControl;
      case 'run':
        return isPitcher ? null : run;
      case 'field':
        return isPitcher ? null : field;
      case 'arm':
        return isPitcher ? null : arm;
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
    if (isPitcher) {
      return getPitcherEvaluation(scoutSkill);
    } else {
      return getBatterEvaluation(scoutSkill);
    }
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
      scoutEvaluation: scoutEvaluation ?? this.scoutEvaluation,
      scoutNotes: scoutNotes ?? this.scoutNotes,
    );
  }
} 