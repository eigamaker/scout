import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../models/professional/professional_player.dart';
import '../models/professional/professional_team.dart';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import 'data_service.dart';

/// プロ野球選手管理サービス
class ProfessionalPlayerService {
  final DataService _dataService;

  ProfessionalPlayerService(this._dataService);

  /// プロ野球選手をデータベースに保存
  Future<void> saveProfessionalPlayers(List<ProfessionalTeam> teams) async {
    print('ProfessionalPlayerService.saveProfessionalPlayers: 開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      final db = await _dataService.database;
      
      // トランザクション開始
      await db.transaction((txn) async {
        int totalPlayersSaved = 0;
        
        for (final team in teams) {
          if (team.professionalPlayers == null || team.professionalPlayers!.isEmpty) {
            print('ProfessionalPlayerService: ${team.name}には選手がいません');
            continue;
          }
          
          print('ProfessionalPlayerService: ${team.name}の選手を保存中... (${team.professionalPlayers!.length}人)');
          
          for (final professionalPlayer in team.professionalPlayers!) {
            // Playerテーブルに保存
            final playerId = await _savePlayer(txn, professionalPlayer.player!);
            
            // ProfessionalPlayerテーブルに保存
            await _saveProfessionalPlayer(txn, professionalPlayer, playerId);
            
            totalPlayersSaved++;
          }
        }
        
        print('ProfessionalPlayerService: 合計${totalPlayersSaved}人のプロ野球選手を保存しました');
      });
      
      stopwatch.stop();
      print('ProfessionalPlayerService.saveProfessionalPlayers: 完了 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      print('ProfessionalPlayerService.saveProfessionalPlayers: エラー - $e');
      rethrow;
    }
  }

  /// Playerテーブルに選手を保存
  Future<int> _savePlayer(Transaction txn, Player player) async {
    final playerData = {
      'name': player.name,
      'school': player.school,
      'grade': player.grade,
      'age': player.age,
      'position': player.position,
      'position_fit': _mapToJson(player.positionFit),
      'fame': player.fame,
      'is_famous': player.isFamous ? 1 : 0,
      'is_scout_favorite': player.isScoutFavorite ? 1 : 0,
      'is_scouted': player.isScouted ? 1 : 0,
      'is_graduated': player.isGraduated ? 1 : 0,
      'is_retired': player.isRetired ? 1 : 0,
      'growth_rate': player.growthRate,
      'talent': player.talent,
      'growth_type': player.growthType,
      'mental_grit': player.mentalGrit,
      'peak_ability': player.peakAbility,
      'personality': player.personality,
      'technical_abilities': _enumMapToJson(player.technicalAbilities),
      'mental_abilities': _enumMapToJson(player.mentalAbilities),
      'physical_abilities': _enumMapToJson(player.physicalAbilities),
      'individual_potentials': _mapToJson(player.individualPotentials),
      'technical_potentials': _enumMapToJson(player.technicalPotentials),
      'mental_potentials': _enumMapToJson(player.mentalPotentials),
      'physical_potentials': _enumMapToJson(player.physicalPotentials),
      'overall': player.overall,
      'technical': player.technical,
      'physical': player.physical,
      'mental': player.mental,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    return await txn.insert('Player', playerData);
  }

  /// ProfessionalPlayerテーブルに選手を保存
  Future<void> _saveProfessionalPlayer(Transaction txn, ProfessionalPlayer professionalPlayer, int playerId) async {
    final professionalPlayerData = {
      'player_id': playerId,
      'team_id': professionalPlayer.teamId,
      'contract_year': professionalPlayer.contractYear,
      'salary': professionalPlayer.salary,
      'contract_type': professionalPlayer.contractType.index,
      'draft_year': professionalPlayer.draftYear,
      'draft_round': professionalPlayer.draftRound,
      'draft_position': professionalPlayer.draftPosition,
      'is_active': professionalPlayer.isActive ? 1 : 0,
      'joined_at': professionalPlayer.joinedAt.toIso8601String(),
      'left_at': professionalPlayer.leftAt?.toIso8601String(),
      'created_at': professionalPlayer.createdAt.toIso8601String(),
      'updated_at': professionalPlayer.updatedAt.toIso8601String(),
    };
    
    await txn.insert('ProfessionalPlayer', professionalPlayerData);
  }

  /// プロ野球選手をデータベースから読み込み
  Future<List<ProfessionalPlayer>> loadProfessionalPlayers() async {
    print('ProfessionalPlayerService.loadProfessionalPlayers: 開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      final db = await _dataService.database;
      
      // ProfessionalPlayerとPlayerをJOINして取得
      final results = await db.rawQuery('''
        SELECT 
          pp.*,
          p.name as player_name,
          p.school as player_school,
          p.grade as player_grade,
          p.age as player_age,
          p.position as player_position,
          p.position_fit as player_position_fit,
          p.fame as player_fame,
          p.is_famous as player_is_famous,
          p.is_scout_favorite as player_is_scout_favorite,
          p.is_scouted as player_is_scouted,
          p.is_graduated as player_is_graduated,
          p.is_retired as player_is_retired,
          p.growth_rate as player_growth_rate,
          p.talent as player_talent,
          p.growth_type as player_growth_type,
          p.mental_grit as player_mental_grit,
          p.peak_ability as player_peak_ability,
          p.personality as player_personality,
          p.technical_abilities as player_technical_abilities,
          p.mental_abilities as player_mental_abilities,
          p.physical_abilities as player_physical_abilities,
          p.individual_potentials as player_individual_potentials,
          p.technical_potentials as player_technical_potentials,
          p.mental_potentials as player_mental_potentials,
          p.physical_potentials as player_physical_potentials,
          p.overall as player_overall,
          p.technical as player_technical,
          p.physical as player_physical,
          p.mental as player_mental,
          pt.name as team_name,
          pt.short_name as team_short_name
        FROM ProfessionalPlayer pp
        JOIN Player p ON pp.player_id = p.id
        JOIN ProfessionalTeam pt ON pp.team_id = pt.id
        WHERE pp.is_active = 1
        ORDER BY pp.team_id, p.position
      ''');
      
      final professionalPlayers = <ProfessionalPlayer>[];
      
      for (final row in results) {
        final player = Player(
          id: row['player_id'] as int,
          name: row['player_name'] as String,
          school: row['player_school'] as String,
          grade: row['player_grade'] as int,
          age: row['player_age'] as int,
          position: row['player_position'] as String,
          positionFit: _jsonToIntMap(row['player_position_fit'] as String?),
          fame: row['player_fame'] as int,
          isFamous: (row['player_is_famous'] as int) == 1,
          isScoutFavorite: (row['player_is_scout_favorite'] as int) == 1,
          isScouted: (row['player_is_scouted'] as int) == 1,
          isGraduated: (row['player_is_graduated'] as int) == 1,
          isRetired: (row['player_is_retired'] as int) == 1,
          growthRate: (row['player_growth_rate'] as num).toDouble(),
          talent: row['player_talent'] as int,
          growthType: row['player_growth_type'] as String,
          mentalGrit: (row['player_mental_grit'] as num).toDouble(),
          peakAbility: row['player_peak_ability'] as int,
          personality: row['player_personality'] as String,
          technicalAbilities: _jsonToTechnicalAbilities(row['player_technical_abilities'] as String?),
          mentalAbilities: _jsonToMentalAbilities(row['player_mental_abilities'] as String?),
          physicalAbilities: _jsonToPhysicalAbilities(row['player_physical_abilities'] as String?),
          individualPotentials: _jsonToIntMap(row['player_individual_potentials'] as String?),
          technicalPotentials: _jsonToTechnicalAbilities(row['player_technical_potentials'] as String?),
          mentalPotentials: _jsonToMentalAbilities(row['player_mental_potentials'] as String?),
          physicalPotentials: _jsonToPhysicalAbilities(row['player_physical_potentials'] as String?),
          overall: row['player_overall'] as int,
          technical: row['player_technical'] as int,
          physical: row['player_physical'] as int,
          mental: row['player_mental'] as int,
        );
        
        final professionalPlayer = ProfessionalPlayer(
          id: row['id'] as int,
          playerId: row['player_id'] as int,
          teamId: row['team_id'] as String,
          contractYear: row['contract_year'] as int,
          salary: row['salary'] as int,
          contractType: ContractType.values[row['contract_type'] as int],
          draftYear: row['draft_year'] as int,
          draftRound: row['draft_round'] as int,
          draftPosition: row['draft_position'] as int,
          isActive: (row['is_active'] as int) == 1,
          joinedAt: DateTime.parse(row['joined_at'] as String),
          leftAt: row['left_at'] != null ? DateTime.parse(row['left_at'] as String) : null,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          player: player,
          teamName: row['team_name'] as String,
          teamShortName: row['team_short_name'] as String,
        );
        
        professionalPlayers.add(professionalPlayer);
      }
      
      stopwatch.stop();
      print('ProfessionalPlayerService.loadProfessionalPlayers: 完了 - ${professionalPlayers.length}人 - ${stopwatch.elapsedMilliseconds}ms');
      
      return professionalPlayers;
      
    } catch (e) {
      print('ProfessionalPlayerService.loadProfessionalPlayers: エラー - $e');
      rethrow;
    }
  }

  /// チーム別にプロ野球選手をグループ化
  Map<String, List<ProfessionalPlayer>> groupPlayersByTeam(List<ProfessionalPlayer> players) {
    final groupedPlayers = <String, List<ProfessionalPlayer>>{};
    
    for (final player in players) {
      if (!groupedPlayers.containsKey(player.teamId)) {
        groupedPlayers[player.teamId] = [];
      }
      groupedPlayers[player.teamId]!.add(player);
    }
    
    return groupedPlayers;
  }

  /// MapをJSON文字列に変換
  String _mapToJson(Map<String, dynamic>? map) {
    if (map == null) return '{}';
    return map.entries.map((e) => '"${e.key}":${e.value}').join(',');
  }

  /// EnumMapをJSON文字列に変換
  String _enumMapToJson(Map<dynamic, int>? map) {
    if (map == null) return '{}';
    return map.entries.map((e) => '"${e.key.name}":${e.value}').join(',');
  }

  /// JSON文字列をMapに変換
  Map<String, dynamic> _jsonToMap(String? json) {
    if (json == null || json.isEmpty) return {};
    
    try {
      // 簡単なJSONパース（実際の実装では適切なJSONライブラリを使用）
      final map = <String, dynamic>{};
      final entries = json.split(',');
      
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final key = parts[0].replaceAll('"', '').trim();
          final value = int.tryParse(parts[1].trim()) ?? parts[1].trim();
          map[key] = value;
        }
      }
      
      return map;
    } catch (e) {
      print('ProfessionalPlayerService._jsonToMap: エラー - $e');
      return {};
    }
  }

