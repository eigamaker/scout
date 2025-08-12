import 'dart:math';
import '../models/player/player.dart';
import '../models/player/achievement.dart';
import '../models/player/player_abilities.dart';
import '../models/professional/professional_team.dart';

class PlayerGenerator {
  static final Random _random = Random();

  // テスト用の選手データを生成
  static List<Player> generateTestPlayers() {
    return [
      // 超有名選手（怪物級）
      Player(
        name: '田中 翔太',
        school: '甲子園高校',
        grade: 1,
        position: '投手',
        personality: 'リーダー',
        trustLevel: 80,
        fame: 100,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: true,
        technicalAbilities: generateTechnicalAbilities(5, '投手'),
        mentalAbilities: generateMentalAbilities(5),
        physicalAbilities: generatePhysicalAbilities(5, '投手'),
        mentalGrit: 0.1,
        growthRate: 1.1,
        peakAbility: 140,
        positionFit: {'投手': 95, '野手': 30},
        talent: 5,
        growthType: '早期型',
        individualPotentials: generateIndividualPotentials(5, '投手'),
        achievements: [
          Achievement.create(
            type: AchievementType.u15NationalTeam,
            year: 2024,
            month: 8,
            team: 'U-15日本代表',
          ),
          Achievement.create(
            type: AchievementType.nationalChampionship,
            year: 2024,
            month: 7,
            team: '甲子園高校',
          ),
          Achievement.create(
            type: AchievementType.perfectGame,
            year: 2024,
            month: 6,
            team: '甲子園高校',
          ),
        ],
      ),

      // 有名選手（U-18日本代表）
      Player(
        name: '佐藤 健一',
        school: '野球名門高校',
        grade: 2,
        position: '外野手',
        personality: '積極的',
        trustLevel: 60,
        fame: 85,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: true,
        technicalAbilities: generateTechnicalAbilities(4, '外野手'),
        mentalAbilities: generateMentalAbilities(4),
        physicalAbilities: generatePhysicalAbilities(4, '外野手'),
        mentalGrit: 0.05,
        growthRate: 1.05,
        peakAbility: 130,
        positionFit: {'外野手': 90, '内野手': 70, '投手': 20},
        talent: 4,
        growthType: '標準型',
        individualPotentials: generateIndividualPotentials(4, '外野手'),
        achievements: [
          Achievement.create(
            type: AchievementType.u18NationalTeam,
            year: 2024,
            month: 9,
            team: 'U-18日本代表',
          ),
          Achievement.create(
            type: AchievementType.homeRunKing,
            year: 2024,
            month: 7,
            team: '野球名門高校',
          ),
        ],
      ),

      // 知られている選手（地方大会優勝）
      Player(
        name: '鈴木 大輔',
        school: '地方強豪高校',
        grade: 3,
        position: '投手',
        personality: '冷静',
        trustLevel: 40,
        fame: 55,
        isWatched: false,
        isDiscovered: true,
        isPubliclyKnown: false,
        technicalAbilities: generateTechnicalAbilities(3, '投手'),
        mentalAbilities: generateMentalAbilities(3),
        physicalAbilities: generatePhysicalAbilities(3, '投手'),
        mentalGrit: 0.0,
        growthRate: 1.0,
        peakAbility: 120,
        positionFit: {'投手': 85, '野手': 25},
        talent: 3,
        growthType: '晩成型',
        individualPotentials: generateIndividualPotentials(3, '投手'),
        achievements: [
          Achievement.create(
            type: AchievementType.regionalChampionship,
            year: 2024,
            month: 6,
            team: '地方強豪高校',
          ),
          Achievement.create(
            type: AchievementType.bestPitcher,
            year: 2024,
            month: 7,
            team: '地方強豪高校',
          ),
        ],
      ),

      // 少し知られている選手（リーグ優勝）
      Player(
        name: '高橋 優',
        school: '普通の高校',
        grade: 2,
        position: '内野手',
        personality: '明るい',
        trustLevel: 20,
        fame: 25,
        isWatched: false,
        isDiscovered: false,
        isPubliclyKnown: false,
        technicalAbilities: generateTechnicalAbilities(2, '内野手'),
        mentalAbilities: generateMentalAbilities(2),
        physicalAbilities: generatePhysicalAbilities(2, '内野手'),
        mentalGrit: -0.05,
        growthRate: 0.95,
        peakAbility: 110,
        positionFit: {'内野手': 80, '外野手': 60, '投手': 15},
        talent: 2,
        growthType: '標準型',
        individualPotentials: generateIndividualPotentials(2, '内野手'),
        achievements: [
          Achievement.create(
            type: AchievementType.leagueChampionship,
            year: 2024,
            month: 5,
            team: '普通の高校',
          ),
        ],
      ),

      // 無名選手（実績なし）
      Player(
        name: '伊藤 誠',
        school: '小さな高校',
        grade: 1,
        position: '投手',
        personality: '控えめ',
        trustLevel: 0,
        fame: 0,
        isWatched: false,
        isDiscovered: false,
        isPubliclyKnown: false,
        technicalAbilities: generateTechnicalAbilities(1, '投手'),
        mentalAbilities: generateMentalAbilities(1),
        physicalAbilities: generatePhysicalAbilities(1, '投手'),
        mentalGrit: -0.1,
        growthRate: 0.9,
        peakAbility: 100,
        positionFit: {'投手': 70, '野手': 20},
        talent: 1,
        growthType: '晩成型',
        individualPotentials: generateIndividualPotentials(1, '投手'),
        achievements: [],
      ),

      // 隠れた才能選手（実績なしだが高ポテンシャル）
      Player(
        name: '渡辺 隼人',
        school: '田舎の高校',
        grade: 1,
        position: '外野手',
        personality: '負けん気',
        trustLevel: 0,
        fame: 0,
        isWatched: false,
        isDiscovered: false,
        isPubliclyKnown: false,
        technicalAbilities: generateTechnicalAbilities(4, '外野手'),
        mentalAbilities: generateMentalAbilities(4),
        physicalAbilities: generatePhysicalAbilities(4, '外野手'),
        mentalGrit: 0.15,
        growthRate: 1.15,
        peakAbility: 145,
        positionFit: {'外野手': 90, '内野手': 60, '投手': 30},
        talent: 4,
        growthType: '晩成型',
        individualPotentials: generateIndividualPotentials(4, '外野手'),
        achievements: [],
      ),

      // 発掘済みの無名選手（視察で発見）
      Player(
        name: '山田 太郎',
        school: '小さな高校',
        grade: 2,
        position: '投手',
        personality: '真面目',
        trustLevel: 30,
        fame: 0,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: false,
        technicalAbilities: generateTechnicalAbilities(2, '投手'),
        mentalAbilities: generateMentalAbilities(2),
        physicalAbilities: generatePhysicalAbilities(2, '投手'),
        mentalGrit: 0.05,
        growthRate: 1.0,
        peakAbility: 115,
        positionFit: {'投手': 80, '野手': 25},
        talent: 2,
        growthType: '標準型',
        individualPotentials: generateIndividualPotentials(2, '投手'),
        achievements: [],
      ),

      // 発掘済みの隠れた才能選手
      Player(
        name: '中村 花子',
        school: '普通の高校',
        grade: 1,
        position: '内野手',
        personality: '積極的',
        trustLevel: 50,
        fame: 0,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: false,
        technicalAbilities: generateTechnicalAbilities(3, '内野手'),
        mentalAbilities: generateMentalAbilities(3),
        physicalAbilities: generatePhysicalAbilities(3, '内野手'),
        mentalGrit: 0.1,
        growthRate: 1.1,
        peakAbility: 135,
        positionFit: {'内野手': 85, '外野手': 65, '投手': 20},
        talent: 3,
        growthType: '早期型',
        individualPotentials: generateIndividualPotentials(3, '内野手'),
        achievements: [],
      ),

      // お気に入り選手（発掘済み）
      Player(
        name: '小林 美咲',
        school: '名門高校',
        grade: 2,
        position: '投手',
        personality: '負けん気',
        trustLevel: 70,
        fame: 30,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: false,
        isScoutFavorite: true,
        technicalAbilities: generateTechnicalAbilities(4, '投手'),
        mentalAbilities: generateMentalAbilities(4),
        physicalAbilities: generatePhysicalAbilities(4, '投手'),
        mentalGrit: 0.2,
        growthRate: 1.2,
        peakAbility: 150,
        positionFit: {'投手': 95, '野手': 30},
        talent: 4,
        growthType: '早期型',
        individualPotentials: generateIndividualPotentials(4, '投手'),
        achievements: [
          Achievement.create(
            type: AchievementType.regionalChampionship,
            year: 2024,
            month: 6,
            team: '名門高校',
          ),
        ],
      ),

      // お気に入り選手（注目選手）
      Player(
        name: '佐々木 翔',
        school: '強豪高校',
        grade: 3,
        position: '外野手',
        personality: 'リーダー',
        trustLevel: 80,
        fame: 75,
        isWatched: true,
        isDiscovered: false,
        isPubliclyKnown: true,
        isScoutFavorite: true,
        technicalAbilities: generateTechnicalAbilities(5, '外野手'),
        mentalAbilities: generateMentalAbilities(5),
        physicalAbilities: generatePhysicalAbilities(5, '外野手'),
        mentalGrit: 0.15,
        growthRate: 1.15,
        peakAbility: 155,
        positionFit: {'外野手': 95, '内野手': 70, '投手': 25},
        talent: 5,
        growthType: '標準型',
        individualPotentials: generateIndividualPotentials(5, '外野手'),
        achievements: [
          Achievement.create(
            type: AchievementType.u18NationalTeam,
            year: 2024,
            month: 9,
            team: 'U-18日本代表',
          ),
          Achievement.create(
            type: AchievementType.homeRunKing,
            year: 2024,
            month: 7,
            team: '強豪高校',
          ),
        ],
      ),

      // 注目選手（高知名度）
      Player(
        name: '田中 大輔',
        school: '甲子園常連校',
        grade: 3,
        position: '投手',
        personality: '冷静',
        trustLevel: 0,
        fame: 80,
        isWatched: false,
        isDiscovered: false,
        isPubliclyKnown: true,
        technicalAbilities: generateTechnicalAbilities(4, '投手'),
        mentalAbilities: generateMentalAbilities(4),
        physicalAbilities: generatePhysicalAbilities(4, '投手'),
        mentalGrit: 0.1,
        growthRate: 1.1,
        peakAbility: 140,
        positionFit: {'投手': 90, '野手': 25},
        talent: 4,
        growthType: '標準型',
        individualPotentials: generateIndividualPotentials(4, '投手'),
        achievements: [
          Achievement.create(
            type: AchievementType.nationalChampionship,
            year: 2024,
            month: 7,
            team: '甲子園常連校',
          ),
        ],
      ),

      // 注目選手（中知名度）
      Player(
        name: '山本 健太',
        school: '地方強豪校',
        grade: 2,
        position: '内野手',
        personality: '積極的',
        trustLevel: 0,
        fame: 65,
        isWatched: false,
        isDiscovered: false,
        isPubliclyKnown: false,
        technicalAbilities: generateTechnicalAbilities(3, '内野手'),
        mentalAbilities: generateMentalAbilities(3),
        physicalAbilities: generatePhysicalAbilities(3, '内野手'),
        mentalGrit: 0.05,
        growthRate: 1.05,
        peakAbility: 125,
        positionFit: {'内野手': 85, '外野手': 60, '投手': 20},
        talent: 3,
        growthType: '晩成型',
        individualPotentials: generateIndividualPotentials(3, '内野手'),
        achievements: [
          Achievement.create(
            type: AchievementType.regionalChampionship,
            year: 2024,
            month: 6,
            team: '地方強豪校',
          ),
        ],
      ),
    ];
  }

