import 'dart:math';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../models/player/pitch.dart';
import '../models/school/school.dart';
import 'data_service.dart';

/// 選手データ生成を専門に扱うクラス
class PlayerDataGenerator {
  final DataService _dataService;
  final Random _random = Random();

  PlayerDataGenerator(this._dataService);

  /// 学校ごとの選手を生成
  Future<List<Player>> generatePlayersForSchool(School school, int playerCount) async {
    final players = <Player>[];
    
    for (int i = 0; i < playerCount; i++) {
      final player = await generatePlayer(school);
      players.add(player);
    }
    

    return players;
  }

  /// 個別の選手を生成（統合版）
  Future<Player> generatePlayer(School school) async {
    final db = await _dataService.database;
    
    // 基本情報の生成
    final name = _generatePlayerName();
    final birthDate = _generateBirthDate();
    final gender = '男性'; // 現在は男性のみ
    final hometown = _generateHometown();
    final personality = _generatePersonality();
    
    // Personテーブルに挿入
    final personId = await db.insert('Person', {
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
      'hometown': hometown,
      'personality': personality,
    });

    // 選手固有の情報
    final grade = _random.nextInt(3) + 1; // 1-3年生
    final talent = _generateTalent();
    final position = _determinePositionByPitchingAbility(talent, _random);
    final growthType = _generateGrowthType();
    final mentalGrit = _generateMentalGrit();
    final growthRate = _generateGrowthRate();
    
    // 個別ポテンシャル生成
    final individualPotentials = _generateIndividualPotentials(talent, _random);
    
    // 能力値システムを生成
    final technicalAbilities = _generateTechnicalAbilities(talent, grade, position, _random);
    final mentalAbilities = _generateMentalAbilities(talent, grade, _random);
    final physicalAbilities = _generatePhysicalAbilities(talent, grade, _random);
    
    // 球種を生成（投手の場合）
    final pitches = <Pitch>[];
    if (position == '投手') {
      pitches.addAll(_generatePitches(_random));
    }

    // Playerテーブルに挿入
    final playerId = await db.insert('Player', {
      'id': personId,
      'school_id': school.id,
      'grade': grade,
      'position': position,
      'fame': _generateFame(talent), // 知名度を追加
      'growth_rate': growthRate,
      'talent': talent,
      'growth_type': growthType,
      'mental_grit': mentalGrit,
      'peak_ability': individualPotentials.values.reduce((a, b) => a + b) ~/ individualPotentials.length,
      // Technical abilities
      'contact': technicalAbilities[TechnicalAbility.contact] ?? 25,
      'power': technicalAbilities[TechnicalAbility.power] ?? 25,
      'plate_discipline': technicalAbilities[TechnicalAbility.plateDiscipline] ?? 25,
      'bunt': technicalAbilities[TechnicalAbility.bunt] ?? 25,
      'opposite_field_hitting': technicalAbilities[TechnicalAbility.oppositeFieldHitting] ?? 25,
      'pull_hitting': technicalAbilities[TechnicalAbility.pullHitting] ?? 25,
      'bat_control': technicalAbilities[TechnicalAbility.batControl] ?? 25,
      'swing_speed': technicalAbilities[TechnicalAbility.swingSpeed] ?? 25,
      'fielding': technicalAbilities[TechnicalAbility.fielding] ?? 25,
      'throwing': technicalAbilities[TechnicalAbility.throwing] ?? 25,
      'catcher_ability': technicalAbilities[TechnicalAbility.catcherAbility] ?? 25,
      'control': technicalAbilities[TechnicalAbility.control] ?? 25,
      'fastball': technicalAbilities[TechnicalAbility.fastball] ?? 25,
      'breaking_ball': technicalAbilities[TechnicalAbility.breakingBall] ?? 25,
      'pitch_movement': technicalAbilities[TechnicalAbility.pitchMovement] ?? 25,
      // Mental abilities
      'concentration': mentalAbilities[MentalAbility.concentration] ?? 25,
      'anticipation': mentalAbilities[MentalAbility.anticipation] ?? 25,
      'vision': mentalAbilities[MentalAbility.vision] ?? 25,
      'composure': mentalAbilities[MentalAbility.composure] ?? 25,
      'aggression': mentalAbilities[MentalAbility.aggression] ?? 25,
      'bravery': mentalAbilities[MentalAbility.bravery] ?? 25,
      'leadership': mentalAbilities[MentalAbility.leadership] ?? 25,
      'work_rate': mentalAbilities[MentalAbility.workRate] ?? 25,
      'self_discipline': mentalAbilities[MentalAbility.selfDiscipline] ?? 25,
      'ambition': mentalAbilities[MentalAbility.ambition] ?? 25,
      'teamwork': mentalAbilities[MentalAbility.teamwork] ?? 25,
      'positioning': mentalAbilities[MentalAbility.positioning] ?? 25,
      'pressure_handling': mentalAbilities[MentalAbility.pressureHandling] ?? 25,
      'clutch_ability': mentalAbilities[MentalAbility.clutchAbility] ?? 25,
      // Physical abilities
      'acceleration': physicalAbilities[PhysicalAbility.acceleration] ?? 25,
      'agility': physicalAbilities[PhysicalAbility.agility] ?? 25,
      'balance': physicalAbilities[PhysicalAbility.balance] ?? 25,
      'jumping_reach': physicalAbilities[PhysicalAbility.jumpingReach] ?? 25,
      'natural_fitness': physicalAbilities[PhysicalAbility.naturalFitness] ?? 25,
      'injury_proneness': physicalAbilities[PhysicalAbility.injuryProneness] ?? 25,
      'stamina': physicalAbilities[PhysicalAbility.stamina] ?? 25,
      'strength': physicalAbilities[PhysicalAbility.strength] ?? 25,
      'pace': physicalAbilities[PhysicalAbility.pace] ?? 25,
      'flexibility': physicalAbilities[PhysicalAbility.flexibility] ?? 25,
    });

    // ポテンシャルデータを生成・保存
    await _generateAndSavePotentials(playerId, individualPotentials);

    // 知名度を生成
    final fame = _generateFame(talent);
    
    // Playerオブジェクトを作成
    final player = Player(
      id: playerId,
      name: name,
      school: school.name,
      grade: grade,
      position: position,
      personality: personality,
      fame: fame, // 知名度を設定
      pitches: pitches,
      technicalAbilities: technicalAbilities,
      mentalAbilities: mentalAbilities,
      physicalAbilities: physicalAbilities,
      mentalGrit: mentalGrit,
      growthRate: growthRate,
      peakAbility: individualPotentials.values.reduce((a, b) => a + b) ~/ individualPotentials.length,
      positionFit: _generatePositionFit(position),
      talent: talent,
      growthType: growthType,
      individualPotentials: individualPotentials,
      isDiscovered: false,
      discoveredAt: null,
      discoveredCount: 0,
      scoutedDates: [],
      abilityKnowledge: _generateInitialAbilityKnowledge(),
    );

    return player;
  }

