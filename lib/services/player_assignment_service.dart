import 'dart:math' as math;
import '../models/player/player.dart';
import '../models/school/school.dart';
import '../models/player/player_abilities.dart';
import '../models/player/pitch.dart';
import 'data_service.dart';
import 'default_player_templates.dart';
import 'package:sqflite/sqflite.dart';

/// 選手を学校に配属するサービス
class PlayerAssignmentService {
  final DataService _dataService;
  final math.Random _random = math.Random();

  PlayerAssignmentService(this._dataService);

  /// 選手を学校に配属
  Future<void> assignPlayersToSchools(List<School> schools, List<Player> talentedPlayers) async {
    print('PlayerAssignmentService.assignPlayersToSchools: 開始 - 学校数: ${schools.length}, 才能選手数: ${talentedPlayers.length}');
    
    try {
      // 1. 各学校にデフォルト選手を配置
      await _assignDefaultPlayersToSchools(schools);
      
      // 2. 才能のある選手を学校に配属
      await _assignTalentedPlayersToSchools(schools, talentedPlayers);
      
      print('PlayerAssignmentService.assignPlayersToSchools: 完了');
    } catch (e) {
      print('PlayerAssignmentService.assignPlayersToSchools: エラーが発生しました: $e');
      rethrow;
    }
  }

  /// 各学校にデフォルト選手を配置
  Future<void> _assignDefaultPlayersToSchools(List<School> schools) async {
    print('PlayerAssignmentService._assignDefaultPlayersToSchools: 開始 - 学校数: ${schools.length}');
    
    for (final school in schools) {
      try {
        // 学校ランクに応じたデフォルト選手を生成
        final defaultPlayer = DefaultPlayerTemplate.getTemplateByRank(school.rank, school.name);
        
        // 学校の選手リストに追加
        school.players.add(defaultPlayer);
        
        // データベースに保存
        final savedPlayer = await _savePlayerToDatabase(defaultPlayer, school);
        
        // 保存された選手（ID付き）でリストを更新
        final playerIndex = school.players.indexOf(defaultPlayer);
        if (playerIndex != -1) {
          school.players[playerIndex] = savedPlayer;
        }
        
        // 個別の学校への配置ログは削除
      } catch (e) {
        print('PlayerAssignmentService._assignDefaultPlayersToSchools: ${school.name}でエラー: $e');
        // エラーが発生しても処理を継続
      }
    }
    
    print('PlayerAssignmentService._assignDefaultPlayersToSchools: 完了');
  }

  /// 才能のある選手を学校に配属（指定された確率で）
  Future<void> _assignTalentedPlayersToSchools(List<School> schools, List<Player> talentedPlayers) async {
    // 学校をランク別に分類
    final eliteSchools = schools.where((s) => s.rank == SchoolRank.elite).toList();
    final strongSchools = schools.where((s) => s.rank == SchoolRank.strong).toList();
    final averageSchools = schools.where((s) => s.rank == SchoolRank.average).toList();
    final weakSchools = schools.where((s) => s.rank == SchoolRank.weak).toList();
    
    // 各ランクの学校に配属する選手数を決定
    final totalTalentedPlayers = talentedPlayers.length;
    final eliteCount = (totalTalentedPlayers * 0.45).round();      // 45%
    final strongCount = (totalTalentedPlayers * 0.30).round();     // 30%
    final averageCount = (totalTalentedPlayers * 0.20).round();    // 20%
    final weakCount = totalTalentedPlayers - eliteCount - strongCount - averageCount; // 5%
    

    
    // 各ランクの学校に選手を配属
    await _assignPlayersToRankedSchools(eliteSchools, talentedPlayers.take(eliteCount).toList());
    await _assignPlayersToRankedSchools(strongSchools, talentedPlayers.skip(eliteCount).take(strongCount).toList());
    await _assignPlayersToRankedSchools(averageSchools, talentedPlayers.skip(eliteCount + strongCount).take(averageCount).toList());
    await _assignPlayersToRankedSchools(weakSchools, talentedPlayers.skip(eliteCount + strongCount + averageCount).take(weakCount).toList());
  }