  // ランダムな実績を生成
  static List<Achievement> generateRandomAchievements(int count) {
    final achievementTypes = AchievementType.values;
    final achievements = <Achievement>[];
    
    for (int i = 0; i < count; i++) {
      final type = achievementTypes[_random.nextInt(achievementTypes.length)];
      final year = 2024 - _random.nextInt(3); // 2022-2024年
      final month = _random.nextInt(12) + 1; // 1-12月
      
      achievements.add(Achievement.create(
        type: type,
        year: year,
        month: month,
      ));
    }
    
    return achievements;
  }

  // 知名度に応じた実績数を決定
  static int getAchievementCountByFame(int fameLevel) {
    switch (fameLevel) {
      case 5: return _random.nextInt(3) + 3; // 3-5個
      case 4: return _random.nextInt(2) + 2; // 2-3個
      case 3: return _random.nextInt(2) + 1; // 1-2個
      case 2: return _random.nextInt(1) + 1; // 1個
      case 1: return 0; // 実績なし
      default: return 0;
    }
  }
  
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
        final talent = random.nextBool() ? 4 : (random.nextBool() ? 3 : 5);
        
        // 年齢は18-35歳（プロ野球選手の一般的な年齢）
        final age = 18 + random.nextInt(18);
        
        // プロ野球選手用の能力値生成（高校生より高いレベル）
        final technicalAbilities = _generateProfessionalTechnicalAbilities(talent, position);
        final mentalAbilities = _generateProfessionalMentalAbilities(talent);
        final physicalAbilities = _generateProfessionalPhysicalAbilities(talent, position);
        
