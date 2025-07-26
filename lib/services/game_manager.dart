import 'dart:math';
import '../models/game/game.dart';
import '../models/player/player.dart';
import '../models/player/pitch.dart';
import '../models/school/school.dart';
import '../models/news/news_item.dart';
import 'news_service.dart';
import 'data_service.dart';

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
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    for (final school in _currentGame!.schools) {
      final newPlayers = <Player>[];
      for (int grade = 1; grade <= 3; grade++) {
        final numNew = 10 + (Random().nextInt(6)); // 10〜15人
        for (int i = 0; i < numNew; i++) {
          final isFamous = i == 0 && (Random().nextInt(3) == 0);
          final name = _generateRandomName();
          final position = _randomPosition();
          final personality = _randomPersonality();
          
          // 新しいgeneratePlayerメソッドを使用して選手を生成
          final player = generatePlayer(
            name: name,
            school: school.name,
            grade: grade,
            position: position,
            personality: personality,
          );
          
          // Personテーブルinsert
          final personId = await db.insert('Person', {
            'name': name,
            'birth_date': '20${6 + Random().nextInt(10)}-04-01',
            'gender': '男',
            'hometown': school.location,
            'personality': personality,
          });
          
          // Playerテーブルinsert（すべての選手が投手と野手の両方の能力値を持つ）
          await db.insert('Player', {
            'id': personId,
            'school_id': updatedSchools.length + 1, // 仮: schoolIdは1始まりで順次
            'grade': grade,
            'position': position,
            'fastball_velo': player.fastballVelo ?? 0,
            'max_fastball_velo': (player.fastballVelo ?? 0) + 10,
            'control': player.control ?? 0,
            'max_control': (player.control ?? 0) + 10,
            'stamina': player.stamina ?? 0,
            'max_stamina': (player.stamina ?? 0) + 10,
            'batting_power': player.batPower ?? 0,
            'max_batting_power': (player.batPower ?? 0) + 10,
            'running_speed': player.run ?? 0,
            'max_running_speed': (player.run ?? 0) + 10,
            'defense': player.field ?? 0,
            'max_defense': (player.field ?? 0) + 10,
            'mental': player.arm ?? 0,
            'max_mental': (player.arm ?? 0) + 10,
            'growth_rate': player.growthRate,
            'talent': player.talent,
            'growth_type': player.growthType,
            'mental_grit': player.mentalGrit,
            'peak_ability': player.peakAbility,
          });
          
          // PlayerPotentialsテーブルinsert（個別ポテンシャル保存）
          if (player.individualPotentials != null) {
            await db.insert('PlayerPotentials', {
              'player_id': personId,
              'control_potential': player.individualPotentials!['control'] ?? 0,
              'stamina_potential': player.individualPotentials!['stamina'] ?? 0,
              'break_avg_potential': player.individualPotentials!['breakAvg'] ?? 0,
              'bat_power_potential': player.individualPotentials!['batPower'] ?? 0,
              'bat_control_potential': player.individualPotentials!['batControl'] ?? 0,
              'run_potential': player.individualPotentials!['run'] ?? 0,
              'field_potential': player.individualPotentials!['field'] ?? 0,
              'arm_potential': player.individualPotentials!['arm'] ?? 0,
              'fastball_velo_potential': player.individualPotentials!['fastballVelo'] ?? 0,
            });
          }
          
          newPlayers.add(player);
          if (isFamous) {
            _currentGame = _currentGame!.discoverPlayer(player);
          }
        }
      }
      updatedSchools.add(school.copyWith(players: newPlayers));
    }
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  Future<void> startNewGameWithDb(String scoutName, DataService dataService) async {
    // 初期データ投入（初回のみ）
    await dataService.insertInitialData();
    final db = await dataService.database;
    // 学校リスト取得
    final schoolMaps = await db.query('Organization', where: 'type = ?', whereArgs: ['高校']);
    final schools = schoolMaps.map((m) => School(
      name: m['name'] as String,
      location: m['location'] as String,
      players: [], // 後で選手を割り当て
      coachTrust: m['school_strength'] as int? ?? 70,
      coachName: '未設定',
    )).toList();
    // 選手リスト取得
    final playerMaps = await db.query('Player');
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
      potentials[playerId] = {
        'control': p['control_potential'] as int? ?? 0,
        'stamina': p['stamina_potential'] as int? ?? 0,
        'breakAvg': p['break_avg_potential'] as int? ?? 0,
        'batPower': p['bat_power_potential'] as int? ?? 0,
        'batControl': p['bat_control_potential'] as int? ?? 0,
        'run': p['run_potential'] as int? ?? 0,
        'field': p['field_potential'] as int? ?? 0,
        'arm': p['arm_potential'] as int? ?? 0,
        'fastballVelo': p['fastball_velo_potential'] as int? ?? 0,
      };
    }
    
    final players = playerMaps.map((p) {
      final person = persons[p['id'] as int] ?? {};
      final playerId = p['id'] as int;
      final individualPotentials = potentials[playerId];
      
      return Player(
        name: person['name'] as String? ?? '名無し',
        school: schools.firstWhere((s) => s.name == '横浜工業高校').name,
        grade: p['grade'] as int? ?? 1,
        position: p['position'] as String? ?? '',
        personality: person['personality'] as String? ?? '',
        fastballVelo: p['fastball_velo'] as int? ?? 0,
        control: p['control'] as int? ?? 0,
        stamina: p['stamina'] as int? ?? 0,
        breakAvg: p['break_avg'] as int? ?? 0,
        pitches: [],
        mentalGrit: (p['mental_grit'] as num?)?.toDouble() ?? 0.0,
        growthRate: p['growth_rate'] as double? ?? 1.0,
        peakAbility: p['peak_ability'] as int? ?? 0,
        positionFit: {},
        talent: p['talent'] is int ? p['talent'] as int : int.tryParse(p['talent']?.toString() ?? '') ?? 3,
        growthType: p['growthType'] is String ? p['growthType'] as String : (p['growthType']?.toString() ?? 'normal'),
        individualPotentials: individualPotentials,
      );
    }).toList();
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
      ap: 6,
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
  }

  // スカウト実行
  Player? scoutNewPlayer(NewsService newsService) {
    if (_currentGame == null || _currentGame!.schools.isEmpty) return null;
    // ランダムな学校を選択
    final school = (_currentGame!.schools..shuffle()).first;
    // ランダムな学年
    final grade = 1 + (Random().nextInt(3));
    // 新しい選手を生成
    final newPlayer = school.generateNewPlayer(grade);
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
    for (final school in _currentGame!.schools) {
      final newPlayers = List<Player>.from(school.players);
      final numNew = 10 + (Random().nextInt(6)); // 10〜15人
      for (int i = 0; i < numNew; i++) {
        final isFamous = i == 0 && (Random().nextInt(3) == 0);
        final name = _generateRandomName();
        final position = _randomPosition();
        final personality = _randomPersonality();
        
        // 新しいgeneratePlayerメソッドを使用して選手を生成
        final player = generatePlayer(
          name: name,
          school: school.name,
          grade: 1,
          position: position,
          personality: personality,
        );
        
        // Personテーブルinsert
        final personId = await db.insert('Person', {
          'name': name,
          'birth_date': '20${6 + Random().nextInt(10)}-04-01',
          'gender': '男',
          'hometown': school.location,
          'personality': personality,
        });
        
        // Playerテーブルinsert（すべての選手が投手と野手の両方の能力値を持つ）
        await db.insert('Player', {
          'id': personId,
          'school_id': updatedSchools.length + 1, // 仮: schoolIdは1始まりで順次
          'grade': 1,
          'position': position,
          'fastball_velo': player.fastballVelo ?? 0,
          'max_fastball_velo': (player.fastballVelo ?? 0) + 10,
          'control': player.control ?? 0,
          'max_control': (player.control ?? 0) + 10,
          'stamina': player.stamina ?? 0,
          'max_stamina': (player.stamina ?? 0) + 10,
          'batting_power': player.batPower ?? 0,
          'max_batting_power': (player.batPower ?? 0) + 10,
          'running_speed': player.run ?? 0,
          'max_running_speed': (player.run ?? 0) + 10,
          'defense': player.field ?? 0,
          'max_defense': (player.field ?? 0) + 10,
          'mental': player.arm ?? 0,
          'max_mental': (player.arm ?? 0) + 10,
          'growth_rate': player.growthRate,
          'talent': player.talent,
          'growth_type': player.growthType,
          'mental_grit': player.mentalGrit,
          'peak_ability': player.peakAbility,
        });
        
        // PlayerPotentialsテーブルinsert（個別ポテンシャル保存）
        if (player.individualPotentials != null) {
          await db.insert('PlayerPotentials', {
            'player_id': personId,
            'control_potential': player.individualPotentials!['control'] ?? 0,
            'stamina_potential': player.individualPotentials!['stamina'] ?? 0,
            'break_avg_potential': player.individualPotentials!['breakAvg'] ?? 0,
            'bat_power_potential': player.individualPotentials!['batPower'] ?? 0,
            'bat_control_potential': player.individualPotentials!['batControl'] ?? 0,
            'run_potential': player.individualPotentials!['run'] ?? 0,
            'field_potential': player.individualPotentials!['field'] ?? 0,
            'arm_potential': player.individualPotentials!['arm'] ?? 0,
            'fastball_velo_potential': player.individualPotentials!['fastballVelo'] ?? 0,
          });
        }
        
        newPlayers.add(player);
        if (isFamous) {
          _currentGame = _currentGame!.discoverPlayer(player);
        }
      }
      updatedSchools.add(school.copyWith(players: newPlayers));
    }
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
  String _randomPosition() {
    final random = Random();
    const positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '外野手'];
    return positions[random.nextInt(positions.length)];
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
    
    // 1. 個別ポテンシャルを生成
    final individualPotentials = IndividualPotentialGenerator.generateIndividualPotentials(talent, random);
    
    // 2. 能力バランスを調整
    final balancedPotentials = AbilityBalanceAdjuster.adjustPotentialsForBalance(
      individualPotentials, 
      talent, 
      random
    );
    
    // 3. 初期能力値を生成
    final initialAbilities = InitialAbilityGenerator.generateInitialAbilities(
      balancedPotentials,
      grade,
      mentalGrit,
      growthRate,
      talent,
      growthType,
      random,
    );
    
    // 4. 学年別確率調整を適用
    final adjustedAbilities = _applyGradeAdjustments(initialAbilities, grade, random);
    
    // 5. ポジション別調整を適用
    final finalAbilities = _applyPositionAdjustments(adjustedAbilities, position, random);
    
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
    
    return Player(
      name: name,
      school: school,
      grade: grade,
      position: position,
      personality: personality,
      fastballVelo: finalAbilities['fastballVelo'] ?? 125,
      control: finalAbilities['control'] ?? 25,
      stamina: finalAbilities['stamina'] ?? 25,
      breakAvg: finalAbilities['breakAvg'] ?? 25,
      pitches: pitches,
      batPower: finalAbilities['batPower'] ?? 25,
      batControl: finalAbilities['batControl'] ?? 25,
      run: finalAbilities['run'] ?? 25,
      field: finalAbilities['field'] ?? 25,
      arm: finalAbilities['arm'] ?? 25,
      mentalGrit: mentalGrit,
      growthRate: growthRate,
      peakAbility: balancedPotentials.values.reduce((a, b) => a + b) ~/ balancedPotentials.length, // 平均ポテンシャル
      positionFit: positionFit,
      talent: talent,
      growthType: growthType,
      individualPotentials: balancedPotentials, // 個別ポテンシャルを保存
    );
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
    final r = random.nextInt(1000); // より細かい確率制御のため1000を使用
    if (r < 499) return 1; // 49.9%
    if (r < 749) return 2; // 25%
    if (r < 949) return 3; // 20%
    if (r < 999) return 4; // 5%
    return 5; // 0.1%
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
      potentials[playerId] = {
        'control': p['control_potential'] as int? ?? 0,
        'stamina': p['stamina_potential'] as int? ?? 0,
        'breakAvg': p['break_avg_potential'] as int? ?? 0,
        'batPower': p['bat_power_potential'] as int? ?? 0,
        'batControl': p['bat_control_potential'] as int? ?? 0,
        'run': p['run_potential'] as int? ?? 0,
        'field': p['field_potential'] as int? ?? 0,
        'arm': p['arm_potential'] as int? ?? 0,
        'fastballVelo': p['fastball_velo_potential'] as int? ?? 0,
      };
    }
    
    // 学校ごとにplayersを再構築
    final updatedSchools = _currentGame!.schools.map((school) {
      final schoolPlayers = playerMaps.where((p) => school.name == school.name).map((p) {
        final person = persons[p['id'] as int] ?? {};
        final playerId = p['id'] as int;
        final individualPotentials = potentials[playerId];
        
        return Player(
          name: person['name'] as String? ?? '名無し',
          school: school.name,
          grade: p['grade'] as int? ?? 1,
          position: p['position'] as String? ?? '',
          personality: person['personality'] as String? ?? '',
          fastballVelo: p['fastball_velo'] as int? ?? 0,
          control: p['control'] as int? ?? 0,
          stamina: p['stamina'] as int? ?? 0,
          breakAvg: p['break_avg'] as int? ?? 0,
          pitches: [],
          mentalGrit: (p['mental_grit'] as num?)?.toDouble() ?? 0.0,
          growthRate: p['growth_rate'] as double? ?? 1.0,
          peakAbility: p['peak_ability'] as int? ?? 0,
          positionFit: {},
          talent: (p['talent'] is int) ? p['talent'] as int : int.tryParse(p['talent']?.toString() ?? '') ?? 3,
          growthType: (p['growthType'] is String) ? p['growthType'] as String : (p['growthType']?.toString() ?? 'normal'),
          individualPotentials: individualPotentials,
        );
      }).toList();
      return school.copyWith(players: schoolPlayers);
    }).toList();
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  /// 週送り時にアクションを実行し、リザルトを返す
  Future<List<String>> advanceWeekWithResults(NewsService newsService, DataService dataService) async {
    final results = <String>[];
    if (_currentGame != null) {
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
      for (final action in _currentGame!.weeklyActions) {
        // 簡易リザルト生成（今後詳細化）
        final schoolName = (action.schoolId < _currentGame!.schools.length)
            ? _currentGame!.schools[action.schoolId].name
            : '不明な学校';
        results.add('${schoolName}で${_actionTypeToText(action.type)}を実行しました');
      }
      // 週送り（週進行、AP/予算リセット、アクションリセット）
      _currentGame = _currentGame!
        .advanceWeek()
        .resetWeeklyResources(newAp: 6, newBudget: _currentGame!.budget)
        .resetActions();
      await saveGame(dataService);
      // オートセーブ
      await dataService.saveAutoGameData(_currentGame!.toJson());
    }
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
} 