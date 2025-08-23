import 'dart:math';
import 'package:flutter/material.dart';
import 'pitch.dart';
import 'achievement.dart';
import 'player_abilities.dart';

// 選手の種類
enum PlayerType { highSchool, college, social }

// 選手の分類（UI表示用）
enum PlayerCategory {
  favorite,      // お気に入り選手（個人的に気に入っている）
  discovered,    // 発掘済み選手（視察で発掘・分析済み）
  famous,        // 注目選手（知名度が高く世間に知られている）
  graduated,     // 卒業生（卒業した選手）
  unknown,       // 未発掘選手（視察していない）
}

// 選手クラス
class Player {
  final int? id; // データベースのID
  final String name;
  final String school;
  int grade; // 1年生、2年生、3年生（高校生の場合）
  int age; // 年齢（15-17歳）
  final String position;
  String personality; // 性格（インタビューで判明）
  final int trustLevel; // 信頼度 0-100
  int mentalStrength; // 精神力 0-100（インタビューで判明）
  String? motivation; // 動機・目標（インタビューで判明）
  int fame; // 知名度 0-100
  bool isWatched; // スカウトが注目しているかどうか
  
  // 発掘状態管理
  bool isDiscovered; // 発掘済みかどうか
  bool isPubliclyKnown; // 世間から注目されているかどうか
  bool isScoutFavorite; // 自分が気に入っている選手かどうか
  String? discoveredBy; // 発掘したスカウト（将来的に複数スカウト対応）
  List<DateTime> scoutedDates; // 視察履歴
  
  // 能力値の把握度（0-100、100で完全把握）
  Map<String, int> abilityKnowledge; // 各能力値の把握度
  
  // 選手の種類と卒業後の年数
  PlayerType type;
  int yearsAfterGraduation; // 卒業後の年数（大学生・社会人用）
  
  // 卒業状態管理
  bool isGraduated; // 卒業済みかどうか
  DateTime? graduatedAt; // 卒業日
  
  // 引退状態管理
  bool isRetired; // 引退済みかどうか
  DateTime? retiredAt; // 引退日
  
  // プロ野球選手状態管理
  bool isDrafted; // プロ野球選手かどうか
  String? professionalTeamId; // 所属プロ野球団ID
  
  // 球種（投手のみ）
  List<Pitch>? pitches;
  
  // 能力値システム
  final Map<TechnicalAbility, int> technicalAbilities; // 技術面能力値
  final Map<MentalAbility, int> mentalAbilities; // メンタル面能力値
  final Map<PhysicalAbility, int> physicalAbilities; // フィジカル面能力値
  
  // 追加された能力値
  final int motivationAbility; // 動機・目標（能力値）
  final int pressureAbility; // プレッシャー耐性（能力値）
  final int adaptabilityAbility; // 適応力（能力値）
  final int consistencyAbility; // 安定性（能力値）
  final int clutchAbility; // 勝負強さ（能力値）
  final int workEthicAbility; // 仕事への取り組み（能力値）
  
  // 総合能力値
  final int overall; // 総合能力値
  final int technical; // 技術面総合
  final int physical; // フィジカル面総合
  final int mental; // メンタル面総合
  
  // スカウト分析データ（UIで表示される能力値）
  final Map<String, int>? scoutAnalysisData; // スカウトが分析した能力値
  
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
  
  // デフォルト選手フラグ
  final bool isDefaultPlayer; // デフォルト選手かどうか（成長・卒業処理をスキップ）
  
  // 実績システム
  final List<Achievement> achievements; // 実績リスト
  final int totalFamePoints; // 総知名度ポイント
  
