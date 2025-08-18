import 'dart:math';
import '../../models/player/player.dart';
import '../../models/player/player_abilities.dart';
import '../data_service.dart';

/// スカウト分析データの取得・保存を担当するサービス
/// 
/// 役割:
/// - スカウト分析データの取得（表示用）
/// - 基本情報分析データの保存（外部から呼び出し用）
/// - データベースアクセスの抽象化
/// 
/// 注意: アクション実行ロジックは action_service.dart が担当
class ScoutAnalysisService {
  final DataService _dataService;
  
  ScoutAnalysisService(this._dataService);
  
  /// 最新のスカウト分析データを取得
  Future<Map<String, int>?> getLatestScoutAnalysis(int playerId, String scoutId) async {
    try {
      final db = await _dataService.database;
      
      final List<Map<String, dynamic>> results = await db.query(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [playerId, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        final record = results.first;
        final scoutedAbilities = <String, int>{};
        
        // スカウトされた能力値を抽出（カラム名をそのまま使用）
        for (final key in record.keys) {
          if (key.endsWith('_scouted') && record[key] != null) {
            scoutedAbilities[key] = record[key] as int;
          }
        }
        
        return scoutedAbilities;
      } else {
        return null;
      }
    } catch (e) {
      print('スカウト分析データ取得エラー: $e');
      return null;
    }
  }

  /// 基本情報のスカウト分析データを保存（外部から呼び出し用）
  Future<void> saveBasicInfoAnalysis(Map<String, dynamic> insertData) async {
    try {
      final db = await _dataService.database;
      
      // 既存の基本情報分析データを確認
      final existingData = await db.query(
        'ScoutBasicInfoAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [insertData['player_id'], insertData['scout_id']],
      );
      
      if (existingData.isNotEmpty) {
        // 既存データがある場合は更新（既存の分析データを保持）
        final existing = existingData.first;
        final updatedData = Map<String, dynamic>.from(existing);
        
        // 新しいデータで既存のnullフィールドのみを更新
        insertData.forEach((key, value) {
          if (value != null && (existing[key] == null || existing[key] == 0)) {
            updatedData[key] = value;
          }
        });
        
        // 分析日時と精度は常に更新
        updatedData['analysis_date'] = insertData['analysis_date'];
        updatedData['accuracy'] = insertData['accuracy'];
        
        await db.update(
          'ScoutBasicInfoAnalysis',
          updatedData,
          where: 'player_id = ? AND scout_id = ?',
          whereArgs: [insertData['player_id'], insertData['scout_id']],
        );
        print('基本情報分析データ更新完了: プレイヤーID ${insertData['player_id']}');
      } else {
        // 新規データの場合は挿入
        print('基本情報分析データ保存: プレイヤーID ${insertData['player_id']}, データ: $insertData');
        await db.insert('ScoutBasicInfoAnalysis', insertData);
        print('基本情報分析データ新規挿入完了');
      }
      
    } catch (e) {
      print('基本情報分析データ保存エラー: $e');
    }
  }

  /// 最新の基本情報分析データを取得
  Future<Map<String, dynamic>?> getLatestBasicInfoAnalysis(int playerId, String scoutId) async {
    try {
      final db = await _dataService.database;
      
      final List<Map<String, dynamic>> results = await db.query(
        'ScoutBasicInfoAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [playerId, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        return results.first;
      } else {
        return null;
      }
    } catch (e) {
      print('基本情報分析データ取得エラー: $e');
      return null;
    }
  }

  /// スカウト精度に基づく誤差範囲を計算
  int _calculateErrorRange(double accuracy) {
    // 精度が高いほど誤差範囲が小さくなる
    if (accuracy >= 0.9) return 2;      // 90%以上: ±2
    if (accuracy >= 0.8) return 3;      // 80%以上: ±3
    if (accuracy >= 0.7) return 4;      // 70%以上: ±4
    if (accuracy >= 0.6) return 5;      // 60%以上: ±5
    return 6;                            // 60%未満: ±6
  }

  /// データベースのテーブル構造をデバッグ出力
  Future<void> debugTableStructure() async {
    try {
      final db = await _dataService.database;
      
      // ScoutAnalysisテーブルの構造を確認
      print('=== ScoutAnalysisテーブル構造 ===');
      final scoutAnalysisColumns = await db.query('ScoutAnalysis', limit: 1);
      if (scoutAnalysisColumns.isNotEmpty) {
        print('カラム: ${scoutAnalysisColumns.first.keys.toList()}');
      }
      
      // ScoutBasicInfoAnalysisテーブルの構造を確認
      print('=== ScoutBasicInfoAnalysisテーブル構造 ===');
      final basicInfoColumns = await db.query('ScoutBasicInfoAnalysis', limit: 1);
      if (basicInfoColumns.isNotEmpty) {
        print('カラム: ${basicInfoColumns.first.keys.toList()}');
      }
      
      // テーブル内のレコード数を確認
      final scoutAnalysisCount = await db.rawQuery('SELECT COUNT(*) as count FROM ScoutAnalysis');
      final basicInfoCount = await db.rawQuery('SELECT COUNT(*) as count FROM ScoutBasicInfoAnalysis');
      
      print('ScoutAnalysisレコード数: ${scoutAnalysisCount.first['count']}');
      print('ScoutBasicInfoAnalysisレコード数: ${basicInfoCount.first['count']}');
      
    } catch (e) {
      print('テーブル構造確認エラー: $e');
    }
  }
  
  /// 仮の能力値を生成
  int? _generateScoutedValue(int trueValue, int errorRange, Random random) {
    // スカウトのスキルが非常に低い場合（errorRangeが50の場合）は判定できない
    if (errorRange >= 50) {
      return null; // 判定できない場合はnullを返す
    }
    
    final error = random.nextInt(errorRange * 2 + 1) - errorRange;
    final scoutedValue = (trueValue + error).clamp(0, 100);
    return scoutedValue;
  }

  /// カラム名を取得（camelCase → snake_case）
  String _getColumnName(String enumName) {
    // 特殊なマッピング
    final mapping = {
      'plateDiscipline': 'plate_discipline',
      'oppositeFieldHitting': 'opposite_field_hitting',
      'pullHitting': 'pull_hitting',
      'batControl': 'bat_control',
      'swingSpeed': 'swing_speed',
      'catcherAbility': 'catcher_ability',
      'breakingBall': 'breaking_ball',
      'pitchMovement': 'pitch_movement',
      'workRate': 'work_rate',
      'selfDiscipline': 'self_discipline',
      'pressureHandling': 'pressure_handling',
      'clutchAbility': 'clutch_ability',
      'jumpingReach': 'jumping_reach',
      'naturalFitness': 'natural_fitness',
      'injuryProneness': 'injury_proneness',
    };
    
    String columnName;
    
    // マッピングに存在する場合はそれを使用
    if (mapping.containsKey(enumName)) {
      columnName = '${mapping[enumName]}_scouted';
    } else {
      // それ以外は通常のcamelCase → snake_case変換
      final snakeCase = enumName.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}'
      );
      columnName = '${snakeCase}_scouted';
    }
    
    print('カラム名生成: $enumName -> $columnName');
    return columnName;
  }

  /// カラム名から能力値名を取得
  String? _getAbilityNameFromColumn(String columnName) {
    if (!columnName.endsWith('_scouted')) return null;
    
    // snake_case から camelCase に変換
    final withoutSuffix = columnName.replaceAll('_scouted', '');
    final parts = withoutSuffix.split('_');
    
    String abilityName;
    if (parts.length == 1) {
      abilityName = parts[0];
    } else {
      abilityName = parts[0] + parts.skip(1).map((part) => 
        part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : ''
      ).join('').replaceAll('_', ''); // 末尾の_を削除
    }
    
    print('カラム名変換: $columnName -> $abilityName');
    return abilityName;
  }

  // 注: 分析結果生成ロジックは action_service.dart に移動済み
} 