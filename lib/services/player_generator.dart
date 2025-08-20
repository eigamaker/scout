import 'dart:math';
import '../models/player/player.dart';
import '../models/player/achievement.dart';
import '../models/player/player_abilities.dart';
import '../models/professional/professional_team.dart';
import '../utils/name_generator.dart';

class PlayerGenerator {
  static final Random _random = Random();

  // 能力値システムの生成メソッド
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
          baseValue += _random.nextInt(16); // 野手は打撃能力+0-15
        }
      }
      
      // 怪物級（才能ランク6）は上限90
      final maxValue = talent == 6 ? 90 : 100;
      abilities[ability] = baseValue.clamp(25, maxValue);
    }
    
    return abilities;
  }
  
  static int _getBaseAbilityByTalent(int talent) {
    switch (talent) {
      case 1: return 25; // 25-45（高校生全体の下限）
      case 2: return 35; // 35-55
      case 3: return 45; // 45-65
      case 4: return 55; // 55-75
      case 5: return 65; // 65-85
      case 6: return 75; // 75-90（怪物級は上限90）
      default: return 35;
    }
  }
  
  static Map<MentalAbility, int> generateMentalAbilities(int talent) {
    final abilities = <MentalAbility, int>{};
    
    // 才能ランクに基づく基本能力値を決定
    final baseAbility = _getBaseAbilityByTalent(talent);
    
    for (final ability in MentalAbility.values) {
      int baseValue = baseAbility + _random.nextInt(20); // 基本値 + ランダム変動
      
      // 才能ランクによる微調整
      baseValue += (talent - 1) * 3; // 才能ランク1つにつき+3
      
      // ランダムな変動
      baseValue += _random.nextInt(11) - 5; // -5から+5の変動
      
      // 怪物級（才能ランク6）は上限90
      final maxValue = talent == 6 ? 90 : 100;
      abilities[ability] = baseValue.clamp(25, maxValue);
    }
    
    return abilities;
  }
  
  static Map<PhysicalAbility, int> generatePhysicalAbilities(int talent, String position) {
    final abilities = <PhysicalAbility, int>{};
    
    // 才能ランクに基づく基本能力値を決定
    final baseAbility = _getBaseAbilityByTalent(talent);
    
    for (final ability in PhysicalAbility.values) {
      int baseValue = baseAbility + _random.nextInt(20); // 基本値 + ランダム変動
      
      // 才能ランクによる微調整
      baseValue += (talent - 1) * 3; // 才能ランク1つにつき+3
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == PhysicalAbility.stamina) {
            baseValue += _random.nextInt(16); // +0-15
          }
          break;
        case '外野手':
          if (ability == PhysicalAbility.pace) {
            baseValue += _random.nextInt(21); // +0-20
          }
          break;
        case '内野手':
          if (ability == PhysicalAbility.agility) {
            baseValue += _random.nextInt(16); // +0-15
          }
          break;
      }
      
      // 怪物級（才能ランク6）は上限90
      final maxValue = talent == 6 ? 90 : 100;
      abilities[ability] = baseValue.clamp(25, maxValue);
    }
    
    return abilities;
  }
  
  // 能力値システムのポテンシャル生成メソッド
  static Map<TechnicalAbility, int> generateTechnicalPotentials(int talent, String position) {
    final potentials = <TechnicalAbility, int>{};
    
    // 才能ランクに基づく基本ポテンシャルを決定
    final basePotential = _getBasePotentialByTalent(talent);
    
    for (final ability in TechnicalAbility.values) {
      int baseValue = basePotential + _random.nextInt(30) - 15; // 基本値 + ランダム変動
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == TechnicalAbility.control || 
              ability == TechnicalAbility.fastball || 
              ability == TechnicalAbility.breakingBall ||
              ability == TechnicalAbility.pitchMovement) {
            baseValue += _random.nextInt(21); // 投手能力ポテンシャル+0-20
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
          baseValue += _random.nextInt(16); // 野手は打撃能力ポテンシャル+0-15
        }
      }
      
      potentials[ability] = baseValue.clamp(50, 150);
    }
    
    return potentials;
  }
  
  static Map<MentalAbility, int> generateMentalPotentials(int talent) {
    final potentials = <MentalAbility, int>{};
    
    // 才能ランクに基づく基本ポテンシャルを決定
    final basePotential = _getBasePotentialByTalent(talent);
    
    for (final ability in MentalAbility.values) {
      int baseValue = basePotential + _random.nextInt(30) - 15; // 基本値 + ランダム変動
      
      // 才能ランクによる微調整
      baseValue += (talent - 1) * 3; // 才能ランク1つにつき+3
      
      // ランダムな変動
      baseValue += _random.nextInt(11) - 5; // -5から+5の変動
      
      potentials[ability] = baseValue.clamp(50, 150);
    }
    
    return potentials;
  }
  
  static Map<PhysicalAbility, int> generatePhysicalPotentials(int talent, String position) {
    final potentials = <PhysicalAbility, int>{};
    
    // 才能ランクに基づく基本ポテンシャルを決定
    final basePotential = _getBasePotentialByTalent(talent);
    
    for (final ability in PhysicalAbility.values) {
      int baseValue = basePotential + _random.nextInt(30) - 15; // 基本値 + ランダム変動
      
      // 才能ランクによる微調整
      baseValue += (talent - 1) * 3; // 才能ランク1つにつき+3
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == PhysicalAbility.stamina) {
            baseValue += _random.nextInt(21); // 投手はスタミナポテンシャル+0-20
          }
          break;
        case '外野手':
          if (ability == PhysicalAbility.pace || ability == PhysicalAbility.acceleration) {
            baseValue += _random.nextInt(16); // 外野手は走力系ポテンシャル+0-15
          }
          break;
        case '内野手':
          if (ability == PhysicalAbility.agility || ability == PhysicalAbility.balance) {
            baseValue += _random.nextInt(16); // 内野手は敏捷性系ポテンシャル+0-15
          }
          break;
      }
      
      potentials[ability] = baseValue.clamp(50, 150);
    }
    
    return potentials;
  }
  
  static int _getBasePotentialByTalent(int talent) {
    switch (talent) {
      case 1: return 75; // 75-95（現在値25-45を確実に上回る）
      case 2: return 85; // 85-105
      case 3: return 95; // 95-115
      case 4: return 105; // 105-125
      case 5: return 115; // 115-135
      case 6: return 140; // 140-150（怪物級の伝説級ポテンシャル）
      default: return 85;
    }
  }
  
  // 能力値システムに対応した個別ポテンシャル生成
  static Map<String, int> generateIndividualPotentials(int talent, String position) {
    final potentials = <String, int>{};
    
    // Technical（技術面）能力値ポテンシャル
    final technicalPotentials = generateTechnicalPotentials(talent, position);
    for (final entry in technicalPotentials.entries) {
      potentials[entry.key.name] = entry.value;
    }
    
    // Mental（メンタル面）能力値ポテンシャル
    final mentalPotentials = generateMentalPotentials(talent);
    for (final entry in mentalPotentials.entries) {
      potentials[entry.key.name] = entry.value;
    }
    
    // Physical（フィジカル面）能力値ポテンシャル
    final physicalPotentials = generatePhysicalPotentials(talent, position);
    for (final entry in physicalPotentials.entries) {
      potentials[entry.key.name] = entry.value;
    }
    
    return potentials;
  }
  
  // プロ野球選手を生成
  static List<Player> generateProfessionalPlayers(ProfessionalTeam team) {
    final players = <Player>[];
    final random = Random();
    
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
    
    // 各ポジションの選手を生成
    for (final entry in positionCounts.entries) {
      final position = entry.key;
      final count = entry.value;
      
      for (int i = 0; i < count; i++) {
        // talentランク3, 4, 5のみ（NPB選手レベル）
        final talent = _generateTalent();
        
        // 年齢は18-35歳（プロ野球選手の一般的な年齢）
        final age = 18 + random.nextInt(18);
        
        // 年齢に基づいて能力値の成長段階を決定
        final ageGroup = _getAgeGroup(age);
        final experienceLevel = _getExperienceLevel(age);
        
        // 既存の高校生用能力値生成メソッドを活用（プロ野球選手用に調整）
        final technicalAbilities = _generateProfessionalTechnicalAbilities(talent, position, ageGroup, experienceLevel);
        final mentalAbilities = _generateProfessionalMentalAbilities(talent, ageGroup, experienceLevel);
        final physicalAbilities = _generateProfessionalPhysicalAbilities(talent, position, ageGroup, experienceLevel);
        
        // 既存の高校生用ポテンシャル生成メソッドを活用（プロ野球選手用に調整）
        final individualPotentials = _generateProfessionalIndividualPotentials(talent, position, ageGroup);
        
        // 年齢に基づいてピーク能力を調整
        final peakAbility = _calculatePeakAbilityByAge(talent, age);
        
        final player = Player(
          name: 'プロ選手${i + 1}',
          school: 'プロ野球団',
          grade: 0, // プロ選手は学年なし
          position: position,
          personality: 'プロフェッショナル',
          type: PlayerType.social, // 既存のPlayerTypeを使用
          age: age,
          yearsAfterGraduation: age - 18,
          technicalAbilities: technicalAbilities,
          mentalAbilities: mentalAbilities,
          physicalAbilities: physicalAbilities,
          mentalGrit: 0.7 + (random.nextDouble() - 0.5) * 0.2, // 0.6-0.8
          growthRate: 0.9 + (random.nextDouble() - 0.5) * 0.2, // 0.8-1.0
          peakAbility: peakAbility,
          positionFit: _generatePositionFit(position, random),
          talent: talent,
          growthType: _generateGrowthType(random),
          individualPotentials: individualPotentials,
        );
        
        players.add(player);
      }
    }
    
    return players;
  }
  
  /// 才能ランクを生成（改善版）
  static int _generateTalent() {
    final random = Random();
    final r = random.nextInt(1000000); // より細かい確率制御のため1000000を使用
    if (r < 700000) return 1;      // 70%
    if (r < 930000) return 2;      // 23%
    if (r < 980000) return 3;      // 5%
    if (r < 999800) return 4;      // 2%
    if (r < 999990) return 5;      // 0.01%
    return 6;                       // 0.0004% (各県に数人程度)
  }
  
  // 年齢グループを取得（能力値生成の基準）
  static String _getAgeGroup(int age) {
    if (age <= 22) return 'young';      // 若手（18-22歳）
    else if (age <= 28) return 'prime'; // 全盛期（23-28歳）
    else if (age <= 32) return 'veteran'; // ベテラン（29-32歳）
    else return 'senior';               // シニア（33-35歳）
  }
  
  // 経験レベルを取得（能力値の安定性）
  static String _getExperienceLevel(int age) {
    if (age <= 20) return 'rookie';     // ルーキー（18-20歳）
    else if (age <= 25) return 'developing'; // 成長期（21-25歳）
    else if (age <= 30) return 'established'; // 確立期（26-30歳）
    else return 'mature';               // 成熟期（31-35歳）
  }
  
  // 年齢に基づくピーク能力を計算
  static int _calculatePeakAbilityByAge(int talent, int age) {
    final random = Random();
    final basePeak = 100 + (talent - 3) * 10; // talent 3: 100, 4: 110, 5: 120
    
    if (age <= 22) {
      // 若手：ピーク能力の70-85%（まだ成長の余地あり）
      return (basePeak * (0.7 + random.nextDouble() * 0.15)).round();
    } else if (age <= 28) {
      // 全盛期：ピーク能力の90-105%（ピーク付近）
      return (basePeak * (0.9 + random.nextDouble() * 0.15)).round();
    } else if (age <= 32) {
      // ベテラン：ピーク能力の85-95%（ピークを過ぎたが高いレベル維持）
      return (basePeak * (0.85 + random.nextDouble() * 0.1)).round();
    } else {
      // シニア：ピーク能力の75-85%（能力低下）
      return (basePeak * (0.75 + random.nextDouble() * 0.1)).round();
    }
  }
  
  // 年齢に基づく成長率を計算
  static double _calculateGrowthRateByAge(int age) {
    final random = Random();
    
    if (age <= 22) {
      // 若手：高い成長率（1.0-1.2）
      return 1.0 + random.nextDouble() * 0.2;
    } else if (age <= 28) {
      // 全盛期：標準的な成長率（0.95-1.05）
      return 0.95 + random.nextDouble() * 0.1;
    } else if (age <= 32) {
      // ベテラン：低い成長率（0.85-0.95）
      return 0.85 + random.nextDouble() * 0.1;
    } else {
      // シニア：非常に低い成長率（0.75-0.85）
      return 0.75 + random.nextDouble() * 0.1;
    }
  }
  
  // 年齢に基づく成長タイプを決定
  static String _getGrowthTypeByAge(int age) {
    if (age <= 22) return '若手成長型';
    else if (age <= 28) return '全盛期型';
    else if (age <= 32) return 'ベテラン型';
    else return 'シニア型';
  }
  
  // プロ野球選手用の技術面能力値生成（既存メソッドを活用）
  static Map<TechnicalAbility, int> _generateProfessionalTechnicalAbilities(int talent, String position, String ageGroup, String experienceLevel) {
    // 既存の高校生用メソッドを呼び出し
    final baseAbilities = generateTechnicalAbilities(talent, position);
    final random = Random();
    
    // 年齢と経験に基づいて能力値を調整
    for (final entry in baseAbilities.entries) {
      final ability = entry.key;
      int value = entry.value;
      
      // プロ野球選手レベルに調整（基本値+50-70）
      value += 50 + random.nextInt(21); // 50-70の追加
      
      // 年齢グループによる調整
      if (ageGroup == 'young') {
        value += random.nextInt(10); // 若手は能力値が若干高め
      } else if (ageGroup == 'prime') {
        value += random.nextInt(5); // 全盛期は能力値が若干低め
      }
      
      // 経験レベルによる調整
      if (experienceLevel == 'rookie') {
        value += random.nextInt(10); // ルーキーは能力値が若干高め
      } else if (experienceLevel == 'developing') {
        value += random.nextInt(5); // 成長期は能力値が若干低め
      }
      
      // NPB選手レベルに制限（95-120）
      baseAbilities[ability] = value.clamp(95, 120);
    }
    
    return baseAbilities;
  }
  
  // プロ野球選手用のメンタル面能力値生成（既存メソッドを活用）
  static Map<MentalAbility, int> _generateProfessionalMentalAbilities(int talent, String ageGroup, String experienceLevel) {
    // 既存の高校生用メソッドを呼び出し
    final baseAbilities = generateMentalAbilities(talent);
    final random = Random();
    
    // 年齢と経験に基づいて能力値を調整
    for (final entry in baseAbilities.entries) {
      final ability = entry.key;
      int value = entry.value;
      
      // プロ野球選手レベルに調整（基本値+50-70）
      value += 50 + random.nextInt(21); // 50-70の追加
      
      // 年齢グループによる調整
      if (ageGroup == 'young') {
        value += random.nextInt(10); // 若手は能力値が若干高め
      } else if (ageGroup == 'prime') {
        value += random.nextInt(5); // 全盛期は能力値が若干低め
      }
      
      // 経験レベルによる調整
      if (experienceLevel == 'rookie') {
        value += random.nextInt(10); // ルーキーは能力値が若干高め
      } else if (experienceLevel == 'developing') {
        value += random.nextInt(5); // 成長期は能力値が若干低め
      }
      
      // NPB選手レベルに制限（95-120）
      baseAbilities[ability] = value.clamp(95, 120);
    }
    
    return baseAbilities;
  }
  
  // プロ野球選手用のフィジカル面能力値生成（既存メソッドを活用）
  static Map<PhysicalAbility, int> _generateProfessionalPhysicalAbilities(int talent, String position, String ageGroup, String experienceLevel) {
    // 既存の高校生用メソッドを呼び出し
    final baseAbilities = generatePhysicalAbilities(talent, position);
    final random = Random();
    
    // 年齢と経験に基づいて能力値を調整
    for (final entry in baseAbilities.entries) {
      final ability = entry.key;
      int value = entry.value;
      
      // プロ野球選手レベルに調整（基本値+50-70）
      value += 50 + random.nextInt(21); // 50-70の追加
      
      // 年齢グループによる調整
      if (ageGroup == 'young') {
        value += random.nextInt(10); // 若手は能力値が若干高め
      } else if (ageGroup == 'prime') {
        value += random.nextInt(5); // 全盛期は能力値が若干低め
      }
      
      // 経験レベルによる調整
      if (experienceLevel == 'rookie') {
        value += random.nextInt(10); // ルーキーは能力値が若干高め
      } else if (experienceLevel == 'developing') {
        value += random.nextInt(5); // 成長期は能力値が若干低め
      }
      
      // NPB選手レベルに制限（95-120）
      baseAbilities[ability] = value.clamp(95, 120);
    }
    
    return baseAbilities;
  }
  
  // プロ野球選手用の個別ポテンシャル生成（既存メソッドを活用）
  static Map<String, int> _generateProfessionalIndividualPotentials(int talent, String position, String ageGroup) {
    // 既存の高校生用メソッドを呼び出し
    final basePotentials = generateIndividualPotentials(talent, position);
    final random = Random();
    
    // 年齢グループによるポテンシャル調整
    double ageMultiplier;
    switch (ageGroup) {
      case 'young':
        ageMultiplier = 1.0 + random.nextDouble() * 0.1; // 若手：100-110%
        break;
      case 'prime':
        ageMultiplier = 0.95 + random.nextDouble() * 0.1; // 全盛期：95-105%
        break;
      case 'veteran':
        ageMultiplier = 0.9 + random.nextDouble() * 0.1; // ベテラン：90-100%
        break;
      case 'senior':
        ageMultiplier = 0.85 + random.nextDouble() * 0.1; // シニア：85-95%
        break;
      default:
        ageMultiplier = 1.0;
    }
    
    // 各ポテンシャルを年齢に基づいて調整
    for (final entry in basePotentials.entries) {
      final baseValue = (entry.value * ageMultiplier).round();
      basePotentials[entry.key] = baseValue + random.nextInt(11) - 5; // ±5の変動
    }
    
    return basePotentials;
  }
  
  // プロ野球選手用のポジション適性生成
  static Map<String, int> _generatePositionFit(String position, Random random) {
    final fit = <String, int>{};
    
    // メインポジションは90-100
    fit[position] = 90 + random.nextInt(11);
    
    // 他のポジションは適度に低く
    final otherPositions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    for (final otherPosition in otherPositions) {
      if (otherPosition != position) {
        fit[otherPosition] = 20 + random.nextInt(41); // 20-60
      }
    }
    
    return fit;
  }
  
  // プロ野球選手用の成長タイプを決定
  static String _generateGrowthType(Random random) {
    final r = random.nextInt(100);
    if (r < 30) return '若手成長型';
    else if (r < 60) return '全盛期型';
    else if (r < 90) return 'ベテラン型';
    else return 'シニア型';
  }
  
  // プロ野球選手用の実績生成
  static List<Achievement> _generateProfessionalAchievements(int talent, int age) {
    final achievements = <Achievement>[];
    final random = Random();
    
    // 年齢に基づいて実績数を決定
    int achievementCount;
    if (age <= 22) {
      achievementCount = 1 + random.nextInt(2); // 若手：1-2個
    } else if (age <= 28) {
      achievementCount = 2 + random.nextInt(3); // 全盛期：2-4個
    } else if (age <= 32) {
      achievementCount = 3 + random.nextInt(3); // ベテラン：3-5個
    } else {
      achievementCount = 4 + random.nextInt(3); // シニア：4-6個
    }
    
    // 才能ランクによる調整
    achievementCount += (talent - 3) * 2; // talent 3: +0, 4: +2, 5: +4
    
    // 実績の種類を年齢に応じて選択
    final availableAchievements = <AchievementType>[];
    
    if (age <= 22) {
      // 若手：ルーキー関連の実績
      availableAchievements.addAll([
        AchievementType.rookieOfTheYear,
        AchievementType.allStar,
        AchievementType.homeRunKing,
        AchievementType.strikeoutKing,
        AchievementType.bestPitcher,
        AchievementType.bestBatter,
      ]);
    } else if (age <= 28) {
      // 全盛期：主要な個人タイトル
      availableAchievements.addAll([
        AchievementType.mvp,
        AchievementType.bestPitcher,
        AchievementType.bestBatter,
        AchievementType.homeRunKing,
        AchievementType.strikeoutKing,
        AchievementType.allStar,
        AchievementType.goldenGlove,
        AchievementType.noHitter,
        AchievementType.perfectGame,
      ]);
    } else if (age <= 32) {
      // ベテラン：長期的な実績
      availableAchievements.addAll([
        AchievementType.mvp,
        AchievementType.bestPitcher,
        AchievementType.bestBatter,
        AchievementType.homeRunKing,
        AchievementType.strikeoutKing,
        AchievementType.allStar,
        AchievementType.goldenGlove,
        AchievementType.noHitter,
        AchievementType.perfectGame,
        AchievementType.cycleHit,
        AchievementType.grandSlam,
      ]);
    } else {
      // シニア：キャリア実績
      availableAchievements.addAll([
        AchievementType.mvp,
        AchievementType.bestPitcher,
        AchievementType.bestBatter,
        AchievementType.homeRunKing,
        AchievementType.strikeoutKing,
        AchievementType.allStar,
        AchievementType.goldenGlove,
        AchievementType.noHitter,
        AchievementType.perfectGame,
        AchievementType.cycleHit,
        AchievementType.grandSlam,
        AchievementType.comebackPlayer,
      ]);
    }
    
    // 実績を生成
    for (int i = 0; i < achievementCount && availableAchievements.isNotEmpty; i++) {
      final type = availableAchievements[random.nextInt(availableAchievements.length)];
      final year = 2024 - random.nextInt(age - 17); // 年齢に応じた年数
      final month = random.nextInt(12) + 1;
      
      achievements.add(Achievement.create(
        type: type,
        year: year,
        month: month,
        team: 'プロ野球団',
      ));
      
      // 同じ実績を重複させない
      availableAchievements.remove(type);
    }
    
    return achievements;
  }
  
  // プロ野球選手用の名前生成
  static String _generateProfessionalPlayerName() {
    return NameGenerator.generateProfessionalPlayerName();
  }
  
  // プロ野球選手用の性格生成
  static String _generateProfessionalPersonality() {
    final personalities = ['リーダー', '冷静', '積極的', '謙虚', '情熱的', '集中力', '責任感'];
    return personalities[Random().nextInt(personalities.length)];
  }
}
