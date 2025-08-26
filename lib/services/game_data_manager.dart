import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game/game.dart';
import 'data_service.dart';

/// ゲームデータの保存・読み込み・復元を専門に扱うクラス
class GameDataManager {
  static const String _saveKey = 'scout_game_save';
  static const String _autoSaveKey = 'scout_game_autosave';

  final DataService _dataService;

  GameDataManager(this._dataService);

  /// ゲームデータを指定スロットに保存（メモリ最適化版）
  Future<void> saveGameData(Game game, dynamic slot) async {
    try {
      // メモリ使用量を監視
      final gameData = game.toJson();
      final dataSize = _estimateDataSize(gameData);
      
      print('セーブデータサイズ: ${(dataSize / 1024 / 1024).toStringAsFixed(2)}MB');
      
      // データサイズが大きい場合はデータベースに直接保存
      if (dataSize > 10 * 1024 * 1024) { // 10MB以上
        print('データサイズが大きいため、データベースに直接保存します');
        await _dataService.saveGameDataToDatabase(gameData);
        
        // 軽量化されたデータのみSharedPreferencesに保存
        final lightData = _createLightSaveData(gameData);
        await _dataService.saveGameDataToSlot(lightData, slot);
      } else {
        // 通常の保存
        await _dataService.saveGameDataToSlot(gameData, slot);
      }
      
      print('ゲームデータを保存しました: スロット $slot');
    } catch (e) {
      print('ゲームデータ保存エラー: $e');
      
      // エラーが発生した場合は、データベースに直接保存を試行
      try {
        print('SharedPreferences保存に失敗したため、データベースに直接保存を試行します');
        final gameData = game.toJson();
        await _dataService.saveGameDataToDatabase(gameData);
        print('データベースへの直接保存が完了しました');
      } catch (dbError) {
        print('データベース保存も失敗: $dbError');
        rethrow;
      }
    }
  }

  /// ゲームデータをオートセーブに保存（メモリ最適化版）
  Future<void> saveAutoGameData(Game game) async {
    try {
      final gameData = game.toJson();
      final dataSize = _estimateDataSize(gameData);
      
      print('オートセーブデータサイズ: ${(dataSize / 1024 / 1024).toStringAsFixed(2)}MB');
      
      // オートセーブは常に軽量化されたデータを使用
      final lightData = _createLightSaveData(gameData);
      await _dataService.saveAutoGameData(lightData);
      
      // 完全なデータはデータベースに保存
      if (dataSize > 5 * 1024 * 1024) { // 5MB以上
        print('オートセーブデータが大きいため、データベースにも保存します');
        await _dataService.saveGameDataToDatabase(gameData);
      }
      
      print('オートセーブデータを保存しました');
    } catch (e) {
      print('オートセーブ保存エラー: $e');
      // オートセーブエラーは致命的ではないので、エラーを投げない
    }
  }

  /// 指定スロットからゲームデータを読み込み
  Future<Game?> loadGameData(dynamic slot) async {
    try {
      final json = await _dataService.loadGameDataFromSlot(slot);
      if (json != null) {
        final game = Game.fromJson(json);
        print('ゲームデータを読み込みました: スロット $slot');
        return game;
      }
      print('スロット $slot にセーブデータがありません');
      return null;
    } catch (e) {
      print('ゲームデータ読み込みエラー: $e');
      return null;
    }
  }

  /// オートセーブからゲームデータを読み込み
  Future<Game?> loadAutoGameData() async {
    try {
      final json = await _dataService.loadAutoGameData();
      if (json != null) {
        final game = Game.fromJson(json);
        print('オートセーブデータを読み込みました');
        return game;
      }
      print('オートセーブデータがありません');
      return null;
    } catch (e) {
      print('オートセーブ読み込みエラー: $e');
      return null;
    }
  }

  /// 指定スロットにセーブデータが存在するかチェック
  Future<bool> hasGameData(dynamic slot) async {
    return await _dataService.hasGameDataInSlot(slot);
  }

  /// ゲームデータの整合性をチェック
  bool validateGameData(Game game) {
    try {
      // 基本的な整合性チェック
      if (game.schools.isEmpty) {
        print('警告: 学校データが空です');
        return false;
      }

      // 選手データの整合性チェック
      for (final school in game.schools) {
        for (final player in school.players) {
          if (player.name.isEmpty) {
            print('警告: 選手名が空です');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('ゲームデータ整合性チェックエラー: $e');
      return false;
    }
  }

  /// ゲームデータの復元処理
  Future<Game?> restoreGameData(dynamic slot) async {
    try {
      final game = await loadGameData(slot);
      if (game != null && validateGameData(game)) {
        print('ゲームデータの復元が完了しました');
        return game;
      } else {
        print('ゲームデータの復元に失敗しました');
        return null;
      }
    } catch (e) {
      print('ゲームデータ復元エラー: $e');
      return null;
    }
  }

  /// 全スロットのセーブデータ状況を取得
  Future<Map<String, bool>> getAllSlotStatus() async {
    final status = <String, bool>{};
    for (int i = 1; i <= 3; i++) {
      status['スロット$i'] = await hasGameData(i);
    }
    status['オートセーブ'] = await hasGameData('autosave');
    return status;
  }

  /// セーブデータの詳細情報を取得
  Future<Map<String, dynamic>?> getSaveDataInfo(dynamic slot) async {
    try {
      final json = await _dataService.loadGameDataFromSlot(slot);
      if (json != null) {
        return {
          'slot': slot,
          'timestamp': json['timestamp'] ?? '不明',
          'schoolCount': (json['schools'] as List?)?.length ?? 0,
          'discoveredPlayerCount': (json['discoveredPlayers'] as List?)?.length ?? 0,
          'currentWeek': json['currentWeek'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      print('セーブデータ情報取得エラー: $e');
      return null;
    }
  }

  /// データサイズを推定
  int _estimateDataSize(Map<String, dynamic> data) {
    try {
      final jsonString = jsonEncode(data);
      return jsonString.length;
    } catch (e) {
      // エラーが発生した場合は概算
      return data.length * 1000; // 1キーあたり約1000バイトと仮定
    }
  }
  
  /// 軽量化されたセーブデータを作成
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
    
    // 発掘選手も軽量化
    if (fullData['discoveredPlayers'] != null) {
      final players = fullData['discoveredPlayers'] as List;
      lightData['discoveredPlayers'] = players.map((player) {
        final playerData = Map<String, dynamic>.from(player);
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
    
    return lightData;
  }
} 