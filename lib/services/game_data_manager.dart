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

  /// ゲームデータを指定スロットに保存
  Future<void> saveGameData(Game game, dynamic slot) async {
    try {
      final gameData = game.toJson();
      await _dataService.saveGameDataToSlot(gameData, slot);
      print('ゲームデータを保存しました: スロット $slot');
    } catch (e) {
      print('ゲームデータ保存エラー: $e');
      rethrow;
    }
  }

  /// ゲームデータをオートセーブに保存
  Future<void> saveAutoGameData(Game game) async {
    try {
      final gameData = game.toJson();
      await _dataService.saveAutoGameData(gameData);
      print('オートセーブデータを保存しました');
    } catch (e) {
      print('オートセーブ保存エラー: $e');
      rethrow;
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
} 