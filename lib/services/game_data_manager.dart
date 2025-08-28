import 'dart:convert';
import '../models/game/game.dart';
import 'data_service.dart';

/// ゲームデータの保存・読み込み・復元を専門に扱うクラス（最適化版）
class GameDataManager {
  final DataService _dataService;

  GameDataManager(this._dataService);

  /// ゲームデータをデータベースに保存（最適化版）
  Future<void> saveGameData(Game game) async {
    try {
      final gameData = game.toJson();
      
      // データベースに直接保存（重複保存なし）
      await _dataService.saveGameDataToDatabase(gameData);
    } catch (e) {
      rethrow;
    }
  }

  /// データベースからゲームデータを読み込み
  Future<Game?> loadGameData() async {
    try {
      final game = await _dataService.loadGameDataFromDatabase();
      if (game != null) {
        return game;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// セーブデータが存在するかチェック
  Future<bool> hasGameData() async {
    return await _dataService.hasGameDataInDatabase();
  }

  /// ゲームデータの整合性をチェック
  bool validateGameData(Game game) {
    try {
      // 基本的な整合性チェック
      if (game.schools.isEmpty) {
        return false;
      }

      // 選手データの整合性チェック
      for (final school in game.schools) {
        for (final player in school.players) {
          if (player.name.isEmpty) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ゲームデータの復元処理
  Future<Game?> restoreGameData() async {
    try {
      final game = await loadGameData();
      if (game != null && validateGameData(game)) {
        return game;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// セーブデータの詳細情報を取得
  Future<Map<String, dynamic>?> getSaveDataInfo() async {
    try {
      final game = await loadGameData();
      if (game != null) {
        return {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'schoolCount': game.schools.length,
          'discoveredPlayerCount': game.discoveredPlayerIds.length,
          'currentYear': game.currentYear,
          'currentMonth': game.currentMonth,
          'currentWeekOfMonth': game.currentWeekOfMonth,
          'scoutName': game.scoutName,
          'level': game.level,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }


} 