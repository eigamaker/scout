import 'dart:math';
import '../player/player.dart';
import '../player/pitch.dart';
import '../player/player_abilities.dart';
import '../../services/player_generator.dart';

// 高校クラス
class School {
  final String name;
  final String location;
  final List<Player> players;
  final int coachTrust; // 監督の信頼度 0-100
  final String coachName;
  
  School({
    required this.name,
    required this.location,
    required this.players,
    required this.coachTrust,
    required this.coachName,
  });
  
  School copyWith({
    String? name,
    String? location,
    List<Player>? players,
    int? coachTrust,
    String? coachName,
  }) {
    return School(
      name: name ?? this.name,
      location: location ?? this.location,
      players: players ?? this.players,
      coachTrust: coachTrust ?? this.coachTrust,
      coachName: coachName ?? this.coachName,
    );
  }

  // 選手を生成（個別ポテンシャルシステムを使用）
  Player generatePlayer({
    required String position,
    required String personality,
    required int talentRank,
    required Random random,
  }) {
    // 能力値システムの生成
    final technicalAbilities = PlayerGenerator.generateTechnicalAbilities(talentRank, position);
    final mentalAbilities = PlayerGenerator.generateMentalAbilities(talentRank);
    final physicalAbilities = PlayerGenerator.generatePhysicalAbilities(talentRank, position);
    
    // 個別ポテンシャルの生成
    final individualPotentials = _generateIndividualPotentials(talentRank, random);
    
    // 球種の生成（投手のみ）
    final pitches = position == '投手' ? _generatePitches(talentRank, random) : <Pitch>[];
    
    // 隠し能力値の生成
    final mentalGrit = 0.5 + random.nextDouble() * 0.3; // 0.5-0.8
    final growthRate = 0.9 + random.nextDouble() * 0.3; // 0.9-1.2
    final peakAbility = _getMinPotentialByTalent(talentRank) + random.nextInt(_getMaxPotentialByTalent(talentRank) - _getMinPotentialByTalent(talentRank));
    
    // 成長タイプの決定
    final growthType = _determineGrowthType(random);
    
    // 知名度の決定
    final fame = _determineFame(talentRank, random);
    
    return Player(
      name: _generateName(random),
      school: name,
      grade: _generateGrade(random),
      position: position,
      personality: personality,
      trustLevel: 0,
      fame: fame,
      isWatched: false,
      isDiscovered: false,
      isPubliclyKnown: false,
      type: PlayerType.highSchool,
      yearsAfterGraduation: 0,
      pitches: pitches,
      technicalAbilities: technicalAbilities,
      mentalAbilities: mentalAbilities,
      physicalAbilities: physicalAbilities,
      mentalGrit: mentalGrit,
      growthRate: growthRate,
      peakAbility: peakAbility,
      positionFit: _generatePositionFit(position, random),
      talent: talentRank,
      growthType: growthType,
      individualPotentials: individualPotentials,
    );
  }
  
