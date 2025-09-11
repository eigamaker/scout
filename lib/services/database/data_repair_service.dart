import 'dart:math';
import 'package:sqflite/sqflite.dart';

/// データ修復に関する機能を担当するサービス
class DataRepairService {
  final Database _db;

  DataRepairService(this._db);

  /// 数値データの型を修正
  Future<void> repairNumericData() async {
    print('DataRepairService: 数値データの型修正を開始...');
    final stopwatch = Stopwatch()..start();
    
    try {
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
          final stringValues = await _db.query('Player', 
            columns: [column], 
            where: 'typeof($column) = \'text\' AND $column IS NOT NULL AND $column != \'\''
          );
          
          if (stringValues.isNotEmpty) {
            print('DataRepairService: $columnカラムに文字列データが${stringValues.length}件見つかりました');
            
            // 文字列を整数に変換
            await _db.execute('''
              UPDATE Player 
              SET $column = CAST($column AS INTEGER) 
              WHERE typeof($column) = 'text' AND $column IS NOT NULL AND $column != ''
            ''');
            
            // 変換できなかった場合は0に設定
            await _db.execute('''
              UPDATE Player 
              SET $column = 0 
              WHERE $column IS NULL OR $column = '' OR typeof($column) = 'text'
            ''');
            
            print('DataRepairService: ${column}カラムを修正しました');
          } else {
            print('DataRepairService: ${column}カラムは正常です');
          }
        } catch (e) {
          print('DataRepairService: ${column}カラムの修正でエラー: $e');
        }
      }
      
      // ポテンシャル値の修正（現在の能力値より低い場合）
      await _repairPotentialValues();
      
      // 高校生のポテンシャル値の修正
      await _repairHighSchoolPotentials();
      