  /// 個別ポテンシャル生成システム
  Map<String, int> _generateIndividualPotentials(int talentRank, Random random) {
    // 才能ランクに基づく平均ポテンシャルを決定
    final averagePotential = _getAveragePotentialByTalent(talentRank, random);
    
    // 各能力値のポテンシャルを生成（全選手共通）
    final potentials = <String, int>{};
    
    // Technical（技術面）能力値
    final technicalAbilities = [
      'contact', 'power', 'plateDiscipline', 'bunt', 'oppositeFieldHitting', 
      'pullHitting', 'batControl', 'swingSpeed', 'fielding', 'throwing', 
      'catcherAbility', 'control', 'fastball', 'breakingBall', 'pitchMovement'
    ];
    
    // Mental（メンタル面）能力値
    final mentalAbilities = [
      'concentration', 'anticipation', 'vision', 'composure', 'aggression', 
      'bravery', 'leadership', 'workRate', 'selfDiscipline', 'ambition',
      'teamwork', 'positioning', 'pressureHandling', 'clutchAbility'
    ];
    
    // Physical（フィジカル面）能力値
    final physicalAbilities = [
      'acceleration', 'agility', 'balance', 'jumpingReach', 'naturalFitness', 
      'injuryProneness', 'stamina', 'strength', 'pace', 'flexibility'
    ];
    
    // 各カテゴリのポテンシャルを生成
    for (final ability in technicalAbilities) {
      potentials[ability] = _generateAbilityPotential(averagePotential, talentRank, random);
    }
    
    for (final ability in mentalAbilities) {
      potentials[ability] = _generateAbilityPotential(averagePotential, talentRank, random);
    }
    
    for (final ability in physicalAbilities) {
      potentials[ability] = _generateAbilityPotential(averagePotential, talentRank, random);
    }
    
    return potentials;
  }

