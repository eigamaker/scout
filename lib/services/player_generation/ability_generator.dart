import 'dart:math';
import '../../models/player/player_abilities.dart';

/// 選手の能力値生成を担当するクラス
class AbilityGenerator {
  static final Random _random = Random();

  /// 技術面能力値を生成
  static Map<TechnicalAbility, int> generateTechnicalAbilities(int talent, String position) {
    final abilities = <TechnicalAbility, int>{};
    
    // 才能ランクに基づく基本能力値を決定
    final baseAbility = _getBaseAbilityByTalent(talent);
    
    for (final ability in TechnicalAbility.values) {
      int baseValue = baseAbility + _random.nextInt(20); // 基本値 + ランダム変動
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == TechnicalAbility.control || 
              ability == TechnicalAbility.fastball || 
              ability == TechnicalAbility.breakingBall ||
              ability == TechnicalAbility.pitchMovement) {
            baseValue += _random.nextInt(21); // 投手能力+0-20
          }
          break;
        case '捕手':
          if (ability == TechnicalAbility.catcherAbility) {
            baseValue += _random.nextInt(21);
          }
          break;
        case '内野手':
        case '外野手':
          if (ability == TechnicalAbility.fielding || 
              ability == TechnicalAbility.throwing) {
            baseValue += _random.nextInt(16); // +0-15
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
          baseValue += _random.nextInt(16); // 野手は打撃技術+0-15
        }
      }
      
      // 能力値の上限・下限を設定
      abilities[ability] = baseValue.clamp(1, 100);
    }
    
    return abilities;
  }

  /// メンタル面能力値を生成
  static Map<MentalAbility, int> generateMentalAbilities(int talent) {
    final abilities = <MentalAbility, int>{};
    final baseAbility = _getBaseAbilityByTalent(talent);
    
    for (final ability in MentalAbility.values) {
      int baseValue = baseAbility + _random.nextInt(20);
      
      // メンタル能力の特別調整
      if (ability == MentalAbility.concentration || 
          ability == MentalAbility.composure ||
          ability == MentalAbility.pressureHandling) {
        baseValue += _random.nextInt(11); // 重要なメンタル能力+0-10
      }
      
      abilities[ability] = baseValue.clamp(1, 100);
    }
    
    return abilities;
  }

  /// フィジカル面能力値を生成
  static Map<PhysicalAbility, int> generatePhysicalAbilities(int talent, String position) {
    final abilities = <PhysicalAbility, int>{};
    final baseAbility = _getBaseAbilityByTalent(talent);
    
    for (final ability in PhysicalAbility.values) {
      int baseValue = baseAbility + _random.nextInt(20);
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == PhysicalAbility.strength || 
              ability == PhysicalAbility.stamina) {
            baseValue += _random.nextInt(16); // 投手は体力・筋力重視
          }
          break;
        case '外野手':
          if (ability == PhysicalAbility.acceleration || 
              ability == PhysicalAbility.pace) {
            baseValue += _random.nextInt(16); // 外野手はスピード重視
          }
          break;
        case '内野手':
          if (ability == PhysicalAbility.agility || 
              ability == PhysicalAbility.balance) {
            baseValue += _random.nextInt(11); // 内野手は敏捷性重視
          }
          break;
      }
      
      // 怪我しやすさは低い方が良い
      if (ability == PhysicalAbility.injuryProneness) {
        baseValue = (baseValue * 0.7).round(); // 怪我しやすさを下げる
      }
      
      abilities[ability] = baseValue.clamp(1, 100);
    }
    
    return abilities;
  }

  /// 才能ランクに基づく基本能力値を取得
  static int _getBaseAbilityByTalent(int talent) {
    switch (talent) {
      case 1: return 20; // 弱小
      case 2: return 35; // 平均
      case 3: return 50; // 有望
      case 4: return 65; // 才能
      case 5: return 80; // 天才
      default: return 50;
    }
  }
}