  /// JSON文字列をIntMapに変換
  Map<String, int> _jsonToIntMap(String? json) {
    if (json == null || json.isEmpty) return {};
    
    try {
      final map = <String, int>{};
      final entries = json.split(',');
      
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final key = parts[0].replaceAll('"', '').trim();
          final value = int.tryParse(parts[1].trim()) ?? 0;
          map[key] = value;
        }
      }
      
      return map;
    } catch (e) {
      print('ProfessionalPlayerService._jsonToIntMap: エラー - $e');
      return {};
    }
  }

  /// JSON文字列をTechnicalAbilitiesに変換
  Map<TechnicalAbility, int> _jsonToTechnicalAbilities(String? json) {
    if (json == null || json.isEmpty) return {};
    
    try {
      final map = <TechnicalAbility, int>{};
      final entries = json.split(',');
      
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final keyName = parts[0].replaceAll('"', '').trim();
          final value = int.tryParse(parts[1].trim()) ?? 0;
          
          for (final ability in TechnicalAbility.values) {
            if (ability.name == keyName) {
              map[ability] = value;
              break;
            }
          }
        }
      }
      
      return map;
    } catch (e) {
      print('ProfessionalPlayerService._jsonToTechnicalAbilities: エラー - $e');
      return {};
    }
  }

  /// JSON文字列をMentalAbilitiesに変換
  Map<MentalAbility, int> _jsonToMentalAbilities(String? json) {
    if (json == null || json.isEmpty) return {};
    
    try {
      final map = <MentalAbility, int>{};
      final entries = json.split(',');
      
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final keyName = parts[0].replaceAll('"', '').trim();
          final value = int.tryParse(parts[1].trim()) ?? 0;
          
          for (final ability in MentalAbility.values) {
            if (ability.name == keyName) {
              map[ability] = value;
              break;
            }
          }
        }
      }
      
      return map;
    } catch (e) {
      print('ProfessionalPlayerService._jsonToMentalAbilities: エラー - $e');
      return {};
    }
  }

  /// JSON文字列をPhysicalAbilitiesに変換
  Map<PhysicalAbility, int> _jsonToPhysicalAbilities(String? json) {
    if (json == null || json.isEmpty) return {};
    
    try {
      final map = <PhysicalAbility, int>{};
      final entries = json.split(',');
      
      for (final entry in entries) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final keyName = parts[0].replaceAll('"', '').trim();
          final value = int.tryParse(parts[1].trim()) ?? 0;
          
          for (final ability in PhysicalAbility.values) {
            if (ability.name == keyName) {
              map[ability] = value;
              break;
            }
          }
        }
      }
      
      return map;
    } catch (e) {
      print('ProfessionalPlayerService._jsonToPhysicalAbilities: エラー - $e');
      return {};
    }
  }
}