  Player({
    this.id,
    required this.name,
    required this.school,
    required this.grade,
    int? age,
    required this.position,
    required this.personality,
    this.trustLevel = 0,
    this.mentalStrength = 0,
    this.fame = 0,
    this.isWatched = false,
    this.isDiscovered = false,
    this.isPubliclyKnown = false,
    this.isScoutFavorite = false,
    this.discoveredBy,
    List<DateTime>? scoutedDates,
    this.type = PlayerType.highSchool,
    this.yearsAfterGraduation = 0,
    this.isGraduated = false,
    this.graduatedAt,
    this.isRetired = false,
    this.retiredAt,
    this.isDrafted = false,
    this.professionalTeamId,
    this.pitches,
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
    this.scoutAnalysisData,
    this.isDefaultPlayer = false,
    this.motivationAbility = 50,
    this.pressureAbility = 50,
    this.adaptabilityAbility = 50,
    this.consistencyAbility = 50,
    this.clutchAbility = 50,
    this.workEthicAbility = 50,
    this.overall = 50,
    this.technical = 50,
    this.physical = 50,
    this.mental = 50,
  }) :
    age = age ?? (type == PlayerType.highSchool ? (15 + (grade - 1)) : 18), // 高校生は学年から年齢を計算、プロ選手は18歳以上
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
  
