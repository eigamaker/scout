import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DataService {
  static const String saveKey = 'scout_game_save';
  static const String autoSaveKey = 'scout_game_autosave';

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
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
            max_fastball_velo INTEGER,
            control INTEGER,
            max_control INTEGER,
            stamina INTEGER,
            max_stamina INTEGER,
            batting_power INTEGER,
            max_batting_power INTEGER,
            running_speed INTEGER,
            max_running_speed INTEGER,
            defense INTEGER,
            max_defense INTEGER,
            mental INTEGER,
            max_mental INTEGER,
            growth_rate REAL
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
      'max_fastball_velo': 152,
      'control': 70,
      'max_control': 85,
      'stamina': 80,
      'max_stamina': 90,
      'batting_power': 60,
      'max_batting_power': 75,
      'running_speed': 65,
      'max_running_speed': 80,
      'defense': 68,
      'max_defense': 80,
      'mental': 75,
      'max_mental': 90,
      'growth_rate': 1.1,
    });
  }
} 