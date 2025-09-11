import 'dart:math';
import '../models/player/player.dart';
import '../models/player/achievement.dart';
import '../models/player/player_abilities.dart';
import '../models/professional/professional_team.dart';
import '../utils/name_generator.dart';
import 'player_generation/ability_generator.dart';
import 'player_generation/potential_generator.dart';
import 'player_generation/professional_player_generator.dart';

/// 選手生成のメインクラス（リファクタリング版）
class PlayerGenerator {
  static final Random _random = Random();

  // 能力値システムの生成メソッド（委譲）
  static Map<TechnicalAbility, int> generateTechnicalAbilities(int talent, String position) {
    return AbilityGenerator.generateTechnicalAbilities(talent, position);
  }

  static Map<MentalAbility, int> generateMentalAbilities(int talent) {
    return AbilityGenerator.generateMentalAbilities(talent);
  }

  static Map<PhysicalAbility, int> generatePhysicalAbilities(int talent, String position) {
    return AbilityGenerator.generatePhysicalAbilities(talent, position);
  }

  // ポテンシャル生成メソッド（委譲）
  static Map<TechnicalAbility, int> generateTechnicalPotentials(int talent, String position) {
    return PotentialGenerator.generateTechnicalPotentials(talent, position);
  }

  static Map<MentalAbility, int> generateMentalPotentials(int talent) {
    return PotentialGenerator.generateMentalPotentials(talent);
  }

  static Map<PhysicalAbility, int> generatePhysicalPotentials(int talent, String position) {
    return PotentialGenerator.generatePhysicalPotentials(talent, position);
  }

  static Map<String, int> generateIndividualPotentials(int talent, String position) {
    return PotentialGenerator.generateIndividualPotentials(talent, position);
  }

  /// 総合ポテンシャル値を計算
  static int _calculateOverallPotential(Map<String, int> individualPotentials, String position) {
    return PotentialGenerator.calculateOverallPotential(individualPotentials, position);
  }

  /// 技術面ポテンシャル値を計算
  static int _calculateTechnicalPotential(Map<String, int> individualPotentials) {
    return PotentialGenerator.calculateOverallPotential(individualPotentials, '野手');
  }

  /// メンタル面ポテンシャル値を計算
  static int _calculateMentalPotential(Map<String, int> individualPotentials) {
    return PotentialGenerator.calculateOverallPotential(individualPotentials, '野手');
  }

  /// フィジカル面ポテンシャル値を計算
  static int _calculatePhysicalPotential(Map<String, int> individualPotentials) {
    return PotentialGenerator.calculateOverallPotential(individualPotentials, '野手');
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

  // プロ野球選手を生成（委譲）
  static List<Player> generateProfessionalPlayers(ProfessionalTeam team) {
    return ProfessionalPlayerGenerator.generateProfessionalPlayers(team);
  }

  /// 才能ランクを生成（改善版）
  static int _generateTalent() {
    // 重み付きランダム選択
    final weights = [0.20, 0.30, 0.25, 0.20, 0.05]; // 1-5の重み
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

  // 年齢グループを取得（能力値生成の基準）
  static String _getAgeGroup(int age) {
    if (age < 18) return 'young';
    if (age < 22) return 'prime';
    return 'veteran';
  }

  // 経験レベルを取得（能力値の安定性）
  static String _getExperienceLevel(int age) {
    if (age < 17) return 'rookie';
    if (age < 20) return 'experienced';
    return 'veteran';
  }

  // 年齢に基づくピーク能力を計算
  static int _calculatePeakAbilityByAge(int talent, int age) {
    final basePeak = 60 + (talent * 15); // 才能ランクに基づく基本ピーク
    final ageFactor = 1.0 - ((age - 18).abs() * 0.02); // 18歳をピークとする
    return (basePeak * ageFactor).round().clamp(50, 100);
  }

  // プロ野球選手用の技術面能力値生成（ポテンシャルの90%程度で生成）
  static Map<TechnicalAbility, int> _generateProfessionalTechnicalAbilities(int talent, String position, String ageGroup, String experienceLevel) {
    return AbilityGenerator.generateTechnicalAbilities(talent, position);
  }

  // プロ野球選手用のメンタル面能力値生成（ポテンシャルの90%程度で生成）
  static Map<MentalAbility, int> _generateProfessionalMentalAbilities(int talent, String ageGroup, String experienceLevel) {
    return AbilityGenerator.generateMentalAbilities(talent);
  }

  // プロ野球選手用のフィジカル面能力値生成（ポテンシャルの90%程度で生成）
  static Map<PhysicalAbility, int> _generateProfessionalPhysicalAbilities(int talent, String position, String ageGroup, String experienceLevel) {
    return AbilityGenerator.generatePhysicalAbilities(talent, position);
  }

  // プロ野球選手用の個別ポテンシャル生成（既存メソッドを活用）
  static Map<String, int> _generateProfessionalIndividualPotentials(int talent, String position, String ageGroup) {
    return PotentialGenerator.generateIndividualPotentials(talent, position);
  }

  // プロ野球選手用のポジション適性生成
  static Map<String, int> _generatePositionFit(String position, Random random) {
    final positionFit = <String, int>{};
    
    // ポジションに応じた適性を設定
    switch (position) {
      case '投手':
        positionFit['投手'] = 90 + random.nextInt(11); // 90-100
        positionFit['捕手'] = 20 + random.nextInt(21); // 20-40
        positionFit['一塁手'] = 30 + random.nextInt(21); // 30-50
        positionFit['二塁手'] = 20 + random.nextInt(21); // 20-40
        positionFit['三塁手'] = 20 + random.nextInt(21); // 20-40
        positionFit['遊撃手'] = 20 + random.nextInt(21); // 20-40
        positionFit['外野手'] = 20 + random.nextInt(21); // 20-40
        break;
      case '捕手':
        positionFit['投手'] = 20 + random.nextInt(21); // 20-40
        positionFit['捕手'] = 90 + random.nextInt(11); // 90-100
        positionFit['一塁手'] = 60 + random.nextInt(21); // 60-80
        positionFit['二塁手'] = 30 + random.nextInt(21); // 30-50
        positionFit['三塁手'] = 30 + random.nextInt(21); // 30-50
        positionFit['遊撃手'] = 20 + random.nextInt(21); // 20-40
        positionFit['外野手'] = 30 + random.nextInt(21); // 30-50
        break;
      default:
        // 野手の場合
        positionFit['投手'] = 20 + random.nextInt(21); // 20-40
        positionFit['捕手'] = 20 + random.nextInt(21); // 20-40
        positionFit['一塁手'] = 70 + random.nextInt(21); // 70-90
        positionFit['二塁手'] = 60 + random.nextInt(21); // 60-80
        positionFit['三塁手'] = 60 + random.nextInt(21); // 60-80
        positionFit['遊撃手'] = 50 + random.nextInt(21); // 50-70
        positionFit['外野手'] = 70 + random.nextInt(21); // 70-90
        break;
    }
    
    return positionFit;
  }

  // プロ野球選手用の成長タイプを決定
  static String _generateProfessionalGrowthType(Random random) {
    final growthTypes = ['早熟', '普通', '晩成', '持続'];
    return growthTypes[random.nextInt(growthTypes.length)];
  }

  // プロ野球選手用の名前生成
  static String _generateProfessionalPlayerName() {
    final nameGenerator = NameGenerator();
    return NameGenerator.generatePlayerName();
  }
}