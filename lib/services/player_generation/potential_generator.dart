import 'dart:math';
import '../../models/player/player_abilities.dart';

/// 選手のポテンシャル生成を担当するクラス
class PotentialGenerator {
  static final Random _random = Random();

  /// 技術面ポテンシャルを生成
  static Map<TechnicalAbility, int> generateTechnicalPotentials(int talent, String position) {
    final potentials = <TechnicalAbility, int>{};
    final basePotential = _getBasePotentialByTalent(talent);
    
    for (final ability in TechnicalAbility.values) {
      int baseValue = basePotential + _random.nextInt(25);
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == TechnicalAbility.control || 
              ability == TechnicalAbility.fastball || 
              ability == TechnicalAbility.breakingBall ||
              ability == TechnicalAbility.pitchMovement) {
            baseValue += _random.nextInt(26); // 投手能力+0-25
          }
          break;
        case '捕手':
          if (ability == TechnicalAbility.catcherAbility) {
            baseValue += _random.nextInt(26);
          }
          break;
        case '内野手':
        case '外野手':
          if (ability == TechnicalAbility.fielding || 
              ability == TechnicalAbility.throwing) {
            baseValue += _random.nextInt(21); // +0-20
          }
          break;
      }
      
      // 打撃技術の調整
      if (ability == TechnicalAbility.contact || 
          ability == TechnicalAbility.power ||
          ability == TechnicalAbility.plateDiscipline ||
          ability == TechnicalAbility.batControl ||
          ability == TechnicalAbility.swingSpeed) {
        if (position != '投手') {
          baseValue += _random.nextInt(21); // 野手は打撃技術+0-20
        }
      }
      
      potentials[ability] = baseValue.clamp(1, 100);
    }
    
    return potentials;
  }

  /// メンタル面ポテンシャルを生成
  static Map<MentalAbility, int> generateMentalPotentials(int talent) {
    final potentials = <MentalAbility, int>{};
    final basePotential = _getBasePotentialByTalent(talent);
    
    for (final ability in MentalAbility.values) {
      int baseValue = basePotential + _random.nextInt(25);
      
      // メンタル能力の特別調整
      if (ability == MentalAbility.concentration || 
          ability == MentalAbility.composure ||
          ability == MentalAbility.pressureHandling) {
        baseValue += _random.nextInt(16); // 重要なメンタル能力+0-15
      }
      
      potentials[ability] = baseValue.clamp(1, 100);
    }
    
    return potentials;
  }

  /// フィジカル面ポテンシャルを生成
  static Map<PhysicalAbility, int> generatePhysicalPotentials(int talent, String position) {
    final potentials = <PhysicalAbility, int>{};
    final basePotential = _getBasePotentialByTalent(talent);
    
    for (final ability in PhysicalAbility.values) {
      int baseValue = basePotential + _random.nextInt(25);
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == PhysicalAbility.strength || 
              ability == PhysicalAbility.stamina) {
            baseValue += _random.nextInt(21); // 投手は体力・筋力重視
          }
          break;
        case '外野手':
          if (ability == PhysicalAbility.acceleration || 
              ability == PhysicalAbility.pace) {
            baseValue += _random.nextInt(21); // 外野手はスピード重視
          }
          break;
        case '内野手':
          if (ability == PhysicalAbility.agility || 
              ability == PhysicalAbility.balance) {
            baseValue += _random.nextInt(16); // 内野手は敏捷性重視
          }
          break;
      }
      
      // 怪我しやすさは低い方が良い
      if (ability == PhysicalAbility.injuryProneness) {
        baseValue = (baseValue * 0.7).round(); // 怪我しやすさを下げる
      }
      
      potentials[ability] = baseValue.clamp(1, 100);
    }
    
    return potentials;
  }

  /// 個別ポテンシャルを生成
  static Map<String, int> generateIndividualPotentials(int talent, String position) {
    final individualPotentials = <String, int>{};
    
    // 技術面ポテンシャル
    final technicalPotentials = generateTechnicalPotentials(talent, position);
    for (final entry in technicalPotentials.entries) {
      individualPotentials[entry.key.name] = entry.value;
    }
    
    // メンタル面ポテンシャル
    final mentalPotentials = generateMentalPotentials(talent);
    for (final entry in mentalPotentials.entries) {
      individualPotentials[entry.key.name] = entry.value;
    }
    
    // フィジカル面ポテンシャル
    final physicalPotentials = generatePhysicalPotentials(talent, position);
    for (final entry in physicalPotentials.entries) {
      individualPotentials[entry.key.name] = entry.value;
    }
    
    return individualPotentials;
  }

  /// 総合ポテンシャル値を計算
  static int calculateOverallPotential(Map<String, int> individualPotentials, String position) {
    final technicalPotential = _calculateTechnicalPotential(individualPotentials);
    final mentalPotential = _calculateMentalPotential(individualPotentials);
    final physicalPotential = _calculatePhysicalPotential(individualPotentials);
    
    // ポジション別の重み付け
    if (position == '投手') {
      // 投手: 技術50%、精神30%、身体20%
      return ((technicalPotential * 0.5) + (mentalPotential * 0.3) + (physicalPotential * 0.2)).round();
    } else {
      // 野手: 技術40%、精神25%、身体35%
      return ((technicalPotential * 0.4) + (mentalPotential * 0.25) + (physicalPotential * 0.35)).round();
    }
  }

  /// 技術面ポテンシャル値を計算
  static int _calculateTechnicalPotential(Map<String, int> individualPotentials) {
    final technicalKeys = TechnicalAbility.values.map((e) => e.name).toList();
    final values = technicalKeys.map((key) => individualPotentials[key] ?? 50).toList();
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  /// メンタル面ポテンシャル値を計算
  static int _calculateMentalPotential(Map<String, int> individualPotentials) {
    final mentalKeys = MentalAbility.values.map((e) => e.name).toList();
    final values = mentalKeys.map((key) => individualPotentials[key] ?? 50).toList();
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  /// フィジカル面ポテンシャル値を計算
  static int _calculatePhysicalPotential(Map<String, int> individualPotentials) {
    final physicalKeys = PhysicalAbility.values.map((e) => e.name).toList();
    final values = physicalKeys.map((key) => individualPotentials[key] ?? 50).toList();
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  /// 才能ランクに基づく基本ポテンシャル値を取得
  static int _getBasePotentialByTalent(int talent) {
    switch (talent) {
      case 1: return 30; // 弱小
      case 2: return 45; // 平均
      case 3: return 60; // 有望
      case 4: return 75; // 才能
      case 5: return 90; // 天才
      default: return 60;
    }
  }
}
