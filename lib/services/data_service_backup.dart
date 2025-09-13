import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:math';
import '../utils/name_generator.dart';
import '../models/game/game.dart';

class DataService {
  // スロット機能は廃止、単一データベースファイルを使用

  static Database? _db;

  static const int _databaseVersion = 2;

  // スロット機能は廃止、単一データベースファイルを使用

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
      print('既存のデータベースファイルを削除しました（スキーマ変更のため）');
      // 静的変数もリセットして、確実に新しいスキーマで再作成されるようにする
      _db = null;
    }
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        // 最新のスキーマでテーブルを作成
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ゲーム未リリースのため、最新スキーマで再作成
        print('データベーススキーマを最新版で再作成中...');
        await _createAllTables(db);
      },
    );
  }





  // スロット機能は廃止、データベースのみに保存

  // データベースからゲームデータを読み込み
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
      print('データベースからの読み込みエラー: $e');
      return null;
    }
  }

  // セーブデータが存在するかチェック
  Future<bool> hasGameDataInDatabase() async {
    try {
      final db = await database;
      final gameInfo = await db.query('GameInfo', limit: 1);
      return gameInfo.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 学校データをデータベースから読み込み
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
      print('学校データ読み込みエラー: $e');
      return [];
    }
  }

  // 発掘選手IDリストをデータベースから読み込み
  Future<List<int>> _loadDiscoveredPlayerIdsFromDatabase(Database db) async {
    try {
      final players = await db.query('DiscoveredPlayer');
      return players.map((p) => p['player_id'] as int).toList();
    } catch (e) {
      print('発掘選手IDリスト読み込みエラー: $e');
      return [];
    }
  }

  // 注目選手IDリストをデータベースから読み込み
  Future<List<int>> _loadWatchedPlayerIdsFromDatabase(Database db) async {
    try {
      final players = await db.query('WatchedPlayer');
      return players.map((p) => p['player_id'] as int).toList();
    } catch (e) {
      print('注目選手IDリスト読み込みエラー: $e');
      return [];
    }
  }

  // お気に入り選手IDリストをデータベースから読み込み
  Future<List<int>> _loadFavoritePlayerIdsFromDatabase(Database db) async {
    try {
      final players = await db.query('FavoritePlayer');
      return players.map((p) => p['player_id'] as int).toList();
    } catch (e) {
      print('お気に入り選手IDリスト読み込みエラー: $e');
      return [];
    }
  }

  // プロ野球データをデータベースから読み込み
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
      print('プロ野球データ読み込みエラー: $e');
      return {'teams': []};
    }
  }
  
  /// 軽量化されたセーブデータを作成（オートセーブ用）
  Map<String, dynamic> _createLightSaveData(Map<String, dynamic> fullData) {
    final lightData = <String, dynamic>{};
    
    // 重要なデータのみをコピー
    lightData['scoutName'] = fullData['scoutName'];
    lightData['currentYear'] = fullData['currentYear'];
    lightData['currentMonth'] = fullData['currentMonth'];
    lightData['currentWeekOfMonth'] = fullData['currentWeekOfMonth'];
    lightData['state'] = fullData['state'];
    lightData['ap'] = fullData['ap'];
    lightData['budget'] = fullData['budget'];
    lightData['scoutSkills'] = fullData['scoutSkills'];
    lightData['reputation'] = fullData['reputation'];
    lightData['experience'] = fullData['experience'];
    lightData['level'] = fullData['level'];
    lightData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    
    // 学校データは軽量化（選手の詳細情報は除外）
    if (fullData['schools'] != null) {
      final schools = fullData['schools'] as List;
      lightData['schools'] = schools.map((school) {
        final schoolData = Map<String, dynamic>.from(school);
        // 選手の詳細情報を除外して軽量化
        if (schoolData['players'] != null) {
          final players = schoolData['players'] as List;
          schoolData['players'] = players.map((player) {
            final playerData = Map<String, dynamic>.from(player);
            // 必要最小限の情報のみ保持
            return {
              'id': playerData['id'],
              'name': playerData['name'],
              'position': playerData['position'],
              'age': playerData['age'],
              'isGraduated': playerData['isGraduated'],
              'isRetired': playerData['isRetired'],
              'school': playerData['school'],
            };
          }).toList();
        }
        return schoolData;
      }).toList();
    }
    
    // 発掘選手IDリストも軽量化
    if (fullData['discoveredPlayerIds'] != null) {
      lightData['discoveredPlayerIds'] = fullData['discoveredPlayerIds'];
    }
    
    return lightData;
  }

  // オートセーブ機能は廃止

  Future<void> insertInitialData() async {
    final db = await database;
    
    // プロ野球団とプロ選手の初期データを挿入
    await _insertProfessionalTeams(db);
  }

  // スロット機能は廃止、単一データベースファイルを使用
  
  // スロット機能は廃止

  // データベースファイルを削除（新しいスキーマで再作成するため）
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scout_game.db');
    await deleteDatabaseAtPath(path);
  }
  
  // 数値データの型を修正するメソッド（内部用）
  Future<void> _repairNumericData(Database db) async {
    print('_repairNumericData: 数値データの型修正を開始...');
    
    // Playerテーブルの数値カラムを修正
    final numericColumns = [
      'grade', 'age', 'fame', 'growth_rate', 'talent', 'mental_grit', 'peak_ability',
      'contact', 'power', 'plate_discipline', 'bunt', 'opposite_field_hitting', 'pull_hitting',
      'bat_control', 'swing_speed', 'fielding', 'throwing', 'catcher_ability', 'control',
      'fastball', 'breaking_ball', 'pitch_movement', 'concentration', 'anticipation',
      'vision', 'composure', 'aggression', 'bravery', 'leadership', 'work_rate',
      'self_discipline', 'ambition', 'teamwork', 'positioning', 'pressure_handling',
      'clutch_ability', 'acceleration', 'agility', 'balance', 'jumping_reach',
      'natural_fitness', 'injury_proneness', 'stamina', 'strength', 'pace', 'flexibility'
    ];
    
    for (final column in numericColumns) {
      try {
        // 文字列として保存されている数値を整数に変換
        await db.execute('''
          UPDATE Player 
          SET $column = CAST($column AS INTEGER) 
          WHERE typeof($column) = 'text' AND $column IS NOT NULL
        ''');
        
        // 変換できなかった場合は0に設定
        await db.execute('''
          UPDATE Player 
          SET $column = 0 
          WHERE $column IS NULL OR $column = ''
        ''');
        
        print('_repairNumericData: $columnカラムを修正しました');
      } catch (e) {
        print('_repairNumericData: $columnカラムの修正でエラー: $e');
      }
    }
    
    print('_repairNumericData: 数値データの型修正が完了しました');
  }
  
  // 数値データの型を修正するメソッド（外部から呼び出し可能）
  Future<void> repairNumericData() async {
    try {
      print('_repairNumericData: 数値データの型修正を開始...');
      final db = await database;
      
      // 重複選手を削除（メソッドが削除されたためコメントアウト）
      // await removeDuplicatePlayers();
      
      // 数値カラムの型を修正
      final numericColumns = [
        'grade', 'age', 'fame', 'growth_rate', 'talent', 'mental_grit', 'peak_ability',
        'contact', 'power', 'plate_discipline', 'bunt', 'opposite_field_hitting', 'pull_hitting',
        'bat_control', 'swing_speed', 'fielding', 'throwing', 'catcher_ability',
        'control', 'fastball', 'breaking_ball', 'pitch_movement',
        'concentration', 'anticipation', 'vision', 'composure', 'aggression', 'bravery',
        'leadership', 'work_rate', 'self_discipline', 'ambition', 'teamwork',
        'positioning', 'pressure_handling', 'clutch_ability',
        'acceleration', 'agility', 'balance', 'jumping_reach', 'flexibility',
        'natural_fitness', 'injury_proneness', 'stamina', 'strength', 'pace'
      ];
      
      for (final column in numericColumns) {
        try {
          // まず、文字列として保存されている数値を確認
          final stringValues = await db.query('Player', 
            columns: [column], 
            where: 'typeof($column) = \'text\' AND $column IS NOT NULL AND $column != \'\''
          );
          
          if (stringValues.isNotEmpty) {
            print('_repairNumericData: $columnカラムに文字列データが${stringValues.length}件見つかりました');
            
            // 文字列を整数に変換
            await db.execute('''
              UPDATE Player 
              SET $column = CAST($column AS INTEGER) 
              WHERE typeof($column) = 'text' AND $column IS NOT NULL AND $column != ''
            ''');
            
            // 変換できなかった場合は0に設定
            await db.execute('''
              UPDATE Player 
              SET $column = 0 
              WHERE $column IS NULL OR $column = '' OR typeof($column) = 'text'
            ''');
            
            print('_repairNumericData: ${column}カラムを修正しました');
          } else {
            print('_repairNumericData: ${column}カラムは正常です');
          }
        } catch (e) {
          print('_repairNumericData: ${column}カラムの修正でエラー: $e');
        }
      }
      
      // ポテンシャル値の修正（現在の能力値より低い場合）
      await _repairPotentialValues(db);
      
      // 高校生のポテンシャル値の修正
      await _repairHighSchoolPotentials(db);
      
      print('_repairNumericData: 数値データの型修正完了');
    } catch (e) {
      print('_repairNumericData: エラーが発生しました: $e');
      rethrow;
    }
  }

  // ポテンシャル値の修正（現在の能力値より低い場合）
  Future<void> _repairPotentialValues(Database db) async {
    print('_repairPotentialValues: ポテンシャル値の修正を開始...');
    
    try {
      // 能力値のリスト
      final abilities = [
        'contact', 'power', 'plate_discipline', 'bunt', 'opposite_field_hitting', 'pull_hitting',
        'bat_control', 'swing_speed', 'fielding', 'throwing', 'catcher_ability',
        'control', 'fastball', 'breaking_ball', 'pitch_movement',
        'concentration', 'anticipation', 'vision', 'composure', 'aggression', 'bravery',
        'leadership', 'work_rate', 'self_discipline', 'ambition', 'teamwork',
        'positioning', 'pressure_handling', 'clutch_ability',
        'acceleration', 'agility', 'balance', 'jumping_reach', 'flexibility',
        'natural_fitness', 'injury_proneness', 'stamina', 'strength', 'pace'
      ];
      
      for (final ability in abilities) {
        final potentialColumn = '${ability}_potential';
        
        // 現在の能力値よりポテンシャル値が低い選手を取得
        final lowPotentialPlayers = await db.rawQuery('''
          SELECT pl.id, pl.$ability as current_value, pp.$potentialColumn as potential_value
          FROM Player pl 
          JOIN PlayerPotentials pp ON pl.id = pp.player_id 
          WHERE pl.$ability > pp.$potentialColumn 
          AND pl.is_default_player = 0
        ''');
        
        if (lowPotentialPlayers.isNotEmpty) {
          print('_repairPotentialValues: $ability で${lowPotentialPlayers.length}件の修正が必要');
          
          // ポテンシャル値を現在値 + 10〜30の範囲で設定
          final batch = db.batch();
          final random = Random();
          
          for (final player in lowPotentialPlayers) {
            final playerId = player['id'] as int;
            final currentValue = player['current_value'] as int;
            final bonus = 10 + random.nextInt(21); // 10〜30のボーナス
            final newPotential = (currentValue + bonus).clamp(25, 150);
            
            batch.update(
              'PlayerPotentials',
              {potentialColumn: newPotential},
              where: 'player_id = ?',
              whereArgs: [playerId],
            );
          }
          
          await batch.commit(noResult: true);
          print('_repairPotentialValues: $ability のポテンシャル値を修正しました');
        }
      }
      
      print('_repairPotentialValues: ポテンシャル値の修正完了');
      
      // 高校生のポテンシャル値も修正
      await _repairHighSchoolPotentials(db);
    } catch (e) {
      print('_repairPotentialValues: エラーが発生しました: $e');
    }
  }

  // 高校生のポテンシャル値が低すぎる場合の修正
  Future<void> _repairHighSchoolPotentials(Database db) async {
    print('_repairHighSchoolPotentials: 高校生のポテンシャル値の修正を開始...');
    
    try {
      // 高校生の選手を取得（プロ選手以外）
      final highSchoolPlayers = await db.rawQuery('''
        SELECT DISTINCT pl.id, pl.grade, pl.talent
        FROM Player pl 
        LEFT JOIN ProfessionalPlayer pp ON pl.id = pp.player_id 
        WHERE pp.player_id IS NULL 
        AND pl.is_default_player = 0
        AND pl.grade IS NOT NULL
      ''');
      
      if (highSchoolPlayers.isNotEmpty) {
        print('_repairHighSchoolPotentials: ${highSchoolPlayers.length}件の高校生選手のポテンシャル値を修正中...');
        
        final batch = db.batch();
        final random = Random();
        
        for (final player in highSchoolPlayers) {
          final playerId = player['id'] as int;
          final grade = player['grade'] as int? ?? 1;
          final talentRank = player['talent'] as int? ?? 3;
          
          // 才能ランクに基づく適切なポテンシャル範囲を計算
          final basePotential = _getHighSchoolBasePotential(talentRank);
          final variationRange = 10;
          final minPotential = basePotential - variationRange;
          final maxPotential = basePotential + variationRange;
          
          // 各能力値のポテンシャルを適切な範囲で設定
          final abilities = [
            'contact', 'power', 'plate_discipline', 'bunt', 'opposite_field_hitting', 'pull_hitting',
            'bat_control', 'swing_speed', 'fielding', 'throwing', 'catcher_ability',
            'control', 'fastball', 'breaking_ball', 'pitch_movement',
            'concentration', 'anticipation', 'vision', 'composure', 'aggression', 'bravery',
            'leadership', 'work_rate', 'self_discipline', 'ambition', 'teamwork',
            'positioning', 'pressure_handling', 'clutch_ability',
            'acceleration', 'agility', 'balance', 'jumping_reach', 'flexibility',
            'natural_fitness', 'injury_proneness', 'stamina', 'strength', 'pace'
          ];
          
          for (final ability in abilities) {
            final potentialColumn = '${ability}_potential';
            final variation = random.nextInt(variationRange * 2 + 1) - variationRange;
            final potential = (basePotential + variation).clamp(minPotential, maxPotential);
            
            batch.update(
              'PlayerPotentials',
              {potentialColumn: potential},
              where: 'player_id = ?',
              whereArgs: [playerId],
            );
          }
        }
        
        await batch.commit(noResult: true);
        print('_repairHighSchoolPotentials: 高校生のポテンシャル値を修正しました');
      }
      
      print('_repairHighSchoolPotentials: 高校生のポテンシャル値の修正完了');
    } catch (e) {
      print('_repairHighSchoolPotentials: エラーが発生しました: $e');
    }
  }

  // 高校生の才能ランクに基づく基本ポテンシャルを取得（最高値100）
  int _getHighSchoolBasePotential(int talentRank) {
    switch (talentRank) {
      case 3: return 65;  // ランク3: 60-70
      case 4: return 75;  // ランク4: 70-80
      case 5: return 85;  // ランク5: 80-90
      case 6: return 95;  // ランク6: 90-100
      default: return 65;
    }
  }

  // 指定されたパスのデータベースファイルを削除
  Future<void> deleteDatabaseAtPath(String path) async {
    await databaseFactory.deleteDatabase(path);
  }

  // スロット間でDBファイルをコピー
  Future<void> copyDatabaseBetweenSlots(String fromSlot, String toSlot) async {
    final dbPath = await getDatabasesPath();
    final fromDbName = fromSlot == 'オートセーブ' ? 'autosave.db' : 'save${_slotNumber(fromSlot)}.db';
    final toDbName = toSlot == 'オートセーブ' ? 'autosave.db' : 'save${_slotNumber(toSlot)}.db';
    final fromPath = join(dbPath, fromDbName);
    final toPath = join(dbPath, toDbName);
    final fromFile = File(fromPath);
    final toFile = File(toPath);
    if (await toFile.exists()) {
      await toFile.delete();
    }
    if (await fromFile.exists()) {
      await fromFile.copy(toPath);
    }
    // DBキャッシュをリセット
    _db = null;
  }

  // スロット名から番号を取得
  int _slotNumber(String slot) {
    if (slot == 'セーブ1') return 1;
    if (slot == 'セーブ2') return 2;
    if (slot == 'セーブ3') return 3;
    return 1;
  }

  // データベースの作成
  Future<void> _createDatabase(Database db, int version) async {
    print('データベーススキーマを作成中（バージョン$version）...');
    
    // 基本テーブルの作成
    await _createAllTables(db);
    
    // プロ野球団の初期データを挿入
    await _insertProfessionalTeams(db);
    
    print('データベーススキーマの作成完了');
  }




  // テーブル作成処理を共通化
  Future<void> _createAllTables(Database db) async {
    // Schoolテーブル（学校情報）
    await db.execute('''
      CREATE TABLE School (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        location TEXT NOT NULL,
        prefecture TEXT NOT NULL,
        rank TEXT NOT NULL,
        school_strength INTEGER DEFAULT 50,
        coach_trust INTEGER DEFAULT 50,
        coach_name TEXT DEFAULT '未設定',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Personテーブル（個人基本情報）
    await db.execute('''
      CREATE TABLE Person (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        gender TEXT DEFAULT '男性',
        hometown TEXT,
        personality TEXT,
        is_drafted INTEGER DEFAULT 0,
        drafted_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Playerテーブル（選手情報）
    await db.execute('''
      CREATE TABLE Player (
        id INTEGER PRIMARY KEY,
        person_id INTEGER NOT NULL,
        school_id INTEGER,
        school TEXT, -- 学校名（インタビューなどの機能で使用）
        grade INTEGER,
        age INTEGER DEFAULT 15,
        position TEXT NOT NULL,
        fame INTEGER DEFAULT 0,
        is_famous INTEGER DEFAULT 0,
        is_scout_favorite INTEGER DEFAULT 0,
        is_scouted INTEGER DEFAULT 0,
        is_graduated INTEGER DEFAULT 0,
        graduated_at TEXT,
        is_retired INTEGER DEFAULT 0,
        retired_at TEXT,
        status TEXT DEFAULT 'active', -- active, graduated, retired, professional
        growth_rate REAL DEFAULT 1.0,
        talent INTEGER DEFAULT 3,
        growth_type TEXT DEFAULT 'normal',
        mental_grit REAL DEFAULT 0.0,
        peak_ability INTEGER DEFAULT 100,
        -- Technical（技術面）能力値
        contact INTEGER DEFAULT 50,
        power INTEGER DEFAULT 50,
        plate_discipline INTEGER DEFAULT 50,
        bunt INTEGER DEFAULT 50,
        opposite_field_hitting INTEGER DEFAULT 50,
        pull_hitting INTEGER DEFAULT 50,
        bat_control INTEGER DEFAULT 50,
        swing_speed INTEGER DEFAULT 50,
        fielding INTEGER DEFAULT 50,
        throwing INTEGER DEFAULT 50,
        catcher_ability INTEGER DEFAULT 50,
        control INTEGER DEFAULT 50,
        fastball INTEGER DEFAULT 50,
        breaking_ball INTEGER DEFAULT 50,
        pitch_movement INTEGER DEFAULT 50,
        -- Mental（メンタル面）能力値
        concentration INTEGER DEFAULT 50,
        anticipation INTEGER DEFAULT 50,
        vision INTEGER DEFAULT 50,
        composure INTEGER DEFAULT 50,
        aggression INTEGER DEFAULT 50,
        bravery INTEGER DEFAULT 50,
        leadership INTEGER DEFAULT 50,
        work_rate INTEGER DEFAULT 50,
        self_discipline INTEGER DEFAULT 50,
        ambition INTEGER DEFAULT 50,
        teamwork INTEGER DEFAULT 50,
        positioning INTEGER DEFAULT 50,
        pressure_handling INTEGER DEFAULT 50,
        clutch_ability INTEGER DEFAULT 50,
        -- Physical（フィジカル面）能力値
        acceleration INTEGER DEFAULT 50,
        agility INTEGER DEFAULT 50,
        balance INTEGER DEFAULT 50,
        jumping_reach INTEGER DEFAULT 50,
        flexibility INTEGER DEFAULT 50,
        natural_fitness INTEGER DEFAULT 50,
        injury_proneness INTEGER DEFAULT 50,
        stamina INTEGER DEFAULT 50,
        strength INTEGER DEFAULT 50,
        pace INTEGER DEFAULT 50,
        -- 追加された能力値カラム（重複のため削除）
        -- motivation INTEGER DEFAULT 50,
        -- pressure INTEGER DEFAULT 50,
        -- adaptability INTEGER DEFAULT 50,
        -- consistency INTEGER DEFAULT 50,
        -- clutch INTEGER DEFAULT 50,
        -- work_ethic INTEGER DEFAULT 50,
        -- 総合能力値カラム
        overall INTEGER DEFAULT 50,
        technical INTEGER DEFAULT 50,
        physical INTEGER DEFAULT 50,
        mental INTEGER DEFAULT 50,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (person_id) REFERENCES Person (id),
        FOREIGN KEY (school_id) REFERENCES School (id),
        UNIQUE(person_id, school_id, grade) -- 同じ人物が同じ学校の同じ学年に重複して存在することを防ぐ
      )
    ''');

    // PlayerPotentialsテーブル（ポテンシャル）
    await db.execute('''
      CREATE TABLE PlayerPotentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        -- Technical（技術面）ポテンシャル
        contact_potential INTEGER DEFAULT 50,
        power_potential INTEGER DEFAULT 50,
        plate_discipline_potential INTEGER DEFAULT 50,
        bunt_potential INTEGER DEFAULT 50,
        opposite_field_hitting_potential INTEGER DEFAULT 50,
        pull_hitting_potential INTEGER DEFAULT 50,
        bat_control_potential INTEGER DEFAULT 50,
        swing_speed_potential INTEGER DEFAULT 50,
        fielding_potential INTEGER DEFAULT 50,
        throwing_potential INTEGER DEFAULT 50,
        catcher_ability_potential INTEGER DEFAULT 50,
        control_potential INTEGER DEFAULT 50,
        fastball_potential INTEGER DEFAULT 50,
        breaking_ball_potential INTEGER DEFAULT 50,
        pitch_movement_potential INTEGER DEFAULT 50,
        -- Mental（メンタル面）ポテンシャル
        concentration_potential INTEGER DEFAULT 50,
        anticipation_potential INTEGER DEFAULT 50,
        vision_potential INTEGER DEFAULT 50,
        composure_potential INTEGER DEFAULT 50,
        aggression_potential INTEGER DEFAULT 50,
        bravery_potential INTEGER DEFAULT 50,
        leadership_potential INTEGER DEFAULT 50,
        work_rate_potential INTEGER DEFAULT 50,
        self_discipline_potential INTEGER DEFAULT 50,
        ambition_potential INTEGER DEFAULT 50,
        teamwork_potential INTEGER DEFAULT 50,
        positioning_potential INTEGER DEFAULT 50,
        pressure_handling_potential INTEGER DEFAULT 50,
        clutch_ability_potential INTEGER DEFAULT 50,
        -- 以下のカラムは重複のため削除
        -- motivation_potential INTEGER DEFAULT 50,
        -- pressure_potential INTEGER DEFAULT 50,
        -- adaptability_potential INTEGER DEFAULT 50,
        -- consistency_potential INTEGER DEFAULT 50,
        -- clutch_potential INTEGER DEFAULT 50,
        -- work_ethic_potential INTEGER DEFAULT 50,
        -- Physical（フィジカル面）ポテンシャル
        acceleration_potential INTEGER DEFAULT 50,
        agility_potential INTEGER DEFAULT 50,
        balance_potential INTEGER DEFAULT 50,
        jumping_reach_potential INTEGER DEFAULT 50,
        natural_fitness_potential INTEGER DEFAULT 50,
        injury_proneness_potential INTEGER DEFAULT 50,
        stamina_potential INTEGER DEFAULT 50,
        strength_potential INTEGER DEFAULT 50,
        pace_potential INTEGER DEFAULT 50,
        flexibility_potential INTEGER DEFAULT 50,
        -- 総合ポテンシャル指標
        overall_potential INTEGER DEFAULT 50,
        technical_potential INTEGER DEFAULT 50,
        physical_potential INTEGER DEFAULT 50,
        mental_potential INTEGER DEFAULT 50,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');

    // ProfessionalPlayerテーブル（プロ選手情報）
    await db.execute('''
      CREATE TABLE ProfessionalPlayer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        team_id TEXT NOT NULL,
        contract_year INTEGER NOT NULL,
        salary INTEGER NOT NULL, -- 年俸（万円）
        contract_type TEXT DEFAULT 'regular', -- regular, minor, free_agent
        draft_year INTEGER NOT NULL,
        draft_round INTEGER NOT NULL,
        draft_position INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        joined_at TEXT NOT NULL,
        left_at TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES Player (id),
        FOREIGN KEY (team_id) REFERENCES ProfessionalTeam (id)
      )
    ''');

    // ProfessionalTeamテーブル（プロ球団）
    await db.execute('''
      CREATE TABLE ProfessionalTeam (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        short_name TEXT NOT NULL,
        league TEXT NOT NULL, -- 'central' or 'pacific'
        division TEXT NOT NULL, -- 'east', 'west', 'central'
        strategy TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // PlayerStatsテーブル（選手成績）
    await db.execute('''
      CREATE TABLE PlayerStats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        team_id TEXT,
        year INTEGER NOT NULL,
        league TEXT NOT NULL, -- 'central', 'pacific', 'minor'
        games INTEGER DEFAULT 0,
        at_bats INTEGER DEFAULT 0,
        hits INTEGER DEFAULT 0,
        doubles INTEGER DEFAULT 0,
        triples INTEGER DEFAULT 0,
        home_runs INTEGER DEFAULT 0,
        runs_batted_in INTEGER DEFAULT 0,
        runs INTEGER DEFAULT 0,
        stolen_bases INTEGER DEFAULT 0,
        caught_stealing INTEGER DEFAULT 0,
        walks INTEGER DEFAULT 0,
        strikeouts INTEGER DEFAULT 0,
        batting_average REAL DEFAULT 0.0,
        on_base_percentage REAL DEFAULT 0.0,
        slugging_percentage REAL DEFAULT 0.0,
        -- 投手成績
        wins INTEGER DEFAULT 0,
        losses INTEGER DEFAULT 0,
        saves INTEGER DEFAULT 0,
        holds INTEGER DEFAULT 0,
        innings_pitched REAL DEFAULT 0.0,
        earned_runs INTEGER DEFAULT 0,
        earned_run_average REAL DEFAULT 0.0,
        hits_allowed INTEGER DEFAULT 0,
        walks_allowed INTEGER DEFAULT 0,
        strikeouts_pitched INTEGER DEFAULT 0,
        wild_pitches INTEGER DEFAULT 0,
        hit_batters INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES Player (id),
        FOREIGN KEY (team_id) REFERENCES ProfessionalTeam (id),
        UNIQUE(player_id, year, league)
      )
    ''');

    // TeamHistoryテーブル（球団履歴）
    await db.execute('''
      CREATE TABLE TeamHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        team_id TEXT NOT NULL,
        year INTEGER NOT NULL,
        league TEXT NOT NULL,
        division TEXT NOT NULL,
        games INTEGER NOT NULL,
        wins INTEGER NOT NULL,
        losses INTEGER NOT NULL,
        ties INTEGER DEFAULT 0,
        winning_percentage REAL DEFAULT 0.0,
        games_behind REAL DEFAULT 0.0,
        rank INTEGER NOT NULL,
        runs_scored INTEGER DEFAULT 0,
        runs_allowed INTEGER DEFAULT 0,
        run_differential INTEGER DEFAULT 0,
        home_wins INTEGER DEFAULT 0,
        home_losses INTEGER DEFAULT 0,
        away_wins INTEGER DEFAULT 0,
        away_losses INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (team_id) REFERENCES ProfessionalTeam (id),
        UNIQUE(team_id, year)
      )
    ''');

    // ScoutAnalysisテーブル（スカウト分析データ）
    await db.execute('''
      CREATE TABLE ScoutAnalysis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        scout_id TEXT NOT NULL,
        analysis_date TEXT NOT NULL,
        accuracy INTEGER DEFAULT 50,
        -- スカウト済み能力値（実際に分析された値）
        contact_scouted INTEGER,
        power_scouted INTEGER,
        plate_discipline_scouted INTEGER,
        bunt_scouted INTEGER,
        opposite_field_hitting_scouted INTEGER,
        pull_hitting_scouted INTEGER,
        bat_control_scouted INTEGER,
        swing_speed_scouted INTEGER,
        fielding_scouted INTEGER,
        throwing_scouted INTEGER,
        catcher_ability_scouted INTEGER,
        control_scouted INTEGER,
        fastball_scouted INTEGER,
        breaking_ball_scouted INTEGER,
        pitch_movement_scouted INTEGER,
        concentration_scouted INTEGER,
        anticipation_scouted INTEGER,
        vision_scouted INTEGER,
        composure_scouted INTEGER,
        aggression_scouted INTEGER,
        bravery_scouted INTEGER,
        leadership_scouted INTEGER,
        work_rate_scouted INTEGER,
        self_discipline_scouted INTEGER,
        ambition_scouted INTEGER,
        teamwork_scouted INTEGER,
        positioning_scouted INTEGER,
        pressure_handling_scouted INTEGER,
        clutch_ability_scouted INTEGER,
        -- 以下のカラムは重複のため削除
        -- motivation_scouted INTEGER,
        -- adaptability_scouted INTEGER,
        -- consistency_scouted INTEGER,
        acceleration_scouted INTEGER,
        agility_scouted INTEGER,
        balance_scouted INTEGER,
        jumping_reach_scouted INTEGER,
        natural_fitness_scouted INTEGER,
        injury_proneness_scouted INTEGER,
        stamina_scouted INTEGER,
        strength_scouted INTEGER,
        pace_scouted INTEGER,
        flexibility_scouted INTEGER,
        -- 総合評価指標
        overall_evaluation INTEGER DEFAULT 50,
        technical_evaluation INTEGER DEFAULT 50,
        physical_evaluation INTEGER DEFAULT 50,
        mental_evaluation INTEGER DEFAULT 50,
        -- その他
        is_graduated INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');

    // ScoutBasicInfoAnalysisテーブル（スカウト基本情報分析）
    await db.execute('''
      CREATE TABLE ScoutBasicInfoAnalysis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        scout_id TEXT NOT NULL,
        analysis_date TEXT NOT NULL,
        -- スカウト済み基本情報（実際に分析された値）
        personality_scouted INTEGER,
        talent_scouted INTEGER,
        growth_scouted INTEGER,
        mental_scouted INTEGER,
        potential_scouted INTEGER,
        -- 分析精度
        accuracy INTEGER DEFAULT 50,
        -- その他
        is_graduated INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');

    // インデックスの作成
    await db.execute('CREATE INDEX idx_player_person_id ON Player(person_id)');
    await db.execute('CREATE INDEX idx_player_school_id ON Player(school_id)');
    await db.execute('CREATE INDEX idx_player_status ON Player(status)');
    await db.execute('CREATE INDEX idx_professional_player_player_id ON ProfessionalPlayer(player_id)');
    await db.execute('CREATE INDEX idx_professional_player_team_id ON ProfessionalPlayer(team_id)');
    await db.execute('CREATE INDEX idx_player_stats_player_id ON PlayerStats(player_id)');
    await db.execute('CREATE INDEX idx_player_stats_team_year ON PlayerStats(team_id, year)');
    await db.execute('CREATE INDEX idx_professional_team_league ON ProfessionalTeam(league)');
    await db.execute('CREATE INDEX idx_professional_team_division ON ProfessionalTeam(division)');
    await db.execute('CREATE INDEX idx_team_history_team_year ON TeamHistory(team_id, year)');
    
    // GameInfoテーブル（ゲーム基本情報）
    await db.execute('''
      CREATE TABLE GameInfo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scoutName TEXT NOT NULL,
        currentYear INTEGER NOT NULL,
        currentMonth INTEGER NOT NULL,
        currentWeekOfMonth INTEGER NOT NULL,
        state INTEGER NOT NULL,
        ap INTEGER NOT NULL,
        budget INTEGER NOT NULL,
        scoutSkills TEXT NOT NULL,
        reputation INTEGER NOT NULL,
        experience INTEGER NOT NULL,
        level INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    
    // DiscoveredPlayerテーブル（発掘選手ID）
    await db.execute('''
      CREATE TABLE DiscoveredPlayer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        discovered_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');
    
    // WatchedPlayerテーブル（注目選手ID）
    await db.execute('''
      CREATE TABLE WatchedPlayer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        watched_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');
    
    // FavoritePlayerテーブル（お気に入り選手ID）
    await db.execute('''
      CREATE TABLE FavoritePlayer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        favorited_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');
    
    // スカウトレポートテーブル（スカウトレポート）
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scout_reports (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        player_name TEXT NOT NULL,
        scout_id TEXT NOT NULL,
        scout_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        future_potential TEXT NOT NULL,
        overall_rating REAL NOT NULL,
        expected_draft_position TEXT NOT NULL,
        player_type TEXT NOT NULL,
        position_suitability TEXT NOT NULL,
        mental_strength REAL NOT NULL,
        injury_risk REAL NOT NULL,
        years_to_mlb INTEGER NOT NULL,
        strengths TEXT NOT NULL,
        weaknesses TEXT NOT NULL,
        development_plan TEXT NOT NULL,
        additional_notes TEXT NOT NULL,
        is_analysis_complete INTEGER NOT NULL
      )
    ''');

    // 追加のインデックス
    await db.execute('CREATE INDEX idx_game_info_timestamp ON GameInfo(timestamp)');
    await db.execute('CREATE INDEX idx_discovered_player_id ON DiscoveredPlayer(player_id)');
    await db.execute('CREATE INDEX idx_watched_player_id ON WatchedPlayer(player_id)');
    await db.execute('CREATE INDEX idx_favorite_player_id ON FavoritePlayer(player_id)');
    await db.execute('CREATE INDEX idx_scout_reports_player_id ON scout_reports(player_id)');
    await db.execute('CREATE INDEX idx_scout_reports_scout_id ON scout_reports(scout_id)');
  }

  // プロ野球団の初期データを挿入
  Future<void> _insertProfessionalTeams(Database db) async {
    final teams = [
      // セ・リーグ
      {
        'id': 'giants',
        'name': '読売ジャイアンツ',
        'short_name': '巨人',
        'league': 'central',
        'division': 'east',
        'home_stadium': '東京ドーム',
        'city': '東京都',
        'budget': 80000,
        'strategy': '打撃重視',
        'strengths': '["打撃力", "知名度", "資金力"]',
        'weaknesses': '["投手力", "若手育成"]',
        'popularity': 90,
        'success': 85,
      },
      {
        'id': 'tigers',
        'name': '阪神タイガース',
        'short_name': '阪神',
        'league': 'central',
        'division': 'west',
        'home_stadium': '阪神甲子園球場',
        'city': '兵庫県',
        'budget': 70000,
        'strategy': 'バランス型',
        'strengths': '["投手力", "守備力"]',
        'weaknesses': '["打撃力", "長打力"]',
        'popularity': 85,
        'success': 80,
      },
      {
        'id': 'carp',
        'name': '広島東洋カープ',
        'short_name': '広島',
        'league': 'central',
        'division': 'central',
        'home_stadium': 'MAZDA Zoom-Zoom スタジアム広島',
        'city': '広島県',
        'budget': 60000,
        'strategy': '若手育成重視',
        'strengths': '["若手育成", "打撃力"]',
        'weaknesses': '["投手力", "資金力"]',
        'popularity': 75,
        'success': 70,
      },
      {
        'id': 'dragons',
        'name': '中日ドラゴンズ',
        'short_name': '中日',
        'league': 'central',
        'division': 'central',
        'home_stadium': 'バンテリンドーム ナゴヤ',
        'city': '愛知県',
        'budget': 75000,
        'strategy': '投手重視',
        'strengths': '["投手力", "守備力", "伝統"]',
        'weaknesses': '["打撃力", "長打力"]',
        'popularity': 75,
        'success': 75,
      },
      {
        'id': 'baystars',
        'name': '横浜DeNAベイスターズ',
        'short_name': 'DeNA',
        'league': 'central',
        'division': 'east',
        'home_stadium': '横浜スタジアム',
        'city': '神奈川県',
        'budget': 60000,
        'strategy': '打撃重視',
        'strengths': '["打撃力", "長打力", "若手育成"]',
        'weaknesses': '["投手力", "守備力"]',
        'popularity': 65,
        'success': 60,
      },
      {
        'id': 'swallows',
        'name': '東京ヤクルトスワローズ',
        'short_name': 'ヤクルト',
        'league': 'central',
        'division': 'east',
        'home_stadium': '明治神宮野球場',
        'city': '東京都',
        'budget': 55000,
        'strategy': '若手育成重視',
        'strengths': '["若手育成", "打撃力", "スピード"]',
        'weaknesses': '["投手力", "資金力"]',
        'popularity': 60,
        'success': 55,
      },
      // パ・リーグ
      {
        'id': 'hawks',
        'name': '福岡ソフトバンクホークス',
        'short_name': 'ソフトバンク',
        'league': 'pacific',
        'division': 'west',
        'home_stadium': '福岡PayPayドーム',
        'city': '福岡県',
        'budget': 90000,
        'strategy': '投手重視',
        'strengths': '["投手力", "資金力", "戦略性"]',
        'weaknesses': '["内野守備"]',
        'popularity': 80,
        'success': 90,
      },
      {
        'id': 'marines',
        'name': '千葉ロッテマリーンズ',
        'short_name': 'ロッテ',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': 'ZOZOマリンスタジアム',
        'city': '千葉県',
        'budget': 50000,
        'strategy': '若手育成重視',
        'strengths': '["若手育成", "守備力"]',
        'weaknesses': '["投手力", "打撃力", "資金力"]',
        'popularity': 60,
        'success': 55,
      },
      {
        'id': 'eagles',
        'name': '東北楽天ゴールデンイーグルス',
        'short_name': '楽天',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': '楽天生命パーク宮城',
        'city': '宮城県',
        'budget': 65000,
        'strategy': 'バランス型',
        'strengths': '["打撃力", "若手育成"]',
        'weaknesses': '["投手力", "守備力"]',
        'popularity': 70,
        'success': 65,
      },
      {
        'id': 'lions',
        'name': '埼玉西武ライオンズ',
        'short_name': '西武',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': 'ベルーナドーム',
        'city': '埼玉県',
        'budget': 70000,
        'strategy': 'バランス型',
        'strengths': '["投手力", "内野守備", "若手育成"]',
        'weaknesses': '["外野守備", "長打力"]',
        'popularity': 70,
        'success': 75,
      },
      {
        'id': 'fighters',
        'name': '北海道日本ハムファイターズ',
        'short_name': '日本ハム',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': 'エスコンフィールドHOKKAIDO',
        'city': '北海道',
        'budget': 65000,
        'strategy': '投手重視',
        'strengths': '["投手力", "外野守備", "若手育成"]',
        'weaknesses': '["内野守備", "打撃力"]',
        'popularity': 65,
        'success': 60,
      },
      {
        'id': 'buffaloes',
        'name': 'オリックス・バファローズ',
        'short_name': 'オリックス',
        'league': 'pacific',
        'division': 'west',
        'home_stadium': '京セラドーム大阪',
        'city': '大阪府',
        'budget': 80000,
        'strategy': '投手重視',
        'strengths': '["投手力", "守備力", "資金力"]',
        'weaknesses': '["打撃力", "長打力"]',
        'popularity': 75,
        'success': 80,
      },
    ];

    for (final team in teams) {
      await db.insert('ProfessionalTeam', team);
    }
    
    // プロ選手の初期データを生成・挿入
    await _insertProfessionalPlayers(db);
  }

  // プロ選手の初期データを生成・挿入
  Future<void> _insertProfessionalPlayers(Database db) async {
    // プロ野球団のリストを取得
    final teamMaps = await db.query('ProfessionalTeam');
    if (teamMaps.isEmpty) {
      return;
    }
    
    // 各チームにプロ選手を生成・挿入
    for (final teamMap in teamMaps) {
      final teamId = teamMap['id'] as String;
      final teamName = teamMap['name'] as String;
      final teamShortName = teamMap['short_name'] as String;
      
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
      
      // 各ポジションの選手を生成・挿入
      for (final entry in positionCounts.entries) {
        final position = entry.key;
        final count = entry.value;
        
        for (int i = 0; i < count; i++) {
          // 選手の基本情報を生成
          final playerName = _generateProfessionalPlayerName();
          final age = 18 + (Random().nextInt(18)); // 18-35歳
          final talent = _generateTalentForProfessional(); // 3-5のtalent
          
          // ランダム性を向上させるための個別の乱数生成
          final random = Random();
          
          // Personテーブルに挿入
          final personId = await db.insert('Person', {
            'name': playerName,
            'birth_date': DateTime.now().subtract(Duration(days: age * 365)).toIso8601String(),
            'gender': '男性',
            'hometown': '日本',
            'personality': _generateProfessionalPersonality(),
            'is_drafted': 1,
            'drafted_at': DateTime.now().subtract(Duration(days: 365)).toIso8601String(),
          });
          
          // peak_abilityを基準とした能力値生成（95%前後）
          final peakAbility = _calculatePeakAbilityByAge(talent, age);
          final targetAbility = (peakAbility * 0.95).round(); // peak_abilityの95%を目標
          
          // Playerテーブルに挿入
          final playerId = await db.insert('Player', {
            'person_id': personId,
            'school_id': null, // プロ選手は学校なし
            'grade': 0, // プロ選手は学年なし
            'age': age,
            'position': position,
            'fame': 60 + random.nextInt(41), // 60-100
            'is_famous': 1,
            'is_scout_favorite': 0,
            'is_graduated': 1, // プロ選手は高校卒業済み
            'is_retired': 0, // プロ選手は引退していない
            'status': 'professional', // プロ選手ステータス
            'growth_rate': _calculateGrowthRateByAge(age),
            'talent': talent,
            'growth_type': _getGrowthTypeByAge(age),
            'mental_grit': 0.6 + random.nextDouble() * 0.4, // 0.6-1.0
            'peak_ability': peakAbility,
            // 技術的能力値（peak_abilityの95%前後で生成、上限はpeak_ability+10）
            'contact': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'power': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'plate_discipline': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'bunt': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'opposite_field_hitting': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'pull_hitting': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'bat_control': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'swing_speed': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'fielding': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'throwing': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'catcher_ability': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'control': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'fastball': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'breaking_ball': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'pitch_movement': _generateProPlayerAbility(targetAbility, peakAbility, random),
            // 精神的能力値（peak_abilityの95%前後で生成、上限はpeak_ability+10）
            'concentration': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'anticipation': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'vision': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'composure': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'aggression': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'bravery': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'leadership': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'work_rate': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'self_discipline': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'ambition': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'teamwork': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'positioning': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'pressure_handling': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'clutch_ability': _generateProPlayerAbility(targetAbility, peakAbility, random),
            // 身体的能力値（peak_abilityの95%前後で生成、上限はpeak_ability+10）
            'acceleration': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'agility': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'balance': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'jumping_reach': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'natural_fitness': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'injury_proneness': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'stamina': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'strength': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'pace': _generateProPlayerAbility(targetAbility, peakAbility, random),
            'flexibility': _generateProPlayerAbility(targetAbility, peakAbility, random),
          });
          
          // PlayerPotentialsテーブルに挿入
          await db.insert('PlayerPotentials', {
            'player_id': playerId,
            // 技術的ポテンシャル（peak_abilityを基準に生成、上限はpeak_ability+15）
            'contact_potential': _generateProPlayerPotential(peakAbility, random),
            'power_potential': _generateProPlayerPotential(peakAbility, random),
            'plate_discipline_potential': _generateProPlayerPotential(peakAbility, random),
            'bunt_potential': _generateProPlayerPotential(peakAbility, random),
            'opposite_field_hitting_potential': _generateProPlayerPotential(peakAbility, random),
            'pull_hitting_potential': _generateProPlayerPotential(peakAbility, random),
            'bat_control_potential': _generateProPlayerPotential(peakAbility, random),
            'swing_speed_potential': _generateProPlayerPotential(peakAbility, random),
            'fielding_potential': _generateProPlayerPotential(peakAbility, random),
            'throwing_potential': _generateProPlayerPotential(peakAbility, random),
            'catcher_ability_potential': _generateProPlayerPotential(peakAbility, random),
            'control_potential': _generateProPlayerPotential(peakAbility, random),
            'fastball_potential': _generateProPlayerPotential(peakAbility, random),
            'breaking_ball_potential': _generateProPlayerPotential(peakAbility, random),
            'pitch_movement_potential': _generateProPlayerPotential(peakAbility, random),
            // 精神的ポテンシャル（peak_abilityを基準に生成、上限はpeak_ability+15）
            'concentration_potential': _generateProPlayerPotential(peakAbility, random),
            'anticipation_potential': _generateProPlayerPotential(peakAbility, random),
            'vision_potential': _generateProPlayerPotential(peakAbility, random),
            'composure_potential': _generateProPlayerPotential(peakAbility, random),
            'aggression_potential': _generateProPlayerPotential(peakAbility, random),
            'bravery_potential': _generateProPlayerPotential(peakAbility, random),
            'leadership_potential': _generateProPlayerPotential(peakAbility, random),
            'work_rate_potential': _generateProPlayerPotential(peakAbility, random),
            'self_discipline_potential': _generateProPlayerPotential(peakAbility, random),
            'ambition_potential': _generateProPlayerPotential(peakAbility, random),
            'teamwork_potential': _generateProPlayerPotential(peakAbility, random),
            'positioning_potential': _generateProPlayerPotential(peakAbility, random),
            'pressure_handling_potential': _generateProPlayerPotential(peakAbility, random),
            'clutch_ability_potential': _generateProPlayerPotential(peakAbility, random),
            // 身体的ポテンシャル（peak_abilityを基準に生成、上限はpeak_ability+15）
            'acceleration_potential': _generateProPlayerPotential(peakAbility, random),
            'agility_potential': _generateProPlayerPotential(peakAbility, random),
            'balance_potential': _generateProPlayerPotential(peakAbility, random),
            'jumping_reach_potential': _generateProPlayerPotential(peakAbility, random),
            'natural_fitness_potential': _generateProPlayerPotential(peakAbility, random),
            'injury_proneness_potential': _generateProPlayerPotential(peakAbility, random),
            'stamina_potential': _generateProPlayerPotential(peakAbility, random),
            'strength_potential': _generateProPlayerPotential(peakAbility, random),
            'pace_potential': _generateProPlayerPotential(peakAbility, random),
            'flexibility_potential': _generateProPlayerPotential(peakAbility, random),
            // 総合ポテンシャル指標（事前計算済み）
            'overall_potential': _calculateProfessionalOverallPotential(peakAbility, position, random),
            'technical_potential': _calculateProfessionalTechnicalPotential(peakAbility, random),
            'mental_potential': _calculateProfessionalMentalPotential(peakAbility, random),
            'physical_potential': _calculateProfessionalPhysicalPotential(peakAbility, random),
          });
          
          // ProfessionalPlayerテーブルに挿入
          await db.insert('ProfessionalPlayer', {
            'player_id': playerId,
            'team_id': teamId,
            'contract_year': 1,
            'salary': 1000 + (talent * 200) + random.nextInt(500), // 1000-2500万円
            'contract_type': 'regular',
            'draft_year': DateTime.now().year - 1,
            'draft_round': 1,
            'draft_position': 1,
            'is_active': 1,
            'joined_at': DateTime.now().subtract(Duration(days: 365)).toIso8601String(),
            'left_at': null,
          });
          
          // 総合能力値指標の計算・更新は不要（高校野球選手と同様）
        }
      }
    }
  }

  // プロ選手用の名前生成
  String _generateProfessionalPlayerName() {
    return NameGenerator.generateProfessionalPlayerName();
  }

  // プロ選手用の性格生成
  String _generateProfessionalPersonality() {
    final personalities = ['リーダー', '積極的', '冷静', '情熱的', '謙虚', '自信家', '努力家', '天才型'];
    final random = DateTime.now().millisecondsSinceEpoch;
    return personalities[random % personalities.length];
  }

  // プロ選手用のtalent生成（3-5）
  int _generateTalentForProfessional() {
    final random = DateTime.now().millisecondsSinceEpoch;
    if (random % 3 == 0) return 5; // 33%で5
    if (random % 2 == 0) return 4; // 33%で4
    return 3; // 33%で3
  }

  // 年齢に基づく成長率計算
  double _calculateGrowthRateByAge(int age) {
    if (age <= 22) return 1.1;      // 若手
    else if (age <= 28) return 1.0; // 全盛期
    else if (age <= 32) return 0.9; // ベテラン
    else return 0.8;                // シニア
  }

  // 年齢に基づく成長タイプ取得
  String _getGrowthTypeByAge(int age) {
    if (age <= 22) return '早期型';
    else if (age <= 28) return '標準型';
    else if (age <= 32) return '晩成型';
    else return '維持型';
  }

  // 選手の総合能力値指標を計算・更新
  Future<void> _updatePlayerOverallAbilities(Database db, int playerId) async {
    try {
      // 選手の能力値を取得
      final player = await db.query('Player', where: 'id = ?', whereArgs: [playerId]);
      if (player.isEmpty) return;
      
      final playerData = player.first;
      
      // 技術的能力値の平均（投手と野手で異なる重み付け）
      final position = playerData['position'] as String? ?? '投手';
      int technicalAbility;
      
      if (position == '投手') {
        // 投手は投球関連能力値を重視
        final pitchingAbilities = [
          playerData['control'] as int? ?? 50,
          playerData['fastball'] as int? ?? 50,
          playerData['breaking_ball'] as int? ?? 50,
          playerData['pitch_movement'] as int? ?? 50,
        ];
        final fieldingAbilities = [
          playerData['fielding'] as int? ?? 50,
          playerData['throwing'] as int? ?? 50,
        ];
        final battingAbilities = [
          playerData['contact'] as int? ?? 50,
          playerData['power'] as int? ?? 50,
          playerData['plate_discipline'] as int? ?? 50,
          playerData['bunt'] as int? ?? 50,
        ];
        
        // 投手能力: 投球関連60%、守備関連25%、打撃関連15%
        final pitchingAvg = pitchingAbilities.reduce((a, b) => a + b) / pitchingAbilities.length;
        final fieldingAvg = fieldingAbilities.reduce((a, b) => a + b) / fieldingAbilities.length;
        final battingAvg = battingAbilities.reduce((a, b) => a + b) / battingAbilities.length;
        
        technicalAbility = (
          (pitchingAvg * 0.6) +
          (fieldingAvg * 0.25) +
          (battingAvg * 0.15)
        ).round();
      } else {
        // 野手は打撃・守備関連能力値を重視
        final battingAbilities = [
          playerData['contact'] as int? ?? 50,
          playerData['power'] as int? ?? 50,
          playerData['plate_discipline'] as int? ?? 50,
          playerData['bunt'] as int? ?? 50,
          playerData['opposite_field_hitting'] as int? ?? 50,
          playerData['pull_hitting'] as int? ?? 50,
          playerData['bat_control'] as int? ?? 50,
          playerData['swing_speed'] as int? ?? 50,
        ];
        final fieldingAbilities = [
          playerData['fielding'] as int? ?? 50,
          playerData['throwing'] as int? ?? 50,
        ];
        
        // 野手能力: 打撃関連70%、守備関連30%
        final battingAvg = battingAbilities.reduce((a, b) => a + b) / battingAbilities.length;
        final fieldingAvg = fieldingAbilities.reduce((a, b) => a + b) / fieldingAbilities.length;
        
        technicalAbility = (
          (battingAvg * 0.7) +
          (fieldingAvg * 0.3)
        ).round();
      }
      
      // 精神的能力値の平均（重要な能力値を重視）
      final mentalAbilities = [
        (playerData['concentration'] as int? ?? 50) * 1.2, // 集中力
        (playerData['anticipation'] as int? ?? 50) * 1.1, // 予測力
        (playerData['vision'] as int? ?? 50) * 1.1, // 視野
        (playerData['composure'] as int? ?? 50) * 1.2, // 冷静さ
        (playerData['aggression'] as int? ?? 50) * 1.0, // 積極性
        (playerData['bravery'] as int? ?? 50) * 1.0, // 勇気
        (playerData['leadership'] as int? ?? 50) * 1.1, // リーダーシップ
        (playerData['work_rate'] as int? ?? 50) * 1.2, // 練習量
        (playerData['self_discipline'] as int? ?? 50) * 1.1, // 自己管理
        (playerData['ambition'] as int? ?? 50) * 1.0, // 野心
        (playerData['teamwork'] as int? ?? 50) * 1.1, // チームワーク
        (playerData['positioning'] as int? ?? 50) * 1.0, // ポジショニング
        (playerData['pressure_handling'] as int? ?? 50) * 1.2, // プレッシャー処理
        (playerData['clutch_ability'] as int? ?? 50) * 1.2, // 勝負強さ
        // 追加された能力値（重複のため削除）
        // (playerData['motivation'] as int? ?? 50) * 1.1, // 動機・目標
        // (playerData['pressure'] as int? ?? 50) * 1.0, // プレッシャー耐性
        // (playerData['adaptability'] as int? ?? 50) * 1.1, // 適応力
        // (playerData['consistency'] as int? ?? 50) * 1.1, // 安定性
        // (playerData['clutch'] as int? ?? 50) * 1.2, // 勝負強さ
        // (playerData['work_ethic'] as int? ?? 50) * 1.2, // 仕事への取り組み
      ];
      
      final mentalAbility = (mentalAbilities.reduce((a, b) => a + b) / mentalAbilities.length).round();
      
      // 身体的能力値の平均（ポジション別の重み付け）
      int physicalAbility;
      if (position == '投手') {
        // 投手は持久力と筋力を重視
        final staminaAbilities = [
          (playerData['stamina'] as int? ?? 50) * 1.3, // 持久力
          (playerData['strength'] as int? ?? 50) * 1.2, // 筋力
          (playerData['natural_fitness'] as int? ?? 50) * 1.1, // 自然な体力
        ];
        final otherAbilities = [
          playerData['agility'] as int? ?? 50,
          playerData['balance'] as int? ?? 50,
          playerData['jumping_reach'] as int? ?? 50,
          playerData['injury_proneness'] as int? ?? 50,
          playerData['pace'] as int? ?? 50,
          playerData['flexibility'] as int? ?? 50,
        ];
        
        final staminaAvg = staminaAbilities.reduce((a, b) => a + b) / staminaAbilities.length;
        final otherAvg = otherAbilities.reduce((a, b) => a + b) / otherAbilities.length;
        
        physicalAbility = (
          (staminaAvg * 0.6) +
          (otherAvg * 0.4)
        ).round();
      } else {
        // 野手は敏捷性と加速力を重視
        final speedAbilities = [
          (playerData['agility'] as int? ?? 50) * 1.2, // 敏捷性
          (playerData['acceleration'] as int? ?? 50) * 1.2, // 加速力
        ];
        final otherAbilities = [
          playerData['balance'] as int? ?? 50,
          playerData['jumping_reach'] as int? ?? 50,
          playerData['natural_fitness'] as int? ?? 50,
          playerData['injury_proneness'] as int? ?? 50,
          playerData['stamina'] as int? ?? 50,
          playerData['strength'] as int? ?? 50,
          playerData['pace'] as int? ?? 50,
          playerData['flexibility'] as int? ?? 50,
        ];
        
        final speedAvg = speedAbilities.reduce((a, b) => a + b) / speedAbilities.length;
        final otherAvg = otherAbilities.reduce((a, b) => a + b) / otherAbilities.length;
        
        physicalAbility = (
          (speedAvg * 0.5) +
          (otherAvg * 0.5)
        ).round();
      }
      
      // 総合能力値（ポジション別の重み付け）
      int overallAbility;
      if (position == '投手') {
        // 投手: 技術50%、精神30%、身体20%
        overallAbility = (
          (technicalAbility * 0.5) +
          (mentalAbility * 0.3) +
          (physicalAbility * 0.2)
        ).round();
      } else {
        // 野手: 技術40%、精神25%、身体35%
        overallAbility = (
          (technicalAbility * 0.4) +
          (mentalAbility * 0.25) +
          (physicalAbility * 0.35)
        ).round();
      }
      
      // 総合能力値をデータベースに保存
      await db.update('Player', {
        'overall': overallAbility,
        'technical': technicalAbility,
        'physical': physicalAbility,
        'mental': mentalAbility,
      }, where: 'id = ?', whereArgs: [playerId]);
      
      print('選手ID $playerId の総合能力値を更新: overall=$overallAbility, technical=$technicalAbility, physical=$physicalAbility, mental=$mentalAbility');
      
    } catch (e) {
      print('総合能力値指標の計算・更新でエラー: $e');
    }
  }

  /// スカウト分析の総合評価を更新
  Future<void> updateScoutAnalysisOverallEvaluations(int playerId) async {
    try {
      final db = await database;
      
      // スカウト分析データを取得
      final scoutAnalysisData = await db.query(
        'ScoutAnalysis',
        where: 'player_id = ?',
        whereArgs: [playerId],
        orderBy: 'analysis_date DESC',
      );
      
      if (scoutAnalysisData.isEmpty) return;
      
      // 最新のスカウト分析データを使用
      final latestAnalysis = scoutAnalysisData.first;
      
      // 各カテゴリの評価を計算
      final technicalEvaluation = _calculateScoutTechnicalEvaluation(latestAnalysis);
      final physicalEvaluation = _calculateScoutPhysicalEvaluation(latestAnalysis);
      final mentalEvaluation = _calculateScoutMentalEvaluation(latestAnalysis);
      final overallEvaluation = _calculateScoutOverallEvaluation(
        technicalEvaluation, 
        physicalEvaluation, 
        mentalEvaluation,
        latestAnalysis['position'] as String? ?? '投手'
      );
      
      // 最新のスカウト分析データを更新
      await db.update(
        'ScoutAnalysis',
        {
          'overall_evaluation': overallEvaluation,
          'technical_evaluation': technicalEvaluation,
          'physical_evaluation': physicalEvaluation,
          'mental_evaluation': mentalEvaluation,
        },
        where: 'id = ?',
        whereArgs: [latestAnalysis['id']],
      );
      
      print('スカウト分析総合評価を更新: playerId=$playerId, overall=$overallEvaluation, technical=$technicalEvaluation, physical=$physicalEvaluation, mental=$mentalEvaluation');
      
    } catch (e) {
      print('スカウト分析総合評価更新エラー: $e');
    }
  }
  
  /// スカウト分析の技術面評価を計算
  int _calculateScoutTechnicalEvaluation(Map<String, dynamic> analysis) {
    final position = analysis['position'] as String? ?? '投手';
    
    if (position == '投手') {
      final pitchingAbilities = [
        analysis['control_scouted'] as int? ?? 50,
        analysis['fastball_scouted'] as int? ?? 50,
        analysis['breaking_ball_scouted'] as int? ?? 50,
        analysis['pitch_movement_scouted'] as int? ?? 50,
      ];
      final fieldingAbilities = [
        analysis['fielding_scouted'] as int? ?? 50,
        analysis['throwing_scouted'] as int? ?? 50,
      ];
      final battingAbilities = [
        analysis['contact_scouted'] as int? ?? 50,
        analysis['power_scouted'] as int? ?? 50,
        analysis['plate_discipline_scouted'] as int? ?? 50,
        analysis['bunt_scouted'] as int? ?? 50,
      ];
      
      // 投手能力: 投球関連60%、守備関連25%、打撃関連15%
      final pitchingAvg = pitchingAbilities.reduce((a, b) => a + b) / pitchingAbilities.length;
      final fieldingAvg = fieldingAbilities.reduce((a, b) => a + b) / fieldingAbilities.length;
      final battingAvg = battingAbilities.reduce((a, b) => a + b) / battingAbilities.length;
      
      return (
        (pitchingAvg * 0.6) +
        (fieldingAvg * 0.25) +
        (battingAvg * 0.15)
      ).round();
    } else {
      // 野手は打撃・守備関連能力値を重視
      final battingAbilities = [
        analysis['contact_scouted'] as int? ?? 50,
        analysis['power_scouted'] as int? ?? 50,
        analysis['plate_discipline_scouted'] as int? ?? 50,
        analysis['bunt_scouted'] as int? ?? 50,
        analysis['opposite_field_hitting_scouted'] as int? ?? 50,
        analysis['pull_hitting_scouted'] as int? ?? 50,
        analysis['bat_control_scouted'] as int? ?? 50,
        analysis['swing_speed_scouted'] as int? ?? 50,
      ];
      final fieldingAbilities = [
        analysis['fielding_scouted'] as int? ?? 50,
        analysis['throwing_scouted'] as int? ?? 50,
      ];
      
      // 野手能力: 打撃関連70%、守備関連30%
      final battingAvg = battingAbilities.reduce((a, b) => a + b) / battingAbilities.length;
      final fieldingAvg = fieldingAbilities.reduce((a, b) => a + b) / fieldingAbilities.length;
      
      return (
        (battingAvg * 0.7) +
        (fieldingAvg * 0.3)
      ).round();
    }
  }
  
  /// スカウト分析のフィジカル面評価を計算
  int _calculateScoutPhysicalEvaluation(Map<String, dynamic> analysis) {
    final position = analysis['position'] as String? ?? '投手';
    
    if (position == '投手') {
      // 投手は持久力と筋力を重視
      final staminaAbilities = [
        (analysis['stamina_scouted'] as int? ?? 50) * 1.3,
        (analysis['strength_scouted'] as int? ?? 50) * 1.2,
        (analysis['natural_fitness_scouted'] as int? ?? 50) * 1.1,
      ];
      final otherAbilities = [
        analysis['agility_scouted'] as int? ?? 50,
        analysis['balance_scouted'] as int? ?? 50,
        analysis['jumping_reach_scouted'] as int? ?? 50,
        analysis['injury_proneness_scouted'] as int? ?? 50,
        analysis['pace_scouted'] as int? ?? 50,
        analysis['flexibility_scouted'] as int? ?? 50,
      ];
      
      final staminaAvg = staminaAbilities.reduce((a, b) => a + b) / staminaAbilities.length;
      final otherAvg = otherAbilities.reduce((a, b) => a + b) / otherAbilities.length;
      
      return (
        (staminaAvg * 0.6) +
        (otherAvg * 0.4)
      ).round();
    } else {
      // 野手は敏捷性と加速力を重視
      final speedAbilities = [
        (analysis['agility_scouted'] as int? ?? 50) * 1.2,
        (analysis['acceleration_scouted'] as int? ?? 50) * 1.2,
      ];
      final otherAbilities = [
        analysis['balance_scouted'] as int? ?? 50,
        analysis['jumping_reach_scouted'] as int? ?? 50,
        analysis['natural_fitness_scouted'] as int? ?? 50,
        analysis['injury_proneness_scouted'] as int? ?? 50,
        analysis['stamina_scouted'] as int? ?? 50,
        analysis['strength_scouted'] as int? ?? 50,
        analysis['pace_scouted'] as int? ?? 50,
        analysis['flexibility_scouted'] as int? ?? 50,
      ];
      
      final speedAvg = speedAbilities.reduce((a, b) => a + b) / speedAbilities.length;
      final otherAvg = otherAbilities.reduce((a, b) => a + b) / otherAbilities.length;
      
      return (
        (speedAvg * 0.5) +
        (otherAvg * 0.5)
      ).round();
    }
  }
  
  /// スカウト分析のメンタル面評価を計算
  int _calculateScoutMentalEvaluation(Map<String, dynamic> analysis) {
    final mentalAbilities = [
      (analysis['concentration_scouted'] as int? ?? 50) * 1.2,
      (analysis['anticipation_scouted'] as int? ?? 50) * 1.1,
      (analysis['vision_scouted'] as int? ?? 50) * 1.1,
      (analysis['composure_scouted'] as int? ?? 50) * 1.2,
      (analysis['aggression_scouted'] as int? ?? 50) * 1.0,
      (analysis['bravery_scouted'] as int? ?? 50) * 1.0,
      (analysis['leadership_scouted'] as int? ?? 50) * 1.1,
      (analysis['work_rate_scouted'] as int? ?? 50) * 1.2,
      (analysis['self_discipline_scouted'] as int? ?? 50) * 1.1,
      (analysis['ambition_scouted'] as int? ?? 50) * 1.0,
      (analysis['teamwork_scouted'] as int? ?? 50) * 1.1,
      (analysis['positioning_scouted'] as int? ?? 50) * 1.0,
      (analysis['pressure_handling_scouted'] as int? ?? 50) * 1.2,
      (analysis['clutch_ability_scouted'] as int? ?? 50) * 1.2,
      // 追加された能力値（重複のため削除）
      // (analysis['motivation_scouted'] as int? ?? 50) * 1.1,
      // (analysis['pressure_scouted'] as int? ?? 50) * 1.0,
      // (analysis['adaptability_scouted'] as int? ?? 50) * 1.1,
      // (analysis['consistency_scouted'] as int? ?? 50) * 1.1,
      // (analysis['clutch_scouted'] as int? ?? 50) * 1.2,
      // (analysis['work_ethic_scouted'] as int? ?? 50) * 1.2,
    ];
    
    return (mentalAbilities.reduce((a, b) => a + b) / mentalAbilities.length).round();
  }
  
  /// スカウト分析の総合評価を計算
  int _calculateScoutOverallEvaluation(int technicalEvaluation, int physicalEvaluation, int mentalEvaluation, String position) {
    if (position == '投手') {
      // 投手: 技術50%、精神30%、身体20%
      return ((technicalEvaluation * 0.5) + (mentalEvaluation * 0.3) + (physicalEvaluation * 0.2)).round();
    } else {
      // 野手: 技術40%、精神25%、身体35%
      return ((technicalEvaluation * 0.4) + (mentalEvaluation * 0.25) + (physicalEvaluation * 0.35)).round();
    }
  }

  // 年齢に基づくピーク能力計算（高校生と同じロジック）
  int _calculatePeakAbilityByAge(int talent, int age) {
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

  /// プロ選手の能力値を生成（peak_abilityを基準とした95%前後）
  int _generateProPlayerAbility(int targetAbility, int peakAbility, Random random) {
    // targetAbility（peak_abilityの95%）を中心とした変動
    final variation = random.nextInt(21) - 10; // -10 から +10 の変動
    final ability = targetAbility + variation;
    
    // 上限はpeak_ability + 10、下限はtargetAbility - 15
    final maxAbility = peakAbility + 10;
    final minAbility = (targetAbility - 15).clamp(0, targetAbility);
    
    return ability.clamp(minAbility, maxAbility);
  }

  /// プロ選手のポテンシャルを生成（peak_abilityを基準とした上限+15）
  int _generateProPlayerPotential(int peakAbility, Random random) {
    // peak_abilityを中心とした変動
    final variation = random.nextInt(21) - 10; // -10 から +10 の変動
    final potential = peakAbility + variation;
    
    // 上限はpeak_ability + 15、下限はpeak_ability - 10
    final maxPotential = peakAbility + 15;
    final minPotential = (peakAbility - 10).clamp(0, peakAbility);
    
    return potential.clamp(minPotential, maxPotential);
  }

  /// 既存選手の注目選手フラグを再計算して設定（マイグレーション用）
  Future<void> _updateExistingPlayersPubliclyKnown(Database db) async {
    try {
      print('既存選手の注目選手フラグを再計算中...');
      
      // 全選手を取得
      final players = await db.query('Player');
      int updatedCount = 0;
      
      for (final player in players) {
        final fame = player['fame'] as int? ?? 0;
        final talent = player['talent'] as int? ?? 1;
        final grade = player['grade'] as int? ?? 1;
        
        // 注目選手判定ロジック（PlayerDataGeneratorと同じ）
        bool shouldBePubliclyKnown = false;
        
        // 基本条件: 知名度65以上または才能6以上
        if (fame >= 65 || talent >= 6) {
          shouldBePubliclyKnown = true;
        }
        // 3年生で知名度55以上なら注目選手（進路注目）
        else if (grade == 3 && fame >= 55) {
          shouldBePubliclyKnown = true;
        }
        // 才能5で知名度50以上なら注目選手
        else if (talent >= 5 && fame >= 50) {
          shouldBePubliclyKnown = true;
        }
        
        // 注目選手フラグを更新（注目選手でない場合も明示的に0を設定）
        await db.update(
          'Player',
          {'is_famous': shouldBePubliclyKnown ? 1 : 0},
          where: 'id = ?',
          whereArgs: [player['id']],
        );
        
        if (shouldBePubliclyKnown) {
          updatedCount++;
        }
      }
      
      print('注目選手フラグ再計算完了: ${updatedCount}人が注目選手に設定されました');
    } catch (e) {
      print('注目選手フラグ再計算エラー: $e');
    }
  }

  /// 既存選手の年齢を学年から計算して設定（マイグレーション用）
  Future<void> _updateExistingPlayersAge(Database db) async {
    try {
      print('既存選手の年齢を学年から計算中...');
      
      // 全選手を取得
      final players = await db.query('Player');
      int updatedCount = 0;
      
      for (final player in players) {
        final grade = player['grade'] as int? ?? 1;
        final age = 15 + (grade - 1); // 1年生=15歳、2年生=16歳、3年生=17歳
        
        await db.update(
          'Player',
          {'age': age},
          where: 'id = ?',
          whereArgs: [player['id']],
        );
        
        updatedCount++;
      }
      
      print('年齢更新完了: ${updatedCount}人の年齢を更新しました');
    } catch (e) {
      print('年齢更新エラー: $e');
    }
  }

  /// 全選手の総合能力値指標を再計算（成長期などで使用）
  Future<void> recalculateAllPlayerAbilities() async {
    try {
      print('全選手の総合能力値指標を再計算中...');
      
      final db = await database;
      final players = await db.query('Player');
      int updatedCount = 0;
      
      for (final player in players) {
        final playerId = player['id'] as int;
        await _updatePlayerOverallAbilities(db, playerId);
        updatedCount++;
      }
      
      print('総合能力値指標再計算完了: ${updatedCount}人の選手を更新しました');
    } catch (e) {
      print('総合能力値指標再計算エラー: $e');
    }
  }

  /// 既存選手の引退判定を実行（マイグレーション用）
  Future<void> _updateExistingPlayersRetirementStatus(Database db) async {
    try {
      print('既存選手の引退判定を実行中...');
      
      // 全選手を取得
      final players = await db.query('Player');
      int retiredCount = 0;
      
      for (final player in players) {
        final age = player['age'] as int? ?? 15;
        final grade = player['grade'] as int? ?? 1;
        
        // 高校卒業後（18歳以上）で引退判定
        if (age > 17) {
          // 簡単な引退判定（年齢ベース）
          bool shouldRetire = false;
          
          if (age >= 40) {
            shouldRetire = true; // 40歳以上で強制引退
          } else if (age >= 35) {
            shouldRetire = Random().nextBool(); // 35歳以上で50%の確率で引退
          } else if (age >= 30) {
            shouldRetire = Random().nextInt(10) < 3; // 30歳以上で30%の確率で引退
          }
          
          if (shouldRetire) {
            await db.update(
              'Player',
              {
                'is_retired': 1,
                'retired_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [player['id']],
            );
            retiredCount++;
          }
        }
      }
      
      print('引退判定完了: ${retiredCount}人が引退しました');
    } catch (e) {
      print('引退判定エラー: $e');
    }
  }

  /// プロ選手の総合ポテンシャル値を計算（ポジション別重み付け）
  int _calculateProfessionalOverallPotential(int peakAbility, String position, Random random) {
    // 基本ポテンシャル値を計算
    final technicalPotential = _calculateProfessionalTechnicalPotential(peakAbility, random);
    final mentalPotential = _calculateProfessionalMentalPotential(peakAbility, random);
    final physicalPotential = _calculateProfessionalPhysicalPotential(peakAbility, random);
    
    // ポジション別の重み付けを適用
    if (position == '投手') {
      // 投手: 技術50%、精神30%、身体20%
      return ((technicalPotential * 0.5) + (mentalPotential * 0.3) + (physicalPotential * 0.2)).round();
    } else {
      // 野手: 技術40%、精神25%、身体35%
      return ((technicalPotential * 0.4) + (mentalPotential * 0.25) + (physicalPotential * 0.35)).round();
    }
  }

  /// プロ選手の技術面ポテンシャル値を計算
  int _calculateProfessionalTechnicalPotential(int peakAbility, Random random) {
    // 技術面ポテンシャルは個別能力値の平均
    // 各能力値のポテンシャルはpeak_ability + 0-15の範囲
    final technicalAbilities = [
      peakAbility + random.nextInt(16), // contact
      peakAbility + random.nextInt(16), // power
      peakAbility + random.nextInt(16), // plate_discipline
      peakAbility + random.nextInt(16), // bunt
      peakAbility + random.nextInt(16), // opposite_field_hitting
      peakAbility + random.nextInt(16), // pull_hitting
      peakAbility + random.nextInt(16), // bat_control
      peakAbility + random.nextInt(16), // swing_speed
      peakAbility + random.nextInt(16), // fielding
      peakAbility + random.nextInt(16), // throwing
      peakAbility + random.nextInt(16), // catcher_ability
      peakAbility + random.nextInt(16), // control
      peakAbility + random.nextInt(16), // fastball
      peakAbility + random.nextInt(16), // breaking_ball
      peakAbility + random.nextInt(16), // pitch_movement
    ];
    
    final total = technicalAbilities.reduce((a, b) => a + b);
    return total ~/ technicalAbilities.length;
  }

  /// プロ選手のメンタル面ポテンシャル値を計算
  int _calculateProfessionalMentalPotential(int peakAbility, Random random) {
    // メンタル面ポテンシャルは個別能力値の平均
    // 各能力値のポテンシャルはpeak_ability + 0-15の範囲
    final mentalAbilities = [
      peakAbility + random.nextInt(16), // concentration
      peakAbility + random.nextInt(16), // anticipation
      peakAbility + random.nextInt(16), // vision
      peakAbility + random.nextInt(16), // composure
      peakAbility + random.nextInt(16), // aggression
      peakAbility + random.nextInt(16), // bravery
      peakAbility + random.nextInt(16), // leadership
      peakAbility + random.nextInt(16), // work_rate
      peakAbility + random.nextInt(16), // self_discipline
      peakAbility + random.nextInt(16), // ambition
      peakAbility + random.nextInt(16), // teamwork
      peakAbility + random.nextInt(16), // positioning
      peakAbility + random.nextInt(16), // pressure_handling
      peakAbility + random.nextInt(16), // clutch_ability
    ];
    
    final total = mentalAbilities.reduce((a, b) => a + b);
    return total ~/ mentalAbilities.length;
  }

  /// プロ選手のフィジカル面ポテンシャル値を計算
  int _calculateProfessionalPhysicalPotential(int peakAbility, Random random) {
    // フィジカル面ポテンシャルは個別能力値の平均
    // 各能力値のポテンシャルはpeak_ability + 0-15の範囲
    final physicalAbilities = [
      peakAbility + random.nextInt(16), // acceleration
      peakAbility + random.nextInt(16), // agility
      peakAbility + random.nextInt(16), // balance
      peakAbility + random.nextInt(16), // jumping_reach
      peakAbility + random.nextInt(16), // natural_fitness
      peakAbility + random.nextInt(16), // injury_proneness
      peakAbility + random.nextInt(16), // stamina
      peakAbility + random.nextInt(16), // strength
      peakAbility + random.nextInt(16), // pace
      peakAbility + random.nextInt(16), // flexibility
    ];
    
    final total = physicalAbilities.reduce((a, b) => a + b);
    return total ~/ physicalAbilities.length;
  }

  /// ゲームデータをデータベースに直接保存（メモリ使用量削減）
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
      
      print('ゲームデータをデータベースに直接保存しました');
    } catch (e) {
      print('データベース保存エラー: $e');
      rethrow;
    }
  }
  
  /// ゲーム基本情報を保存
  Future<void> _saveGameBasicInfo(Transaction txn, Map<String, dynamic> data) async {
    // GameInfoテーブルに保存
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
  
  /// 学校データをバッチ処理で保存（最適化版）
  Future<void> _saveSchoolsInBatches(Transaction txn, List schools) async {
    const batchSize = 1000; // バッチサイズを最適化（50 → 1000）
    
    for (int i = 0; i < schools.length; i += batchSize) {
      final end = (i + batchSize < schools.length) ? i + batchSize : schools.length;
      final batch = schools.sublist(i, end);
      
      // 学校情報を保存
      for (final schoolData in batch) {
        final school = Map<String, dynamic>.from(schoolData);
        final schoolId = await _saveSchoolInfo(txn, school);
        
        // 選手データを保存（詳細情報は除外）
        if (school['players'] != null) {
          await _saveSchoolPlayersInBatches(txn, school['players'] as List, schoolId);
        }
      }
      
      // バッチ処理後にメモリを解放
      print('学校データバッチ処理完了: ${i + 1}-$end / ${schools.length}');
    }
  }
  
  /// 学校情報を保存
  Future<int> _saveSchoolInfo(Transaction txn, Map<String, dynamic> school) async {
    final schoolId = await txn.insert('School', {
      'name': school['name'] ?? '',
      'type': school['type'] ?? 'high_school',
      'region': school['region'] ?? '',
      'level': school['level'] ?? 1,
      'reputation': school['reputation'] ?? 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    
    return schoolId;
  }
  
  /// 学校の選手データをバッチ処理で保存（最適化版）
  Future<void> _saveSchoolPlayersInBatches(Transaction txn, List players, int schoolId) async {
    const batchSize = 5000; // バッチサイズを最適化（100 → 5000）
    
    for (int i = 0; i < players.length; i += batchSize) {
      final end = (i + batchSize < players.length) ? i + batchSize : players.length;
      final batch = players.sublist(i, end);
      
      for (final playerData in batch) {
        final player = Map<String, dynamic>.from(playerData);
        
        // 必要最小限の情報のみ保存
        await txn.insert('Player', {
          'id': player['id'],
          'name': player['name'] ?? '',
          'position': player['position'] ?? '',
          'age': player['age'] ?? 0,
          'grade': player['grade'] ?? 1,
          'isGraduated': player['isGraduated'] ?? false ? 1 : 0,
          'isRetired': player['isRetired'] ?? false ? 1 : 0,
          'school': schoolId,
          'fame': player['fame'] ?? 0,
          'growth_rate': player['growth_rate'] ?? 0,
          'talent': player['talent'] ?? 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      // バッチ処理後にメモリを解放
      print('選手データバッチ処理完了: ${i + 1}-$end / ${players.length}');
    }
  }
  
  /// 発掘選手IDリストをバッチ処理で保存（最適化版）
  Future<void> _saveDiscoveredPlayerIdsInBatches(Transaction txn, List<int> playerIds) async {
    const batchSize = 5000; // バッチサイズを最適化（100 → 5000）
    
    for (int i = 0; i < playerIds.length; i += batchSize) {
      final end = (i + batchSize < playerIds.length) ? i + batchSize : playerIds.length;
      final batch = playerIds.sublist(i, end);
      
      for (final playerId in batch) {
        await txn.insert('DiscoveredPlayer', {
          'player_id': playerId,
          'discovered_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('発掘選手IDリストバッチ処理完了: ${i + 1}-$end / ${playerIds.length}');
    }
  }

  /// 注目選手IDリストをバッチ処理で保存（最適化版）
  Future<void> _saveWatchedPlayerIdsInBatches(Transaction txn, List<int> playerIds) async {
    const batchSize = 5000; // バッチサイズを最適化（100 → 5000）
    
    for (int i = 0; i < playerIds.length; i += batchSize) {
      final end = (i + batchSize < playerIds.length) ? i + batchSize : playerIds.length;
      final batch = playerIds.sublist(i, end);
      
      for (final playerId in batch) {
        await txn.insert('WatchedPlayer', {
          'player_id': playerId,
          'watched_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('注目選手IDリストバッチ処理完了: ${i + 1}-$end / ${playerIds.length}');
    }
  }

  /// お気に入り選手IDリストをバッチ処理で保存（最適化版）
  Future<void> _saveFavoritePlayerIdsInBatches(Transaction txn, List<int> playerIds) async {
    const batchSize = 5000; // バッチサイズを最適化（100 → 5000）
    
    for (int i = 0; i < playerIds.length; i += batchSize) {
      final end = (i + batchSize < playerIds.length) ? i + batchSize : playerIds.length;
      final batch = playerIds.sublist(i, end);
      
      for (final playerId in batch) {
        await txn.insert('FavoritePlayer', {
          'player_id': playerId,
          'favorited_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      print('お気に入り選手IDリストバッチ処理完了: ${i + 1}-$end / ${playerIds.length}');
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
      
      // プロ選手データも保存
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



} 