        // プロ野球選手用のポテンシャル生成
        final individualPotentials = _generateProfessionalIndividualPotentials(talent, position);
        
        final player = Player(
          name: _generateProfessionalPlayerName(),
          school: 'プロ野球団',
          grade: 0, // プロ野球選手は学年なし
          position: position,
          personality: _generateProfessionalPersonality(),
          trustLevel: 80 + random.nextInt(21), // 80-100（プロ選手なので高い信頼度）
          fame: 60 + random.nextInt(41), // 60-100（プロ選手なので高い知名度）
          isWatched: true,
          isDiscovered: true,
          isPubliclyKnown: true,
          type: PlayerType.social, // 社会人選手として扱う
          yearsAfterGraduation: age - 18, // 高校卒業後の年数
          isGraduated: true, // プロ選手は卒業済み
          isDrafted: true, // プロ選手フラグ
          professionalTeamId: team.id, // 所属チームID
          technicalAbilities: technicalAbilities,
          mentalAbilities: mentalAbilities,
          physicalAbilities: physicalAbilities,
          mentalGrit: 0.6 + random.nextDouble() * 0.4, // 0.6-1.0（プロ選手なので高い精神力）
          growthRate: 0.9 + random.nextDouble() * 0.2, // 0.9-1.1（プロ選手なので安定した成長）
          peakAbility: 100 + random.nextInt(51), // 100-150（NPB選手レベル）
          positionFit: _generateProfessionalPositionFit(position),
          talent: talent,
          growthType: '標準型', // プロ選手は標準的な成長
          individualPotentials: individualPotentials,
          achievements: _generateProfessionalAchievements(talent),
        );
        