  /// 特定ランクの学校群に選手を配属
  Future<void> _assignPlayersToRankedSchools(List<School> schools, List<Player> players) async {
    if (schools.isEmpty || players.isEmpty) return;
    
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
        
        for (int j = 0; j < playersToAssign && playerIndex < players.length; j++) {
          final player = players[playerIndex];
          
          // 選手の学校を設定（Playerオブジェクトは不変なので、データベースのみ更新）
          // player.school = school.name; // この行はコメントアウト
          
          // 選手の学校情報を更新（データベース用）
          final updatedPlayer = player.copyWith(school: school.name);
          
          // 学校の選手リストに追加（更新された選手情報）
          school.players.add(updatedPlayer);
          
          // データベースに保存（更新された選手情報）
          final savedPlayer = await _savePlayerToDatabase(updatedPlayer, school);
          
          // 保存された選手（ID付き）でリストを更新
          final playerIndexInSchool = school.players.indexOf(updatedPlayer);
          if (playerIndexInSchool != -1) {
            school.players[playerIndexInSchool] = savedPlayer;
          }
          
          playerIndex++;
        }
      }
    }
  }



  /// 現在の生成選手数を取得
  int _getCurrentGeneratedPlayerCount(School school) {
    return school.players.where((p) => p.talent >= 3).length;
  }





  /// 選手をデータベースに保存
  Future<Player> _savePlayerToDatabase(Player player, School school) async {
    try {
      final db = await _dataService.database;
      
      // Personテーブルに挿入
      final personId = await db.insert('Person', {
        'name': player.name,
        'birth_date': DateTime.now().toIso8601String(), // デフォルト生年月日
        'gender': '男性',
        'hometown': '未設定', // デフォルト出身地
        'personality': player.personality,
      });
      
      // Playerテーブルに挿入
      final playerId = await db.insert('Player', {
        'person_id': personId,
        'school_id': school.id,
        'school': player.school, // 学校名を保存
        'grade': player.grade,
        'age': player.age ?? 15,
        'position': player.position,
        'fame': player.fame,
        'is_publicly_known': player.isPubliclyKnown ? 1 : 0,
        'is_scout_favorite': player.isScoutFavorite ? 1 : 0,
        'is_default_player': player.isDefaultPlayer ? 1 : 0, // デフォルト選手フラグ
        'growth_rate': player.growthRate,
        'talent': player.talent,
        'growth_type': player.growthType,
        'mental_grit': player.mentalGrit,
        'peak_ability': player.peakAbility,
        // Technical abilities
        'contact': player.technicalAbilities[TechnicalAbility.contact] ?? 25,
        'power': player.technicalAbilities[TechnicalAbility.power] ?? 25,
        'plate_discipline': player.technicalAbilities[TechnicalAbility.plateDiscipline] ?? 25,
        'bunt': player.technicalAbilities[TechnicalAbility.bunt] ?? 25,
        'opposite_field_hitting': player.technicalAbilities[TechnicalAbility.oppositeFieldHitting] ?? 25,
        'pull_hitting': player.technicalAbilities[TechnicalAbility.pullHitting] ?? 25,
        'bat_control': player.technicalAbilities[TechnicalAbility.batControl] ?? 25,
        'swing_speed': player.technicalAbilities[TechnicalAbility.swingSpeed] ?? 25,
        'fielding': player.technicalAbilities[TechnicalAbility.fielding] ?? 25,
        'throwing': player.technicalAbilities[TechnicalAbility.throwing] ?? 25,
        'catcher_ability': player.technicalAbilities[TechnicalAbility.catcherAbility] ?? 25,
        'control': player.technicalAbilities[TechnicalAbility.control] ?? 25,
        'fastball': player.technicalAbilities[TechnicalAbility.fastball] ?? 25,
        'breaking_ball': player.technicalAbilities[TechnicalAbility.breakingBall] ?? 25,
        'pitch_movement': player.technicalAbilities[TechnicalAbility.pitchMovement] ?? 25,
        // Mental abilities
        'concentration': player.mentalAbilities[MentalAbility.concentration] ?? 25,
        'anticipation': player.mentalAbilities[MentalAbility.anticipation] ?? 25,
        'vision': player.mentalAbilities[MentalAbility.vision] ?? 25,
        'composure': player.mentalAbilities[MentalAbility.composure] ?? 25,
        'aggression': player.mentalAbilities[MentalAbility.aggression] ?? 25,
        'bravery': player.mentalAbilities[MentalAbility.bravery] ?? 25,
        'leadership': player.mentalAbilities[MentalAbility.leadership] ?? 25,
        'work_rate': player.mentalAbilities[MentalAbility.workRate] ?? 25,
        'self_discipline': player.mentalAbilities[MentalAbility.selfDiscipline] ?? 25,
        'ambition': player.mentalAbilities[MentalAbility.ambition] ?? 25,
        'teamwork': player.mentalAbilities[MentalAbility.teamwork] ?? 25,
        'positioning': player.mentalAbilities[MentalAbility.positioning] ?? 25,
        'pressure_handling': player.mentalAbilities[MentalAbility.pressureHandling] ?? 25,
        'clutch_ability': player.mentalAbilities[MentalAbility.clutchAbility] ?? 25,
        // Physical abilities
        'acceleration': player.physicalAbilities[PhysicalAbility.acceleration] ?? 25,
        'agility': player.physicalAbilities[PhysicalAbility.agility] ?? 25,
        'balance': player.physicalAbilities[PhysicalAbility.balance] ?? 25,
        'jumping_reach': player.physicalAbilities[PhysicalAbility.jumpingReach] ?? 25,
        'natural_fitness': player.physicalAbilities[PhysicalAbility.naturalFitness] ?? 25,
        'injury_proneness': player.physicalAbilities[PhysicalAbility.injuryProneness] ?? 25,
        'stamina': player.physicalAbilities[PhysicalAbility.stamina] ?? 25,
        'strength': player.physicalAbilities[PhysicalAbility.strength] ?? 25,
        'pace': player.physicalAbilities[PhysicalAbility.pace] ?? 25,
        'flexibility': player.physicalAbilities[PhysicalAbility.flexibility] ?? 25,
        // 追加された能力値（重複のため削除）
        // 'motivation': player.motivationAbility,
        // 'pressure': player.pressureAbility,
        // 'adaptability': player.adaptabilityAbility,
        // 'consistency': player.consistencyAbility,
        // 'clutch': player.clutchAbility,
        // 'work_ethic': player.workEthicAbility,
        // 総合能力値（後で計算して更新）
        'overall': 50,
        'technical': 50,
        'physical': 50,
        'mental': 50,
      });
      
      // ポテンシャルデータを保存
      if (player.individualPotentials?.isNotEmpty == true) {
        await _savePlayerPotentials(playerId, player.individualPotentials!, db);
      }
      
      // 選手のIDを設定したPlayerオブジェクトを返す
      return player.copyWith(id: playerId);
      
    } catch (e) {
      print('選手のデータベース保存でエラー: $e');
      rethrow;
    }
  }

  /// 選手のポテンシャルを保存
  Future<void> _savePlayerPotentials(int playerId, Map<String, int> potentials, Database db) async {
    final potentialData = <String, dynamic>{
      'player_id': playerId,
    };
    
    // 各能力値のポテンシャルを追加
    for (final entry in potentials.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // キャメルケースをスネークケースに変換
      final snakeKey = key.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}'
      );
      
      potentialData['${snakeKey}_potential'] = value;
    }
    
    // 追加された能力値のポテンシャルも設定（デフォルト値）（重複のため削除）
    // potentialData['motivation_potential'] = 50;
    // potentialData['pressure_potential'] = 50;
    // potentialData['adaptability_potential'] = 50;
    // potentialData['consistency_potential'] = 50;
    // potentialData['clutch_potential'] = 50;
    // potentialData['work_ethic_potential'] = 50;
    
    // 総合ポテンシャルを計算
    final allPotentials = potentialData.values.where((v) => v is int && v != playerId).cast<int>();
    final overallPotential = allPotentials.reduce((a, b) => a + b) ~/ allPotentials.length;
    
    // カテゴリ別ポテンシャルを計算
    final technicalPotentials = [
      potentialData['contact_potential'] ?? 50,
      potentialData['power_potential'] ?? 50,
      potentialData['plate_discipline_potential'] ?? 50,
      potentialData['bunt_potential'] ?? 50,
      potentialData['opposite_field_hitting_potential'] ?? 50,
      potentialData['pull_hitting_potential'] ?? 50,
      potentialData['bat_control_potential'] ?? 50,
      potentialData['swing_speed_potential'] ?? 50,
      potentialData['fielding_potential'] ?? 50,
      potentialData['throwing_potential'] ?? 50,
      potentialData['catcher_ability_potential'] ?? 50,
      potentialData['control_potential'] ?? 50,
      potentialData['fastball_potential'] ?? 50,
      potentialData['breaking_ball_potential'] ?? 50,
      potentialData['pitch_movement_potential'] ?? 50,
    ];
    
    final mentalPotentials = [
      potentialData['concentration_potential'] ?? 50,
      potentialData['anticipation_potential'] ?? 50,
      potentialData['vision_potential'] ?? 50,
      potentialData['composure_potential'] ?? 50,
      potentialData['aggression_potential'] ?? 50,
      potentialData['bravery_potential'] ?? 50,
      potentialData['leadership_potential'] ?? 50,
      potentialData['work_rate_potential'] ?? 50,
      potentialData['self_discipline_potential'] ?? 50,
      potentialData['ambition_potential'] ?? 50,
      potentialData['teamwork_potential'] ?? 50,
      potentialData['positioning_potential'] ?? 50,
      potentialData['pressure_handling_potential'] ?? 50,
      potentialData['clutch_ability_potential'] ?? 50,
      // 以下のポテンシャルは重複のため削除
      // potentialData['motivation_potential'] ?? 50,
      // potentialData['pressure_potential'] ?? 50,
      // potentialData['adaptability_potential'] ?? 50,
      // potentialData['consistency_potential'] ?? 50,
      // potentialData['clutch_potential'] ?? 50,
      // potentialData['work_ethic_potential'] ?? 50,
    ];
    
    final physicalPotentials = [
      potentialData['acceleration_potential'] ?? 50,
      potentialData['agility_potential'] ?? 50,
      potentialData['balance_potential'] ?? 50,
      potentialData['jumping_reach_potential'] ?? 50,
      potentialData['natural_fitness_potential'] ?? 50,
      potentialData['injury_proneness_potential'] ?? 50,
      potentialData['stamina_potential'] ?? 50,
      potentialData['strength_potential'] ?? 50,
      potentialData['pace_potential'] ?? 50,
      potentialData['flexibility_potential'] ?? 50,
    ];
    
    potentialData['overall_potential'] = overallPotential;
    potentialData['technical_potential'] = technicalPotentials.reduce((a, b) => a + b) ~/ technicalPotentials.length;
    potentialData['mental_potential'] = mentalPotentials.reduce((a, b) => a + b) ~/ mentalPotentials.length;
    potentialData['physical_potential'] = physicalPotentials.reduce((a, b) => a + b) ~/ physicalPotentials.length;
    
    await db.insert('PlayerPotentials', potentialData);
  }

  /// 学校の選手リストを更新
  Future<void> _updateSchoolPlayerLists(List<School> schools) async {
    // 学校ごとの生成選手数を表示
    for (final school in schools) {
      final generatedCount = school.players.where((p) => p.talent >= 3).length;
      print('${school.name} (${school.rank.name}): 生成選手${generatedCount}人');
    }
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
