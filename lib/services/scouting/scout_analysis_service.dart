import 'dart:math';
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



  // 注: 分析結果生成ロジックは action_service.dart に移動済み
} 