  // メンタル面能力値の初期化（データベースに存在するカラムのみ）
  static Map<MentalAbility, int> _initializeMentalAbilities() {
    return {
      // データベースに存在するカラムのみ
      MentalAbility.concentration: 25,
      MentalAbility.anticipation: 25,
      MentalAbility.vision: 25,
      MentalAbility.composure: 25,
      MentalAbility.aggression: 25,
      MentalAbility.bravery: 25,
      MentalAbility.leadership: 25,
      MentalAbility.workRate: 25,
      MentalAbility.selfDiscipline: 25,
      MentalAbility.ambition: 25,
      MentalAbility.teamwork: 25,
      MentalAbility.positioning: 25,
      MentalAbility.pressureHandling: 25,
      MentalAbility.clutchAbility: 25,
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
  
  // メンタル面能力値ポテンシャルの初期化（データベースに存在するカラムのみ）
  static Map<MentalAbility, int> _initializeMentalPotentials() {
    return {
      // データベースに存在するカラムのみ
      MentalAbility.concentration: 50,
      MentalAbility.anticipation: 50,
      MentalAbility.vision: 50,
      MentalAbility.composure: 50,
      MentalAbility.aggression: 50,
      MentalAbility.bravery: 50,
      MentalAbility.leadership: 50,
      MentalAbility.workRate: 50,
      MentalAbility.selfDiscipline: 50,
      MentalAbility.ambition: 50,
      MentalAbility.teamwork: 50,
      MentalAbility.positioning: 50,
      MentalAbility.pressureHandling: 50,
      MentalAbility.clutchAbility: 50,
    };
  }
  
  // フィジカル面能力値ポテンシャルの初期化
  static Map<PhysicalAbility, int> _initializePhysicalPotentials() {
    return {
      for (var ability in PhysicalAbility.values)
        ability: 50, // 基本ポテンシャル50
    };
  }

  // 有効なメンタル能力値かどうかを判定
  static bool _isValidMentalAbility(String abilityName) {
    return [
      'concentration',
      'anticipation',
      'vision',
      'composure',
      'aggression',
      'bravery',
      'leadership',
      'workRate',
      'selfDiscipline',
      'ambition',
      'teamwork',
      'positioning',
      'pressureHandling',
      'clutchAbility',
    ].contains(abilityName);
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

  // 選手の分類を取得（UI表示用）- 単一カテゴリ（後方互換性のため）
  PlayerCategory get category {
    return _calculateCategory();
  }
  
  // 選手が属する全てのカテゴリを取得（UI表示用）
  List<PlayerCategory> get allCategories {
    final categories = <PlayerCategory>[];
    
    // お気に入りの場合は必ず含める
    if (isScoutFavorite) {
      categories.add(PlayerCategory.favorite);
    }
    
    // 注目選手の場合は必ず含める
    if (isPubliclyKnown) {
      categories.add(PlayerCategory.famous);
    }
    
    // 発掘済みの場合は必ず含める（isDiscoveredフラグまたはisPubliclyKnownフラグがtrueの場合）
    if (isDiscovered || isPubliclyKnown) {
      categories.add(PlayerCategory.discovered);
    }
    
    // 卒業生の場合は必ず含める
    if (isGraduated) {
      categories.add(PlayerCategory.graduated);
    }
    
    // どのカテゴリにも属していない場合は未発掘
    if (categories.isEmpty) {
      categories.add(PlayerCategory.unknown);
    }
    
    return categories;
  }
  
  PlayerCategory _calculateCategory() {
    if (isScoutFavorite) {
      return PlayerCategory.favorite;
    } else if (isPubliclyKnown) {
      return PlayerCategory.famous; // isPubliclyKnownフラグを最優先（注目選手として固定）
    } else if (isDiscovered) {
      return PlayerCategory.discovered;
    } else {
      return PlayerCategory.unknown;
    }
  }

  // 分類名を取得
  String get categoryName {
    switch (category) {
      case PlayerCategory.favorite:
        return 'お気に入り';
      case PlayerCategory.discovered:
        return '発掘済み';
      case PlayerCategory.famous:
        return '注目選手';
      case PlayerCategory.graduated:
        return '卒業生';
      case PlayerCategory.unknown:
        return '未発掘';
    }
  }

  // 分類の説明を取得
  String get categoryDescription {
    switch (category) {
      case PlayerCategory.favorite:
        return '個人的に気に入っている選手';
      case PlayerCategory.discovered:
        return '視察で発掘・分析済みの選手';
      case PlayerCategory.famous:
        return '知名度が高く世間に知られている選手';
      case PlayerCategory.graduated:
        return '卒業した選手';
      case PlayerCategory.unknown:
        return '視察していない未発掘選手';
    }
  }

  // 分類の色を取得
  Color get categoryColor {
    switch (category) {
      case PlayerCategory.favorite:
        return Colors.red;
      case PlayerCategory.discovered:
        return Colors.blue;
      case PlayerCategory.famous:
        return Colors.orange;
      case PlayerCategory.graduated:
        return Colors.purple;
      case PlayerCategory.unknown:
        return Colors.grey;
    }
  }
  
  // 球速スコア（0-100に換算）
  int get veloScore {
    final fastballAbility = getTechnicalAbility(TechnicalAbility.fastball);
    // 高校生の場合はそのまま、大学生・社会人の場合は100を超える部分を調整
    if (isHighSchoolStudent) {
      return fastballAbility;
    } else {
      // 大学生・社会人の場合、100を超える部分を100に制限
      return fastballAbility.clamp(25, 100);
    }
  }
  
  // 能力値システムのゲッター
  int getTechnicalAbility(TechnicalAbility ability) {
    return technicalAbilities[ability] ?? 25;
  }
  
  // 球速を実際のkm/hに変換（全選手共通の計算式）
  int getFastballVelocityKmh() {
    final fastballAbility = getTechnicalAbility(TechnicalAbility.fastball);
    
    // 全選手共通の計算式（能力値25-150 → 球速125-165km/h）
    if (fastballAbility <= 100) {
      // 100以下: 125-155km/h（高校生レベル）
      return 125 + ((fastballAbility - 25) * 30 / 75).round();
    } else {
      // 100超: 155-165km/h（プロ選手レベル）
      return 155 + ((fastballAbility - 100) * 10 / 50).round();
    }
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
  int get trueTotalAbility {
    // 能力値システムに基づく総合能力値計算
    final technicalAvg = getAverageTechnicalAbility();
    final mentalAvg = getAverageMentalAbility();
    final physicalAvg = getAveragePhysicalAbility();
    
    return ((technicalAvg + mentalAvg + physicalAvg) / 3).round();
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
  
  // 真の能力値を取得（能力値システム）
  int? _getAbilityValue(String abilityName) {
    switch (abilityName) {
      case 'fastballVelo':
        return veloScore;
      case 'control':
        return getTechnicalAbility(TechnicalAbility.control);
      case 'stamina':
        return getPhysicalAbility(PhysicalAbility.stamina);
      case 'breakAvg':
        return getTechnicalAbility(TechnicalAbility.breakingBall);
      case 'batPower':
        return getTechnicalAbility(TechnicalAbility.power);
      case 'batControl':
        return getTechnicalAbility(TechnicalAbility.batControl);
      case 'run':
        return getPhysicalAbility(PhysicalAbility.pace);
      case 'field':
        return getTechnicalAbility(TechnicalAbility.fielding);
      case 'arm':
        return getTechnicalAbility(TechnicalAbility.throwing);
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
  
  // 知名度を計算（改善版）
  void calculateInitialFame() {
    final baseFame = _getBaseFame();
    final schoolFame = _getSchoolFame();
    final performanceFame = _getPerformanceFame();
    final achievementFame = _getAchievementFame();
    final gradeFame = _getGradeFame();
    
    // 重み付け計算（能力40%、学校30%、実績20%、学年10%）
    final weightedFame = (baseFame * 0.4 + 
                         schoolFame * 0.3 + 
                         achievementFame * 0.2 + 
                         gradeFame * 0.1).round().clamp(0, 100);
    
    fame = weightedFame;
  }
  
  // 基本知名度を計算（能力値ベース）- 4段階制
  int _getBaseFame() {
    final totalAbility = trueTotalAbility;
    
    // 能力値に基づく知名度（4段階制）
    if (totalAbility >= 80) return 90;      // 一流以上（超高校級）
    if (totalAbility >= 70) return 70;      // 中堅以上（注目レベル）
    if (totalAbility >= 60) return 50;      // 平均以上（認知レベル）
    return 0;                               // 平均以下（無名）
  }
  
  // 学校の知名度を取得（改善版）
  int _getSchoolFame() {
    // 学校名から知名度を判定
    final schoolFameMap = {
      '甲子園': 90,      // 甲子園常連校
      '名門': 80,        // 野球名門校
      '強豪': 70,        // 強豪校
      '中堅': 50,        // 中堅校
      '弱小': 30,        // 弱小校
      '新興': 40,        // 新興校
    };
    
    // 学校名に含まれるキーワードで判定
    for (final entry in schoolFameMap.entries) {
      if (school.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // デフォルトは中堅校レベル
    return 50;
  }
  
  // 成績による知名度を計算（改善版）
  int _getPerformanceFame() {
    // 実績から計算
    if (achievements.isEmpty) return 0;
    
    // 最新の実績を重視
    final recentAchievements = achievements
        .where((a) => a.year >= 2024) // 最新年度の実績
        .toList();
    
    if (recentAchievements.isEmpty) return 0;
    
    // 最新実績の平均知名度ポイント
    final avgFamePoints = recentAchievements
        .map((a) => a.famePoints)
        .reduce((a, b) => a + b) / recentAchievements.length;
    
    return (avgFamePoints * 0.8).round(); // 実績ポイントを知名度に変換
  }
  
  // 実績による知名度を計算
  int _getAchievementFame() {
    if (achievements.isEmpty) return 0;
    
    // 実績の重要度に基づいて計算
    int totalFame = 0;
    for (final achievement in achievements) {
      // 代表選出は特に重要
      if (achievement.type == AchievementType.u18NationalTeam ||
          achievement.type == AchievementType.highSchoolNational) {
        totalFame += achievement.famePoints * 2; // 2倍の重み
      } else {
        totalFame += achievement.famePoints;
      }
    }
    
    return (totalFame * 0.6).round().clamp(0, 100); // 実績ポイントを知名度に変換
  }
  
  // 学年による知名度を計算
  int _getGradeFame() {
    switch (grade) {
      case 3: return 60; // 3年生は経験豊富
      case 2: return 40; // 2年生は中程度
      case 1: return 20; // 1年生は新入生
      default: return 30;
    }
  }
  
  // 選手の成長
  void grow() {
    if (isDefaultPlayer) return; // デフォルト選手は成長しない

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
    // 能力値システムに基づく成長
    // 技術面能力値の成長
    for (final ability in [TechnicalAbility.control, TechnicalAbility.fastball, TechnicalAbility.breakingBall, TechnicalAbility.pitchMovement]) {
      final currentValue = technicalAbilities[ability] ?? 25;
      final potential = individualPotentials?[ability.name] ?? 100;
      if (currentValue < potential) {
        technicalAbilities[ability] = (currentValue + Random().nextInt(3) + 1).clamp(25, potential);
      }
    }
    
    // フィジカル面能力値の成長
    final staminaCurrent = physicalAbilities[PhysicalAbility.stamina] ?? 25;
    final staminaPotential = individualPotentials?['stamina'] ?? 100;
    if (staminaCurrent < staminaPotential) {
      physicalAbilities[PhysicalAbility.stamina] = (staminaCurrent + Random().nextInt(3) + 1).clamp(25, staminaPotential);
    }
  }
  
  void _growBatter() {
    // 能力値システムに基づく成長
    // 技術面能力値の成長
    for (final ability in [TechnicalAbility.contact, TechnicalAbility.power, TechnicalAbility.batControl, TechnicalAbility.fielding, TechnicalAbility.throwing]) {
      final currentValue = technicalAbilities[ability] ?? 25;
      final potential = individualPotentials?[ability.name] ?? 100;
      if (currentValue < potential) {
        technicalAbilities[ability] = (currentValue + Random().nextInt(3) + 1).clamp(25, potential);
      }
    }
    
    // フィジカル面能力値の成長
    final paceCurrent = physicalAbilities[PhysicalAbility.pace] ?? 25;
    final pacePotential = individualPotentials?['pace'] ?? 100;
    if (paceCurrent < pacePotential) {
      physicalAbilities[PhysicalAbility.pace] = (paceCurrent + Random().nextInt(3) + 1).clamp(25, pacePotential);
    }
  }

  // 新入生の初期実績を生成
  void generateInitialAchievements() {
    if (achievements.isNotEmpty) return; // 既に実績がある場合はスキップ
    
    final random = Random();
    final currentYear = 2024;
    
    // 能力値に基づいて実績を生成
    final totalAbility = trueTotalAbility;
    
    // 高能力選手は初期実績を持っている可能性が高い
    if (totalAbility >= 85) {
      // 超一流選手の初期実績
      if (random.nextBool()) {
        achievements.add(Achievement(
          type: AchievementType.u18NationalTeam,
          name: 'U-18日本代表',
          description: 'U-18日本代表に選出',
          year: currentYear - 1,
          month: 8,
          famePoints: 80,
        ));
      }
      
      if (random.nextBool()) {
        achievements.add(Achievement(
          type: AchievementType.nationalChampionship,
          name: '全国大会優勝',
          description: '全国大会で優勝',
          year: currentYear - 1,
          month: 8,
          famePoints: 60,
        ));
      }
    } else if (totalAbility >= 75) {
      // 一流選手の初期実績
      if (random.nextBool()) {
        achievements.add(Achievement(
          type: AchievementType.regionalChampionship,
          name: '地方大会優勝',
          description: '地方大会で優勝',
          year: currentYear - 1,
          month: 7,
          famePoints: 40,
        ));
      }
      
      if (random.nextBool()) {
        achievements.add(Achievement(
          type: AchievementType.bestPitcher,
          name: '最優秀投手',
          description: '最優秀投手賞を受賞',
          year: currentYear - 1,
          month: 8,
          famePoints: 50,
        ));
      }
    } else if (totalAbility >= 65) {
      // 中堅以上選手の初期実績
      if (random.nextBool()) {
        achievements.add(Achievement(
          type: AchievementType.allStar,
          name: 'オールスター選出',
          description: 'オールスターに選出',
          year: currentYear - 1,
          month: 7,
          famePoints: 30,
        ));
      }
    }
    
    // 学年に応じた実績
    if (grade >= 2) {
      // 2年生以上は過去の実績がある
      if (random.nextBool()) {
        achievements.add(Achievement(
          type: AchievementType.leagueChampionship,
          name: 'リーグ優勝',
          description: 'リーグ戦で優勝',
          year: currentYear - 1,
          month: 6,
          famePoints: 35,
        ));
      }
    }
    
    // 実績ポイントはgetterで計算されるため、再計算は不要
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'school': school,
    'grade': grade,
    'age': age, // 年齢フィールドを追加
    'position': position,
    'personality': personality,
    'trustLevel': trustLevel,
    'fame': fame,
    'isWatched': isWatched,
    'isDiscovered': isDiscovered,
    'isPubliclyKnown': isPubliclyKnown,
    'isScoutFavorite': isScoutFavorite,
    'discoveredBy': discoveredBy,
    'scoutedDates': scoutedDates.map((d) => d.toIso8601String()).toList(),
    'abilityKnowledge': abilityKnowledge,
    'type': type.index,
    'yearsAfterGraduation': yearsAfterGraduation,
    'isGraduated': isGraduated,
    'graduatedAt': graduatedAt?.toIso8601String(),
    'isRetired': isRetired,
    'retiredAt': retiredAt?.toIso8601String(),
    'isDrafted': isDrafted,
    'professionalTeamId': professionalTeamId,
    'pitches': pitches?.map((p) => p.toJson()).toList(),
    'technicalAbilities': technicalAbilities.map((key, value) => MapEntry(key.name, value)),
    'mentalAbilities': Map.fromEntries(
        mentalAbilities.entries
            .where((entry) => _isValidMentalAbility(entry.key.name))
            .map((entry) => MapEntry(entry.key.name, entry.value))
    ),
    'physicalAbilities': physicalAbilities.map((key, value) => MapEntry(key.name, value)),
    'mentalGrit': mentalGrit,
    'growthRate': growthRate,
    'peakAbility': peakAbility,
    'positionFit': positionFit,
    'talent': talent,
    'growthType': growthType,
    'individualPotentials': individualPotentials,
    'scoutEvaluation': scoutEvaluation,
    'scoutNotes': scoutNotes,
    'scoutAnalysisData': scoutAnalysisData,
    'isDefaultPlayer': isDefaultPlayer,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    name: json['name'],
    school: json['school'],
    grade: json['grade'],
    age: json['age'], // 年齢フィールドを追加
    position: json['position'],
    personality: json['personality'],
    trustLevel: json['trustLevel'] ?? 0,
    fame: json['fame'] ?? 0,
    isWatched: json['isWatched'] ?? false,
    isDiscovered: json['isDiscovered'] ?? false,
    isPubliclyKnown: json['isPubliclyKnown'] ?? false,
    isScoutFavorite: json['isScoutFavorite'] ?? false,
    discoveredBy: json['discoveredBy'],
    scoutedDates: json['scoutedDates'] != null 
      ? (json['scoutedDates'] as List).map((d) => DateTime.parse(d)).toList()
      : [],
    abilityKnowledge: json['abilityKnowledge'] != null 
      ? Map<String, int>.from(json['abilityKnowledge'])
      : null,
    type: PlayerType.values[json['type'] ?? 0],
    yearsAfterGraduation: json['yearsAfterGraduation'] ?? 0,
    isGraduated: json['isGraduated'] ?? false,
    graduatedAt: json['graduatedAt'] != null ? DateTime.parse(json['graduatedAt']) : null,
    isRetired: json['isRetired'] ?? false,
    retiredAt: json['retiredAt'] != null ? DateTime.parse(json['retiredAt']) : null,
    isDrafted: json['isDrafted'] ?? false,
    professionalTeamId: json['professionalTeamId'],
    pitches: json['pitches'] != null
      ? (json['pitches'] as List).map((p) => Pitch.fromJson(p)).toList()
      : null,
    technicalAbilities: json['technicalAbilities'] != null
      ? Map.fromEntries(
          (json['technicalAbilities'] as Map<String, dynamic>).entries.map(
            (entry) => MapEntry(TechnicalAbility.values.firstWhere((e) => e.name == entry.key), entry.value as int)
          )
        )
      : null,
    mentalAbilities: json['mentalAbilities'] != null
      ? Map.fromEntries(
          (json['mentalAbilities'] as Map<String, dynamic>).entries
            .where((entry) => _isValidMentalAbility(entry.key)) // 有効な能力値のみ
            .map((entry) => MapEntry(MentalAbility.values.firstWhere((e) => e.name == entry.key), entry.value as int))
        )
      : null,
    physicalAbilities: json['physicalAbilities'] != null
      ? Map.fromEntries(
          (json['physicalAbilities'] as Map<String, dynamic>).entries.map(
            (entry) => MapEntry(PhysicalAbility.values.firstWhere((e) => e.name == entry.key), entry.value as int)
          )
        )
      : null,
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
    scoutAnalysisData: json['scoutAnalysisData'] != null
      ? Map<String, int>.from(json['scoutAnalysisData'])
      : null,
    isDefaultPlayer: json['isDefaultPlayer'] ?? false,
  );

  Player copyWith({
    int? id,
    String? name,
    String? school,
    int? grade,
    int? age,
    String? position,
    String? personality,
    int? trustLevel,
    int? fame,
    bool? isWatched,
    bool? isDiscovered,
    bool? isPubliclyKnown,
    bool? isScoutFavorite,
    String? discoveredBy,
    List<DateTime>? scoutedDates,
    Map<String, int>? abilityKnowledge,
    PlayerType? type,
    int? yearsAfterGraduation,
    List<Pitch>? pitches,
    Map<TechnicalAbility, int>? technicalAbilities,
    Map<MentalAbility, int>? mentalAbilities,
    Map<PhysicalAbility, int>? physicalAbilities,
    double? mentalGrit,
    double? growthRate,
    int? peakAbility,
    Map<String, int>? positionFit,
    int? talent,
    String? growthType,
    Map<String, int>? individualPotentials,
    String? scoutEvaluation,
    String? scoutNotes,
    Map<String, int>? scoutAnalysisData,
    bool? isGraduated,
    DateTime? graduatedAt,
    bool? isRetired,
    DateTime? retiredAt,
    bool? isDrafted,
    String? professionalTeamId,
    bool? isDefaultPlayer,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      age: age ?? this.age, // 年齢フィールドを追加
      position: position ?? this.position,
      personality: personality ?? this.personality,
      trustLevel: trustLevel ?? this.trustLevel,
      fame: fame ?? this.fame,
      isWatched: isWatched ?? this.isWatched,
      isDiscovered: isDiscovered ?? this.isDiscovered,
      isPubliclyKnown: isPubliclyKnown ?? this.isPubliclyKnown,
      isScoutFavorite: isScoutFavorite ?? this.isScoutFavorite,
          discoveredBy: discoveredBy ?? this.discoveredBy,
    scoutedDates: scoutedDates ?? this.scoutedDates,
      abilityKnowledge: abilityKnowledge ?? Map<String, int>.from(this.abilityKnowledge),
      type: type ?? this.type,
      yearsAfterGraduation: yearsAfterGraduation ?? this.yearsAfterGraduation,
      isGraduated: isGraduated ?? this.isGraduated,
      graduatedAt: graduatedAt ?? this.graduatedAt,
      isRetired: isRetired ?? this.isRetired,
      retiredAt: retiredAt ?? this.retiredAt,
      isDrafted: isDrafted ?? this.isDrafted,
      professionalTeamId: professionalTeamId ?? this.professionalTeamId,
      pitches: pitches ?? this.pitches,
      technicalAbilities: technicalAbilities ?? Map<TechnicalAbility, int>.from(this.technicalAbilities),
      mentalAbilities: mentalAbilities ?? Map<MentalAbility, int>.fromEntries(
          this.mentalAbilities.entries
              .where((entry) => _isValidMentalAbility(entry.key.name))
              .map((entry) => MapEntry(entry.key, entry.value))
      ),
      physicalAbilities: physicalAbilities ?? Map<PhysicalAbility, int>.from(this.physicalAbilities),
      mentalGrit: mentalGrit ?? this.mentalGrit,
      growthRate: growthRate ?? this.growthRate,
      peakAbility: peakAbility ?? this.peakAbility,
      positionFit: positionFit ?? Map<String, int>.from(this.positionFit),
      talent: talent ?? this.talent,
      growthType: growthType ?? this.growthType,
      individualPotentials: individualPotentials ?? this.individualPotentials,
      scoutEvaluation: scoutEvaluation ?? this.scoutEvaluation,
      scoutNotes: scoutNotes ?? this.scoutNotes,
      scoutAnalysisData: scoutAnalysisData ?? this.scoutAnalysisData,
      isDefaultPlayer: isDefaultPlayer ?? this.isDefaultPlayer,
    );
  }
} 