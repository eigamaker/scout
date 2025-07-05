// 選手関連のデータモデル
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
  int getVisibleAbility(int scoutSkill) {
    final trueAbility = _trueTotalAbility;
    final range = _getVisibleAbilityRange(scoutSkill);
    final random = Random();
    
    // スカウトスキルが低いほどランダム要素が強くなる
    final accuracy = scoutSkill / 100.0;
    final randomFactor = (1.0 - accuracy) * range;
    
    final visibleAbility = trueAbility + (random.nextDouble() - 0.5) * randomFactor * 2;
    return visibleAbility.round().clamp(0, 100);
  }
  
  // 一般的な評価（世間の評価）- 現時点の能力値から自動算出、確率的ブレあり
  String getGeneralEvaluation() {
    final ability = _trueTotalAbility;
    final random = Random();
    
    // 評価のブレ（±10%の確率的変動）
    final evaluationVariance = (random.nextDouble() - 0.5) * 0.2; // -10%〜+10%
    final adjustedAbility = ability * (1.0 + evaluationVariance);
    
    if (adjustedAbility > 85) return 'S';
    if (adjustedAbility > 70) return 'A';
    if (adjustedAbility > 55) return 'B';
    if (adjustedAbility > 40) return 'C';
    return 'D';
  }
  
  // ポテンシャル評価（スカウトの目利きが活きる）
  String getPotentialEvaluation(int scoutSkill) {
    final currentAbility = _trueTotalAbility;
    final potential = peakAbility;
    final random = Random();
    
    // スカウトスキルが高いほど正確なポテンシャルが見える
    final skillAccuracy = scoutSkill / 100.0;
    
    // 現在の能力値とポテンシャルの関係を分析
    final growthPotential = potential - currentAbility;
    final growthRate = growthPotential / 100.0; // 成長余地の割合
    
    // スカウトスキルに基づくポテンシャル推定
    final estimatedPotential = currentAbility + (growthPotential * skillAccuracy);
    
    // ランダム要素（スカウトの勘）
    final randomFactor = (random.nextDouble() - 0.5) * (1.0 - skillAccuracy) * 30;
    final finalEstimate = estimatedPotential + randomFactor;
    
    // ポテンシャル評価の基準
    if (finalEstimate > 120) return '超一流級の可能性';
    if (finalEstimate > 110) return '一流級の可能性';
    if (finalEstimate > 100) return '有望な可能性';
    if (finalEstimate > 90) return '成長の可能性あり';
    if (finalEstimate > 80) return 'やや期待できる';
    return '限定的な可能性';
  }
  
  // ポテンシャルの曖昧な表現（従来のメソッドを更新）
  String getPotentialDescription() {
    // スカウトスキル50をデフォルトとして使用
    return getPotentialEvaluation(50);
  }
  
  // 選手を発掘する
  void discover(String scoutName) {
    if (!isDiscovered) {
      isDiscovered = true;
      discoveredAt = DateTime.now();
      discoveredBy = scoutName;
      
      // 発掘時に基本的な能力値を少し把握
      _improveBasicKnowledge();
    }
  }
  
  // 世間の注目を集める
  void makePubliclyKnown() {
    isPubliclyKnown = true;
    fame = (fame + 30).clamp(0, 100); // 知名度を上げる
  }
  
  // スカウトのお気に入りに設定
  void setAsFavorite() {
    isScoutFavorite = true;
  }
  
  // お気に入りを解除
  void removeFromFavorites() {
    isScoutFavorite = false;
  }
  
  // 能力値の把握度を向上させる
  void improveKnowledge(String abilityName, int improvement) {
    if (abilityKnowledge.containsKey(abilityName)) {
      abilityKnowledge[abilityName] = (abilityKnowledge[abilityName]! + improvement).clamp(0, 100);
    }
  }
  
  // 発掘時に基本的な能力値を少し把握
  void _improveBasicKnowledge() {
    if (isPitcher) {
      improveKnowledge('fastballVelo', 20);
      improveKnowledge('control', 15);
      improveKnowledge('stamina', 15);
      improveKnowledge('breakAvg', 15);
    } else {
      improveKnowledge('batPower', 15);
      improveKnowledge('batControl', 15);
      improveKnowledge('run', 20);
      improveKnowledge('field', 15);
      improveKnowledge('arm', 15);
    }
    improveKnowledge('mentalGrit', 10);
    improveKnowledge('growthRate', 10);
    improveKnowledge('peakAbility', 5);
  }
  
  // 把握度に基づく表示能力値を取得
  int getDisplayAbility(String abilityName, int trueValue) {
    final knowledge = abilityKnowledge[abilityName] ?? 0;
    final random = Random();
    
    if (knowledge >= 100) return trueValue; // 完全把握
    
    // 把握度に応じて誤差を計算
    final accuracy = knowledge / 100.0;
    final maxError = (1.0 - accuracy) * 30; // 最大±30の誤差
    
    final error = (random.nextDouble() - 0.5) * maxError * 2;
    return (trueValue + error).round().clamp(0, 100);
  }
  
  // 投手の表示能力値を取得
  int? getDisplayFastballVelo() {
    if (fastballVelo == null) return null;
    return getDisplayAbility('fastballVelo', fastballVelo!);
  }
  
  int? getDisplayControl() {
    if (control == null) return null;
    return getDisplayAbility('control', control!);
  }
  
  int? getDisplayStamina() {
    if (stamina == null) return null;
    return getDisplayAbility('stamina', stamina!);
  }
  
  int? getDisplayBreakAvg() {
    if (breakAvg == null) return null;
    return getDisplayAbility('breakAvg', breakAvg!);
  }
  
  // 野手の表示能力値を取得
  int? getDisplayBatPower() {
    if (batPower == null) return null;
    return getDisplayAbility('batPower', batPower!);
  }
  
  int? getDisplayBatControl() {
    if (batControl == null) return null;
    return getDisplayAbility('batControl', batControl!);
  }
  
  int? getDisplayRun() {
    if (run == null) return null;
    return getDisplayAbility('run', run!);
  }
  
  int? getDisplayField() {
    if (field == null) return null;
    return getDisplayAbility('field', field!);
  }
  
  int? getDisplayArm() {
    if (arm == null) return null;
    return getDisplayAbility('arm', arm!);
  }
  
  // 選手の状態を取得
  String getDiscoveryStatus() {
    if (isPubliclyKnown) return '世間注目';
    if (isScoutFavorite) return 'お気に入り';
    if (isDiscovered) return '発掘済み';
    return '未発掘';
  }
  
  // スカウトの個人評価を設定
  void setScoutEvaluation(String evaluation, String notes) {
    scoutEvaluation = evaluation;
    scoutNotes = notes;
  }
  
  // 投手の総合評価（一般的評価）
  String getPitcherEvaluation() {
    if (!isPitcher) return 'N/A';
    return getGeneralEvaluation();
  }
  
  // 野手の総合評価（一般的評価）
  String getBatterEvaluation() {
    if (isPitcher) return 'N/A';
    return getGeneralEvaluation();
  }
  
  // 入学時の知名度を計算（学校の知名度と個人能力の組み合わせ）
  void calculateInitialFame() {
    final ability = _trueTotalAbility;
    final evaluation = getGeneralEvaluation();
    
    // 学校の知名度を考慮（有名校ほど基本知名度が高い）
    final schoolFame = _getSchoolFame();
    
    // 能力値に基づく個人知名度
    int personalFame = 0;
    if (evaluation == 'S') personalFame = 60;
    else if (evaluation == 'A') personalFame = 40;
    else if (evaluation == 'B') personalFame = 20;
    else if (evaluation == 'C') personalFame = 10;
    else personalFame = 5;
    
    // 学年による調整（上級生ほど注目される）
    final gradeBonus = (grade - 1) * 5;
    
    // 投手の球速による追加知名度
    int veloBonus = 0;
    if (isPitcher && fastballVelo != null) {
      if (fastballVelo! >= 150) veloBonus = 15;
      else if (fastballVelo! >= 145) veloBonus = 10;
      else if (fastballVelo! >= 140) veloBonus = 5;
    }
    
    // ランダム要素（無名校から優秀な選手が現れる可能性）
    final random = Random();
    final randomFactor = random.nextDouble() * 20 - 10; // -10〜+10
    
    // 学校の知名度と個人能力を組み合わせ
    final baseFame = (schoolFame * 0.6 + personalFame * 0.4).round();
    fame = (baseFame + gradeBonus + veloBonus + randomFactor.round()).clamp(0, 100);
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
} 