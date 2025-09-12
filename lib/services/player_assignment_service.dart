import 'dart:math' as math;
import '../models/player/player.dart';
import '../models/school/school.dart';
import '../models/player/player_abilities.dart';
import 'data_service.dart';
import 'default_player_templates.dart';
import 'package:sqflite/sqflite.dart';

/// 選手を学校に配属するサービス
class PlayerAssignmentService {
  final DataService _dataService;

  PlayerAssignmentService(this._dataService);

  /// 選手を学校に配属（最適化版）
  Future<void> assignPlayersToSchools(List<School> schools, List<Player> talentedPlayers, {required bool isNewYear}) async {
    try {
      final overallStopwatch = Stopwatch()..start();
      print('PlayerAssignmentService.assignPlayersToSchools: 開始 - 学校数: ${schools.length}, 才能選手数: ${talentedPlayers.length}, 新年度処理: $isNewYear');
      
      if (isNewYear) {
        print('PlayerAssignmentService.assignPlayersToSchools: 新年度処理のため、デフォルト選手の配置をスキップします');
        overallStopwatch.stop();
        print('PlayerAssignmentService.assignPlayersToSchools: 完了 - ${overallStopwatch.elapsedMilliseconds}ms');
        return;
      }

      // デフォルト選手を各学校に配属
      final defaultAssignmentStart = Stopwatch()..start();
      await _assignDefaultPlayersToSchools(schools);
      defaultAssignmentStart.stop();
      print('PlayerAssignmentService.assignPlayersToSchools: デフォルト選手配属完了 - ${defaultAssignmentStart.elapsedMilliseconds}ms');
      
      // 才能のある選手を学校に配属（バッチ処理版）
      if (talentedPlayers.isNotEmpty) {
        final talentedAssignmentStart = Stopwatch()..start();
        await _assignTalentedPlayersToSchoolsOptimized(schools, talentedPlayers);
        talentedAssignmentStart.stop();
        print('PlayerAssignmentService.assignPlayersToSchools: 才能選手配属完了 - ${talentedAssignmentStart.elapsedMilliseconds}ms');
      }
      
      overallStopwatch.stop();
      print('PlayerAssignmentService.assignPlayersToSchools: 完了 - ${overallStopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('PlayerAssignmentService.assignPlayersToSchools: エラーが発生しました: $e');
      rethrow;
    }
  }

  /// 各学校にデフォルト選手を配置（最適化版 - バッチ処理）
  Future<void> _assignDefaultPlayersToSchools(List<School> schools) async {
    try {
      final stopwatch = Stopwatch()..start();
      print('PlayerAssignmentService._assignDefaultPlayersToSchools: 開始 - 学校数: ${schools.length}');
      
      // 全デフォルト選手のデータを準備
      final personDataList = <Map<String, dynamic>>[];
      final playerDataList = <Map<String, dynamic>>[];
      final schoolPlayerMap = <String, List<Player>>{}; // 学校ID -> 選手リスト
      
      for (final school in schools) {
        try {
          // 学校ランクに応じたデフォルト選手を生成
          final defaultPlayer = DefaultPlayerTemplate.getTemplateByRank(school.rank, school.name);
          
          // 学校の選手リストに追加
          school.players.add(defaultPlayer);
          
          // 学校IDをキーとして選手を保存
          if (!schoolPlayerMap.containsKey(school.id)) {
            schoolPlayerMap[school.id] = [];
          }
          schoolPlayerMap[school.id]!.add(defaultPlayer);
          
          // バッチ挿入用のデータを準備
          personDataList.add({
            'name': defaultPlayer.name,
            'birth_date': DateTime.now().toIso8601String(),
            'gender': '男性',
            'hometown': '未設定',
            'personality': defaultPlayer.personality,
          });
          
          playerDataList.add({
            'school_id': int.parse(school.id),
            'school': school.name,
            'grade': defaultPlayer.grade,
            'age': defaultPlayer.age,
            'position': defaultPlayer.position,
            'fame': defaultPlayer.fame,
            'is_famous': defaultPlayer.isFamous ? 1 : 0,
            'is_scout_favorite': defaultPlayer.isScoutFavorite ? 1 : 0,
            'is_default_player': defaultPlayer.isDefaultPlayer ? 1 : 0,
            'growth_rate': defaultPlayer.growthRate,
            'talent': defaultPlayer.talent,
            'growth_type': defaultPlayer.growthType,
            'mental_grit': defaultPlayer.mentalGrit,
            'peak_ability': defaultPlayer.peakAbility,
            // Technical abilities
            'contact': defaultPlayer.technicalAbilities[TechnicalAbility.contact] ?? 25,
            'power': defaultPlayer.technicalAbilities[TechnicalAbility.power] ?? 25,
            'plate_discipline': defaultPlayer.technicalAbilities[TechnicalAbility.plateDiscipline] ?? 25,
            'bunt': defaultPlayer.technicalAbilities[TechnicalAbility.bunt] ?? 25,
            'opposite_field_hitting': defaultPlayer.technicalAbilities[TechnicalAbility.oppositeFieldHitting] ?? 25,
            'pull_hitting': defaultPlayer.technicalAbilities[TechnicalAbility.pullHitting] ?? 25,
            'bat_control': defaultPlayer.technicalAbilities[TechnicalAbility.batControl] ?? 25,
            'swing_speed': defaultPlayer.technicalAbilities[TechnicalAbility.swingSpeed] ?? 25,
            'fielding': defaultPlayer.technicalAbilities[TechnicalAbility.fielding] ?? 25,
            'throwing': defaultPlayer.technicalAbilities[TechnicalAbility.throwing] ?? 25,
            'catcher_ability': defaultPlayer.technicalAbilities[TechnicalAbility.catcherAbility] ?? 25,
            'control': defaultPlayer.technicalAbilities[TechnicalAbility.control] ?? 25,
            'fastball': defaultPlayer.technicalAbilities[TechnicalAbility.fastball] ?? 25,
            'breaking_ball': defaultPlayer.technicalAbilities[TechnicalAbility.breakingBall] ?? 25,
            'pitch_movement': defaultPlayer.technicalAbilities[TechnicalAbility.pitchMovement] ?? 25,
            // Mental abilities
            'concentration': defaultPlayer.mentalAbilities[MentalAbility.concentration] ?? 25,
            'anticipation': defaultPlayer.mentalAbilities[MentalAbility.anticipation] ?? 25,
            'vision': defaultPlayer.mentalAbilities[MentalAbility.vision] ?? 25,
            'composure': defaultPlayer.mentalAbilities[MentalAbility.composure] ?? 25,
            'aggression': defaultPlayer.mentalAbilities[MentalAbility.aggression] ?? 25,
            'bravery': defaultPlayer.mentalAbilities[MentalAbility.bravery] ?? 25,
            'leadership': defaultPlayer.mentalAbilities[MentalAbility.leadership] ?? 25,
            'work_rate': defaultPlayer.mentalAbilities[MentalAbility.workRate] ?? 25,
            'self_discipline': defaultPlayer.mentalAbilities[MentalAbility.selfDiscipline] ?? 25,
            'ambition': defaultPlayer.mentalAbilities[MentalAbility.ambition] ?? 25,
            'teamwork': defaultPlayer.mentalAbilities[MentalAbility.teamwork] ?? 25,
            'positioning': defaultPlayer.mentalAbilities[MentalAbility.positioning] ?? 25,
            'pressure_handling': defaultPlayer.mentalAbilities[MentalAbility.pressureHandling] ?? 25,
            'clutch_ability': defaultPlayer.mentalAbilities[MentalAbility.clutchAbility] ?? 25,
            // Physical abilities
            'acceleration': defaultPlayer.physicalAbilities[PhysicalAbility.acceleration] ?? 25,
            'agility': defaultPlayer.physicalAbilities[PhysicalAbility.agility] ?? 25,
            'balance': defaultPlayer.physicalAbilities[PhysicalAbility.balance] ?? 25,
            'jumping_reach': defaultPlayer.physicalAbilities[PhysicalAbility.jumpingReach] ?? 25,
            'natural_fitness': defaultPlayer.physicalAbilities[PhysicalAbility.naturalFitness] ?? 25,
            'injury_proneness': defaultPlayer.physicalAbilities[PhysicalAbility.injuryProneness] ?? 25,
            'stamina': defaultPlayer.physicalAbilities[PhysicalAbility.stamina] ?? 25,
            'strength': defaultPlayer.physicalAbilities[PhysicalAbility.strength] ?? 25,
            'pace': defaultPlayer.physicalAbilities[PhysicalAbility.pace] ?? 25,
            'flexibility': defaultPlayer.physicalAbilities[PhysicalAbility.flexibility] ?? 25,
            // 総合能力値（後で計算して更新）
            'overall': 50,
            'technical': 50,
            'physical': 50,
            'mental': 50,
          });
          
        } catch (e) {
          print('PlayerAssignmentService._assignDefaultPlayersToSchools: ${school.name}でエラー: $e');
          // エラーが発生しても処理を継続
        }
      }
      
      // バッチ挿入実行
      final db = await _dataService.database;
      await db.transaction((txn) async {
        // Personテーブルにバッチ挿入（真のバッチ処理）
        final personIds = <int>[];
        for (final personData in personDataList) {
          final personId = await txn.insert('Person', personData);
          personIds.add(personId);
        }
        
        // Playerテーブルにバッチ挿入（真のバッチ処理）
        for (int i = 0; i < playerDataList.length; i++) {
          final playerData = Map<String, dynamic>.from(playerDataList[i]);
          playerData['person_id'] = personIds[i];
          await txn.insert('Player', playerData);
        }
        
        // 学校の選手リストを更新（IDを設定）
        int playerIndex = 0;
        for (final school in schools) {
          if (schoolPlayerMap.containsKey(school.id)) {
            final schoolPlayers = schoolPlayerMap[school.id]!;
            for (int i = 0; i < schoolPlayers.length; i++) {
              final player = schoolPlayers[i];
              final updatedPlayer = player.copyWith(id: personIds[playerIndex + i]);
              final playerIndexInSchool = school.players.indexOf(player);
              if (playerIndexInSchool != -1) {
                school.players[playerIndexInSchool] = updatedPlayer;
              }
            }
            playerIndex += schoolPlayers.length;
          }
        }
      });
      
      stopwatch.stop();
      print('PlayerAssignmentService._assignDefaultPlayersToSchools: 完了 - ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('PlayerAssignmentService._assignDefaultPlayersToSchools: エラーが発生しました: $e');
      rethrow;
    }
  }

  /// 才能のある選手を学校に配属（最適化版 - バッチ処理）
  Future<void> _assignTalentedPlayersToSchoolsOptimized(List<School> schools, List<Player> talentedPlayers) async {
    try {
      final stopwatch = Stopwatch()..start();
      print('PlayerAssignmentService._assignTalentedPlayersToSchoolsOptimized: 開始 - 選手数: ${talentedPlayers.length}');
      
      // 学校をランク別に分類
      final eliteSchools = schools.where((s) => s.rank == SchoolRank.elite).toList();
      final strongSchools = schools.where((s) => s.rank == SchoolRank.strong).toList();
      final otherSchools = schools.where((s) => s.rank == SchoolRank.average || s.rank == SchoolRank.weak).toList();
      
      // 各ランクの学校に配属する選手数を決定（名門60%、強豪30%、その他10%）
      final totalTalentedPlayers = talentedPlayers.length;
      final eliteCount = (totalTalentedPlayers * 0.60).round();      // 60%
      final strongCount = (totalTalentedPlayers * 0.30).round();     // 30%
      final otherCount = totalTalentedPlayers - eliteCount - strongCount; // 10%
      
      print('PlayerAssignmentService._assignTalentedPlayersToSchoolsOptimized: 配分 - 名門: $eliteCount, 強豪: $strongCount, その他: $otherCount');
      
      // 選手を配分
      final elitePlayers = talentedPlayers.take(eliteCount).toList();
      final strongPlayers = talentedPlayers.skip(eliteCount).take(strongCount).toList();
      final otherPlayers = talentedPlayers.skip(eliteCount + strongCount).take(otherCount).toList();
      
      // バッチ処理で一括挿入
      await _batchInsertPlayersToDatabase(eliteSchools, elitePlayers);
      await _batchInsertPlayersToDatabase(strongSchools, strongPlayers);
      await _batchInsertPlayersToDatabase(otherSchools, otherPlayers);
      
      stopwatch.stop();
      print('PlayerAssignmentService._assignTalentedPlayersToSchoolsOptimized: 完了 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      print('PlayerAssignmentService._assignTalentedPlayersToSchoolsOptimized: エラー: $e');
      rethrow;
    }
  }





  /// バッチ処理で選手をデータベースに一括挿入
  Future<void> _batchInsertPlayersToDatabase(List<School> schools, List<Player> players) async {
    if (schools.isEmpty || players.isEmpty) return;
    
    try {
      final stopwatch = Stopwatch()..start();
      print('PlayerAssignmentService._batchInsertPlayersToDatabase: 開始 - 学校数: ${schools.length}, 選手数: ${players.length}');
      
      final db = await _dataService.database;
      
      await db.transaction((txn) async {
        // 選手を学校に均等に配分
        final playersPerSchool = players.length ~/ schools.length;
        final remainingPlayers = players.length % schools.length;
        
        int playerIndex = 0;
        
        for (int i = 0; i < schools.length; i++) {
          final school = schools[i];
          final schoolPlayerCount = playersPerSchool + (i < remainingPlayers ? 1 : 0);
          
          // 学校の制限をチェック
          final currentGeneratedCount = _getCurrentGeneratedPlayerCount(school);
          final maxGeneratedPlayers = school.getMaxGeneratedPlayers();
          
          if (currentGeneratedCount < maxGeneratedPlayers) {
            final availableSlots = maxGeneratedPlayers - currentGeneratedCount;
            final playersToAssign = math.min(schoolPlayerCount, availableSlots);
            
            if (playersToAssign > 0) {
              // この学校に配属する選手を取得
              final schoolPlayers = players.skip(playerIndex).take(playersToAssign).toList();
              
              // バッチ挿入用のデータを準備
              final personDataList = <Map<String, dynamic>>[];
              final playerDataList = <Map<String, dynamic>>[];
              final potentialDataList = <Map<String, dynamic>>[];
              
              for (final player in schoolPlayers) {
                final updatedPlayer = player.copyWith(school: school.name);
                
                // Personデータを準備
                personDataList.add({
                  'name': updatedPlayer.name,
                  'birth_date': DateTime.now().toIso8601String(),
                  'gender': '男性',
                  'hometown': '未設定',
                  'personality': updatedPlayer.personality,
                });
                
                // Playerデータを準備
                playerDataList.add({
                  'school_id': school.id,
                  'school': school.name,
                  'grade': updatedPlayer.grade,
                  'age': updatedPlayer.age,
                  'position': updatedPlayer.position,
                  'fame': updatedPlayer.fame,
                  'is_famous': updatedPlayer.isFamous ? 1 : 0,
                  'is_scout_favorite': updatedPlayer.isScoutFavorite ? 1 : 0,
                  'is_default_player': updatedPlayer.isDefaultPlayer ? 1 : 0,
                  'growth_rate': updatedPlayer.growthRate,
                  'talent': updatedPlayer.talent,
                  'growth_type': updatedPlayer.growthType,
                  'mental_grit': updatedPlayer.mentalGrit,
                  'peak_ability': updatedPlayer.peakAbility,
                  // Technical abilities
                  'contact': updatedPlayer.technicalAbilities[TechnicalAbility.contact] ?? 25,
                  'power': updatedPlayer.technicalAbilities[TechnicalAbility.power] ?? 25,
                  'plate_discipline': updatedPlayer.technicalAbilities[TechnicalAbility.plateDiscipline] ?? 25,
                  'bunt': updatedPlayer.technicalAbilities[TechnicalAbility.bunt] ?? 25,
                  'opposite_field_hitting': updatedPlayer.technicalAbilities[TechnicalAbility.oppositeFieldHitting] ?? 25,
                  'pull_hitting': updatedPlayer.technicalAbilities[TechnicalAbility.pullHitting] ?? 25,
                  'bat_control': updatedPlayer.technicalAbilities[TechnicalAbility.batControl] ?? 25,
                  'swing_speed': updatedPlayer.technicalAbilities[TechnicalAbility.swingSpeed] ?? 25,
                  'fielding': updatedPlayer.technicalAbilities[TechnicalAbility.fielding] ?? 25,
                  'throwing': updatedPlayer.technicalAbilities[TechnicalAbility.throwing] ?? 25,
                  'catcher_ability': updatedPlayer.technicalAbilities[TechnicalAbility.catcherAbility] ?? 25,
                  'control': updatedPlayer.technicalAbilities[TechnicalAbility.control] ?? 25,
                  'fastball': updatedPlayer.technicalAbilities[TechnicalAbility.fastball] ?? 25,
                  'breaking_ball': updatedPlayer.technicalAbilities[TechnicalAbility.breakingBall] ?? 25,
                  'pitch_movement': updatedPlayer.technicalAbilities[TechnicalAbility.pitchMovement] ?? 25,
                  // Mental abilities
                  'concentration': updatedPlayer.mentalAbilities[MentalAbility.concentration] ?? 25,
                  'anticipation': updatedPlayer.mentalAbilities[MentalAbility.anticipation] ?? 25,
                  'vision': updatedPlayer.mentalAbilities[MentalAbility.vision] ?? 25,
                  'composure': updatedPlayer.mentalAbilities[MentalAbility.composure] ?? 25,
                  'aggression': updatedPlayer.mentalAbilities[MentalAbility.aggression] ?? 25,
                  'bravery': updatedPlayer.mentalAbilities[MentalAbility.bravery] ?? 25,
                  'leadership': updatedPlayer.mentalAbilities[MentalAbility.leadership] ?? 25,
                  'work_rate': updatedPlayer.mentalAbilities[MentalAbility.workRate] ?? 25,
                  'self_discipline': updatedPlayer.mentalAbilities[MentalAbility.selfDiscipline] ?? 25,
                  'ambition': updatedPlayer.mentalAbilities[MentalAbility.ambition] ?? 25,
                  'teamwork': updatedPlayer.mentalAbilities[MentalAbility.teamwork] ?? 25,
                  'positioning': updatedPlayer.mentalAbilities[MentalAbility.positioning] ?? 25,
                  'pressure_handling': updatedPlayer.mentalAbilities[MentalAbility.pressureHandling] ?? 25,
                  'clutch_ability': updatedPlayer.mentalAbilities[MentalAbility.clutchAbility] ?? 25,
                  // Physical abilities
                  'acceleration': updatedPlayer.physicalAbilities[PhysicalAbility.acceleration] ?? 25,
                  'agility': updatedPlayer.physicalAbilities[PhysicalAbility.agility] ?? 25,
                  'balance': updatedPlayer.physicalAbilities[PhysicalAbility.balance] ?? 25,
                  'jumping_reach': updatedPlayer.physicalAbilities[PhysicalAbility.jumpingReach] ?? 25,
                  'natural_fitness': updatedPlayer.physicalAbilities[PhysicalAbility.naturalFitness] ?? 25,
                  'injury_proneness': updatedPlayer.physicalAbilities[PhysicalAbility.injuryProneness] ?? 25,
                  'stamina': updatedPlayer.physicalAbilities[PhysicalAbility.stamina] ?? 25,
                  'strength': updatedPlayer.physicalAbilities[PhysicalAbility.strength] ?? 25,
                  'pace': updatedPlayer.physicalAbilities[PhysicalAbility.pace] ?? 25,
                  'flexibility': updatedPlayer.physicalAbilities[PhysicalAbility.flexibility] ?? 25,
                  // 総合能力値（後で計算して更新）
                  'overall': 50,
                  'technical': 50,
                  'physical': 50,
                  'mental': 50,
                });
                
                // ポテンシャルデータを準備
                if (updatedPlayer.individualPotentials != null && updatedPlayer.individualPotentials!.isNotEmpty) {
                  potentialDataList.add(_preparePotentialData(updatedPlayer));
                }
              }
              
                  // バッチ挿入実行
                  final personIds = <int>[];
                  for (final personData in personDataList) {
                    final personId = await txn.insert('Person', personData);
                    personIds.add(personId);
                  }
                  
                  for (int i = 0; i < playerDataList.length; i++) {
                    final playerData = Map<String, dynamic>.from(playerDataList[i]);
                    playerData['person_id'] = personIds[i];
                    await txn.insert('Player', playerData);
                  }
                  
                  for (int i = 0; i < potentialDataList.length && i < personIds.length; i++) {
                    final potentialData = Map<String, dynamic>.from(potentialDataList[i]);
                    potentialData['player_id'] = personIds[i];
                    await txn.insert('PlayerPotentials', potentialData);
                  }
              
              // 学校の選手リストを更新
              for (int j = 0; j < schoolPlayers.length; j++) {
                final player = schoolPlayers[j];
                final updatedPlayer = player.copyWith(school: school.name, id: personIds[j]);
                school.players.add(updatedPlayer);
              }
            }
            
            playerIndex += playersToAssign;
          }
        }
      });
      
      stopwatch.stop();
      print('PlayerAssignmentService._batchInsertPlayersToDatabase: 完了 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      print('PlayerAssignmentService._batchInsertPlayersToDatabase: エラー: $e');
      rethrow;
    }
  }


  /// ポテンシャルデータを準備
  Map<String, dynamic> _preparePotentialData(Player player) {
    final individualPotentials = player.individualPotentials ?? <String, int>{};
    
    return {
      // 技術面ポテンシャル
      'contact_potential': individualPotentials['contact'] ?? 50,
      'power_potential': individualPotentials['power'] ?? 50,
      'plate_discipline_potential': individualPotentials['plate_discipline'] ?? 50,
      'bunt_potential': individualPotentials['bunt'] ?? 50,
      'opposite_field_hitting_potential': individualPotentials['opposite_field_hitting'] ?? 50,
      'pull_hitting_potential': individualPotentials['pull_hitting'] ?? 50,
      'bat_control_potential': individualPotentials['bat_control'] ?? 50,
      'swing_speed_potential': individualPotentials['swing_speed'] ?? 50,
      'fielding_potential': individualPotentials['fielding'] ?? 50,
      'throwing_potential': individualPotentials['throwing'] ?? 50,
      'catcher_ability_potential': individualPotentials['catcher_ability'] ?? 50,
      'control_potential': individualPotentials['control'] ?? 50,
      'fastball_potential': individualPotentials['fastball'] ?? 50,
      'breaking_ball_potential': individualPotentials['breaking_ball'] ?? 50,
      'pitch_movement_potential': individualPotentials['pitch_movement'] ?? 50,
      
      // メンタル面ポテンシャル
      'concentration_potential': individualPotentials['concentration'] ?? 50,
      'anticipation_potential': individualPotentials['anticipation'] ?? 50,
      'vision_potential': individualPotentials['vision'] ?? 50,
      'composure_potential': individualPotentials['composure'] ?? 50,
      'aggression_potential': individualPotentials['aggression'] ?? 50,
      'bravery_potential': individualPotentials['bravery'] ?? 50,
      'leadership_potential': individualPotentials['leadership'] ?? 50,
      'work_rate_potential': individualPotentials['work_rate'] ?? 50,
      'self_discipline_potential': individualPotentials['self_discipline'] ?? 50,
      'ambition_potential': individualPotentials['ambition'] ?? 50,
      'teamwork_potential': individualPotentials['teamwork'] ?? 50,
      'positioning_potential': individualPotentials['positioning'] ?? 50,
      'pressure_handling_potential': individualPotentials['pressure_handling'] ?? 50,
      'clutch_ability_potential': individualPotentials['clutch_ability'] ?? 50,
      
      // フィジカル面ポテンシャル
      'acceleration_potential': individualPotentials['acceleration'] ?? 50,
      'agility_potential': individualPotentials['agility'] ?? 50,
      'balance_potential': individualPotentials['balance'] ?? 50,
      'jumping_reach_potential': individualPotentials['jumping_reach'] ?? 50,
      'natural_fitness_potential': individualPotentials['natural_fitness'] ?? 50,
      'injury_proneness_potential': individualPotentials['injury_proneness'] ?? 50,
      'stamina_potential': individualPotentials['stamina'] ?? 50,
      'strength_potential': individualPotentials['strength'] ?? 50,
      'pace_potential': individualPotentials['pace'] ?? 50,
      'flexibility_potential': individualPotentials['flexibility'] ?? 50,
    };
  }

  /// 現在の生成選手数を取得
  int _getCurrentGeneratedPlayerCount(School school) {
    return school.players.where((p) => p.talent >= 3).length;
  }











  /// 選手配属の統計情報を取得
  Future<Map<SchoolRank, Map<String, int>>> getPlayerDistributionStats(List<School> schools) async {
    final stats = <SchoolRank, Map<String, int>>{};
    
    for (final rank in SchoolRank.values) {
      final rankSchools = schools.where((s) => s.rank == rank).toList();
      final totalSchools = rankSchools.length;
      
      int totalGeneratedPlayers = 0;
      
      for (final school in rankSchools) {
        totalGeneratedPlayers += school.players.where((p) => p.talent >= 3).length;
      }
      
      stats[rank] = {
        'total_schools': totalSchools,
        'total_generated_players': totalGeneratedPlayers,
      };
    }
    
    return stats;
  }
}