        players.add(player);
      }
    }
    
    return players;
  }
  
  // プロ野球選手用の技術面能力値生成
  static Map<TechnicalAbility, int> _generateProfessionalTechnicalAbilities(int talent, String position) {
    final abilities = <TechnicalAbility, int>{};
    final random = Random();
    
    // NPB選手レベルの基本能力値（100-115）
    final baseValue = 100 + (talent - 3) * 5; // talent 3: 100, 4: 105, 5: 110
    
    for (final ability in TechnicalAbility.values) {
      int value = baseValue + random.nextInt(21) - 10; // ±10の変動
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == TechnicalAbility.control || ability == TechnicalAbility.breakingBall) {
            value += random.nextInt(16); // 投手の投球能力+0-15
          }
          break;
        case '捕手':
          if (ability == TechnicalAbility.fielding || ability == TechnicalAbility.throwing) {
            value += random.nextInt(16); // 捕手の守備能力+0-15
          }
          break;
        case '内野手':
          if (ability == TechnicalAbility.fielding || ability == TechnicalAbility.throwing) {
            value += random.nextInt(16); // 内野手の守備能力+0-15
          }
          break;
        case '外野手':
          if (ability == TechnicalAbility.fielding || ability == TechnicalAbility.throwing) {
            value += random.nextInt(16); // 外野手の守備能力+0-15
          }
          break;
      }
      
      abilities[ability] = value.clamp(95, 120); // NPB選手レベルに制限
    }
    
    return abilities;
  }
  
  // プロ野球選手用のメンタル面能力値生成
  static Map<MentalAbility, int> _generateProfessionalMentalAbilities(int talent) {
    final abilities = <MentalAbility, int>{};
    final random = Random();
    
    // NPB選手レベルの基本能力値（100-115）
    final baseValue = 100 + (talent - 3) * 5; // talent 3: 100, 4: 105, 5: 110
    
    for (final ability in MentalAbility.values) {
      int value = baseValue + random.nextInt(21) - 10; // ±10の変動
      abilities[ability] = value.clamp(95, 120); // NPB選手レベルに制限
    }
    
    return abilities;
  }
  
  // プロ野球選手用のフィジカル面能力値生成
  static Map<PhysicalAbility, int> _generateProfessionalPhysicalAbilities(int talent, String position) {
    final abilities = <PhysicalAbility, int>{};
    final random = Random();
    
    // NPB選手レベルの基本能力値（100-115）
    final baseValue = 100 + (talent - 3) * 5; // talent 3: 100, 4: 105, 5: 110
    
    for (final ability in PhysicalAbility.values) {
      int value = baseValue + random.nextInt(21) - 10; // ±10の変動
      
      // ポジションによる調整
      switch (position) {
        case '投手':
          if (ability == PhysicalAbility.stamina) {
            value += random.nextInt(16); // 投手のスタミナ+0-15
          }
          break;
        case '外野手':
          if (ability == PhysicalAbility.pace || ability == PhysicalAbility.acceleration) {
            value += random.nextInt(16); // 外野手の走力+0-15
          }
          break;
        case '内野手':
          if (ability == PhysicalAbility.agility || ability == PhysicalAbility.balance) {
            value += random.nextInt(16); // 内野手の敏捷性+0-15
          }
          break;
      }
      
      abilities[ability] = value.clamp(95, 120); // NPB選手レベルに制限
    }
    
    return abilities;
  }
  
  // プロ野球選手用の個別ポテンシャル生成
  static Map<String, int> _generateProfessionalIndividualPotentials(int talent, String position) {
    final potentials = <String, int>{};
    final random = Random();
    
    // NPB選手レベルの基本ポテンシャル（100-120）
    final basePotential = 100 + (talent - 3) * 5; // talent 3: 100, 4: 105, 5: 110
    
    // Technical（技術面）能力値ポテンシャル
    final technicalPotentials = _generateProfessionalTechnicalAbilities(talent, position);
    for (final entry in technicalPotentials.entries) {
      potentials[entry.key.name] = entry.value + random.nextInt(11) - 5; // ±5の変動
    }
    
    // Mental（メンタル面）能力値ポテンシャル
    final mentalPotentials = _generateProfessionalMentalAbilities(talent);
    for (final entry in mentalPotentials.entries) {
      potentials[entry.key.name] = entry.value + random.nextInt(11) - 5; // ±5の変動
    }
    
    // Physical（フィジカル面）能力値ポテンシャル
    final physicalPotentials = _generateProfessionalPhysicalAbilities(talent, position);
    for (final entry in physicalPotentials.entries) {
      potentials[entry.key.name] = entry.value + random.nextInt(11) - 5; // ±5の変動
    }
    
    return potentials;
  }
  
  // プロ野球選手用のポジション適性生成
  static Map<String, int> _generateProfessionalPositionFit(String position) {
    final fit = <String, int>{};
    
    // メインポジションは90-100
    fit[position] = 90 + Random().nextInt(11);
    
    // 他のポジションは適度に低く
    final otherPositions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    for (final otherPosition in otherPositions) {
      if (otherPosition != position) {
        fit[otherPosition] = 20 + Random().nextInt(41); // 20-60
      }
    }
    
    return fit;
  }
  
  // プロ野球選手用の実績生成
  static List<Achievement> _generateProfessionalAchievements(int talent) {
    final achievements = <Achievement>[];
    final random = Random();
    
    // talentランクに応じて実績を生成
    if (talent >= 4) {
      achievements.add(Achievement.create(
        type: AchievementType.nationalChampionship,
        year: 2024,
        month: random.nextInt(12) + 1,
        team: 'プロ野球団',
      ));
    }
    
    if (talent >= 3) {
      achievements.add(Achievement.create(
        type: AchievementType.homeRunKing,
        year: 2024,
        month: random.nextInt(12) + 1,
        team: 'プロ野球団',
      ));
    }
    
    return achievements;
  }
  
  // プロ野球選手用の名前生成
  static String _generateProfessionalPlayerName() {
    final surnames = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final givenNames = ['翔太', '健一', '大輔', '雄一', '達也', '智也', '誠', '勇', '剛', '正'];
    
    return '${surnames[Random().nextInt(surnames.length)]} ${givenNames[Random().nextInt(givenNames.length)]}';
  }
  
  // プロ野球選手用の性格生成
  static String _generateProfessionalPersonality() {
    final personalities = ['リーダー', '冷静', '積極的', '謙虚', '情熱的', '集中力', '責任感'];
    return personalities[Random().nextInt(personalities.length)];
  }
}
