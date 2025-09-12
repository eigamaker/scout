import 'package:sqflite/sqflite.dart';

/// is_default_playerカラムを削除するマイグレーション
class RemoveIsDefaultPlayerMigration {
  static const int version = 1;
  
  /// マイグレーションを実行
  static Future<void> migrate(Database db) async {
    try {
      print('RemoveIsDefaultPlayerMigration: is_default_playerカラムの削除を開始');
      
      // 既存のテーブル構造を確認
      final tableInfo = await db.rawQuery("PRAGMA table_info(Player)");
      final hasIsDefaultPlayerColumn = tableInfo.any((column) => column['name'] == 'is_default_player');
      
      if (hasIsDefaultPlayerColumn) {
        print('RemoveIsDefaultPlayerMigration: is_default_playerカラムが見つかりました。削除を実行します。');
        
        // 新しいテーブルを作成（is_default_playerカラムなし）
        await db.execute('''
          CREATE TABLE Player_new (
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
            status TEXT DEFAULT 'active',
            growth_rate REAL DEFAULT 1.0,
            talent INTEGER DEFAULT 3,
            growth_type TEXT DEFAULT 'normal',
            mental_grit REAL DEFAULT 0.0,
            peak_ability INTEGER DEFAULT 100,
            -- Technical abilities
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
            -- Mental abilities
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
            -- Physical abilities
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
            -- 総合能力値
            overall INTEGER DEFAULT 50,
            technical INTEGER DEFAULT 50,
            physical INTEGER DEFAULT 50,
            mental INTEGER DEFAULT 50,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        
        // データをコピー（is_default_playerカラムを除く）
        await db.execute('''
          INSERT INTO Player_new (
            id, person_id, school_id, school, grade, age, position, fame,
            is_famous, is_scout_favorite, is_scouted, is_graduated, graduated_at,
            is_retired, retired_at, status, growth_rate, talent, growth_type,
            mental_grit, peak_ability,
            contact, power, plate_discipline, bunt, opposite_field_hitting,
            pull_hitting, bat_control, swing_speed, fielding, throwing,
            catcher_ability, control, fastball, breaking_ball, pitch_movement,
            concentration, anticipation, vision, composure, aggression, bravery,
            leadership, work_rate, self_discipline, ambition, teamwork,
            positioning, pressure_handling, clutch_ability,
            acceleration, agility, balance, jumping_reach, natural_fitness,
            injury_proneness, stamina, strength, pace, flexibility,
            overall, technical, physical, mental, created_at, updated_at
          )
          SELECT 
            id, person_id, school_id, school, grade, age, position, fame,
            is_famous, is_scout_favorite, is_scouted, is_graduated, graduated_at,
            is_retired, retired_at, status, growth_rate, talent, growth_type,
            mental_grit, peak_ability,
            contact, power, plate_discipline, bunt, opposite_field_hitting,
            pull_hitting, bat_control, swing_speed, fielding, throwing,
            catcher_ability, control, fastball, breaking_ball, pitch_movement,
            concentration, anticipation, vision, composure, aggression, bravery,
            leadership, work_rate, self_discipline, ambition, teamwork,
            positioning, pressure_handling, clutch_ability,
            acceleration, agility, balance, jumping_reach, natural_fitness,
            injury_proneness, stamina, strength, pace, flexibility,
            overall, technical, physical, mental, created_at, updated_at
          FROM Player
        ''');
        
        // 古いテーブルを削除
        await db.execute('DROP TABLE Player');
        
        // 新しいテーブルをPlayerにリネーム
        await db.execute('ALTER TABLE Player_new RENAME TO Player');
        
        print('RemoveIsDefaultPlayerMigration: is_default_playerカラムの削除が完了しました');
      } else {
        print('RemoveIsDefaultPlayerMigration: is_default_playerカラムは存在しません。マイグレーションをスキップします。');
      }
    } catch (e) {
      print('RemoveIsDefaultPlayerMigration: エラーが発生しました: $e');
      rethrow;
    }
  }
}
