import 'dart:math';
import '../../models/player/player.dart';
import '../../models/player/player_abilities.dart';
import '../../models/professional/professional_team.dart';
import '../../utils/name_generator.dart';
import 'ability_generator.dart';
import 'potential_generator.dart';

/// プロ野球選手の生成を担当するクラス
class ProfessionalPlayerGenerator {
  static final Random _random = Random();

  /// プロ野球選手を生成
  static List<Player> generateProfessionalPlayers(ProfessionalTeam team) {
    final players = <Player>[];
    final nameGenerator = NameGenerator();
    
    // チームのポジション別選手数を決定
    final positionCounts = {
      '投手': 12,      // 投手12名
      '捕手': 3,       // 捕手3名
      '一塁手': 2,     // 一塁手2名
      '二塁手': 2,     // 二塁手2名
      '三塁手': 2,     // 三塁手2名
      '遊撃手': 2,     // 遊撃手2名
      '左翼手': 2,     // 左翼手2名
      '中堅手': 2,     // 中堅手2名
      '右翼手': 2,     // 右翼手2名
    };
    
    for (final entry in positionCounts.entries) {
      final position = entry.key;
      final count = entry.value;
      
      for (int i = 0; i < count; i++) {
        final player = _generateProfessionalPlayer(team, position, nameGenerator);
        players.add(player);
      }
    }
    
    return players;
  }

  /// 個別のプロ野球選手を生成
  static Player _generateProfessionalPlayer(ProfessionalTeam team, String position, NameGenerator nameGenerator) {
    final age = 20 + _random.nextInt(10); // 20-29歳
    final talent = _generateTalent();
    final ageGroup = _getAgeGroup(age);
    final experienceLevel = _getExperienceLevel(age);
    
    // 能力値を生成
    final technicalAbilities = _generateProfessionalTechnicalAbilities(talent, position, ageGroup, experienceLevel);
    final mentalAbilities = _generateProfessionalMentalAbilities(talent, ageGroup, experienceLevel);
    final physicalAbilities = _generateProfessionalPhysicalAbilities(talent, position, ageGroup, experienceLevel);
    
    // ポテンシャルを生成
    final individualPotentials = _generateProfessionalIndividualPotentials(talent, position, ageGroup);
    final technicalPotentials = _getTechnicalPotentialsFromIndividual(individualPotentials);
    final mentalPotentials = _getMentalPotentialsFromIndividual(individualPotentials);
    final physicalPotentials = _getPhysicalPotentialsFromIndividual(individualPotentials);
    
    // ピーク能力を計算
    final peakAbility = _calculatePeakAbilityByAge(talent, age);
    
    return Player(
      id: null, // データベースで設定
      name: NameGenerator.generatePlayerName(),
      school: team.name,
      grade: 0, // プロ選手は学年なし
      age: age,
      position: position,
      positionFit: _generatePositionFit(position),
      fame: 70 + _random.nextInt(30), // 70-99
      isFamous: true, // プロ選手は常に注目選手
      isScoutFavorite: _random.nextBool(),
      isScouted: true,
      isGraduated: true,
      isRetired: false,
      growthRate: 0.5 + _random.nextDouble() * 0.5, // 0.5-1.0
      talent: talent,
      growthType: _generateProfessionalGrowthType(),
      mentalGrit: 0.6 + _random.nextDouble() * 0.4, // 0.6-1.0
      peakAbility: peakAbility,
      personality: 'プロフェッショナル',
      technicalAbilities: technicalAbilities,
      mentalAbilities: mentalAbilities,
      physicalAbilities: physicalAbilities,
      individualPotentials: individualPotentials,
      technicalPotentials: technicalPotentials,
      mentalPotentials: mentalPotentials,
      physicalPotentials: physicalPotentials,
    );
  }