  // 個別ポテンシャル生成システム（簡易版）
  Map<String, int> _generateIndividualPotentials(int talentRank, Random random) {
    // 才能ランクに基づく平均ポテンシャルを決定
    final averagePotential = _getAveragePotentialByTalent(talentRank, random);
    
    // 各能力値のポテンシャルを生成（全選手共通）
    final potentials = <String, int>{};
    
    // 投手能力値（全選手が持つ）
    potentials['control'] = _generateAbilityPotential(averagePotential, talentRank, random);
    potentials['stamina'] = _generateAbilityPotential(averagePotential, talentRank, random);
    potentials['breakAvg'] = _generateAbilityPotential(averagePotential, talentRank, random);
    
    // 野手能力値（全選手が持つ）
    potentials['batPower'] = _generateAbilityPotential(averagePotential, talentRank, random);
    potentials['batControl'] = _generateAbilityPotential(averagePotential, talentRank, random);
    potentials['run'] = _generateAbilityPotential(averagePotential, talentRank, random);
    potentials['field'] = _generateAbilityPotential(averagePotential, talentRank, random);
    potentials['arm'] = _generateAbilityPotential(averagePotential, talentRank, random);
    
    // 球速（全選手が持つ）
    potentials['fastballVelo'] = _generateFastballPotential(talentRank, random);
    
    // 新しいTechnical（技術面）能力値ポテンシャル
    final technicalAbilities = [
      'contact', 'power', 'plateDiscipline', 'bunt', 'oppositeFieldHitting', 
      'pullHitting', 'batControl', 'swingSpeed', 'fielding', 'throwing', 
      'catcherAbility', 'control', 'fastball', 'breakingBall', 'pitchMovement'
    ];
    
    // 新しいMental（メンタル面）能力値ポテンシャル
    final mentalAbilities = [
      'concentration', 'anticipation', 'vision', 'composure', 'aggression', 
      'bravery', 'leadership', 'workRate', 'selfDiscipline', 'ambition',
      'teamwork', 'positioning', 'pressureHandling', 'clutchAbility',
      'naturalFitness', 'injuryProneness'
    ];
    
    // 新しいPhysical（フィジカル面）能力値ポテンシャル
    final physicalAbilities = [
      'acceleration', 'agility', 'balance', 'jumpingReach', 'flexibility',
      'naturalFitness', 'injuryProneness', 'stamina', 'strength', 'pace'
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
  
  int _getAveragePotentialByTalent(int talentRank, Random random) {
    switch (talentRank) {
      case 1: return 60 + random.nextInt(16); // 60-75
      case 2: return 70 + random.nextInt(16); // 70-85
      case 3: return 80 + random.nextInt(16); // 80-95
      case 4: return 90 + random.nextInt(21); // 90-110
      case 5: return 100 + random.nextInt(31); // 100-130
      default: return 70 + random.nextInt(16);
    }
  }
  
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
  
  int _getVariationRangeByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 20; // 低ランクは変動が小さい
      case 2: return 25;
      case 3: return 30;
      case 4: return 35;
      case 5: return 40; // 高ランクは変動が大きい
      default: return 25;
    }
  }
  