  /// 才能ランクに基づく平均ポテンシャルを取得
  int _getAveragePotentialByTalent(int talentRank, Random random) {
    switch (talentRank) {
      case 1:
        return 60 + random.nextInt(16); // 60-75
      case 2:
        return 70 + random.nextInt(16); // 70-85
      case 3:
        return 80 + random.nextInt(16); // 80-95
      case 4:
        return 90 + random.nextInt(21); // 90-110
      case 5:
        return 100 + random.nextInt(31); // 100-130
      case 6:
        return 120 + random.nextInt(31); // 120-150 (怪物級)
      default:
        return 70 + random.nextInt(16);
    }
  }

  /// 能力値ポテンシャルを生成
  int _generateAbilityPotential(int averagePotential, int talentRank, Random random) {
    // 才能ランクに基づく変動幅を決定
    final variationRange = _getVariationRangeByTalent(talentRank);
    
    // 平均ポテンシャルを中心とした変動
    final variation = (random.nextDouble() - 0.5) * variationRange;
    final potential = averagePotential + variation.round();
    
    // 才能ランクに基づく最小・最大値を制限
    final minPotential = _getMinPotentialByTalent(talentRank);
    final maxPotential = _getMaxPotentialByTalent(talentRank);
    
    return potential.clamp(minPotential, maxPotential);
  }

