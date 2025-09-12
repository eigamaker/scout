import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../../models/game/game.dart';
import 'database_schema_service.dart';
import 'professional_data_service.dart';
import 'data_repair_service.dart';

/// リファクタリングされたデータサービス
/// 機能を分離してより管理しやすくした
class RefactoredDataService {
  static Database? _db;
  late final DatabaseSchemaService _schemaService;
  late final ProfessionalDataService _professionalDataService;
  late final DataRepairService _repairService;

  RefactoredDataService() {
    _schemaService = DatabaseSchemaService();
  }

  /// データベースインスタンスを取得
  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    
    // データベースが存在しない場合は初期化
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scout_game.db');
    
    // 既存のデータベースファイルを削除（スキーマ変更のため）
    final dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.delete();
      print('RefactoredDataService: 既存のデータベースファイルを削除しました（スキーマ変更のため）');
      _db = null;
    }
    
    return await openDatabase(
      path,
      version: _schemaService.databaseVersion,
      onCreate: (db, version) async {
        // 最新のスキーマでテーブルを作成
        await _schemaService.createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ゲーム未リリースのため、最新スキーマで再作成
        print('RefactoredDataService: データベーススキーマを最新版で再作成中...');
        await _schemaService.createAllTables(db);
      },
    );
  }

  /// データベースからゲームデータを読み込み
  Future<Game?> loadGameDataFromDatabase() async {
    try {
      final db = await database;
      
      // ゲーム基本情報を読み込み
      final gameInfo = await db.query('GameInfo', limit: 1);
      if (gameInfo.isEmpty) return null;
      
      // 学校データを読み込み
      final schools = await _loadSchoolsFromDatabase(db);
      
      // 発掘選手IDリストを読み込み
      final discoveredPlayerIds = await _loadDiscoveredPlayerIdsFromDatabase(db);
      
      // 注目選手IDリストを読み込み
      final watchedPlayerIds = await _loadWatchedPlayerIdsFromDatabase(db);
      
      // お気に入り選手IDリストを読み込み
      final favoritePlayerIds = await _loadFavoritePlayerIdsFromDatabase(db);
      
      // プロ野球データを読み込み
      final professionalTeams = await _loadProfessionalTeamsFromDatabase(db);
      
      // Gameオブジェクトを構築
      final gameData = {
        'scoutName': gameInfo.first['scoutName'],
        'currentYear': gameInfo.first['currentYear'],
        'currentMonth': gameInfo.first['currentMonth'],
        'currentWeekOfMonth': gameInfo.first['currentWeekOfMonth'],
        'state': gameInfo.first['state'],
        'ap': gameInfo.first['ap'],
        'budget': gameInfo.first['budget'],
        'scoutSkills': jsonDecode(gameInfo.first['scoutSkills'] as String),
        'reputation': gameInfo.first['reputation'],
        'experience': gameInfo.first['experience'],
        'level': gameInfo.first['level'],
        'schools': schools,
        'discoveredPlayerIds': discoveredPlayerIds,
        'watchedPlayerIds': watchedPlayerIds,
        'favoritePlayerIds': favoritePlayerIds,
        'professionalTeams': professionalTeams,
      };
      
      return Game.fromJson(gameData);
    } catch (e) {
      print('RefactoredDataService: データベースからの読み込みエラー: $e');
      return null;
    }
  }

  /// セーブデータが存在するかチェック
  Future<bool> hasGameDataInDatabase() async {
    try {
      final db = await database;
      final gameInfo = await db.query('GameInfo', limit: 1);
      return gameInfo.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 学校データをデータベースから読み込み
  Future<List<Map<String, dynamic>>> _loadSchoolsFromDatabase(Database db) async {
    try {
      final schools = await db.query('School');
      final result = <Map<String, dynamic>>[];
      
      for (final school in schools) {
        final schoolData = Map<String, dynamic>.from(school);
        
        // 学校の選手データも読み込み
        final players = await db.query('Player', where: 'school = ?', whereArgs: [school['id']]);
        schoolData['players'] = players;
        
        result.add(schoolData);
      }
      
      return result;
    } catch (e) {
      print('RefactoredDataService: 学校データ読み込みエラー: $e');
      return [];
    }
  }

  /// 発掘選手IDリストをデータベースから読み込み
  Future<List<int>> _loadDiscoveredPlayerIdsFromDatabase(Database db) async {
    try {
      final players = await db.query('DiscoveredPlayer');
      return players.map((p) => p['player_id'] as int).toList();
    } catch (e) {
      print('RefactoredDataService: 発掘選手IDリスト読み込みエラー: $e');
      return [];
    }
  }

  /// 注目選手IDリストをデータベースから読み込み
  Future<List<int>> _loadWatchedPlayerIdsFromDatabase(Database db) async {
    try {
      final players = await db.query('WatchedPlayer');
      return players.map((p) => p['player_id'] as int).toList();
    } catch (e) {
      print('RefactoredDataService: 注目選手IDリスト読み込みエラー: $e');
      return [];
    }
  }

  /// お気に入り選手IDリストをデータベースから読み込み
  Future<List<int>> _loadFavoritePlayerIdsFromDatabase(Database db) async {
    try {
      final players = await db.query('FavoritePlayer');
      return players.map((p) => p['player_id'] as int).toList();
    } catch (e) {
      print('RefactoredDataService: お気に入り選手IDリスト読み込みエラー: $e');
      return [];
    }
  }

  /// プロ野球データをデータベースから読み込み
  Future<Map<String, dynamic>> _loadProfessionalTeamsFromDatabase(Database db) async {
    try {
      final teams = await db.query('ProfessionalTeam');
      final result = <Map<String, dynamic>>[];
      
      for (final team in teams) {
        final teamData = Map<String, dynamic>.from(team);
        
        // プロ選手データも読み込み
        final players = await db.query('ProfessionalPlayer', where: 'team = ?', whereArgs: [team['id']]);
        teamData['professionalPlayers'] = players;
        
        result.add(teamData);
      }
      
      return {'teams': result};
    } catch (e) {
      print('RefactoredDataService: プロ野球データ読み込みエラー: $e');
      return {'teams': []};
    }
  }

  /// 初期データを挿入
  Future<void> insertInitialData() async {
    final db = await database;
    
    // プロ野球団とプロ選手の初期データを挿入
    _professionalDataService = ProfessionalDataService(db);
    await _professionalDataService.insertProfessionalTeams();
  }

  /// データベースファイルを削除
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scout_game.db');
    await deleteDatabaseAtPath(path);
  }

  /// 指定されたパスのデータベースファイルを削除
  Future<void> deleteDatabaseAtPath(String path) async {
    await databaseFactory.deleteDatabase(path);
  }

  /// 数値データの型を修正
  Future<void> repairNumericData() async {
    final db = await database;
    _repairService = DataRepairService(db);
    await _repairService.repairNumericData();
  }

  /// ゲームデータをデータベースに直接保存
  Future<void> saveGameDataToDatabase(Map<String, dynamic> data) async {
    try {
      final db = await database;
      
      // トランザクションを使用して一括保存
      await db.transaction((txn) async {
        // ゲーム基本情報を保存
        await _saveGameBasicInfo(txn, data);
        
        // 学校データを分割して保存
        if (data['schools'] != null) {
          await _saveSchoolsInBatches(txn, data['schools'] as List);
        }
        
        // 発掘選手IDリストを保存
        if (data['discoveredPlayerIds'] != null) {
          await _saveDiscoveredPlayerIdsInBatches(txn, (data['discoveredPlayerIds'] as List).cast<int>());
        }

        // 注目選手IDリストを保存
        if (data['watchedPlayerIds'] != null) {
          await _saveWatchedPlayerIdsInBatches(txn, (data['watchedPlayerIds'] as List).cast<int>());
        }

        // お気に入り選手IDリストを保存
        if (data['favoritePlayerIds'] != null) {
          await _saveFavoritePlayerIdsInBatches(txn, (data['favoritePlayerIds'] as List).cast<int>());
        }
        
        // プロ野球データを保存
        if (data['professionalTeams'] != null) {
          await _saveProfessionalData(txn, data['professionalTeams'] as List);
        }
      });
      
      print('RefactoredDataService: ゲームデータをデータベースに直接保存しました');
    } catch (e) {
      print('RefactoredDataService: データベース保存エラー: $e');
      rethrow;
    }
  }

  /// ゲーム基本情報を保存
  Future<void> _saveGameBasicInfo(Transaction txn, Map<String, dynamic> data) async {
    await txn.insert('GameInfo', {
      'scoutName': data['scoutName'] ?? '',
      'currentYear': data['currentYear'] ?? 1,
      'currentMonth': data['currentMonth'] ?? 4,
      'currentWeekOfMonth': data['currentWeekOfMonth'] ?? 1,
      'state': data['state'] ?? 'playing',
      'ap': data['ap'] ?? 0,
      'budget': data['budget'] ?? 0,
      'scoutSkills': jsonEncode(data['scoutSkills'] ?? {}),
      'reputation': data['reputation'] ?? 0,
      'experience': data['experience'] ?? 0,
      'level': data['level'] ?? 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 学校データをバッチ処理で保存
  Future<void> _saveSchoolsInBatches(Transaction txn, List schools) async {
    const batchSize = 1000;
    
    for (int i = 0; i < schools.length; i += batchSize) {
      final end = (i + batchSize < schools.length) ? i + batchSize : schools.length;
      final batch = schools.sublist(i, end);
      
      for (final schoolData in batch) {
        final school = Map<String, dynamic>.from(schoolData);
        final schoolId = await _saveSchoolInfo(txn, school);
        
        if (school['players'] != null) {
          await _saveSchoolPlayersInBatches(txn, school['players'] as List, schoolId);
        }
      }
      
      print('RefactoredDataService: 学校データバッチ処理完了: ${i + 1}-$end / ${schools.length}');
    }
  }

  /// 学校情報を保存
  Future<int> _saveSchoolInfo(Transaction txn, Map<String, dynamic> school) async {
    final schoolId = await txn.insert('School', {
      'name': school['name'] ?? '',
      'type': school['type'] ?? 'high_school',
      'location': school['location'] ?? '',
      'prefecture': school['prefecture'] ?? '',
      'rank': school['rank'] ?? 'average',
      'school_strength': school['school_strength'] ?? 50,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    return schoolId;
  }

  /// 学校の選手データをバッチ処理で保存
  Future<void> _saveSchoolPlayersInBatches(Transaction txn, List players, int schoolId) async {
    const batchSize = 5000;
    
    for (int i = 0; i < players.length; i += batchSize) {
      final end = (i + batchSize < players.length) ? i + batchSize : players.length;
      final batch = players.sublist(i, end);
      
      for (final playerData in batch) {
        final player = Map<String, dynamic>.from(playerData);
        
        await txn.insert('Player', {
          'id': player['id'],
          'person_id': player['person_id'],
          'position': player['position'] ?? '',
          'age': player['age'] ?? 0,
          'grade': player['grade'] ?? 1,
          'is_graduated': player['isGraduated'] ?? false ? 1 : 0,
          'is_retired': player['isRetired'] ?? false ? 1 : 0,
          'school_id': schoolId,
          'fame': player['fame'] ?? 0,
          'growth_rate': player['growth_rate'] ?? 0,
          'talent': player['talent'] ?? 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('RefactoredDataService: 選手データバッチ処理完了: ${i + 1}-$end / ${players.length}');
    }
  }

  /// 発掘選手IDリストをバッチ処理で保存
  Future<void> _saveDiscoveredPlayerIdsInBatches(Transaction txn, List<int> playerIds) async {
    const batchSize = 5000;
    
    for (int i = 0; i < playerIds.length; i += batchSize) {
      final end = (i + batchSize < playerIds.length) ? i + batchSize : playerIds.length;
      final batch = playerIds.sublist(i, end);
      
      for (final playerId in batch) {
        await txn.insert('DiscoveredPlayer', {
          'player_id': playerId,
          'discovered_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('RefactoredDataService: 発掘選手IDリストバッチ処理完了: ${i + 1}-$end / ${playerIds.length}');
    }
  }

  /// 注目選手IDリストをバッチ処理で保存
  Future<void> _saveWatchedPlayerIdsInBatches(Transaction txn, List<int> playerIds) async {
    const batchSize = 5000;
    
    for (int i = 0; i < playerIds.length; i += batchSize) {
      final end = (i + batchSize < playerIds.length) ? i + batchSize : playerIds.length;
      final batch = playerIds.sublist(i, end);
      
      for (final playerId in batch) {
        await txn.insert('WatchedPlayer', {
          'player_id': playerId,
          'watched_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('RefactoredDataService: 注目選手IDリストバッチ処理完了: ${i + 1}-$end / ${playerIds.length}');
    }
  }

  /// お気に入り選手IDリストをバッチ処理で保存
  Future<void> _saveFavoritePlayerIdsInBatches(Transaction txn, List<int> playerIds) async {
    const batchSize = 5000;
    
    for (int i = 0; i < playerIds.length; i += batchSize) {
      final end = (i + batchSize < playerIds.length) ? i + batchSize : playerIds.length;
      final batch = playerIds.sublist(i, end);
      
      for (final playerId in batch) {
        await txn.insert('FavoritePlayer', {
          'player_id': playerId,
          'favorited_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('RefactoredDataService: お気に入り選手IDリストバッチ処理完了: ${i + 1}-$end / ${playerIds.length}');
    }
  }

  /// プロ野球データを保存
  Future<void> _saveProfessionalData(Transaction txn, List teams) async {
    for (final teamData in teams) {
      final team = Map<String, dynamic>.from(teamData);
      
      final teamId = await txn.insert('ProfessionalTeam', {
        'name': team['name'] ?? '',
        'league': team['league'] ?? '',
        'division': team['division'] ?? '',
        'region': team['region'] ?? '',
        'reputation': team['reputation'] ?? 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      
      if (team['professionalPlayers'] != null) {
        final players = team['professionalPlayers'] as List;
        for (final playerData in players) {
          final player = Map<String, dynamic>.from(playerData);
          
          await txn.insert('ProfessionalPlayer', {
            'id': player['id'],
            'name': player['name'] ?? '',
            'position': player['position'] ?? '',
            'age': player['age'] ?? 0,
            'team': teamId,
            'isRetired': player['isRetired'] ?? false ? 1 : 0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
  }

  // 以下、既存のDataServiceから移行するメソッド（簡略化）
  
  /// 全学校を取得
  Future<List<Map<String, dynamic>>> getAllSchools() async {
    final db = await database;
    return await db.query('School');
  }

  /// 全学校を選手情報と共に取得
  Future<List<Map<String, dynamic>>> getAllSchoolsWithPlayers() async {
    final db = await database;
    final schools = await db.query('School');
    final result = <Map<String, dynamic>>[];
    
    for (final school in schools) {
      final schoolData = Map<String, dynamic>.from(school);
      final players = await db.query('Player', where: 'school = ?', whereArgs: [school['id']]);
      schoolData['players'] = players;
      result.add(schoolData);
    }
    
    return result;
  }

  /// 学校を挿入
  Future<int> insertSchool(Map<String, dynamic> schoolData) async {
    final db = await database;
    return await db.insert('School', schoolData);
  }

  /// 選手を挿入
  Future<int> insertPlayer(Map<String, dynamic> playerData) async {
    final db = await database;
    return await db.insert('Player', playerData);
  }

  /// 発掘選手を追加
  Future<void> addDiscoveredPlayer(int playerId) async {
    final db = await database;
    await db.insert('DiscoveredPlayer', {
      'player_id': playerId,
      'discovered_at': DateTime.now().toIso8601String(),
    });
  }

  /// 選手の能力値把握度を更新
  Future<void> updatePlayerKnowledge(Map<String, dynamic> player) async {
    // 実装は既存のDataServiceから移行
    print('RefactoredDataService: 選手の能力値把握度を更新: ${player['name']}');
  }

  /// 全プロ野球団を取得
  Future<List<Map<String, dynamic>>> getAllProfessionalTeams() async {
    final db = await database;
    return await db.query('ProfessionalTeam');
  }

  /// チームのプロ選手を取得
  Future<List<Map<String, dynamic>>> getProfessionalPlayersByTeam(String teamId) async {
    final db = await database;
    return await db.query('ProfessionalPlayer', where: 'team_id = ?', whereArgs: [teamId]);
  }
}
