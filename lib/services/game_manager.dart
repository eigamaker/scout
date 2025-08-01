import 'dart:math';
import 'dart:convert';
import '../models/game/game.dart';
import '../models/player/player.dart';
import '../models/player/pitch.dart';
import '../models/player/player_abilities.dart';
import '../models/school/school.dart';
import '../models/news/news_item.dart';
import 'news_service.dart';
import 'data_service.dart';
import 'player_generator.dart';
import 'scouting/action_service.dart' as scouting;
import 'scouting/scout_analysis_service.dart';

// 個別ポテンシャル生成システム
class IndividualPotentialGenerator {
  static Map<String, int> generateIndividualPotentials(int talentRank, Random random) {
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
    
    return potentials;
  }
  
  static int _getAveragePotentialByTalent(int talentRank, Random random) {
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
      default:
        return 70 + random.nextInt(16);
    }
  }
  
  static int _generateAbilityPotential(int averagePotential, int talentRank, Random random) {
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
  
  static int _getVariationRangeByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 20; // 低ランクは変動が小さい
      case 2: return 25;
      case 3: return 30;
      case 4: return 35;
      case 5: return 40; // 高ランクは変動が大きい
      default: return 25;
    }
  }
  
  static int _getMinPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 50;
      case 2: return 60;
      case 3: return 70;
      case 4: return 80;
      case 5: return 90;
      default: return 60;
    }
  }
  
  static int _getMaxPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 85;
      case 2: return 95;
      case 3: return 105;
      case 4: return 120;
      case 5: return 150;
      default: return 95;
    }
  }
  
  static int _generateFastballPotential(int talentRank, Random random) {
    // 球速は全選手が持つ（km/h単位）
    final baseVelocity = _getBaseFastballVelocityByTalent(talentRank);
    final variation = random.nextInt(_getFastballVariationByTalent(talentRank));
    
    return baseVelocity + variation;
  }
  
  static int _getBaseFastballVelocityByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 135; // 135 km/h基準
      case 2: return 140; // 140 km/h基準
      case 3: return 145; // 145 km/h基準
      case 4: return 150; // 150 km/h基準
      case 5: return 155; // 155 km/h基準
      default: return 140;
    }
  }
  
  static int _getFastballVariationByTalent(int talentRank) {
    switch (talentRank) {
      case 1: return 10; // ±5 km/h
      case 2: return 15; // ±7.5 km/h
      case 3: return 20; // ±10 km/h
      case 4: return 25; // ±12.5 km/h
      case 5: return 30; // ±15 km/h
      default: return 15;
    }
  }
}