  /// 才能ランクに基づく変動幅を取得
  int _getVariationRangeByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 20; // 低ランクは変動が小さい
      case 2: return 25;
      case 3: return 30;
      case 4: return 35;
      case 5: return 40; // 高ランクは変動が大きい
      case 6: return 50; // 怪物級は変動が大きい
      default: return 25;
    }
  }

  /// 才能ランクに基づく最小ポテンシャルを取得
  int _getMinPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 50;
      case 2: return 60;
      case 3: return 70;
      case 4: return 80;
      case 5: return 90;
      case 6: return 100; // 怪物級の最小値
      default: return 60;
    }
  }

  /// 才能ランクに基づく最大ポテンシャルを取得
  int _getMaxPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 85;
      case 2: return 95;
      case 3: return 105;
      case 4: return 120;
      case 5: return 150;
      case 6: return 200; // 怪物級の最大値
      default: return 95;
    }
  }

  /// 投手適正確率によるポジション決定
  String _determinePositionByPitchingAbility(int talent, Random random) {
    // 才能ランクに基づく基本能力値を計算
    final baseAbility = _getBaseAbilityByTalent(talent);
    final baseVelocity = _getBaseVelocityByTalent(talent);
    
    // 投手能力の総合評価を計算
    final pitcherScore = _calculatePitcherScore(baseAbility, baseVelocity, random);
    final fielderScore = _calculateFielderScore(baseAbility, random);
    
    // 投手適性を判定（バランスを考慮）
    double pitcherProbability = _calculatePitcherProbability(pitcherScore, fielderScore);
    
    // 才能ランクに基づく調整（高才能選手はよりバランスの取れた分布を目指す）
    if (talent >= 4) {
      // 高才能選手（ランク4以上）は投手確率を少し下げる
      pitcherProbability *= 0.8;
    } else if (talent <= 2) {
      // 低才能選手（ランク2以下）は投手確率を少し上げる
      pitcherProbability *= 1.2;
    }
    
    final isPitcher = random.nextDouble() < pitcherProbability;
    
    if (isPitcher) {
      return '投手';
    } else {
      // 野手ポジションを決定（投手能力が高いほど肩の良いポジションに）
      return _determineFielderPositionByPitchingAbility(pitcherScore, random);
    }
  }

  /// 投手能力総合スコアを計算
  int _calculatePitcherScore(int baseAbility, int baseVelocity, Random random) {
    final control = baseAbility + random.nextInt(20);
    final stamina = baseAbility + random.nextInt(20);
    final breakAvg = baseAbility + random.nextInt(20);
    final velocity = baseVelocity + random.nextInt(20);
    
    // 球速を能力値システムに合わせて正規化（130-155km/h → 25-100の能力値）
    final normalizedVelocity = 25 + ((velocity - 130) * 75 / 25).clamp(0, 75);
    
    // 投手能力の重み付け（球速40%、制球25%、スタミナ20%、変化球15%）
    return ((normalizedVelocity * 0.4) + (control * 0.25) + (stamina * 0.2) + (breakAvg * 0.15)).round();
  }

  /// 野手能力総合スコアを計算
  int _calculateFielderScore(int baseAbility, Random random) {
    final batPower = baseAbility + random.nextInt(20);
    final batControl = baseAbility + random.nextInt(20);
    final run = baseAbility + random.nextInt(20);
    final field = baseAbility + random.nextInt(20);
    final arm = baseAbility + random.nextInt(20);
    
    // 野手能力の重み付け（打撃50%、守備50%）
    final battingScore = (batPower + batControl) / 2;
    final fieldingScore = (run + field + arm) / 3;
    return ((battingScore * 0.5) + (fieldingScore * 0.5)).round();
  }

  /// 投手適性確率を計算（投手能力と野手能力のバランスを考慮）
  double _calculatePitcherProbability(int pitcherScore, int fielderScore) {
    final scoreDifference = pitcherScore - fielderScore;
    
    // よりバランスの取れた確率設定（投手:野手 = 約4:5の比率を目指す）
    if (scoreDifference >= 30) return 0.70;      // 大幅に高い場合でも確率を下げる
    if (scoreDifference >= 20) return 0.55;      // 高い場合
    if (scoreDifference >= 10) return 0.40;      // やや高い場合
    if (scoreDifference >= 0) return 0.25;       // 同等の場合
    if (scoreDifference >= -10) return 0.15;     // やや低い場合
    if (scoreDifference >= -20) return 0.08;     // 低い場合
    return 0.03;                                 // 大幅に低い場合
  }

  /// 投手能力に基づく野手ポジション決定
  String _determineFielderPositionByPitchingAbility(int pitcherScore, Random random) {
    if (pitcherScore >= 140) {
      // 投手能力が非常に高い場合、捕手か外野手
      final positions = ['捕手', '右翼手', '中堅手', '左翼手'];
      return positions[random.nextInt(positions.length)];
    } else if (pitcherScore >= 130) {
      // 投手能力が高い場合、捕手、外野手、三塁手
      final positions = ['捕手', '右翼手', '中堅手', '三塁手'];
      return positions[random.nextInt(positions.length)];
    } else if (pitcherScore >= 120) {
      // 投手能力が中程度の場合、三塁手、遊撃手、外野手
      final positions = ['三塁手', '遊撃手', '右翼手', '中堅手'];
      return positions[random.nextInt(positions.length)];
    } else if (pitcherScore >= 110) {
      // 投手能力がやや低い場合、内野手
      final positions = ['二塁手', '遊撃手', '三塁手'];
      return positions[random.nextInt(positions.length)];
    } else {
      // 投手能力が低い場合、内野手（一塁手、二塁手）
      final positions = ['一塁手', '二塁手', '遊撃手'];
      return positions[random.nextInt(positions.length)];
    }
  }

  /// 能力値システムの生成
  Map<TechnicalAbility, int> _generateTechnicalAbilities(int talent, int grade, String position, Random random) {
    final abilities = <TechnicalAbility, int>{};
    final baseAbility = _getBaseAbilityByTalent(talent);
    final gradeMultiplier = _getGradeMultiplier(grade);
    
    // 才能ランク6の怪物は特別な上限を設定
    final maxAbility = talent == 6 ? 90 : 100;
    
    // Technical abilitiesを生成
    for (final ability in TechnicalAbility.values) {
      final baseValue = ((baseAbility * gradeMultiplier + random.nextInt(20)).round()).clamp(25, maxAbility);
      abilities[ability] = baseValue;
    }
    
    // ポジション別調整を適用
    if (position == '投手') {
      abilities[TechnicalAbility.control] = (abilities[TechnicalAbility.control]! + random.nextInt(21)).clamp(25, 100);
      abilities[TechnicalAbility.fastball] = (abilities[TechnicalAbility.fastball]! + random.nextInt(21)).clamp(25, 100);
      abilities[TechnicalAbility.breakingBall] = (abilities[TechnicalAbility.breakingBall]! + random.nextInt(21)).clamp(25, 100);
      abilities[TechnicalAbility.pitchMovement] = (abilities[TechnicalAbility.pitchMovement]! + random.nextInt(21)).clamp(25, 100);
    } else {
      abilities[TechnicalAbility.contact] = (abilities[TechnicalAbility.contact]! + random.nextInt(21)).clamp(25, 100);
      abilities[TechnicalAbility.power] = (abilities[TechnicalAbility.power]! + random.nextInt(21)).clamp(25, 100);
      abilities[TechnicalAbility.batControl] = (abilities[TechnicalAbility.batControl]! + random.nextInt(21)).clamp(25, 100);
      abilities[TechnicalAbility.fielding] = (abilities[TechnicalAbility.fielding]! + random.nextInt(21)).clamp(25, 100);
      abilities[TechnicalAbility.throwing] = (abilities[TechnicalAbility.throwing]! + random.nextInt(21)).clamp(25, 100);
    }
    
    return abilities;
  }

  Map<MentalAbility, int> _generateMentalAbilities(int talent, int grade, Random random) {
    final abilities = <MentalAbility, int>{};
    final baseAbility = _getBaseAbilityByTalent(talent);
    final gradeMultiplier = _getGradeMultiplier(grade);
    
    // 才能ランク6の怪物は特別な上限を設定
    final maxAbility = talent == 6 ? 90 : 100;
    
    // Mental abilitiesを生成
    for (final ability in MentalAbility.values) {
      final baseValue = ((baseAbility * gradeMultiplier + random.nextInt(20)).round()).clamp(25, maxAbility);
      abilities[ability] = baseValue;
    }
    
    return abilities;
  }

  Map<PhysicalAbility, int> _generatePhysicalAbilities(int talent, int grade, Random random) {
    final abilities = <PhysicalAbility, int>{};
    final baseAbility = _getBaseAbilityByTalent(talent);
    final gradeMultiplier = _getGradeMultiplier(grade);
    
    // 才能ランク6の怪物は特別な上限を設定
    final maxAbility = talent == 6 ? 90 : 100;
    
    // Physical abilitiesを生成
    for (final ability in PhysicalAbility.values) {
      final baseValue = ((baseAbility * gradeMultiplier + random.nextInt(20)).round()).clamp(25, maxAbility);
      abilities[ability] = baseValue;
    }
    
    return abilities;
  }

  /// 基本能力値を取得
  int _getBaseAbilityByTalent(int talent) {
    switch (talent) {
      case 1: return 35;
      case 2: return 45;
      case 3: return 55;
      case 4: return 65;
      case 5: return 75;
      case 6: return 85; // 怪物級の基本能力値
      default: return 45;
    }
  }

  /// 基本球速を取得
  int _getBaseVelocityByTalent(int talent) {
    switch (talent) {
      case 1: return 130;
      case 2: return 135;
      case 3: return 140;
      case 4: return 145;
      case 5: return 150;
      case 6: return 155; // 怪物級の基本球速
      default: return 135;
    }
  }

  /// 学年倍率を取得
  double _getGradeMultiplier(int grade) {
    switch (grade) {
      case 1: return 0.6;
      case 2: return 0.8;
      case 3: return 1.0;
      default: return 0.8;
    }
  }

  /// 球種を生成
  List<Pitch> _generatePitches(Random random) {
    final pitches = <Pitch>[];
    final pitchTypes = ['直球', 'カーブ', 'スライダー', 'フォーク', 'チェンジアップ'];
    
    // 直球は必ず習得
    pitches.add(Pitch(
      type: '直球',
      breakAmount: 0, // 直球に変化量は不要
      breakPot: 15 + random.nextInt(26), // 15-40
      unlocked: true,
    ));
    
    // 他の球種はランダムに習得
    for (final type in pitchTypes.skip(1)) {
      if (random.nextBool()) {
        pitches.add(Pitch(
          type: type,
          breakAmount: 20 + random.nextInt(41), // 20-60
          breakPot: 25 + random.nextInt(51), // 25-75
          unlocked: true,
        ));
      }
    }
    
    return pitches;
  }

  /// 才能ランクを生成（改善版）
  int _generateTalent() {
    final r = _random.nextInt(1000); // より細かい確率制御のため1000を使用
    if (r < 400) return 1;      // 40%
    if (r < 700) return 2;      // 30%
    if (r < 900) return 3;      // 20%
    if (r < 970) return 4;      // 7%
    if (r < 995) return 5;      // 2.5%
    return 6;                   // 0.5% (各県に数人程度)
  }

  /// 成長タイプを生成
  String _generateGrowthType() {
    final types = ['early', 'normal', 'late', 'spurt'];
    return types[_random.nextInt(types.length)];
  }

  /// メンタルグリットを生成
  double _generateMentalGrit() {
    return 0.5 + (_random.nextDouble() * 0.3); // 0.5-0.8
  }

  /// 成長率を生成
  double _generateGrowthRate() {
    return 0.9 + (_random.nextDouble() * 0.3); // 0.9-1.2
  }

  /// ポジション適性を生成
  Map<String, int> _generatePositionFit(String mainPosition) {
    const positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final fit = <String, int>{};
    for (final pos in positions) {
      if (pos == mainPosition) {
        fit[pos] = 70 + _random.nextInt(21); // 70-90
      } else {
        fit[pos] = 40 + _random.nextInt(31); // 40-70
      }
    }
    return fit;
  }

  /// 選手のポテンシャルを生成・保存
  Future<Map<String, int>> _generateAndSavePotentials(int playerId, Map<String, int> potentials) async {
    final db = await _dataService.database;
    
    final potentialData = <String, dynamic>{
      'player_id': playerId,
    };
    
    // ポテンシャルデータを変換
    for (final entry in potentials.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // キャメルケースをスネークケースに変換
      final snakeKey = key.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}'
      );
      
      potentialData['${snakeKey}_potential'] = value;
    }

    // データベースに保存
    await db.insert('PlayerPotentials', potentialData);
    
    return potentials;
  }

  /// 初期能力値把握度を生成
  Map<String, int> _generateInitialAbilityKnowledge() {
    return {
      'contact': 0,
      'power': 0,
      'plate_discipline': 0,
      'bunt': 0,
      'opposite_field_hitting': 0,
      'pull_hitting': 0,
      'bat_control': 0,
      'swing_speed': 0,
      'fielding': 0,
      'throwing': 0,
      'catcher_ability': 0,
      'control': 0,
      'fastball': 0,
      'breaking_ball': 0,
      'pitch_movement': 0,
      'concentration': 0,
      'anticipation': 0,
      'vision': 0,
      'composure': 0,
      'aggression': 0,
      'bravery': 0,
      'leadership': 0,
      'work_rate': 0,
      'self_discipline': 0,
      'ambition': 0,
      'teamwork': 0,
      'positioning': 0,
      'pressure_handling': 0,
      'clutch_ability': 0,
      'acceleration': 0,
      'agility': 0,
      'balance': 0,
      'jumping_reach': 0,
      'natural_fitness': 0,
      'injury_proneness': 0,
      'stamina': 0,
      'strength': 0,
      'pace': 0,
      'flexibility': 0,
    };
  }

  // 以下、各種生成メソッド
  String _generatePlayerName() {
    final surnames = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final givenNames = ['翔太', '健太', '大輔', '誠', '直樹', '智也', '裕太', '達也', '和也', '正義'];
    
    return surnames[_random.nextInt(surnames.length)] + 
           givenNames[_random.nextInt(givenNames.length)];
  }

  String _generateBirthDate() {
    final year = 2005 + _random.nextInt(3); // 2005-2007年生まれ
    final month = _random.nextInt(12) + 1;
    final day = _random.nextInt(28) + 1;
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String _generateHometown() {
    final cities = ['横浜市', '川崎市', '相模原市', '藤沢市', '茅ヶ崎市', '厚木市', '平塚市', '鎌倉市'];
    return cities[_random.nextInt(cities.length)];
  }

  String _generatePersonality() {
    final personalities = ['真面目', '明るい', 'クール', '熱血', '慎重', '積極的', 'マイペース'];
    return personalities[_random.nextInt(personalities.length)];
  }

  // ランダムな名前生成（簡易）
  String generateRandomName() {
    final random = Random();
    const familyNames = ['田中', '佐藤', '鈴木', '高橋', '伊藤', '渡辺', '山本', '中村', '小林', '加藤'];
    const givenNames = ['太郎', '次郎', '大輔', '翔太', '健太', '悠斗', '陸', '蓮', '颯太', '陽斗'];
    final f = familyNames[random.nextInt(familyNames.length)];
    final g = givenNames[random.nextInt(givenNames.length)];
    return '$f$g';
  }

  String generateRandomPersonality() {
    final random = Random();
    const personalities = ['真面目', '負けず嫌い', 'ムードメーカー', '冷静', '情熱的', '努力家', '天才肌'];
    return personalities[random.nextInt(personalities.length)];
  }

  /// 知名度を生成（改善版）
  int _generateFame(int talent) {
    // 基本的な知名度は才能ランクに基づく
    int baseFame = 0;
    switch (talent) {
      case 1: baseFame = 10; // 低ランク（少し上げる）
      case 2: baseFame = 25; // 中ランク（上げる）
      case 3: baseFame = 40; // 高ランク（上げる）
      case 4: baseFame = 55; // 特別な才能（上げる）
      case 5: baseFame = 70; // 怪物級（上げる）
      case 6: baseFame = 85; // 怪物級（上げる）
      default: baseFame = 25;
    }
    
    // ランダム要素を追加（±15）
    final randomVariation = _random.nextInt(31) - 15;
    return (baseFame + randomVariation).clamp(0, 100);
  }
} 