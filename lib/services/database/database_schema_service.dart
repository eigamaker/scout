import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// データベーススキーマ管理に関する機能を担当するサービス
class DatabaseSchemaService {
  static const int _databaseVersion = 3;

  /// データベースの全テーブルを作成
  Future<void> createAllTables(Database db) async {
    print('DatabaseSchemaService: 全テーブル作成開始');
    
    try {
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
          school TEXT,
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
          is_default_player INTEGER DEFAULT 0,
          status TEXT DEFAULT 'active',
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
          -- 総合能力値カラム
          overall INTEGER DEFAULT 50,
          technical INTEGER DEFAULT 50,
          physical INTEGER DEFAULT 50,
          mental INTEGER DEFAULT 50,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (person_id) REFERENCES Person (id),
          FOREIGN KEY (school_id) REFERENCES School (id),
          UNIQUE(person_id, school_id, grade)
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
          salary INTEGER NOT NULL,
          contract_type TEXT DEFAULT 'regular',
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
          league TEXT NOT NULL,
          division TEXT NOT NULL,
          home_stadium TEXT NOT NULL,
          city TEXT NOT NULL,
          budget INTEGER NOT NULL,
          strategy TEXT NOT NULL,
          strengths TEXT,
          weaknesses TEXT,
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
          league TEXT NOT NULL,
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

      // インデックスの作成
      await _createIndexes(db);
      
      print('DatabaseSchemaService: 全テーブル作成完了');
    } catch (e) {
      print('DatabaseSchemaService: テーブル作成エラー: $e');
      rethrow;
    }
  }

  /// インデックスを作成
  Future<void> _createIndexes(Database db) async {
    print('DatabaseSchemaService: インデックス作成開始');
    
    try {
      // 基本インデックス
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
      
      // 追加のインデックス
      await db.execute('CREATE INDEX idx_game_info_timestamp ON GameInfo(timestamp)');
      await db.execute('CREATE INDEX idx_discovered_player_id ON DiscoveredPlayer(player_id)');
      await db.execute('CREATE INDEX idx_watched_player_id ON WatchedPlayer(player_id)');
      await db.execute('CREATE INDEX idx_favorite_player_id ON FavoritePlayer(player_id)');
      await db.execute('CREATE INDEX idx_scout_reports_player_id ON scout_reports(player_id)');
      await db.execute('CREATE INDEX idx_scout_reports_scout_id ON scout_reports(scout_id)');
      
      print('DatabaseSchemaService: インデックス作成完了');
    } catch (e) {
      print('DatabaseSchemaService: インデックス作成エラー: $e');
      rethrow;
    }
  }

  /// データベースバージョンを取得
  int get databaseVersion => _databaseVersion;
}