// 能力バランス調整システム
class AbilityBalanceAdjuster {
  static Map<String, int> adjustPotentialsForBalance(
    Map<String, int> potentials,
    int talentRank,
    Random random,
  ) {
    final adjustedPotentials = Map<String, int>.from(potentials);
    
    // 平均ポテンシャルを計算（球速を含む）
    final averagePotential = _calculateAveragePotential(adjustedPotentials);
    
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
  
  static double _calculateAveragePotential(Map<String, int> potentials) {
    // 全能力値（球速を含む）の平均を計算
    final allPotentials = potentials.values.toList();
    return allPotentials.reduce((a, b) => a + b).toDouble() / allPotentials.length;
  }
  
  static Map<String, int> _getTargetAverageRange(int talentRank) {
    switch (talentRank) {
      case 1: return <String, int>{'min': 60, 'max': 75};
      case 2: return <String, int>{'min': 70, 'max': 85};
      case 3: return <String, int>{'min': 80, 'max': 95};
      case 4: return <String, int>{'min': 90, 'max': 110};
      case 5: return <String, int>{'min': 100, 'max': 130};
      default: return <String, int>{'min': 70, 'max': 85};
    }
  }
  
  static void _adjustToTargetRange(
    Map<String, int> potentials,
    Map<String, int> targetRange,
    Random random,
  ) {
    final currentAverage = _calculateAveragePotential(potentials);
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
  
  static void _adjustExtremeDifferences(
    Map<String, int> potentials,
    int talentRank,
    Random random,
  ) {
    final allPotentials = potentials.values.toList();
    
    final maxDiff = _getMaxAllowedDifference(talentRank);
    final maxValue = allPotentials.reduce(max);
    final minValue = allPotentials.reduce(min);
    
    if (maxValue - minValue > maxDiff) {
      // 極端な差を調整
      final adjustment = ((maxValue - minValue - maxDiff) / 2).round();
      
      for (final entry in potentials.entries) {
        if (entry.value == maxValue) {
          final newValue = entry.value - adjustment;
          if (entry.key == 'fastballVelo') {
            potentials[entry.key] = newValue.clamp(125, 170);
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
  
  static int _getMaxAllowedDifference(int talentRank) {
    switch (talentRank) {
      case 1: return 25; // 低ランクは差が小さい
      case 2: return 30;
      case 3: return 35;
      case 4: return 40;
      case 5: return 50; // 高ランクは差が大きい
      default: return 30;
    }
  }
}

// 初期能力値生成システム
class InitialAbilityGenerator {
  static Map<String, int> generateInitialAbilities(
    Map<String, int> potentials,
    int grade,
    double mentalGrit,
    double growthRate,
    int talent,
    String growthType,
    Random random,
  ) {
    final initialAbilities = <String, int>{};
    
    for (final entry in potentials.entries) {
      final abilityName = entry.key;
      final potential = entry.value;
      
      if (abilityName == 'fastballVelo') {
        initialAbilities[abilityName] = _generateInitialFastball(potential, grade, random);
      } else {
        initialAbilities[abilityName] = _generateInitialAbility(
          potential, 
          grade, 
          mentalGrit, 
          growthRate, 
          talent, 
          growthType, 
          random
        );
      }
    }
    
    return initialAbilities;
  }
  
  static int _generateInitialAbility(
    int potential,
    int grade,
    double mentalGrit,
    double growthRate,
    int talent,
    String growthType,
    Random random,
  ) {
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
  
  static int _generateInitialFastball(int potential, int grade, Random random) {
    // 球速の特別処理（全選手共通）
    final gradeRate = _getGradeInitializationRate(grade);
    final initialVelocity = 125 + (potential - 125) * gradeRate;
    final randomVariation = (random.nextDouble() - 0.5) * 10;
    
    return (initialVelocity + randomVariation).round().clamp(125, potential);
  }
  
  static double _calculateGrowthCoefficient(double mentalGrit, double growthRate, int talent, String growthType) {
    final baseCoefficient = 0.15 + (mentalGrit - 0.5) * 0.2;
    final growthSpeedCoefficient = (growthRate - 0.9) * 0.3;
    final talentCoefficient = (talent - 1) * 0.05;
    final growthTypeCoefficient = _getGrowthTypeCoefficient(growthType);
    
    return baseCoefficient + growthSpeedCoefficient + talentCoefficient + growthTypeCoefficient;
  }
  
  static double _getGradeInitializationRate(int grade) {
    switch (grade) {
      case 1: return 0.15; // 新入生
      case 2: return 0.45; // 2年生
      case 3: return 0.75; // 3年生
      default: return 0.45;
    }
  }
  
  static double _getGrowthTypeCoefficient(String growthType) {
    switch (growthType) {
      case 'early': return 0.1;
      case 'normal': return 0.0;
      case 'late': return -0.1;
      case 'spurt': return 0.15;
      default: return 0.0;
    }
  }
}

// 学年別確率調整システム
class GradeProbabilityAdjuster {
  static double getAbilityProbabilityAdjustment(int grade, int abilityValue) {
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
  
  static double getFastballProbabilityAdjustment(int grade, int velocity) {
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
}

class GameManager {
  Game? _currentGame;

  Game? get currentGame => _currentGame;

  // ニューゲーム時に全学校に1〜3年生を生成・配属（DBにもinsert）
  Future<void> generateInitialStudentsForAllSchoolsDb(DataService dataService) async {
    final db = await dataService.database;
    final updatedSchools = <School>[];
    
    for (final school in _currentGame!.schools) {
      final newPlayers = <Player>[];
      
      // 各学校に1〜3年生を生成（各学年1〜3人）
      for (int grade = 1; grade <= 3; grade++) {
        final playerCount = 1 + Random().nextInt(3); // 1〜3人
        
        for (int i = 0; i < playerCount; i++) {
          final name = _generateRandomName();
          final personality = _randomPersonality();
          final position = _randomPosition();
          
          final player = generatePlayer(
            name: name,
            school: school.name,
            grade: grade,
            position: position,
            personality: personality,
          );
          
          // 知名度を計算
          player.calculateInitialFame();
          newPlayers.add(player);
        }
      }
      
      updatedSchools.add(school.copyWith(players: newPlayers));
    }
    
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  Future<void> startNewGameWithDb(String scoutName, DataService dataService) async {
    try {
      print('startNewGameWithDb: 開始');
      // 初期データ投入（初回のみ）
      await dataService.insertInitialData();
      print('startNewGameWithDb: 初期データ投入完了');
      final db = await dataService.database;
      print('startNewGameWithDb: DB接続完了');
    // 学校リスト取得
    final schoolMaps = await db.query('Organization', where: 'type = ?', whereArgs: ['高校']);
    final schools = schoolMaps.map((m) => School(
      id: m['id'] as int,
      name: m['name'] as String,
      location: m['location'] as String,
      players: [], // 後で選手を割り当て
      coachTrust: m['school_strength'] as int? ?? 70,
      coachName: '未設定',
    )).toList();
    // 初期選手リストは空で開始（generateInitialStudentsForAllSchoolsDbで生成される）
    final players = <Player>[];
    // Gameインスタンス生成
    _currentGame = Game(
      scoutName: scoutName,
      scoutSkill: 50,
      currentYear: DateTime.now().year,
      currentMonth: 4,
      currentWeekOfMonth: 1,
      state: GameState.scouting,
      schools: schools,
      discoveredPlayers: players,
      watchedPlayers: [],
      favoritePlayers: [],
      ap: 15,
      budget: 1000000,
      scoutSkills: {
        'exploration': 50,
        'observation': 50,
        'analysis': 50,
        'insight': 50,
        'communication': 50,
        'negotiation': 50,
        'stamina': 50,
      },
      reputation: 50,
      experience: 0,
      level: 1,
      weeklyActions: [],
    );
    // 全学校に1〜3年生を生成
    await generateInitialStudentsForAllSchoolsDb(dataService);
    
    // generateInitialStudentsForAllSchoolsDbで更新された学校リストを取得
    final updatedSchools = _currentGame!.schools;
    
    // 全選手をdiscoveredPlayersにも追加
    final allPlayers = <Player>[];
    for (final school in updatedSchools) {
      allPlayers.addAll(school.players);
    }
    _currentGame = _currentGame!.copyWith(discoveredPlayers: allPlayers);
    print('startNewGameWithDb: 完了 - 学校数: ${updatedSchools.length}, 選手数: ${allPlayers.length}');
    for (final s in _currentGame!.schools) {
      print('final schools: name=${s.name}, players=${s.players.length}');
    }
  } catch (e, stackTrace) {
    print('startNewGameWithDb: エラー発生 - $e');
    print('startNewGameWithDb: スタックトレース - $stackTrace');
    rethrow;
  }
  }

  // スカウト実行
  Player? scoutNewPlayer(NewsService newsService) {
    if (_currentGame == null || _currentGame!.schools.isEmpty) return null;
    // ランダムな学校を選択
    final school = (_currentGame!.schools..shuffle()).first;
    // ランダムな学年
    final grade = 1 + (Random().nextInt(3));
    // 選手を生成
    final newPlayer = school.generatePlayer(
      position: _randomPosition(),
      personality: _randomPersonality(),
      talentRank: _randomTalent(),
      random: Random(),
    );
    // 発掘リストに追加
    _currentGame = _currentGame!.discoverPlayer(newPlayer);

    // ニュースも追加
    newsService.addNews(
      NewsItem(
        title: '${newPlayer.name}選手を発掘！',
        content: '${school.name}の${newPlayer.position}、${newPlayer.name}選手を発掘しました。',
        date: DateTime.now(),
        importance: NewsImportance.high,
        category: NewsCategory.player,
        relatedPlayerId: newPlayer.name,
        relatedSchoolId: school.name,
      ),
    );
    return newPlayer;
  }

  // 日付進行・イベント
  void triggerRandomEvent(NewsService newsService) {
    if (_currentGame == null) return;
    final random = Random();
    final rand = random.nextInt(100);
    if (rand < 5) {
      newsService.addNews(
        NewsItem(
          title: '選手が怪我！',
          content: '注目選手の一人が練習中に怪我をしました。',
          date: DateTime.now(),
          importance: NewsImportance.critical,
          category: NewsCategory.player,
        ),
      );
    } else if (rand < 10) {
      newsService.addNews(
        NewsItem(
          title: 'スポンサー獲得！',
          content: '新たなスポンサーがチームを支援してくれることになりました。',
          date: DateTime.now(),
          importance: NewsImportance.high,
          category: NewsCategory.general,
        ),
      );
      _currentGame = _currentGame!.changeBudget(50000);
    } else if (rand < 15) {
      newsService.addNews(
        NewsItem(
          title: 'ファン感謝デー開催',
          content: 'ファン感謝デーが開催され、評判が上がりました。',
          date: DateTime.now(),
          importance: NewsImportance.medium,
          category: NewsCategory.general,
        ),
      );
      _currentGame = _currentGame!.changeReputation(5);
    }
  }

  // 新年度（4月1週）開始時に全学校へ新1年生を生成・配属（DBにもinsert）
  Future<void> generateNewStudentsForAllSchoolsDb(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    
    // バッチ処理用のリスト
    final personBatch = <Map<String, dynamic>>[];
    final playerBatch = <Map<String, dynamic>>[];
    final potentialBatch = <Map<String, dynamic>>[];
    
    for (final school in _currentGame!.schools) {
      final newPlayers = List<Player>.from(school.players);
      final numNew = 10 + (Random().nextInt(6)); // 10〜15人
      for (int i = 0; i < numNew; i++) {
        final isFamous = i == 0 && (Random().nextInt(3) == 0);
        final name = _generateRandomName();
        final position = _randomPosition();
        final personality = _randomPersonality();
        
        // generatePlayerメソッドを使用して選手を生成
        final player = generatePlayer(
          name: name,
          school: school.name,
          grade: 1,
          position: position,
          personality: personality,
        );
        
        // バッチ用データを準備
        personBatch.add({
          'name': name,
          'birth_date': '20${6 + Random().nextInt(10)}-04-01',
          'gender': '男',
          'hometown': school.location,
          'personality': personality,
        });
        
        print('デバッグ: 選手 ${player.name} を学校 ${school.name} (ID: ${school.id}) に割り当て');
                  playerBatch.add({
            'school_id': school.id, // 正しい学校IDを使用
          'grade': 1,
          'position': position,
          'growth_rate': player.growthRate,
          'talent': player.talent,
          'growth_type': player.growthType,
          'mental_grit': player.mentalGrit,
          'peak_ability': player.peakAbility,
          // Technical（技術面）能力値
          'contact': player.getTechnicalAbility(TechnicalAbility.contact),
          'power': player.getTechnicalAbility(TechnicalAbility.power),
          'plate_discipline': player.getTechnicalAbility(TechnicalAbility.plateDiscipline),
          'bunt': player.getTechnicalAbility(TechnicalAbility.bunt),
          'opposite_field_hitting': player.getTechnicalAbility(TechnicalAbility.oppositeFieldHitting),
          'pull_hitting': player.getTechnicalAbility(TechnicalAbility.pullHitting),
          'bat_control': player.getTechnicalAbility(TechnicalAbility.batControl),
          'swing_speed': player.getTechnicalAbility(TechnicalAbility.swingSpeed),
          'fielding': player.getTechnicalAbility(TechnicalAbility.fielding),
          'throwing': player.getTechnicalAbility(TechnicalAbility.throwing),
          'catcher_ability': player.getTechnicalAbility(TechnicalAbility.catcherAbility),
          'control': player.getTechnicalAbility(TechnicalAbility.control),
          'fastball': player.getTechnicalAbility(TechnicalAbility.fastball),
          'breaking_ball': player.getTechnicalAbility(TechnicalAbility.breakingBall),
          'pitch_movement': player.getTechnicalAbility(TechnicalAbility.pitchMovement),
          // Mental（メンタル面）能力値
          'concentration': player.getMentalAbility(MentalAbility.concentration),
          'anticipation': player.getMentalAbility(MentalAbility.anticipation),
          'vision': player.getMentalAbility(MentalAbility.vision),
          'composure': player.getMentalAbility(MentalAbility.composure),
          'aggression': player.getMentalAbility(MentalAbility.aggression),
          'bravery': player.getMentalAbility(MentalAbility.bravery),
          'leadership': player.getMentalAbility(MentalAbility.leadership),
          'work_rate': player.getMentalAbility(MentalAbility.workRate),
          'self_discipline': player.getMentalAbility(MentalAbility.selfDiscipline),
          'ambition': player.getMentalAbility(MentalAbility.ambition),
          'teamwork': player.getMentalAbility(MentalAbility.teamwork),
          'positioning': player.getMentalAbility(MentalAbility.positioning),
          'pressure_handling': player.getMentalAbility(MentalAbility.pressureHandling),
          'clutch_ability': player.getMentalAbility(MentalAbility.clutchAbility),
          // Physical（フィジカル面）能力値
          'acceleration': player.getPhysicalAbility(PhysicalAbility.acceleration),
          'agility': player.getPhysicalAbility(PhysicalAbility.agility),
          'balance': player.getPhysicalAbility(PhysicalAbility.balance),
          'jumping_reach': player.getPhysicalAbility(PhysicalAbility.jumpingReach),
          'flexibility': player.getPhysicalAbility(PhysicalAbility.flexibility),
          'natural_fitness': player.getPhysicalAbility(PhysicalAbility.naturalFitness),
          'injury_proneness': player.getPhysicalAbility(PhysicalAbility.injuryProneness),
          'stamina': player.getPhysicalAbility(PhysicalAbility.stamina),
          'strength': player.getPhysicalAbility(PhysicalAbility.strength),
          'pace': player.getPhysicalAbility(PhysicalAbility.pace),
        });
        
        // PlayerPotentialsテーブル用データを準備
        if (player.individualPotentials != null) {
          potentialBatch.add({
            // Technical（技術面）ポテンシャル
            'contact_potential': player.individualPotentials!['contact'] ?? 0,
            'power_potential': player.individualPotentials!['power'] ?? 0,
            'plate_discipline_potential': player.individualPotentials!['plateDiscipline'] ?? 0,
            'bunt_potential': player.individualPotentials!['bunt'] ?? 0,
            'opposite_field_hitting_potential': player.individualPotentials!['oppositeFieldHitting'] ?? 0,
            'pull_hitting_potential': player.individualPotentials!['pullHitting'] ?? 0,
            'bat_control_potential': player.individualPotentials!['batControl'] ?? 0,
            'swing_speed_potential': player.individualPotentials!['swingSpeed'] ?? 0,
            'fielding_potential': player.individualPotentials!['fielding'] ?? 0,
            'throwing_potential': player.individualPotentials!['throwing'] ?? 0,
            'catcher_ability_potential': player.individualPotentials!['catcherAbility'] ?? 0,
            'control_potential': player.individualPotentials!['control'] ?? 0,
            'fastball_potential': player.individualPotentials!['fastball'] ?? 0,
            'breaking_ball_potential': player.individualPotentials!['breakingBall'] ?? 0,
            'pitch_movement_potential': player.individualPotentials!['pitchMovement'] ?? 0,
            // Mental（メンタル面）ポテンシャル
            'concentration_potential': player.individualPotentials!['concentration'] ?? 0,
            'anticipation_potential': player.individualPotentials!['anticipation'] ?? 0,
            'vision_potential': player.individualPotentials!['vision'] ?? 0,
            'composure_potential': player.individualPotentials!['composure'] ?? 0,
            'aggression_potential': player.individualPotentials!['aggression'] ?? 0,
            'bravery_potential': player.individualPotentials!['bravery'] ?? 0,
            'leadership_potential': player.individualPotentials!['leadership'] ?? 0,
            'work_rate_potential': player.individualPotentials!['workRate'] ?? 0,
            'self_discipline_potential': player.individualPotentials!['selfDiscipline'] ?? 0,
            'ambition_potential': player.individualPotentials!['ambition'] ?? 0,
            'teamwork_potential': player.individualPotentials!['teamwork'] ?? 0,
            'positioning_potential': player.individualPotentials!['positioning'] ?? 0,
            'pressure_handling_potential': player.individualPotentials!['pressureHandling'] ?? 0,
            'clutch_ability_potential': player.individualPotentials!['clutchAbility'] ?? 0,
            // Physical（フィジカル面）ポテンシャル
            'acceleration_potential': player.individualPotentials!['acceleration'] ?? 0,
            'agility_potential': player.individualPotentials!['agility'] ?? 0,
            'balance_potential': player.individualPotentials!['balance'] ?? 0,
            'jumping_reach_potential': player.individualPotentials!['jumpingReach'] ?? 0,
            'natural_fitness_potential': player.individualPotentials!['naturalFitness'] ?? 0,
            'injury_proneness_potential': player.individualPotentials!['injuryProneness'] ?? 0,
            'stamina_potential': player.individualPotentials!['stamina'] ?? 0,
            'strength_potential': player.individualPotentials!['strength'] ?? 0,
            'pace_potential': player.individualPotentials!['pace'] ?? 0,
            'flexibility_potential': player.individualPotentials!['flexibility'] ?? 0,
          });
        }
        
        newPlayers.add(player);
        if (isFamous) {
          _currentGame = _currentGame!.discoverPlayer(player);
        }
      }
      updatedSchools.add(school.copyWith(players: newPlayers));
    }
    
    // バッチ挿入を実行
    await db.transaction((txn) async {
      // Personテーブルをバッチ挿入
      for (final personData in personBatch) {
        final personId = await txn.insert('Person', personData);
        
        // 対応するPlayerデータにpersonIdを設定
        final playerIndex = personBatch.indexOf(personData);
        if (playerIndex < playerBatch.length) {
          playerBatch[playerIndex]['id'] = personId;
          
          // 対応するPotentialデータにplayerIdを設定
          if (playerIndex < potentialBatch.length) {
            potentialBatch[playerIndex]['player_id'] = personId;
          }
        }
      }
      
      // Playerテーブルをバッチ挿入
      for (final playerData in playerBatch) {
        await txn.insert('Player', playerData);
      }
      
      // PlayerPotentialsテーブルをバッチ挿入
      for (final potentialData in potentialBatch) {
        await txn.insert('PlayerPotentials', potentialData);
      }
    });
    
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  // 3月1週→2週の週送り時に卒業処理（3年生を削除）
  Future<void> graduateThirdYearStudents(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    for (final school in _currentGame!.schools) {
      final remaining = school.players.where((p) => p.grade < 3).toList();
      // DBからも3年生を削除
      for (final p in school.players.where((p) => p.grade == 3)) {
        await db.delete('Player', where: 'name = ? AND school_id = ?', whereArgs: [p.name, school.name]);
      }
      updatedSchools.add(school.copyWith(players: remaining));
    }
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  // 3月5週→4月1週の週送り時に全選手のgradeを+1
  Future<void> promoteAllStudents(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    for (final school in _currentGame!.schools) {
      final promoted = <Player>[];
      for (final p in school.players) {
        final newGrade = p.grade + 1;
        // DBも更新
        await db.update('Player', {'grade': newGrade}, where: 'name = ? AND school_id = ?', whereArgs: [p.name, school.name]);
        promoted.add(p.copyWith(grade: newGrade));
      }
      updatedSchools.add(school.copyWith(players: promoted));
    }
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  // 全選手の成長処理（3か月ごと）
  void growAllPlayers() {
    if (_currentGame == null) return;
    final updatedSchools = _currentGame!.schools.map((school) {
      final grownPlayers = school.players.map((p) {
        final player = p.copyWith();
        player.grow();
        return player;
      }).toList();
      return school.copyWith(players: grownPlayers);
    }).toList();
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  // ランダムな名前生成（簡易）
  String _generateRandomName() {
    final random = Random();
    const familyNames = ['田中', '佐藤', '鈴木', '高橋', '伊藤', '渡辺', '山本', '中村', '小林', '加藤'];
    const givenNames = ['太郎', '次郎', '大輔', '翔太', '健太', '悠斗', '陸', '蓮', '颯太', '陽斗'];
    final f = familyNames[random.nextInt(familyNames.length)];
    final g = givenNames[random.nextInt(givenNames.length)];
    return '$f$g';
  }
  // 投手能力総合評価によるポジション決定
  String _determinePositionByPitchingAbility(int talent, Random random) {
    // 才能ランクに基づく基本能力値を計算
    final baseAbility = _getBaseAbilityByTalent(talent);
    final baseVelocity = _getBaseVelocityByTalent(talent);
    
    // 投手能力の総合評価を計算
    final pitcherScore = _calculatePitcherScore(baseAbility, baseVelocity, random);
    final fielderScore = _calculateFielderScore(baseAbility, random);
    
    // 投手適性を判定（バランスを考慮）
    final pitcherProbability = _calculatePitcherProbability(pitcherScore, fielderScore);
    final isPitcher = random.nextDouble() < pitcherProbability;
    
    if (isPitcher) {
      return '投手';
    } else {
      // 野手ポジションを決定（投手能力が高いほど肩の良いポジションに）
      return _determineFielderPositionByPitchingAbility(pitcherScore, random);
    }
  }
  
  // 投手能力総合スコアを計算
  int _calculatePitcherScore(int baseAbility, int baseVelocity, Random random) {
    final control = baseAbility + random.nextInt(20);
    final stamina = baseAbility + random.nextInt(20);
    final breakAvg = baseAbility + random.nextInt(20);
    final velocity = baseVelocity + random.nextInt(20);
    
    // 投手能力の重み付け（球速40%、制球25%、スタミナ20%、変化球15%）
    return ((velocity * 0.4) + (control * 0.25) + (stamina * 0.2) + (breakAvg * 0.15)).round();
  }
  
  // 野手能力総合スコアを計算
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
  
  // 投手適性確率を計算（投手能力と野手能力のバランスを考慮）
  double _calculatePitcherProbability(int pitcherScore, int fielderScore) {
    final scoreDifference = pitcherScore - fielderScore;
    
    // 投手能力が野手能力より大幅に高い場合
    if (scoreDifference >= 30) return 0.80; // 0.90 → 0.80
    if (scoreDifference >= 20) return 0.65; // 0.75 → 0.65
    if (scoreDifference >= 10) return 0.50; // 0.60 → 0.50
    if (scoreDifference >= 0) return 0.35;  // 0.45 → 0.35
    if (scoreDifference >= -10) return 0.20; // 0.30 → 0.20
    if (scoreDifference >= -20) return 0.10; // 0.15 → 0.10
    return 0.05; // 投手能力が野手能力より大幅に低い場合
  }
  
  // 投手能力に基づく野手ポジション決定
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
  
  // 学年・ポジション別の最大球速を決定
  int _getMaxVelocityByGradeAndPosition(int grade, String position, int baseVelocity) {
    if (position == '投手') {
      // 投手の学年別制限（才能ランク6の怪物は特別扱い）
      if (baseVelocity >= 155) return 155; // 才能ランク6の怪物は155km/hまで
      
      switch (grade) {
        case 1: return 140; // 1年生は140km/hまで
        case 2: return 145; // 2年生は145km/hまで
        case 3: return 155; // 3年生は155km/hまで
        default: return 140;
      }
    } else {
      // 野手の球速上限を設定（投手能力が高い選手でも現実的な範囲に）
      if (baseVelocity >= 150) return 145; // 非常に高い投手能力でも145km/hまで
      if (baseVelocity >= 145) return 140; // 高い投手能力でも140km/hまで
      if (baseVelocity >= 140) return 135; // やや高い投手能力でも135km/hまで
      if (baseVelocity >= 135) return 130; // 中程度の投手能力でも130km/hまで
      return 128; // それ以外は128km/hまで
    }
  }
  
  // 野手の最大球速を決定（既存メソッドとの互換性のため）
  int _getMaxVelocityForFielder(int baseVelocity) {
    // 野手の球速上限を設定（投手能力が高い選手でも現実的な範囲に）
    if (baseVelocity >= 150) return 145; // 非常に高い投手能力でも145km/hまで
    if (baseVelocity >= 145) return 140; // 高い投手能力でも140km/hまで
    if (baseVelocity >= 140) return 135; // やや高い投手能力でも135km/hまで
    if (baseVelocity >= 135) return 130; // 中程度の投手能力でも130km/hまで
    return 128; // それ以外は128km/hまで
  }
  
  // 能力値に基づくポジション適性を生成
  Map<String, int> _generateDefaultPositionFit(String position) {
    const positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '外野手'];
    final fit = <String, int>{};
    
    // 基本適性値を設定
    for (final pos in positions) {
      if (pos == position) {
        fit[pos] = 70 + Random().nextInt(21); // 70-90（メインポジション）
      } else {
        fit[pos] = 40 + Random().nextInt(31); // 40-70（サブポジション）
      }
    }
    
    return fit;
  }
  
  // 現実的なポジション分布でランダムポジション決定
  String _randomPosition() {
    final random = Random();
    final rand = random.nextDouble();
    
    // 現実的な野球チームのポジション分布（投手比率を大幅に削減）
    if (rand < 0.08) return '投手';        // 8% - 投手（15% → 8%に削減）
    if (rand < 0.13) return '捕手';        // 5% - 捕手
    if (rand < 0.28) return '一塁手';      // 15% - 一塁手
    if (rand < 0.38) return '二塁手';      // 10% - 二塁手
    if (rand < 0.48) return '三塁手';      // 10% - 三塁手
    if (rand < 0.63) return '遊撃手';      // 15% - 遊撃手
    return '外野手';                       // 37% - 外野手（30% → 37%に増加）
  }
  String _randomPersonality() {
    final random = Random();
    const personalities = ['真面目', '負けず嫌い', 'ムードメーカー', '冷静', '情熱的', '努力家', '天才肌'];
    return personalities[random.nextInt(personalities.length)];
  }

  // 個別ポテンシャルシステムを使用した選手生成
  Player generatePlayer({
    required String name,
    required String school,
    required int grade,
    required String position,
    required String personality,
  }) {
    final random = Random();
    
    // 才能ランク（1〜5）
    final talent = _randomTalent();
    // 成長タイプ
    final growthType = _randomGrowthType();
    // 全ポジション適性
    final positionFit = _randomPositionFit(position);
    // メンタル・成長率
    final mentalGrit = 0.5 + (random.nextDouble() * 0.3); // 0.5-0.8
    final growthRate = 0.9 + (random.nextDouble() * 0.3); // 0.9-1.2
    
    // 球種を生成（投手の場合）
    final pitches = <Pitch>[];
    if (position == '投手') {
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
    }
    
    // 個別ポテンシャル生成（才能ランクに基づく）
    final individualPotentials = PlayerGenerator.generateIndividualPotentials(talent, position);
    
    // 能力値システムを生成
    final technicalAbilities = _generateTechnicalAbilities(talent, grade, position, random);
    final mentalAbilities = _generateMentalAbilities(talent, grade, random);
    final physicalAbilities = _generatePhysicalAbilities(talent, grade, random);
    
    return Player(
      name: name,
      school: school,
      grade: grade,
      position: position,
      personality: personality,
      pitches: pitches,
      technicalAbilities: technicalAbilities,
      mentalAbilities: mentalAbilities,
      physicalAbilities: physicalAbilities,
      mentalGrit: mentalGrit,
      growthRate: growthRate,
      peakAbility: individualPotentials.values.reduce((a, b) => a + b) ~/ individualPotentials.length, // 平均ポテンシャル
      positionFit: positionFit,
      talent: talent,
      growthType: growthType,
      individualPotentials: individualPotentials, // 個別ポテンシャルを保存
    );
  }
  

  
      // 能力値システムの生成
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
  
  // 統合された能力値ポテンシャル生成
  Map<String, int> _generateSimplifiedPotentials(int talent, Random random) {
    final potentials = <String, int>{};
    final basePotential = _getBasePotentialByTalent(talent);
    
    // 球速ポテンシャル
    final baseVelocity = _getBaseVelocityByTalent(talent);
    potentials['fastballVelo'] = (baseVelocity + random.nextInt(30) - 15).clamp(125, 170);
    
    // 能力値ポテンシャルを生成
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
      potentials[ability] = (basePotential + random.nextInt(30) - 15).clamp(50, 150);
    }
    
    for (final ability in mentalAbilities) {
      potentials[ability] = (basePotential + random.nextInt(30) - 15).clamp(50, 150);
    }
    
    for (final ability in physicalAbilities) {
      potentials[ability] = (basePotential + random.nextInt(30) - 15).clamp(50, 150);
    }
    
    return potentials;
  }
  
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
  
  double _getGradeMultiplier(int grade) {
    switch (grade) {
      case 1: return 0.6;
      case 2: return 0.8;
      case 3: return 1.0;
      default: return 0.8;
    }
  }
  
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
  
  int _getBasePotentialByTalent(int talent) {
    switch (talent) {
      case 1: return 65;
      case 2: return 75;
      case 3: return 85;
      case 4: return 95;
      case 5: return 105;
      case 6: return 130; // 怪物級のポテンシャル
      default: return 75;
    }
  }
  
  // 学年別確率調整を適用
  Map<String, int> _applyGradeAdjustments(Map<String, int> abilities, int grade, Random random) {
    final adjustedAbilities = <String, int>{};
    
    for (final entry in abilities.entries) {
      final abilityName = entry.key;
      final abilityValue = entry.value;
      
      if (abilityName == 'fastballVelo') {
        final probability = GradeProbabilityAdjuster.getFastballProbabilityAdjustment(grade, abilityValue);
        if (random.nextDouble() <= probability) {
          adjustedAbilities[abilityName] = abilityValue;
        } else {
          // 確率調整で除外された場合、より低い値を設定
          adjustedAbilities[abilityName] = 125 + random.nextInt(20); // 125-145 km/h
        }
      } else {
        final probability = GradeProbabilityAdjuster.getAbilityProbabilityAdjustment(grade, abilityValue);
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

  int _randomTalent() {
    final random = Random();
    final r = random.nextInt(1000000); // より細かい確率制御のため1000000を使用
    if (r < 499000) return 1;      // 49.9%
    if (r < 749000) return 2;      // 25%
    if (r < 949000) return 3;      // 20%
    if (r < 999000) return 4;      // 5%
    if (r < 999996) return 5;      // 0.0996%
    return 6;                      // 0.0004% (10年に1人程度)
  }
  String _randomGrowthType() {
    final random = Random();
    const types = ['early', 'normal', 'late', 'spurt'];
    return types[random.nextInt(types.length)];
  }
  int _randomPeakAbility(int talent) {
    final random = Random();
    switch (talent) {
      case 1:
        return 75 + random.nextInt(6); // 75-80
      case 2:
        return 85 + random.nextInt(8); // 85-92
      case 3:
        return 95 + random.nextInt(8); // 95-102
      case 4:
        return 105 + random.nextInt(10); // 105-115
      case 5:
        return 120 + random.nextInt(31); // 120-150
      case 6:
        return 130 + random.nextInt(21); // 130-150 (怪物級)
      default:
        return 80;
    }
  }
  Map<String, int> _randomPositionFit(String mainPosition) {
    final random = Random();
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

  Future<void> _refreshPlayersFromDb(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final playerMaps = await db.query('Player');
    print('デバッグ: データベースから ${playerMaps.length} 人の選手を読み込み');
    
    // school_idの分布を確認
    final schoolIdCounts = <int, int>{};
    for (final p in playerMaps) {
      final schoolId = p['school_id'] as int? ?? 0;
      schoolIdCounts[schoolId] = (schoolIdCounts[schoolId] ?? 0) + 1;
    }
    print('デバッグ: school_id分布: $schoolIdCounts');
    
    final personIds = playerMaps.map((p) => p['id'] as int).toList();
    final persons = <int, Map<String, dynamic>>{};
    if (personIds.isNotEmpty) {
      final personMaps = await db.query('Person', where: 'id IN (${List.filled(personIds.length, '?').join(',')})', whereArgs: personIds);
      for (final p in personMaps) {
        persons[p['id'] as int] = p;
      }
    }
    
    // 個別ポテンシャルを取得
    final potentialMaps = await db.query('PlayerPotentials');
    final potentials = <int, Map<String, int>>{};
    for (final p in potentialMaps) {
      final playerId = p['player_id'] as int;
      
      // デバッグログ: ポテンシャルデータの確認
      if (playerId == 1) {
        print('デバッグ: 選手ID 1のポテンシャルデータ読み込み');
        print('teamwork_potential: ${p['teamwork_potential']}');
        print('positioning_potential: ${p['positioning_potential']}');
        print('pressure_handling_potential: ${p['pressure_handling_potential']}');
        print('clutch_ability_potential: ${p['clutch_ability_potential']}');
        print('flexibility_potential: ${p['flexibility_potential']}');
      }
      
      potentials[playerId] = {
        // Technical（技術面）ポテンシャル
        'contact': p['contact_potential'] as int? ?? 0,
        'power': p['power_potential'] as int? ?? 0,
        'plateDiscipline': p['plate_discipline_potential'] as int? ?? 0,
        'bunt': p['bunt_potential'] as int? ?? 0,
        'oppositeFieldHitting': p['opposite_field_hitting_potential'] as int? ?? 0,
        'pullHitting': p['pull_hitting_potential'] as int? ?? 0,
        'batControl': p['bat_control_potential'] as int? ?? 0,
        'swingSpeed': p['swing_speed_potential'] as int? ?? 0,
        'fielding': p['fielding_potential'] as int? ?? 0,
        'throwing': p['throwing_potential'] as int? ?? 0,
        'catcherAbility': p['catcher_ability_potential'] as int? ?? 0,
        'control': p['control_potential'] as int? ?? 0,
        'fastball': p['fastball_potential'] as int? ?? 0,
        'breakingBall': p['breaking_ball_potential'] as int? ?? 0,
        'pitchMovement': p['pitch_movement_potential'] as int? ?? 0,
        // Mental（メンタル面）ポテンシャル
        'concentration': p['concentration_potential'] as int? ?? 0,
        'anticipation': p['anticipation_potential'] as int? ?? 0,
        'vision': p['vision_potential'] as int? ?? 0,
        'composure': p['composure_potential'] as int? ?? 0,
        'aggression': p['aggression_potential'] as int? ?? 0,
        'bravery': p['bravery_potential'] as int? ?? 0,
        'leadership': p['leadership_potential'] as int? ?? 0,
        'workRate': p['work_rate_potential'] as int? ?? 0,
        'selfDiscipline': p['self_discipline_potential'] as int? ?? 0,
        'ambition': p['ambition_potential'] as int? ?? 0,
        'teamwork': p['teamwork_potential'] as int? ?? 0,
        'positioning': p['positioning_potential'] as int? ?? 0,
        'pressureHandling': p['pressure_handling_potential'] as int? ?? 0,
        'clutchAbility': p['clutch_ability_potential'] as int? ?? 0,
        // Physical（フィジカル面）ポテンシャル
        'acceleration': p['acceleration_potential'] as int? ?? 0,
        'agility': p['agility_potential'] as int? ?? 0,
        'balance': p['balance_potential'] as int? ?? 0,
        'jumpingReach': p['jumping_reach_potential'] as int? ?? 0,
        'naturalFitness': p['natural_fitness_potential'] as int? ?? 0,
        'injuryProneness': p['injury_proneness_potential'] as int? ?? 0,
        'stamina': p['stamina_potential'] as int? ?? 0,
        'strength': p['strength_potential'] as int? ?? 0,
        'pace': p['pace_potential'] as int? ?? 0,
        'flexibility': p['flexibility_potential'] as int? ?? 0,
      };
    }
    
    // 学校ごとにplayersを再構築
    final updatedSchools = _currentGame!.schools.map((school) {
      print('デバッグ: 学校 ${school.name} (ID: ${school.id}) の選手を検索中');
      final schoolPlayers = playerMaps.where((p) => p['school_id'] == school.id).map((p) {
        final person = persons[p['id'] as int] ?? {};
        final playerId = p['id'] as int;
        final individualPotentials = potentials[playerId];
        
        // 能力値システムの復元（データベースから直接読み込み）
        final technicalAbilities = <TechnicalAbility, int>{};
        final mentalAbilities = <MentalAbility, int>{};
        final physicalAbilities = <PhysicalAbility, int>{};
        
        // Technical abilities復元
        technicalAbilities[TechnicalAbility.contact] = p['contact'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.power] = p['power'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.plateDiscipline] = p['plate_discipline'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.bunt] = p['bunt'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.oppositeFieldHitting] = p['opposite_field_hitting'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.pullHitting] = p['pull_hitting'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.batControl] = p['bat_control'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.swingSpeed] = p['swing_speed'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.fielding] = p['fielding'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.throwing] = p['throwing'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.catcherAbility] = p['catcher_ability'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.control] = p['control'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.fastball] = p['fastball'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.breakingBall] = p['breaking_ball'] as int? ?? 25;
        technicalAbilities[TechnicalAbility.pitchMovement] = p['pitch_movement'] as int? ?? 25;
        
        // Mental abilities復元
        mentalAbilities[MentalAbility.concentration] = p['concentration'] as int? ?? 25;
        mentalAbilities[MentalAbility.anticipation] = p['anticipation'] as int? ?? 25;
        mentalAbilities[MentalAbility.vision] = p['vision'] as int? ?? 25;
        mentalAbilities[MentalAbility.composure] = p['composure'] as int? ?? 25;
        mentalAbilities[MentalAbility.aggression] = p['aggression'] as int? ?? 25;
        mentalAbilities[MentalAbility.bravery] = p['bravery'] as int? ?? 25;
        mentalAbilities[MentalAbility.leadership] = p['leadership'] as int? ?? 25;
        mentalAbilities[MentalAbility.workRate] = p['work_rate'] as int? ?? 25;
        mentalAbilities[MentalAbility.selfDiscipline] = p['self_discipline'] as int? ?? 25;
        mentalAbilities[MentalAbility.ambition] = p['ambition'] as int? ?? 25;
        mentalAbilities[MentalAbility.teamwork] = p['teamwork'] as int? ?? 25;
        mentalAbilities[MentalAbility.positioning] = p['positioning'] as int? ?? 25;
        mentalAbilities[MentalAbility.pressureHandling] = p['pressure_handling'] as int? ?? 25;
        mentalAbilities[MentalAbility.clutchAbility] = p['clutch_ability'] as int? ?? 25;
        
        // Physical abilities復元
        physicalAbilities[PhysicalAbility.acceleration] = p['acceleration'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.agility] = p['agility'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.balance] = p['balance'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.jumpingReach] = p['jumping_reach'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.flexibility] = p['flexibility'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.naturalFitness] = p['natural_fitness'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.injuryProneness] = p['injury_proneness'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.stamina] = p['stamina'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.strength] = p['strength'] as int? ?? 25;
        physicalAbilities[PhysicalAbility.pace] = p['pace'] as int? ?? 25;
        
        // デバッグログ: 最初の選手の能力値を確認
        if (p['id'] == 1) {
          print('デバッグ: 選手ID 1の能力値読み込み');
          print('contact: ${p['contact']} (型: ${p['contact'].runtimeType})');
          print('power: ${p['power']} (型: ${p['power'].runtimeType})');
          print('fastball: ${p['fastball']} (型: ${p['fastball'].runtimeType})');
          print('natural_fitness: ${p['natural_fitness']} (型: ${p['natural_fitness'].runtimeType})');
          print('injury_proneness: ${p['injury_proneness']} (型: ${p['injury_proneness'].runtimeType})');
          print('flexibility: ${p['flexibility']} (型: ${p['flexibility'].runtimeType})');
          print('復元後のcontact: ${technicalAbilities[TechnicalAbility.contact]}');
          print('復元後のpower: ${technicalAbilities[TechnicalAbility.power]}');
          print('復元後のfastball: ${technicalAbilities[TechnicalAbility.fastball]}');
          print('復元後のnaturalFitness: ${physicalAbilities[PhysicalAbility.naturalFitness]}');
          print('復元後のinjuryProneness: ${physicalAbilities[PhysicalAbility.injuryProneness]}');
          print('復元後のflexibility: ${physicalAbilities[PhysicalAbility.flexibility]}');
        }
        
        // デバッグログ: 最初の選手の能力値を確認
        if (p['id'] == 1) {
          print('デバッグ: 選手ID 1の能力値読み込み');
          print('contact: ${p['contact']}');
          print('power: ${p['power']}');
          print('fastball: ${p['fastball']}');
          print('natural_fitness: ${p['natural_fitness']}');
          print('injury_proneness: ${p['injury_proneness']}');
          print('復元後のcontact: ${technicalAbilities[TechnicalAbility.contact]}');
          print('復元後のpower: ${technicalAbilities[TechnicalAbility.power]}');
          print('復元後のfastball: ${technicalAbilities[TechnicalAbility.fastball]}');
          print('復元後のnaturalFitness: ${physicalAbilities[PhysicalAbility.naturalFitness]}');
          print('復元後のinjuryProneness: ${physicalAbilities[PhysicalAbility.injuryProneness]}');
        }
        
        // デバッグログ: ポテンシャルの確認
        if (p['id'] == 1 && individualPotentials != null) {
          print('デバッグ: 選手ID 1のポテンシャル読み込み');
          print('teamwork_potential: ${individualPotentials['teamwork']}');
          print('positioning_potential: ${individualPotentials['positioning']}');
          print('pressure_handling_potential: ${individualPotentials['pressureHandling']}');
          print('clutch_ability_potential: ${individualPotentials['clutchAbility']}');
          print('flexibility_potential: ${individualPotentials['flexibility']}');
        }
        
        final player = Player(
          id: p['id'] as int?,
          name: person['name'] as String? ?? '名無し',
          school: school.name,
          grade: p['grade'] as int? ?? 1,
          position: p['position'] as String? ?? '',
          personality: person['personality'] as String? ?? '',
          pitches: [],
          technicalAbilities: technicalAbilities,
          mentalAbilities: mentalAbilities,
          physicalAbilities: physicalAbilities,
          mentalGrit: (p['mental_grit'] as num?)?.toDouble() ?? 0.0,
          growthRate: p['growth_rate'] as double? ?? 1.0,
          peakAbility: p['peak_ability'] as int? ?? 0,
          positionFit: _generateDefaultPositionFit(p['position'] as String? ?? '投手'),
          talent: (p['talent'] is int) ? p['talent'] as int : int.tryParse(p['talent']?.toString() ?? '') ?? 3,
          growthType: (p['growthType'] is String) ? p['growthType'] as String : (p['growthType']?.toString() ?? 'normal'),
          individualPotentials: individualPotentials,
        );
        return player;
      }).toList();
      print('デバッグ: 学校 ${school.name} で ${schoolPlayers.length} 人の選手を発見');
      return school.copyWith(players: schoolPlayers.cast<Player>());
    }).toList();
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  /// 週送り時にアクションを実行し、リザルトを返す
  Future<List<String>> advanceWeekWithResults(NewsService newsService, DataService dataService) async {
    final results = <String>[];
    if (_currentGame == null) return results;
    
    // スカウトアクションを実行
    final scoutResults = await executeScoutActions(dataService);
    results.addAll(scoutResults);
    
    // 3月1週→2週の週送り時に卒業処理
    final isGraduation = _currentGame!.currentMonth == 3 && _currentGame!.currentWeekOfMonth == 1;
    if (isGraduation) {
      await graduateThirdYearStudents(dataService);
      await _refreshPlayersFromDb(dataService);
      results.add('3年生が卒業しました。学校には1・2年生のみが在籍しています。');
    }
    
    // 3月5週→4月1週の週送り時に学年アップ＋新入生生成
    final isNewYear = _currentGame!.currentMonth == 3 && _currentGame!.currentWeekOfMonth == 5;
    if (isNewYear) {
      await promoteAllStudents(dataService);
      await generateNewStudentsForAllSchoolsDb(dataService);
      await _refreshPlayersFromDb(dataService);
      results.add('新年度が始まり、全学校で学年が1つ上がり新1年生が入学しました！');
    }
    
    // 3か月ごと（4,7,10,1月の最終週）に成長処理
    final isGrowthMonth = [4, 7, 10, 1].contains(_currentGame!.currentMonth);
    final isLastWeekOfMonth = _currentGame!.getMaxWeeksOfMonth(_currentGame!.currentMonth) == _currentGame!.currentWeekOfMonth;
    if (isGrowthMonth && isLastWeekOfMonth) {
      growAllPlayers();
      results.add('今シーズンの成長イベントが発生しました。選手たちが成長しています。');
    }
    
    // 週送り（週進行、AP/予算リセット、アクションリセット）
    _currentGame = _currentGame!
      .advanceWeek()
      .resetWeeklyResources(newAp: 6, newBudget: _currentGame!.budget)
      .resetActions();
    
    // オートセーブ（週送り完了後）
    await saveGame(dataService);
    await dataService.saveAutoGameData(_currentGame!.toJson());
    
    return results;
  }

  String _actionTypeToText(String type) {
    switch (type) {
      case 'PRAC_WATCH':
        return '練習視察';
      case 'GAME_WATCH':
        return '試合観戦';
      default:
        return type;
    }
  }

  void advanceWeek(NewsService newsService, DataService dataService) async {
    if (_currentGame != null) {
      _currentGame = _currentGame!.advanceWeek();
      // 必要に応じて週遷移時のイベントをここに追加
      triggerRandomEvent(newsService);
      
      // スカウトアクションを実行
      final scoutResults = await executeScoutActions(dataService);
      if (scoutResults.isNotEmpty) {
        print('スカウトアクション実行結果: ${scoutResults.join(', ')}');
      }
      
      // オートセーブ
      await saveGame(dataService);
    }
  }

  void addActionToGame(GameAction action) {
    if (_currentGame != null) {
      _currentGame = _currentGame!.addAction(action);
    }
  }

  // セーブ
  Future<void> saveGame(DataService dataService) async {
    if (_currentGame != null) {
      await dataService.saveGameDataToSlot(_currentGame!.toJson(), 1);
    }
  }

  // ロード
  Future<bool> loadGame(DataService dataService) async {
    final json = await dataService.loadGameDataFromSlot(1);
    if (json != null) {
      _currentGame = Game.fromJson(json);
      return true;
    }
    return false;
  }

  void loadGameFromJson(Map<String, dynamic> json) {
    _currentGame = Game.fromJson(json);
  }

  // 選手を発掘済みとして登録
  void discoverPlayer(Player player) {
    if (_currentGame != null) {
      _currentGame = _currentGame!.discoverPlayer(player);
    }
  }

  // 選手の能力値把握度を更新
  void updatePlayerKnowledge(Player player) {
    if (_currentGame != null) {
      // discoveredPlayersリスト内の該当選手を更新
      final updatedPlayers = _currentGame!.discoveredPlayers.map((p) {
        if (p.name == player.name && p.school == player.school) {
          return player;
        }
        return p;
      }).toList();
      
      _currentGame = _currentGame!.copyWith(discoveredPlayers: updatedPlayers);
    }
  }

  // 週送り時にスカウトアクションを実行
  Future<List<String>> executeScoutActions(DataService dataService) async {
    final results = <String>[];
    
    if (_currentGame == null || _currentGame!.weeklyActions.isEmpty) {
      return results;
    }
    
    final scoutAnalysisService = ScoutAnalysisService(dataService);
    
    for (final action in _currentGame!.weeklyActions) {
      if (action.type == 'SCOUT_SCHOOL') {
        // 学校視察アクションの実行
        final schoolIndex = action.schoolId;
        if (schoolIndex < _currentGame!.schools.length) {
          final school = _currentGame!.schools[schoolIndex];
          
          // 未発掘選手リスト
          final undiscoveredPlayers = school.players.where((p) => !p.isDiscovered).toList();
          if (undiscoveredPlayers.isNotEmpty) {
            // 未発掘選手がいればランダムで1人発掘
            final player = undiscoveredPlayers[Random().nextInt(undiscoveredPlayers.length)];
            player.isDiscovered = true;
            player.discoveredAt = DateTime.now();
            player.discoveredCount = 1;
            player.scoutedDates.add(DateTime.now());
            
            // 能力値把握度を初期値（20～40%）に
            player.abilityKnowledge.updateAll((k, v) => 20 + Random().nextInt(21));
            
            // スカウト分析データを保存
            final scoutId = 'default_scout'; // 仮のスカウトID
            final accuracy = 0.6 + (Random().nextDouble() * 0.3); // 60-90%の精度
            await scoutAnalysisService.saveScoutAnalysis(player, scoutId, accuracy);
            
            discoverPlayer(player);
            results.add('🏫 ${school.name}の視察: 新しい選手「${player.name}」を発見しました！');
          } else {
            // すでに全員発掘済み→ランダムで1人の把握度アップ
            final discovered = school.players.where((p) => p.isDiscovered).toList();
            if (discovered.isNotEmpty) {
              final player = discovered[Random().nextInt(discovered.length)];
              player.discoveredCount += 1;
              player.scoutedDates.add(DateTime.now());
              
              // 能力値把握度を+10～+20%アップ（最大80%）
              player.abilityKnowledge.updateAll((k, v) => (v + 10 + Random().nextInt(11)).clamp(0, 80));
              
              // スカウト分析データを更新
              final scoutId = 'default_scout';
              final accuracy = 0.7 + (Random().nextDouble() * 0.2); // 70-90%の精度（既知選手は精度が高い）
              await scoutAnalysisService.saveScoutAnalysis(player, scoutId, accuracy);
              
              results.add('🏫 ${school.name}の視察: 「${player.name}」の能力値の把握度が上がった！');
            } else {
              results.add('🏫 ${school.name}の視察: 特に新しい発見はありませんでした。');
            }
          }
        }
      }
    }
    
    return results;
  }
} 