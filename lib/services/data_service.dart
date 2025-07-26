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
      version: 1,
      onCreate: (db, version) async {
        // Personテーブル
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
        // Playerテーブル
        await db.execute('''
          CREATE TABLE Player (
            id INTEGER PRIMARY KEY,
            school_id INTEGER,
            grade INTEGER,
            position TEXT,
            fastball_velo INTEGER,
            control INTEGER,
            stamina INTEGER,
            break_avg INTEGER,
            batting_power INTEGER,
            bat_control INTEGER,
            running_speed INTEGER,
            defense INTEGER,
            arm INTEGER,
            growth_rate REAL,
            talent INTEGER,
            growth_type TEXT,
            mental_grit REAL,
            peak_ability INTEGER
          )
        ''');
        
        // PlayerPotentialsテーブル（個別ポテンシャル保存）
        await db.execute('''
          CREATE TABLE PlayerPotentials (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER,
            control_potential INTEGER,
            stamina_potential INTEGER,
            break_avg_potential INTEGER,
            bat_power_potential INTEGER,
            bat_control_potential INTEGER,
            run_potential INTEGER,
            field_potential INTEGER,
            arm_potential INTEGER,
            fastball_velo_potential INTEGER,
            FOREIGN KEY (player_id) REFERENCES Player (id)
          )
        ''');
        // Coachテーブル
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
        // Scoutテーブル
        await db.execute('''
          CREATE TABLE Scout (
            id INTEGER PRIMARY KEY,
            organization_id INTEGER,
            scout_skill INTEGER,
            negotiation INTEGER,
            network INTEGER
          )
        ''');
        // Careerテーブル
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
        // Organizationテーブル
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
      },
    );
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
    // サンプル人物・選手
    final personId = await db.insert('Person', {
      'name': '田中太郎',
      'birth_date': '2006-04-01',
      'gender': '男',
      'hometown': '横浜市',
      'personality': '真面目',
    });
    await db.insert('Player', {
      'id': personId,
      'school_id': schoolIds[0],
      'grade': 3,
      'position': '投手',
      'fastball_velo': 145,
      'control': 70,
      'stamina': 80,
      'break_avg': 75,
      'batting_power': 60,
      'bat_control': 65,
      'running_speed': 65,
      'defense': 68,
      'arm': 75,
      'growth_rate': 1.0,
      'talent': 3,
      'growth_type': 'normal',
      'mental_grit': 0.6,
      'peak_ability': 85,
    });
    
    // 個別ポテンシャルも保存
    await db.insert('PlayerPotentials', {
      'player_id': personId,
      'control_potential': 85,
      'stamina_potential': 90,
      'break_avg_potential': 80,
      'bat_power_potential': 75,
      'bat_control_potential': 80,
      'run_potential': 80,
      'field_potential': 80,
      'arm_potential': 85,
      'fastball_velo_potential': 150,
    });
  }

  // スロットごとにDBファイル名を切り替える
  Future<Database> getDatabaseWithSlot(String slot) async {
    final dbPath = await getDatabasesPath();
    final dbName = slot == 'オートセーブ' ? 'autosave.db' : 'save${_slotNumber(slot)}.db';
    final path = join(dbPath, dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 既存のテーブル作成処理を流用
        await _createAllTables(db);
      },
    );
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
        fastball_velo INTEGER,
        control INTEGER,
        stamina INTEGER,
        break_avg INTEGER,
        batting_power INTEGER,
        bat_control INTEGER,
        running_speed INTEGER,
        defense INTEGER,
        arm INTEGER,
        growth_rate REAL,
        talent INTEGER,
        growth_type TEXT,
        mental_grit REAL,
        peak_ability INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE PlayerPotentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        control_potential INTEGER,
        stamina_potential INTEGER,
        break_avg_potential INTEGER,
        bat_power_potential INTEGER,
        bat_control_potential INTEGER,
        run_potential INTEGER,
        field_potential INTEGER,
        arm_potential INTEGER,
        fastball_velo_potential INTEGER,
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
  }

  // スロット用DBファイルを削除
  Future<void> deleteDatabaseWithSlot(String slot) async {
    final dbPath = await getDatabasesPath();
    final dbName = slot == 'オートセーブ' ? 'autosave.db' : 'save${_slotNumber(slot)}.db';
    final path = join(dbPath, dbName);
    await deleteDatabase(path);
    print('DB削除: $path, exists= ${await File(path).exists()}');
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
} 