  /// 才能ランクを生成
  static int _generateTalent() {
    // プロ選手は高めの才能ランク
    final weights = [0.05, 0.15, 0.30, 0.35, 0.15]; // 1-5の重み
    final randomValue = _random.nextDouble();
    double cumulative = 0.0;
    
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (randomValue <= cumulative) {
        return i + 1;
      }
    }
    return 3; // デフォルト
  }

  /// 年齢グループを取得
  static String _getAgeGroup(int age) {
    if (age < 25) return 'young';
    if (age < 30) return 'prime';
    return 'veteran';
  }

  /// 経験レベルを取得
  static String _getExperienceLevel(int age) {
    if (age < 23) return 'rookie';
    if (age < 27) return 'experienced';
    return 'veteran';
  }

  /// 年齢に基づくピーク能力を計算
  static int _calculatePeakAbilityByAge(int talent, int age) {
    final basePeak = 60 + (talent * 15); // 才能ランクに基づく基本ピーク
    final ageFactor = 1.0 - ((age - 25).abs() * 0.02); // 25歳をピークとする
    return (basePeak * ageFactor).round().clamp(50, 100);
  }

  /// プロ野球選手用の技術面能力値生成
  static Map<TechnicalAbility, int> _generateProfessionalTechnicalAbilities(int talent, String position, String ageGroup, String experienceLevel) {
    final abilities = AbilityGenerator.generateTechnicalAbilities(talent, position);
    
    // プロ選手は能力値を高めに調整
    final multiplier = _getProfessionalMultiplier(ageGroup, experienceLevel);
    for (final ability in abilities.keys) {
      abilities[ability] = (abilities[ability]! * multiplier).round().clamp(1, 100);
    }
    
    return abilities;
  }

  /// プロ野球選手用のメンタル面能力値生成
  static Map<MentalAbility, int> _generateProfessionalMentalAbilities(int talent, String ageGroup, String experienceLevel) {
    final abilities = AbilityGenerator.generateMentalAbilities(talent);
    
    // プロ選手は能力値を高めに調整
    final multiplier = _getProfessionalMultiplier(ageGroup, experienceLevel);
    for (final ability in abilities.keys) {
      abilities[ability] = (abilities[ability]! * multiplier).round().clamp(1, 100);
    }
    
    return abilities;
  }

  /// プロ野球選手用のフィジカル面能力値生成
  static Map<PhysicalAbility, int> _generateProfessionalPhysicalAbilities(int talent, String position, String ageGroup, String experienceLevel) {
    final abilities = AbilityGenerator.generatePhysicalAbilities(talent, position);
    
    // プロ選手は能力値を高めに調整
    final multiplier = _getProfessionalMultiplier(ageGroup, experienceLevel);
    for (final ability in abilities.keys) {
      abilities[ability] = (abilities[ability]! * multiplier).round().clamp(1, 100);
    }
    
    return abilities;
  }

  /// プロ野球選手用の個別ポテンシャル生成
  static Map<String, int> _generateProfessionalIndividualPotentials(int talent, String position, String ageGroup) {
    return PotentialGenerator.generateIndividualPotentials(talent, position);
  }

  /// プロ野球選手用のポジション適性生成
  static Map<String, int> _generatePositionFit(String position) {
    final fit = <String, int>{};
    
    // メインポジションは90-100
    fit[position] = 90 + _random.nextInt(11);
    
    // 関連ポジションは70-89
    switch (position) {
      case '投手':
        fit['捕手'] = 70 + _random.nextInt(20);
        break;
      case '捕手':
        fit['一塁手'] = 70 + _random.nextInt(20);
        break;
      case '一塁手':
        fit['三塁手'] = 70 + _random.nextInt(20);
        fit['外野手'] = 60 + _random.nextInt(20);
        break;
      case '二塁手':
        fit['遊撃手'] = 80 + _random.nextInt(20);
        fit['三塁手'] = 60 + _random.nextInt(20);
        break;
      case '三塁手':
        fit['一塁手'] = 70 + _random.nextInt(20);
        fit['外野手'] = 60 + _random.nextInt(20);
        break;
      case '遊撃手':
        fit['二塁手'] = 80 + _random.nextInt(20);
        fit['三塁手'] = 60 + _random.nextInt(20);
        break;
      case '外野手':
        fit['一塁手'] = 60 + _random.nextInt(20);
        break;
    }
    
    // その他のポジションは50-69
    final allPositions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '外野手'];
    for (final pos in allPositions) {
      if (!fit.containsKey(pos)) {
        fit[pos] = 50 + _random.nextInt(20);
      }
    }
    
    return fit;
  }

  /// プロ野球選手用の成長タイプを決定
  static String _generateProfessionalGrowthType() {
    final types = ['early', 'normal', 'late'];
    final weights = [0.3, 0.5, 0.2]; // early: 30%, normal: 50%, late: 20%
    
    final randomValue = _random.nextDouble();
    double cumulative = 0.0;
    
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (randomValue <= cumulative) {
        return types[i];
      }
    }
    return 'normal';
  }

  /// プロ選手用の能力値倍率を取得
  static double _getProfessionalMultiplier(String ageGroup, String experienceLevel) {
    double multiplier = 1.0;
    
    // 年齢グループによる調整
    switch (ageGroup) {
      case 'young':
        multiplier *= 0.9; // 若手は少し低め
        break;
      case 'prime':
        multiplier *= 1.0; // 全盛期
        break;
      case 'veteran':
        multiplier *= 0.95; // ベテランは少し低め
        break;
    }
    
    // 経験レベルによる調整
    switch (experienceLevel) {
      case 'rookie':
        multiplier *= 0.85; // ルーキーは低め
        break;
      case 'experienced':
        multiplier *= 1.0; // 経験豊富
        break;
      case 'veteran':
        multiplier *= 0.9; // ベテランは少し低め
        break;
    }
    
    return multiplier;
  }

  /// 個別ポテンシャルから技術面ポテンシャルを抽出
  static Map<TechnicalAbility, int> _getTechnicalPotentialsFromIndividual(Map<String, int> individualPotentials) {
    final potentials = <TechnicalAbility, int>{};
    for (final ability in TechnicalAbility.values) {
      potentials[ability] = individualPotentials[ability.name] ?? 50;
    }
    return potentials;
  }

  /// 個別ポテンシャルからメンタル面ポテンシャルを抽出
  static Map<MentalAbility, int> _getMentalPotentialsFromIndividual(Map<String, int> individualPotentials) {
    final potentials = <MentalAbility, int>{};
    for (final ability in MentalAbility.values) {
      potentials[ability] = individualPotentials[ability.name] ?? 50;
    }
    return potentials;
  }

  /// 個別ポテンシャルからフィジカル面ポテンシャルを抽出
  static Map<PhysicalAbility, int> _getPhysicalPotentialsFromIndividual(Map<String, int> individualPotentials) {
    final potentials = <PhysicalAbility, int>{};
    for (final ability in PhysicalAbility.values) {
      potentials[ability] = individualPotentials[ability.name] ?? 50;
    }
    return potentials;
  }
}
