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
  Future<void> assignPlayersToSchools(List<School> schools, List<Player> talentedPlayers, {bool isNewYear = false}) async {
    print('PlayerAssignmentService.assignPlayersToSchools: 開始 - 学校数: ${schools.length}, 才能選手数: ${talentedPlayers.length}, 新年度処理: $isNewYear');
    
    try {
      // 1. 各学校にデフォルト選手を配置（新年度処理時はスキップ）
      if (!isNewYear) {
        await _assignDefaultPlayersToSchools(schools);
      } else {
        print('PlayerAssignmentService.assignPlayersToSchools: 新年度処理のため、デフォルト選手の配置をスキップします');
      }
      
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
      
      // 選手のIDを設定したPlayerオブジェクトを作成
      final playerWithId = player.copyWith(id: playerId);
      
      // ポテンシャルデータを保存（IDが設定された後）
      if (player.individualPotentials?.isNotEmpty == true) {
        await _savePlayerPotentials(playerWithId, db);
      }
      
      // 選手のIDを設定したPlayerオブジェクトを返す
      return playerWithId;
      
    } catch (e) {
      print('選手のデータベース保存でエラー: $e');
      rethrow;
    }
  }

  /// 選手のポテンシャルデータをデータベースに保存
  Future<void> _savePlayerPotentials(Player player, Database db) async {
    final playerId = player.id;
    if (playerId == null) {
      print('_savePlayerPotentials: プレイヤーIDがnullです');
      return;
    }

    // 個別能力値ポテンシャルを取得
    final individualPotentials = player.individualPotentials;
    if (individualPotentials == null) {
      print('_savePlayerPotentials: 個別ポテンシャルがnullです');
      return;
    }

    // データベース用のポテンシャルデータを作成
    final potentialData = <String, dynamic>{
      'player_id': playerId,
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
    
    // プレイヤーオブジェクトから事前計算された総合ポテンシャル値を取得
    // これらは選手生成時に計算され、変更されない固定値
    if (player.technicalPotentials != null && player.mentalPotentials != null && player.physicalPotentials != null) {
      // 技術面ポテンシャル値（事前計算済み）
      potentialData['technical_potential'] = _calculateAverageFromMap(player.technicalPotentials!);
      
      // メンタル面ポテンシャル値（事前計算済み）
      potentialData['mental_potential'] = _calculateAverageFromMap(player.mentalPotentials!);
      
      // フィジカル面ポテンシャル値（事前計算済み）
      potentialData['physical_potential'] = _calculateAverageFromMap(player.physicalPotentials!);
      
      // 総合ポテンシャル値（ポジション別重み付け済み）
      potentialData['overall_potential'] = _calculateOverallPotentialFromPlayer(player);
    } else {
      // フォールバック: individualPotentialsから計算
      print('_savePlayerPotentials: 事前計算されたポテンシャル値が利用できないため、individualPotentialsから計算します');
      
      // カテゴリ別ポテンシャルを計算
      final technicalPotentials = [
        individualPotentials['contact'] ?? 50,
        individualPotentials['power'] ?? 50,
        individualPotentials['plate_discipline'] ?? 50,
        individualPotentials['bunt'] ?? 50,
        individualPotentials['opposite_field_hitting'] ?? 50,
        individualPotentials['pull_hitting'] ?? 50,
        individualPotentials['bat_control'] ?? 50,
        individualPotentials['swing_speed'] ?? 50,
        individualPotentials['fielding'] ?? 50,
        individualPotentials['throwing'] ?? 50,
        individualPotentials['catcher_ability'] ?? 50,
        individualPotentials['control'] ?? 50,
        individualPotentials['fastball'] ?? 50,
        individualPotentials['breaking_ball'] ?? 50,
        individualPotentials['pitch_movement'] ?? 50,
      ];
      
      final mentalPotentials = [
        individualPotentials['concentration'] ?? 50,
        individualPotentials['anticipation'] ?? 50,
        individualPotentials['vision'] ?? 50,
        individualPotentials['composure'] ?? 50,
        individualPotentials['aggression'] ?? 50,
        individualPotentials['bravery'] ?? 50,
        individualPotentials['leadership'] ?? 50,
        individualPotentials['work_rate'] ?? 50,
        individualPotentials['self_discipline'] ?? 50,
        individualPotentials['ambition'] ?? 50,
        individualPotentials['teamwork'] ?? 50,
        individualPotentials['positioning'] ?? 50,
        individualPotentials['pressure_handling'] ?? 50,
        individualPotentials['clutch_ability'] ?? 50,
      ];
      
      final physicalPotentials = [
        individualPotentials['acceleration'] ?? 50,
        individualPotentials['agility'] ?? 50,
        individualPotentials['balance'] ?? 50,
        individualPotentials['jumping_reach'] ?? 50,
        individualPotentials['natural_fitness'] ?? 50,
        individualPotentials['injury_proneness'] ?? 50,
        individualPotentials['stamina'] ?? 50,
        individualPotentials['strength'] ?? 50,
        individualPotentials['pace'] ?? 50,
        individualPotentials['flexibility'] ?? 50,
      ];
      
      // カテゴリ別ポテンシャル値を設定
      potentialData['technical_potential'] = technicalPotentials.reduce((a, b) => a + b) ~/ technicalPotentials.length;
      potentialData['mental_potential'] = mentalPotentials.reduce((a, b) => a + b) ~/ mentalPotentials.length;
      potentialData['physical_potential'] = physicalPotentials.reduce((a, b) => a + b) ~/ physicalPotentials.length;
      
      // 総合ポテンシャル値を計算（ポジション別重み付け）
      potentialData['overall_potential'] = _calculateOverallPotentialFromIndividualPotentials(individualPotentials, player.position);
    }
    
    await db.insert('PlayerPotentials', potentialData);
  }

  /// マップから平均値を計算
  int _calculateAverageFromMap(Map<dynamic, int> map) {
    if (map.isEmpty) return 50;
    final values = map.values.toList();
    return values.reduce((a, b) => a + b) ~/ values.length;
  }

  /// プレイヤーオブジェクトから総合ポテンシャル値を計算（ポジション別重み付け）
  int _calculateOverallPotentialFromPlayer(Player player) {
    if (player.technicalPotentials == null || player.mentalPotentials == null || player.physicalPotentials == null) {
      return 50; // フォールバック値
    }
    
    final technicalAvg = _calculateAverageFromMap(player.technicalPotentials!);
    final mentalAvg = _calculateAverageFromMap(player.mentalPotentials!);
    final physicalAvg = _calculateAverageFromMap(player.physicalPotentials!);
    
    // ポジション別の重み付けを適用（能力値計算と同様）
    if (player.position == '投手') {
      // 投手: 技術50%、精神30%、身体20%
      return ((technicalAvg * 0.5) + (mentalAvg * 0.3) + (physicalAvg * 0.2)).round();
    } else {
      // 野手: 技術40%、精神25%、身体35%
      return ((technicalAvg * 0.4) + (mentalAvg * 0.25) + (physicalAvg * 0.35)).round();
    }
  }

  /// individualPotentialsから総合ポテンシャル値を計算（ポジション別重み付け）
  int _calculateOverallPotentialFromIndividualPotentials(Map<String, int> individualPotentials, String position) {
    // カテゴリ別ポテンシャルを計算
    final technicalPotentials = [
      individualPotentials['contact'] ?? 50,
      individualPotentials['power'] ?? 50,
      individualPotentials['plate_discipline'] ?? 50,
      individualPotentials['bunt'] ?? 50,
      individualPotentials['opposite_field_hitting'] ?? 50,
      individualPotentials['pull_hitting'] ?? 50,
      individualPotentials['bat_control'] ?? 50,
      individualPotentials['swing_speed'] ?? 50,
      individualPotentials['fielding'] ?? 50,
      individualPotentials['throwing'] ?? 50,
      individualPotentials['catcher_ability'] ?? 50,
      individualPotentials['control'] ?? 50,
      individualPotentials['fastball'] ?? 50,
      individualPotentials['breaking_ball'] ?? 50,
      individualPotentials['pitch_movement'] ?? 50,
    ];
    
    final mentalPotentials = [
      individualPotentials['concentration'] ?? 50,
      individualPotentials['anticipation'] ?? 50,
      individualPotentials['vision'] ?? 50,
      individualPotentials['composure'] ?? 50,
      individualPotentials['aggression'] ?? 50,
      individualPotentials['bravery'] ?? 50,
      individualPotentials['leadership'] ?? 50,
      individualPotentials['work_rate'] ?? 50,
      individualPotentials['self_discipline'] ?? 50,
      individualPotentials['ambition'] ?? 50,
      individualPotentials['teamwork'] ?? 50,
      individualPotentials['positioning'] ?? 50,
      individualPotentials['pressure_handling'] ?? 50,
      individualPotentials['clutch_ability'] ?? 50,
    ];
    
    final physicalPotentials = [
      individualPotentials['acceleration'] ?? 50,
      individualPotentials['agility'] ?? 50,
      individualPotentials['balance'] ?? 50,
      individualPotentials['jumping_reach'] ?? 50,
      individualPotentials['natural_fitness'] ?? 50,
      individualPotentials['injury_proneness'] ?? 50,
      individualPotentials['stamina'] ?? 50,
      individualPotentials['strength'] ?? 50,
      individualPotentials['pace'] ?? 50,
      individualPotentials['flexibility'] ?? 50,
    ];
    
    final technicalAvg = technicalPotentials.reduce((a, b) => a + b) ~/ technicalPotentials.length;
    final mentalAvg = mentalPotentials.reduce((a, b) => a + b) ~/ mentalPotentials.length;
    final physicalAvg = physicalPotentials.reduce((a, b) => a + b) ~/ physicalPotentials.length;
    
    // ポジション別の重み付けを適用（能力値計算と同様）
    if (position == '投手') {
      // 投手: 技術50%、精神30%、身体20%
      return ((technicalAvg * 0.5) + (mentalAvg * 0.3) + (physicalAvg * 0.2)).round();
    } else {
      // 野手: 技術40%、精神25%、身体35%
      return ((technicalAvg * 0.4) + (mentalAvg * 0.25) + (physicalAvg * 0.35)).round();
    }
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
