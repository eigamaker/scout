import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io'; // Added for File
import 'dart:math'; // Added for Random

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
              version: 20, // バージョンを20に更新
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
        if (oldVersion < 10) {
          // バージョン10: is_scout_favoriteフィールドを追加
          print('データベーススキーマを更新中（バージョン10）: is_scout_favoriteフィールドを追加...');
          try {
            await db.execute('ALTER TABLE Player ADD COLUMN is_scout_favorite INTEGER DEFAULT 0');
            print('is_scout_favoriteフィールドの追加完了');
          } catch (e) {
            print('is_scout_favoriteフィールド追加エラー: $e');
          }
        }
        if (oldVersion < 11) {
          // バージョン11: 卒業フラグ関連フィールドを追加
          print('データベーススキーマを更新中（バージョン11）: 卒業フラグ関連フィールドを追加...');
          try {
            await db.execute('ALTER TABLE Player ADD COLUMN is_graduated INTEGER DEFAULT 0');
            await db.execute('ALTER TABLE Player ADD COLUMN graduated_at TEXT');
            print('卒業フラグ関連フィールドの追加完了');
          } catch (e) {
            print('卒業フラグ関連フィールド追加エラー: $e');
          }
        }
        if (oldVersion < 12) {
          // バージョン12: 卒業フラグ関連フィールドの再確認
          print('データベーススキーマを更新中（バージョン12）: 卒業フラグ関連フィールドの再確認...');
          try {
            // 既存のカラムが存在するかチェック
            final tableInfo = await db.rawQuery('PRAGMA table_info(Player)');
            final columnNames = tableInfo.map((col) => col['name'] as String).toList();
            
            if (!columnNames.contains('is_graduated')) {
              await db.execute('ALTER TABLE Player ADD COLUMN is_graduated INTEGER DEFAULT 0');
              print('is_graduatedカラムを追加しました');
            }
            
            if (!columnNames.contains('graduated_at')) {
              await db.execute('ALTER TABLE Player ADD COLUMN graduated_at TEXT');
              print('graduated_atカラムを追加しました');
            }
            
            print('卒業フラグ関連フィールドの確認完了');
          } catch (e) {
            print('卒業フラグ関連フィールド確認エラー: $e');
          }
        }
        if (oldVersion < 13) {
          // バージョン13: 関連テーブルに卒業フラグを追加
          print('データベーススキーマを更新中（バージョン13）: 関連テーブルに卒業フラグを追加...');
          try {
            // PlayerPotentialsテーブルに卒業フラグを追加
            try {
              await db.execute('ALTER TABLE PlayerPotentials ADD COLUMN is_graduated INTEGER DEFAULT 0');
              print('PlayerPotentialsテーブルにis_graduatedカラムを追加しました');
            } catch (e) {
              print('PlayerPotentialsテーブルのis_graduatedカラム追加エラー: $e');
            }
            
            // ScoutAnalysisテーブルに卒業フラグを追加
            try {
              await db.execute('ALTER TABLE ScoutAnalysis ADD COLUMN is_graduated INTEGER DEFAULT 0');
              print('ScoutAnalysisテーブルにis_graduatedカラムを追加しました');
            } catch (e) {
              print('ScoutAnalysisテーブルのis_graduatedカラム追加エラー: $e');
            }
            
            // ScoutBasicInfoAnalysisテーブルに卒業フラグを追加
            try {
              await db.execute('ALTER TABLE ScoutBasicInfoAnalysis ADD COLUMN is_graduated INTEGER DEFAULT 0');
              print('ScoutBasicInfoAnalysisテーブルにis_graduatedカラムを追加しました');
            } catch (e) {
              print('ScoutBasicInfoAnalysisテーブルのis_graduatedカラム追加エラー: $e');
            }
            
            print('関連テーブルへの卒業フラグ追加完了');
          } catch (e) {
            print('関連テーブルへの卒業フラグ追加エラー: $e');
          }
        }
        if (oldVersion < 14) {
          // バージョン14: 年齢カラムを追加
          print('データベーススキーマを更新中（バージョン14）: 年齢カラムを追加...');
          try {
            await db.execute('ALTER TABLE Player ADD COLUMN age INTEGER DEFAULT 15');
            print('年齢カラムの追加完了');
            
            // 既存選手の年齢を学年から計算して設定
            await _updateExistingPlayersAge(db);
          } catch (e) {
            print('年齢カラム追加エラー: $e');
          }
        }
        if (oldVersion < 15) {
          // バージョン15: 引退フラグを追加
          print('データベーススキーマを更新中（バージョン15）: 引退フラグを追加...');
          try {
            await db.execute('ALTER TABLE Player ADD COLUMN is_retired INTEGER DEFAULT 0');
            await db.execute('ALTER TABLE Player ADD COLUMN retired_at TEXT');
            print('引退フラグの追加完了');
            
            // 既存選手の引退判定を実行
            await _updateExistingPlayersRetirementStatus(db);
          } catch (e) {
            print('引退フラグ追加エラー: $e');
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
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM School')) ?? 0;
    if (count > 0) return;
    
    // サンプルデータは削除（実際の選手生成はGameManagerで行う）
    // 学校（神奈川県の高校）
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
      final id = await db.insert('School', school);
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
              version: 20, // バージョンを20に更新
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
        if (oldVersion < 20) {
          // バージョン20では新しいリレーショナルスキーマで再作成
          print('データベーススキーマを強制更新中（バージョン20）...');
          // 古いテーブルを削除して新しいスキーマで再作成
          await db.execute('DROP TABLE IF EXISTS Player');
          await db.execute('DROP TABLE IF EXISTS PlayerPotentials');
          await db.execute('DROP TABLE IF EXISTS Person');
          await db.execute('DROP TABLE IF EXISTS Coach');
          await db.execute('DROP TABLE IF EXISTS Scout');
          await db.execute('DROP TABLE IF EXISTS Career');
          await db.execute('DROP TABLE IF EXISTS Organization');
          await db.execute('DROP TABLE IF EXISTS ScoutAnalysis');
          await db.execute('DROP TABLE IF EXISTS ScoutBasicInfoAnalysis');
          await _createAllTables(db);
          await _insertProfessionalTeams(db);
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

  // データベースの作成
  Future<void> _createDatabase(Database db, int version) async {
    print('データベーススキーマを作成中（バージョン$version）...');
    
    // 基本テーブルの作成
    await _createAllTables(db);
    
    // プロ野球団の初期データを挿入
    await _insertProfessionalTeams(db);
    
    print('データベーススキーマの作成完了');
  }

  // データベースのアップグレード
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('データベーススキーマをアップグレード中（$oldVersion → $newVersion）...');
    
    if (oldVersion < 20) {
      // バージョン20: 新しいテーブル構造に完全移行
      print('データベーススキーマを完全更新中（バージョン20）...');
      
      // 既存のテーブルを削除して再作成
      await db.execute('DROP TABLE IF EXISTS Player');
      await db.execute('DROP TABLE IF EXISTS PlayerPotentials');
      await db.execute('DROP TABLE IF EXISTS Person');
      await db.execute('DROP TABLE IF EXISTS ProfessionalTeam');
      await db.execute('DROP TABLE IF EXISTS ProfessionalPlayer');
      await db.execute('DROP TABLE IF EXISTS PlayerStats');
      await db.execute('DROP TABLE IF EXISTS TeamHistory');
      
      // 新しいテーブルを作成
      await _createAllTables(db);
      
      // プロ野球団の初期データを挿入
      await _insertProfessionalTeams(db);
      
      print('データベーススキーマの完全更新完了');
    }
    
    print('データベーススキーマのアップグレード完了');
  }

  // テーブル作成処理を共通化
  Future<void> _createAllTables(Database db) async {
    // Schoolテーブル（学校情報）
    await db.execute('''
      CREATE TABLE School (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        location TEXT NOT NULL,
        school_strength INTEGER DEFAULT 50,
        last_year_strength INTEGER DEFAULT 50,
        scouting_popularity INTEGER DEFAULT 50,
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
        grade INTEGER,
        age INTEGER DEFAULT 15,
        position TEXT NOT NULL,
        fame INTEGER DEFAULT 0,
        is_publicly_known INTEGER DEFAULT 0,
        is_scout_favorite INTEGER DEFAULT 0,
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
        natural_fitness INTEGER DEFAULT 50,
        injury_proneness INTEGER DEFAULT 50,
        stamina INTEGER DEFAULT 50,
        strength INTEGER DEFAULT 50,
        pace INTEGER DEFAULT 50,
        flexibility INTEGER DEFAULT 50,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (person_id) REFERENCES Person (id),
        FOREIGN KEY (school_id) REFERENCES School (id)
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
        home_stadium TEXT NOT NULL,
        city TEXT NOT NULL,
        budget INTEGER NOT NULL, -- 球団予算（万円）
        strategy TEXT NOT NULL,
        strengths TEXT, -- JSON形式で保存
        weaknesses TEXT, -- JSON形式で保存
        popularity INTEGER DEFAULT 50,
        success INTEGER DEFAULT 50,
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
} 