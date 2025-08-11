import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io'; // Added for File

class DataService {
  static const String saveKey = 'scout_game_save';
  static const String autoSaveKey = 'scout_game_autosave';

  static Database? _db;

  String _currentSlot = 'セーブ1'; // デフォルト
  set currentSlot(String slot) {
    _currentSlot = slot;
    _db = null; // スロット切り替え時にキャッシュクリア
  }
  String get currentSlot => _currentSlot;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await getDatabaseWithSlot(_currentSlot);
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scout_game.db');
    return await openDatabase(
      path,
      version: 9,
      onCreate: (db, version) async {
        // 既存のテーブル作成処理を流用
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // 新しい能力値システムのカラムを追加
          await _addNewAbilityColumns(db);
          await _addNewPotentialColumns(db);
        }
        if (oldVersion < 3) {
          // バージョン3では新しいスキーマを使用するため、データベースファイルを削除して再作成
          // 既存のデータは失われますが、新しいスキーマで正しく動作します
          print('データベーススキーマを更新中...');
        }
        if (oldVersion < 4) {
          // バージョン4ではスキーマを更新
          print('データベーススキーマを更新中（バージョン4）...');
        }
        if (oldVersion < 9) {
          // バージョン9: is_publicly_knownフィールドを追加
          print('データベーススキーマを更新中（バージョン9）: is_publicly_knownフィールドを追加...');
          try {
            await db.execute('ALTER TABLE Player ADD COLUMN is_publicly_known INTEGER DEFAULT 0');
            print('is_publicly_knownフィールドの追加完了');
            
            // 既存選手の注目選手フラグを再計算して設定
            await _updateExistingPlayersPubliclyKnown(db);
          } catch (e) {
            print('is_publicly_knownフィールド追加エラー: $e');
          }
        }
        if (oldVersion < 5) {
          // バージョン5では強制的に新しいスキーマで再作成
          print('データベーススキーマを強制更新中（バージョン5）...');
          // 既存のテーブルを削除して再作成
          await db.execute('DROP TABLE IF EXISTS Player');
          await db.execute('DROP TABLE IF EXISTS PlayerPotentials');
          await db.execute('DROP TABLE IF EXISTS Person');
          await _createAllTables(db);
        }
        if (oldVersion < 6) {
          // バージョン6では新しい能力値（natural_fitness, injury_proneness）を含むスキーマで再作成
          print('データベーススキーマを強制更新中（バージョン6）...');
          // 既存のテーブルを削除して再作成
          await db.execute('DROP TABLE IF EXISTS Player');
          await db.execute('DROP TABLE IF EXISTS PlayerPotentials');
          await db.execute('DROP TABLE IF EXISTS Person');
          await _createAllTables(db);
        }
        if (oldVersion < 7) {
          // バージョン7では新しいポテンシャル生成を含むスキーマで再作成
          print('データベーススキーマを強制更新中（バージョン7）...');
          // 既存のテーブルを削除して再作成
          await db.execute('DROP TABLE IF EXISTS Player');
          await db.execute('DROP TABLE IF EXISTS PlayerPotentials');
          await db.execute('DROP TABLE IF EXISTS Person');
          await _createAllTables(db);
        }
        if (oldVersion < 8) {
          // バージョン8ではfameカラムとスカウト分析データを含むスキーマで再作成
          print('データベーススキーマを強制更新中（バージョン8）...');
          // 既存のテーブルを削除して再作成
          await db.execute('DROP TABLE IF EXISTS Player');
          await db.execute('DROP TABLE IF EXISTS PlayerPotentials');
          await db.execute('DROP TABLE IF EXISTS Person');
          await db.execute('DROP TABLE IF EXISTS ScoutAnalysis');
          await _createAllTables(db);
        }
      },
    );
  }

  // 能力値システムのカラムを追加
  Future<void> _addNewAbilityColumns(Database db) async {
    // Technical abilities
    await db.execute('ALTER TABLE Player ADD COLUMN contact INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN power INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN plate_discipline INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN bunt INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN opposite_field_hitting INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN pull_hitting INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN bat_control INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN swing_speed INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN fielding INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN throwing INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN catcher_ability INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN control INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN fastball INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN breaking_ball INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN pitch_movement INTEGER DEFAULT 25');
    
    // Mental abilities
    await db.execute('ALTER TABLE Player ADD COLUMN concentration INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN anticipation INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN vision INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN composure INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN aggression INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN bravery INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN leadership INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN work_rate INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN self_discipline INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN ambition INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN teamwork INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN positioning INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN pressure_handling INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN clutch_ability INTEGER DEFAULT 25');
    
    // Physical abilities
    await db.execute('ALTER TABLE Player ADD COLUMN acceleration INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN agility INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN balance INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN jumping_reach INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN natural_fitness INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN injury_proneness INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN stamina INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN strength INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN pace INTEGER DEFAULT 25');
    await db.execute('ALTER TABLE Player ADD COLUMN flexibility INTEGER DEFAULT 25');
  }

  // ポテンシャルシステムのカラムを追加
  Future<void> _addNewPotentialColumns(Database db) async {
    // Technical potentials
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN contact_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN power_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN plate_discipline_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN bunt_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN opposite_field_hitting_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN pull_hitting_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN bat_control_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN swing_speed_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN fielding_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN throwing_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN catcher_ability_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN control_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN fastball_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN breaking_ball_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN pitch_movement_potential INTEGER DEFAULT 50');
    
    // Mental potentials
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN concentration_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN anticipation_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN vision_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN composure_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN aggression_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN bravery_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN leadership_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN work_rate_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN self_discipline_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN ambition_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN teamwork_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN positioning_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN pressure_handling_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN clutch_ability_potential INTEGER DEFAULT 50');
    
    // Physical potentials
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN acceleration_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN agility_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN balance_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN jumping_reach_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN natural_fitness_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN injury_proneness_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN stamina_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN strength_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN pace_potential INTEGER DEFAULT 50');
    await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN flexibility_potential INTEGER DEFAULT 50');
  }

  String _slotKey(dynamic slot) {
    if (slot == 'autosave') return autoSaveKey;
    return 'scout_game_save_$slot';
  }

  Future<void> saveGameDataToSlot(Map<String, dynamic> data, dynamic slot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_slotKey(slot), jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadGameDataFromSlot(dynamic slot) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_slotKey(slot));
    if (jsonString == null) return null;
    return jsonDecode(jsonString);
  }

  Future<bool> hasGameDataInSlot(dynamic slot) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_slotKey(slot));
  }

  Future<void> saveAutoGameData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(autoSaveKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadAutoGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(autoSaveKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString);
  }

  Future<void> insertInitialData() async {
    final db = await database;
    // 既にデータが存在する場合はスキップ
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Organization')) ?? 0;
    if (count > 0) return;
    
    // サンプルデータは削除（実際の選手生成はGameManagerで行う）
    // 組織（神奈川県の高校）
    final schoolIds = <int>[];
    final schools = [
      {'name': '横浜工業高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 80, 'last_year_strength': 75, 'scouting_popularity': 70},
      {'name': '川崎商業高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 75, 'last_year_strength': 70, 'scouting_popularity': 65},
      {'name': '湘南学園', 'type': '高校', 'location': '神奈川県', 'school_strength': 85, 'last_year_strength': 80, 'scouting_popularity': 80},
      {'name': '相模原高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 70, 'last_year_strength': 68, 'scouting_popularity': 60},
      {'name': '横浜東高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 78, 'last_year_strength': 74, 'scouting_popularity': 68},
      {'name': '横浜西高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 77, 'last_year_strength': 73, 'scouting_popularity': 67},
      {'name': '横浜南高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 76, 'last_year_strength': 72, 'scouting_popularity': 66},
      {'name': '横浜北高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 79, 'last_year_strength': 75, 'scouting_popularity': 69},
      {'name': '鎌倉工業高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 74, 'last_year_strength': 70, 'scouting_popularity': 65},
      {'name': '藤沢商業高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 73, 'last_year_strength': 69, 'scouting_popularity': 64},
      {'name': '厚木学園', 'type': '高校', 'location': '神奈川県', 'school_strength': 82, 'last_year_strength': 78, 'scouting_popularity': 72},
      {'name': '平塚高校', 'type': '高校', 'location': '神奈川県', 'school_strength': 71, 'last_year_strength': 67, 'scouting_popularity': 63},
    ];
    for (final school in schools) {
      final id = await db.insert('Organization', school);
      schoolIds.add(id);
    }
  }

  // スロットごとにDBファイル名を切り替える
  Future<Database> getDatabaseWithSlot(String slot) async {
    final dbPath = await getDatabasesPath();
    final dbName = slot == 'オートセーブ' ? 'autosave.db' : 'save${_slotNumber(slot)}.db';
    final path = join(dbPath, dbName);
    return await openDatabase(
      path,
      version: 7, // バージョンを7に更新
      onCreate: (db, version) async {
        // 既存のテーブル作成処理を流用
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // ポテンシャルカラムを追加
          await _addNewPotentialColumns(db);
        }
        if (oldVersion < 7) {
          // バージョン7では新しいポテンシャル生成を含むスキーマで再作成
          print('データベーススキーマを強制更新中（バージョン7）...');
          // 既存のテーブルを削除して再作成
          await db.execute('DROP TABLE IF EXISTS Player');
          await db.execute('DROP TABLE IF EXISTS PlayerPotentials');
          await db.execute('DROP TABLE IF EXISTS Person');
          await _createAllTables(db);
        }
      },
    );
  }
  
  // スロット用DBファイルを削除
  Future<void> deleteDatabaseWithSlot(String slot) async {
    final dbPath = await getDatabasesPath();
    final dbName = slot == 'オートセーブ' ? 'autosave.db' : 'save${_slotNumber(slot)}.db';
    final path = join(dbPath, dbName);
    await deleteDatabaseAtPath(path);
    print('DB削除: $path, exists= ${await File(path).exists()}');
  }

  // データベースファイルを削除（新しいスキーマで再作成するため）
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'scout_game.db');
    await deleteDatabaseAtPath(path);
  }

  // 指定されたパスのデータベースファイルを削除
  Future<void> deleteDatabaseAtPath(String path) async {
    await databaseFactory.deleteDatabase(path);
    print('データベースファイルを削除しました: $path');
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

  // テーブル作成処理を共通化
  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE Person (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        birth_date TEXT,
        gender TEXT,
        hometown TEXT,
        personality TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE Player (
        id INTEGER PRIMARY KEY,
        school_id INTEGER,
        grade INTEGER,
        position TEXT,
        fame INTEGER,
        is_publicly_known INTEGER DEFAULT 0,
        growth_rate REAL,
        talent INTEGER,
        growth_type TEXT,
        mental_grit REAL,
        peak_ability INTEGER,
        -- Technical（技術面）能力値
        contact INTEGER,
        power INTEGER,
        plate_discipline INTEGER,
        bunt INTEGER,
        opposite_field_hitting INTEGER,
        pull_hitting INTEGER,
        bat_control INTEGER,
        swing_speed INTEGER,
        fielding INTEGER,
        throwing INTEGER,
        catcher_ability INTEGER,
        control INTEGER,
        fastball INTEGER,
        breaking_ball INTEGER,
        pitch_movement INTEGER,
        -- Mental（メンタル面）能力値
        concentration INTEGER,
        anticipation INTEGER,
        vision INTEGER,
        composure INTEGER,
        aggression INTEGER,
        bravery INTEGER,
        leadership INTEGER,
        work_rate INTEGER,
        self_discipline INTEGER,
        ambition INTEGER,
        teamwork INTEGER,
        positioning INTEGER,
        pressure_handling INTEGER,
        clutch_ability INTEGER,
        -- Physical（フィジカル面）能力値
        acceleration INTEGER,
        agility INTEGER,
        balance INTEGER,
        jumping_reach INTEGER,
        natural_fitness INTEGER,
        injury_proneness INTEGER,
        stamina INTEGER,
        strength INTEGER,
        pace INTEGER,
        flexibility INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE PlayerPotentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        -- Technical（技術面）ポテンシャル
        contact_potential INTEGER,
        power_potential INTEGER,
        plate_discipline_potential INTEGER,
        bunt_potential INTEGER,
        opposite_field_hitting_potential INTEGER,
        pull_hitting_potential INTEGER,
        bat_control_potential INTEGER,
        swing_speed_potential INTEGER,
        fielding_potential INTEGER,
        throwing_potential INTEGER,
        catcher_ability_potential INTEGER,
        control_potential INTEGER,
        fastball_potential INTEGER,
        breaking_ball_potential INTEGER,
        pitch_movement_potential INTEGER,
        -- Mental（メンタル面）ポテンシャル
        concentration_potential INTEGER,
        anticipation_potential INTEGER,
        vision_potential INTEGER,
        composure_potential INTEGER,
        aggression_potential INTEGER,
        bravery_potential INTEGER,
        leadership_potential INTEGER,
        work_rate_potential INTEGER,
        self_discipline_potential INTEGER,
        ambition_potential INTEGER,
        teamwork_potential INTEGER,
        positioning_potential INTEGER,
        pressure_handling_potential INTEGER,
        clutch_ability_potential INTEGER,
        -- Physical（フィジカル面）ポテンシャル
        acceleration_potential INTEGER,
        agility_potential INTEGER,
        balance_potential INTEGER,
        jumping_reach_potential INTEGER,
        natural_fitness_potential INTEGER,
        injury_proneness_potential INTEGER,
        stamina_potential INTEGER,
        strength_potential INTEGER,
        pace_potential INTEGER,
        flexibility_potential INTEGER,
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE Coach (
        id INTEGER PRIMARY KEY,
        team_id INTEGER,
        trust INTEGER,
        leadership INTEGER,
        strategy INTEGER,
        training_skill INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE Scout (
        id INTEGER PRIMARY KEY,
        organization_id INTEGER,
        scout_skill INTEGER,
        negotiation INTEGER,
        network INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE Career (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id INTEGER,
        role TEXT,
        organization_id INTEGER,
        start_year INTEGER,
        end_year INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE Organization (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT,
        location TEXT,
        school_strength INTEGER,
        last_year_strength INTEGER,
        scouting_popularity INTEGER
      )
    ''');
    
    // スカウト分析の仮の値を保存するテーブル
    await db.execute('''
      CREATE TABLE ScoutAnalysis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        scout_id TEXT,
        analysis_date TEXT,
        accuracy REAL,
        -- Technical（技術面）仮の能力値
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
        -- Mental（メンタル面）仮の能力値
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
        -- Physical（フィジカル面）仮の能力値
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
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');
    
    // 基本情報のスカウト分析結果を保存するテーブル
    await db.execute('''
      CREATE TABLE ScoutBasicInfoAnalysis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        scout_id TEXT,
        analysis_date TEXT,
        accuracy REAL,
        -- 基本情報の分析結果
        personality_analyzed TEXT,
        talent_analyzed TEXT,
        growth_analyzed TEXT,
        mental_grit_analyzed TEXT,
        potential_analyzed TEXT,
        -- 分析精度（各要素別）
        personality_accuracy REAL,
        talent_accuracy REAL,
        growth_accuracy REAL,
        mental_grit_accuracy REAL,
        potential_accuracy REAL,
        FOREIGN KEY (player_id) REFERENCES Player (id)
      )
    ''');
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
          {'is_publicly_known': shouldBePubliclyKnown ? 1 : 0},
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
} 