      stopwatch.stop();
      print('DataRepairService: 数値データの型修正完了 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('DataRepairService: 数値データの型修正エラー: $e');
      rethrow;
    }
  }

  /// ポテンシャル値の修正（現在の能力値より低い場合）
  Future<void> _repairPotentialValues() async {
    print('DataRepairService: ポテンシャル値の修正を開始...');
    
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
        final lowPotentialPlayers = await _db.rawQuery('''
          SELECT pl.id, pl.$ability as current_value, pp.$potentialColumn as potential_value
          FROM Player pl 
          JOIN PlayerPotentials pp ON pl.id = pp.player_id 
          WHERE pl.$ability > pp.$potentialColumn 
          AND pl.is_default_player = 0
        ''');
        
        if (lowPotentialPlayers.isNotEmpty) {
          print('DataRepairService: $ability で${lowPotentialPlayers.length}件の修正が必要');
          
          // ポテンシャル値を現在値 + 10〜30の範囲で設定
          final batch = _db.batch();
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
          print('DataRepairService: $ability のポテンシャル値を修正しました');
        }
      }
      
      print('DataRepairService: ポテンシャル値の修正完了');
      
    } catch (e) {
      print('DataRepairService: ポテンシャル値の修正エラー: $e');
    }
  }

  /// 高校生のポテンシャル値が低すぎる場合の修正
  Future<void> _repairHighSchoolPotentials() async {
    print('DataRepairService: 高校生のポテンシャル値の修正を開始...');
    
    try {
      // 高校生の選手を取得（プロ選手以外）
      final highSchoolPlayers = await _db.rawQuery('''
        SELECT DISTINCT pl.id, pl.grade, pl.talent
        FROM Player pl 
        LEFT JOIN ProfessionalPlayer pp ON pl.id = pp.player_id 
        WHERE pp.player_id IS NULL 
        AND pl.is_default_player = 0
        AND pl.grade IS NOT NULL
      ''');
      
      if (highSchoolPlayers.isNotEmpty) {
        print('DataRepairService: ${highSchoolPlayers.length}件の高校生選手のポテンシャル値を修正中...');
        
        final batch = _db.batch();
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
        print('DataRepairService: 高校生のポテンシャル値を修正しました');
      }
      
      print('DataRepairService: 高校生のポテンシャル値の修正完了');
      
    } catch (e) {
      print('DataRepairService: 高校生のポテンシャル値の修正エラー: $e');
    }
  }

  /// 高校生の才能ランクに基づく基本ポテンシャルを取得（最高値100）
  int _getHighSchoolBasePotential(int talentRank) {
    switch (talentRank) {
      case 3: return 65;  // ランク3: 60-70
      case 4: return 75;  // ランク4: 70-80
      case 5: return 85;  // ランク5: 80-90
      case 6: return 95;  // ランク6: 90-100
      default: return 65;
    }
  }

  /// 既存選手の注目選手フラグを再計算して設定（マイグレーション用）
  Future<void> updateExistingPlayersPubliclyKnown() async {
    try {
      print('DataRepairService: 既存選手の注目選手フラグを再計算中...');
      
      // 全選手を取得
      final players = await _db.query('Player');
      int updatedCount = 0;
      
      for (final player in players) {
        final fame = player['fame'] as int? ?? 0;
        final talent = player['talent'] as int? ?? 1;
        final grade = player['grade'] as int? ?? 1;
        
        // 注目選手判定ロジック
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
        await _db.update(
          'Player',
          {'is_publicly_known': shouldBePubliclyKnown ? 1 : 0},
          where: 'id = ?',
          whereArgs: [player['id']],
        );
        
        if (shouldBePubliclyKnown) {
          updatedCount++;
        }
      }
      
      print('DataRepairService: 注目選手フラグ再計算完了: ${updatedCount}人が注目選手に設定されました');
    } catch (e) {
      print('DataRepairService: 注目選手フラグ再計算エラー: $e');
    }
  }

  /// 既存選手の年齢を学年から計算して設定（マイグレーション用）
  Future<void> updateExistingPlayersAge() async {
    try {
      print('DataRepairService: 既存選手の年齢を学年から計算中...');
      
      // 全選手を取得
      final players = await _db.query('Player');
      int updatedCount = 0;
      
      for (final player in players) {
        final grade = player['grade'] as int? ?? 1;
        final age = 15 + (grade - 1); // 1年生=15歳、2年生=16歳、3年生=17歳
        
        await _db.update(
          'Player',
          {'age': age},
          where: 'id = ?',
          whereArgs: [player['id']],
        );
        
        updatedCount++;
      }
      
      print('DataRepairService: 年齢更新完了: ${updatedCount}人の年齢を更新しました');
    } catch (e) {
      print('DataRepairService: 年齢更新エラー: $e');
    }
  }

  /// 既存選手の引退判定を実行（マイグレーション用）
  Future<void> updateExistingPlayersRetirementStatus() async {
    try {
      print('DataRepairService: 既存選手の引退判定を実行中...');
      
      // 全選手を取得
      final players = await _db.query('Player');
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
            await _db.update(
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
      
      print('DataRepairService: 引退判定完了: ${retiredCount}人が引退しました');
    } catch (e) {
      print('DataRepairService: 引退判定エラー: $e');
    }
  }

  /// 全選手の総合能力値指標を再計算（成長期などで使用）
  Future<void> recalculateAllPlayerAbilities() async {
    try {
      print('DataRepairService: 全選手の総合能力値指標を再計算中...');
      
      final players = await _db.query('Player');
      int updatedCount = 0;
      
      for (final player in players) {
        final playerId = player['id'] as int;
        await _updatePlayerOverallAbilities(playerId);
        updatedCount++;
      }
      
      print('DataRepairService: 総合能力値指標再計算完了: ${updatedCount}人の選手を更新しました');
    } catch (e) {
      print('DataRepairService: 総合能力値指標再計算エラー: $e');
    }
  }

  /// 選手の総合能力値指標を計算・更新
  Future<void> _updatePlayerOverallAbilities(int playerId) async {
    try {
      // 選手の能力値を取得
      final player = await _db.query('Player', where: 'id = ?', whereArgs: [playerId]);
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
      await _db.update('Player', {
        'overall': overallAbility,
        'technical': technicalAbility,
        'physical': physicalAbility,
        'mental': mentalAbility,
      }, where: 'id = ?', whereArgs: [playerId]);
      
    } catch (e) {
      print('DataRepairService: 総合能力値指標の計算・更新でエラー: $e');
    }
  }
}