  int _getMinPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 50;
      case 2: return 60;
      case 3: return 70;
      case 4: return 80;
      case 5: return 90;
      default: return 60;
    }
  }
  
  int _getMaxPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 85;
      case 2: return 95;
      case 3: return 105;
      case 4: return 120;
      case 5: return 150;
      default: return 95;
    }
  }
  
  int _generateFastballPotential(int talentRank, Random random) {
    // 球速は100段階で管理（0-100）
    final basePotential = _getBaseFastballPotentialByTalent(talentRank);
    final variation = random.nextInt(_getFastballVariationByTalent(talentRank));
    
    return (basePotential + variation).clamp(50, 100);
  }
  
  int _getBaseFastballPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 70; // 70-90（現在値25-45を確実に上回る）
      case 2: return 80; // 80-100
      case 3: return 85; // 85-100
      case 4: return 90; // 90-100
      case 5: return 95; // 95-100
      case 6: return 98; // 98-100（怪物級の球速ポテンシャル）
      default: return 80;
    }
  }
  
  int _getFastballVariationByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 20; // ±10
      case 2: return 20; // ±10
      case 3: return 15; // ±7.5
      case 4: return 10; // ±5
      case 5: return 5;  // ±2.5
      case 6: return 2;  // ±1（怪物級）
      default: return 20;
    }
  }
  
  // 能力バランス調整システム（簡易版）
  Map<String, int> _adjustPotentialsForBalance(Map<String, int> potentials, int talentRank, Random random) {
    final adjustedPotentials = Map<String, int>.from(potentials);
    
    // 平均ポテンシャルを計算（球速を含む）
    final averagePotential = adjustedPotentials.values.reduce((a, b) => a + b) / adjustedPotentials.length;
    
    // 才能ランクに基づく適切な平均範囲を取得
    final targetRange = _getTargetAverageRange(talentRank);
    
    // 平均が範囲外の場合、調整を実行
    if (averagePotential < targetRange['min']! || averagePotential > targetRange['max']!) {
      _adjustToTargetRange(adjustedPotentials, targetRange, random);
    }
    
    // 極端な能力差を調整
    _adjustExtremeDifferences(adjustedPotentials, talentRank, random);
    
    return adjustedPotentials;
  }
  
  Map<String, int> _getTargetAverageRange(int talentRank) {
    switch (talentRank) {
      case 1: return <String, int>{'min': 60, 'max': 75};
      case 2: return <String, int>{'min': 70, 'max': 85};
      case 3: return <String, int>{'min': 80, 'max': 95};
      case 4: return <String, int>{'min': 90, 'max': 110};
      case 5: return <String, int>{'min': 100, 'max': 130};
      default: return <String, int>{'min': 70, 'max': 85};
    }
  }
  
  void _adjustToTargetRange(Map<String, int> potentials, Map<String, int> targetRange, Random random) {
    final currentAverage = potentials.values.reduce((a, b) => a + b) / potentials.length;
    final targetAverage = (targetRange['min']! + targetRange['max']!) / 2;
    
    // 調整量を計算
    final adjustment = (targetAverage - currentAverage).round();
    
    // 各能力値を調整（球速も含む）
    for (final entry in potentials.entries) {
      final newValue = entry.value + adjustment;
              if (entry.key == 'fastballVelo') {
          // 球速は125-170 km/hの範囲で制限
          potentials[entry.key] = newValue.clamp(125, 170);
        } else {
          // その他の能力値は25-150の範囲で制限
          potentials[entry.key] = newValue.clamp(25, 150);
        }
    }
  }
  
  void _adjustExtremeDifferences(Map<String, int> potentials, int talentRank, Random random) {
    final allPotentials = potentials.values.toList();
    
    final maxDiff = _getMaxAllowedDifference(talentRank);
    final maxValue = allPotentials.reduce((a, b) => a > b ? a : b);
    final minValue = allPotentials.reduce((a, b) => a < b ? a : b);
    
    if (maxValue - minValue > maxDiff) {
      // 極端な差を調整
      final adjustment = ((maxValue - minValue - maxDiff) / 2).round();
      
      for (final entry in potentials.entries) {
        if (entry.value == maxValue) {
          final newValue = entry.value - adjustment;
          if (entry.key == 'fastballVelo') {
            potentials[entry.key] = newValue.clamp(125, 155);
          } else {
            potentials[entry.key] = newValue.clamp(25, 150);
          }
        } else if (entry.value == minValue) {
          final newValue = entry.value + adjustment;
          if (entry.key == 'fastballVelo') {
            potentials[entry.key] = newValue.clamp(125, 170);
          } else {
            potentials[entry.key] = newValue.clamp(25, 150);
          }
        }
      }
    }
  }
  
  int _getMaxAllowedDifference(int talentRank) {
    switch (talentRank) {
      case 1: return 25; // 低ランクは差が小さい
      case 2: return 30;
      case 3: return 35;
      case 4: return 40;
      case 5: return 50; // 高ランクは差が大きい
      default: return 30;
    }
  }
  
  // 初期能力値生成システム（簡易版）
  Map<String, int> _generateInitialAbilities(Map<String, int> potentials, int grade, double mentalGrit, double growthRate, int talent, String growthType, Random random) {
    final initialAbilities = <String, int>{};
    
    for (final entry in potentials.entries) {
      final abilityName = entry.key;
      final potential = entry.value;
      
      if (abilityName == 'fastballVelo') {
        initialAbilities[abilityName] = _generateInitialFastball(potential, grade, random);
      } else {
        initialAbilities[abilityName] = _generateInitialAbility(potential, grade, mentalGrit, growthRate, talent, growthType, random);
      }
    }
    
    return initialAbilities;
  }
  
  int _generateInitialAbility(int potential, int grade, double mentalGrit, double growthRate, int talent, String growthType, Random random) {
    // 成長係数を計算
    final growthCoefficient = _calculateGrowthCoefficient(mentalGrit, growthRate, talent, growthType);
    
    // 学年別の初期化率を決定
    final gradeRate = _getGradeInitializationRate(grade);
    
    // 初期能力値を計算
    final initialValue = 25 + (potential - 25) * growthCoefficient * gradeRate;
    
    // ランダム要素を追加
    final randomVariation = (random.nextDouble() - 0.5) * 10;
    
    return (initialValue + randomVariation).round().clamp(25, potential);
  }
  
  int _generateInitialFastball(int potential, int grade, Random random) {
    // 球速の特別処理（全選手共通）
    final gradeRate = _getGradeInitializationRate(grade);
    final initialVelocity = 125 + (potential - 125) * gradeRate;
    final randomVariation = (random.nextDouble() - 0.5) * 10;
    
    return (initialVelocity + randomVariation).round().clamp(125, potential);
  }
  
  double _calculateGrowthCoefficient(double mentalGrit, double growthRate, int talent, String growthType) {
    final baseCoefficient = 0.15 + (mentalGrit - 0.5) * 0.2;
    final growthSpeedCoefficient = (growthRate - 0.9) * 0.3;
    final talentCoefficient = (talent - 1) * 0.05;
    final growthTypeCoefficient = _getGrowthTypeCoefficient(growthType);
    
    return baseCoefficient + growthSpeedCoefficient + talentCoefficient + growthTypeCoefficient;
  }
  
  double _getGradeInitializationRate(int grade) {
    switch (grade) {
      case 1: return 0.15; // 新入生
      case 2: return 0.45; // 2年生
      case 3: return 0.75; // 3年生
      default: return 0.45;
    }
  }
  
  double _getGrowthTypeCoefficient(String growthType) {
    switch (growthType) {
      case 'early': return 0.1;
      case 'normal': return 0.0;
      case 'late': return -0.1;
      case 'spurt': return 0.15;
      default: return 0.0;
    }
  }
  
  // 学年別確率調整システム（簡易版）
  Map<String, int> _applyGradeAdjustments(Map<String, int> abilities, int grade, Random random) {
    final adjustedAbilities = <String, int>{};
    
    for (final entry in abilities.entries) {
      final abilityName = entry.key;
      final abilityValue = entry.value;
      
      if (abilityName == 'fastballVelo') {
        final probability = _getFastballProbabilityAdjustment(grade, abilityValue);
        if (random.nextDouble() <= probability) {
          adjustedAbilities[abilityName] = abilityValue;
        } else {
          // 確率調整で除外された場合、より低い値を設定
          adjustedAbilities[abilityName] = 125 + random.nextInt(20); // 125-145 km/h
        }
      } else {
        final probability = _getAbilityProbabilityAdjustment(grade, abilityValue);
        if (random.nextDouble() <= probability) {
          adjustedAbilities[abilityName] = abilityValue;
        } else {
          // 確率調整で除外された場合、より低い値を設定
          adjustedAbilities[abilityName] = 25 + random.nextInt(30); // 25-55
        }
      }
    }
    
    return adjustedAbilities;
  }
  
  double _getAbilityProbabilityAdjustment(int grade, int abilityValue) {
    if (grade == 3) return 1.0; // 基準値
    
    if (abilityValue >= 90) {
      return grade == 1 ? 0.3 : 0.6;
    } else if (abilityValue >= 80) {
      return grade == 1 ? 0.4 : 0.7;
    } else if (abilityValue >= 70) {
      return grade == 1 ? 0.5 : 0.8;
    } else if (abilityValue >= 60) {
      return grade == 1 ? 0.7 : 0.9;
    } else if (abilityValue >= 50) {
      return grade == 1 ? 0.9 : 0.95;
    } else {
      return 1.0; // 低能力値は学年に関係なく同じ確率
    }
  }
  
  double _getFastballProbabilityAdjustment(int grade, int velocity) {
    if (grade == 3) return 1.0; // 基準値
    
    if (velocity >= 150) {
      return grade == 1 ? 0.2 : 0.5;
    } else if (velocity >= 145) {
      return grade == 1 ? 0.3 : 0.6;
    } else if (velocity >= 140) {
      return grade == 1 ? 0.5 : 0.8;
    } else if (velocity >= 135) {
      return grade == 1 ? 0.7 : 0.9;
    } else if (velocity >= 130) {
      return grade == 1 ? 0.9 : 0.95;
    } else {
      return 1.0; // 低速は学年に関係なく同じ確率
    }
  }
  
  // 現実的なポジション分布でランダムポジション決定
  String _randomPosition() {
    final random = Random();
    final rand = random.nextDouble();
    
    // 現実的な野球チームのポジション分布（投手比率を大幅に削減）
    if (rand < 0.08) return '投手';        // 8% - 投手
    if (rand < 0.13) return '捕手';        // 5% - 捕手
    if (rand < 0.28) return '一塁手';      // 15% - 一塁手
    if (rand < 0.38) return '二塁手';      // 10% - 二塁手
    if (rand < 0.48) return '三塁手';      // 10% - 三塁手
    if (rand < 0.63) return '遊撃手';      // 15% - 遊撃手
    return '外野手';                       // 37% - 外野手
  }

  // ポジション別調整を適用
  Map<String, int> _applyPositionAdjustments(Map<String, int> abilities, String position, Random random) {
    final adjustedAbilities = Map<String, int>.from(abilities);
    
    if (position == '投手') {
      // 投手の場合は投手能力値を高めに調整
      final pitcherAbilities = ['control', 'stamina', 'breakAvg', 'fastballVelo'];
      for (final ability in pitcherAbilities) {
        if (adjustedAbilities.containsKey(ability)) {
          final bonus = random.nextInt(21); // +0-20
          if (ability == 'fastballVelo') {
            adjustedAbilities[ability] = (adjustedAbilities[ability]! + bonus).clamp(125, 170);
          } else {
            adjustedAbilities[ability] = (adjustedAbilities[ability]! + bonus).clamp(25, 150);
          }
        }
      }
    } else {
      // 野手の場合は野手能力値を高めに調整
      final batterAbilities = ['batPower', 'batControl', 'run', 'field', 'arm'];
      for (final ability in batterAbilities) {
        if (adjustedAbilities.containsKey(ability)) {
          final bonus = random.nextInt(21); // +0-20
          adjustedAbilities[ability] = (adjustedAbilities[ability]! + bonus).clamp(25, 150);
        }
      }
    }
    
    return adjustedAbilities;
  }
  
  int _randomTalent(Random random) {
    final r = random.nextInt(1000000); // より細かい確率制御のため1000000を使用
    if (r < 600000) return 1;      // 60% (ランク1が主流)
    if (r < 850000) return 2;      // 25% (ランク2)
    if (r < 980000) return 3;      // 13% (ランク3)
    if (r < 999500) return 4;      // 1.95% (ランク4)
    if (r < 999990) return 5;      // 0.049% (ランク5)
    return 6;                      // 0.001% (1000年に1人程度)
  }
  
  String _randomGrowthType(Random random) {
    const types = ['early', 'normal', 'late', 'spurt'];
    return types[random.nextInt(types.length)];
  }
  
  Map<String, int> _randomPositionFit(String mainPosition, Random random) {
    const positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final fit = <String, int>{};
    for (final pos in positions) {
      if (pos == mainPosition) {
        fit[pos] = 70 + random.nextInt(21); // 70-90
      } else {
        fit[pos] = 40 + random.nextInt(31); // 40-70
      }
    }
    return fit;
  }

  // 球種の生成
  List<Pitch> _generatePitches(int talentRank, Random random) {
    final pitches = <Pitch>[];
    
    // 直球は必ず習得
    pitches.add(Pitch(
      type: '直球',
      breakAmount: 0,
      breakPot: 15 + random.nextInt(26), // 15-40
      unlocked: true,
    ));
    
    // 他の球種はランダムに習得
    final pitchTypes = ['カーブ', 'スライダー', 'フォーク', 'チェンジアップ'];
    for (final type in pitchTypes) {
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
  
  // 成長タイプの決定
  String _determineGrowthType(Random random) {
    final types = ['early', 'normal', 'late', 'spurt'];
    return types[random.nextInt(types.length)];
  }
  
  // 知名度の決定
  int _determineFame(int talentRank, Random random) {
    switch (talentRank) {
      case 1: return random.nextBool() ? 1 : 2;
      case 2: return 2 + random.nextInt(2); // 2-3
      case 3: return 3 + random.nextInt(2); // 3-4
      case 4: return 4 + random.nextInt(2); // 4-5
      case 5: return 5;
      case 6: return 5; // 怪物級
      default: return 2;
    }
  }
  
  // 名前の生成
  String _generateName(Random random) {
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    return names[random.nextInt(names.length)] + 
           (random.nextInt(999) + 1).toString().padLeft(3, '0');
  }
  
  // 学年の決定
  int _generateGrade(Random random) {
    return 1 + random.nextInt(3); // 1-3年生
  }
  
  // デフォルトポジション適性の生成
  Map<String, int> _generatePositionFit(String position, Random random) {
    final fits = <String, int>{};
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '外野手'];
    
    for (final pos in positions) {
      if (pos == position) {
        fits[pos] = 70 + Random().nextInt(21); // 70-90
      } else {
        fits[pos] = 40 + Random().nextInt(31); // 40-70
      }
    }
    
    return fits;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'players': players.map((p) => p.toJson()).toList(),
    'coachTrust': coachTrust,
    'coachName': coachName,
  };

  factory School.fromJson(Map<String, dynamic> json) => School(
    name: json['name'],
    location: json['location'],
    players: (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
    coachTrust: json['coachTrust'],
    coachName: json['coachName'],
  );
} 