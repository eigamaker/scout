import 'dart:math';
import '../models/game/game.dart';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../models/news/news_item.dart';
import 'news_service.dart';
import 'growth_service.dart';
import 'data_service.dart';

class GameStateManager {
  
  // 選手を発掘済みとして登録
  static Game discoverPlayer(Game game, Player player) {
    return game.discoverPlayer(player);
  }

  // 選手の能力値把握度を更新
  static Game updatePlayerKnowledge(Game game, Player player) {
    // discoveredPlayersリスト内の該当選手を更新
    final updatedPlayers = game.discoveredPlayers.map((p) {
      if (p.name == player.name && p.school == player.school) {
        return player;
      }
      return p;
    }).toList();
    
    return game.copyWith(discoveredPlayers: updatedPlayers);
  }

  // ランダムイベントの発生
  static Game triggerRandomEvent(Game game, NewsService newsService) {
    final random = Random();
    final rand = random.nextInt(100);
    if (rand < 5) {
      newsService.addNews(
        NewsItem(
          title: '選手が怪我！',
          content: '注目選手の一人が練習中に怪我をしました。',
          date: DateTime.now(),
          importance: NewsImportance.critical,
          category: NewsCategory.player,
        ),
      );
    } else if (rand < 10) {
      newsService.addNews(
        NewsItem(
          title: 'スポンサー獲得！',
          content: '新たなスポンサーがチームを支援してくれることになりました。',
          date: DateTime.now(),
          importance: NewsImportance.high,
          category: NewsCategory.general,
        ),
      );
      return game.changeBudget(50000);
    } else if (rand < 15) {
      newsService.addNews(
        NewsItem(
          title: 'ファン感謝デー開催',
          content: 'ファン感謝デーが開催され、評判が上がりました。',
          date: DateTime.now(),
          importance: NewsImportance.medium,
          category: NewsCategory.general,
        ),
      );
      return game.changeReputation(5);
    }
    return game;
  }

  // 全選手の成長処理（3ヶ月ごと - 5月1週、8月1週、11月1週、2月1週）
  static Game growAllPlayers(Game game) {
    print('GameStateManager.growAllPlayers: 全選手の成長処理開始');
    
    int totalPlayers = 0;
    int grownPlayersCount = 0;
    bool isFirstSchool = true;
    
    final updatedSchools = game.schools.map((school) {
      final updatedPlayers = school.players.map((p) {
        // デフォルト選手は成長処理をスキップ
        if (p.isDefaultPlayer) {
          return p;
        }
        
        totalPlayers++;
        
        // GrowthServiceを使用して適切な成長処理を実行
        final grownPlayer = GrowthService.growPlayer(p);
        
        // 成長があったかチェック
        if (_hasPlayerGrown(p, grownPlayer)) {
          grownPlayersCount++;
          
          // 1校目のみ、最初の成長した選手の詳細ログを出力
          if (isFirstSchool) {
            _logFirstPlayerGrowth(p, grownPlayer);
            isFirstSchool = false;
          }
        }
        
        return grownPlayer;
      }).toList();
      return school.copyWith(players: updatedPlayers);
    }).toList();
    
    print('GameStateManager.growAllPlayers: 全選手の成長処理完了 - 総選手数: $totalPlayers, 成長した選手数: $grownPlayersCount');
    return game.copyWith(schools: updatedSchools);
  }
  
  // 選手が成長したかチェック
  static bool _hasPlayerGrown(Player oldPlayer, Player newPlayer) {
    // 技術面能力値の変化をチェック
    for (final entry in oldPlayer.technicalAbilities.entries) {
      final oldValue = entry.value;
      final newValue = newPlayer.technicalAbilities[entry.key] ?? oldValue;
      if (newValue != oldValue) return true;
    }
    
    // メンタル面能力値の変化をチェック
    for (final entry in oldPlayer.mentalAbilities.entries) {
      final oldValue = entry.value;
      final newValue = newPlayer.mentalAbilities[entry.key] ?? oldValue;
      if (newValue != oldValue) return true;
    }
    
    // フィジカル面能力値の変化をチェック
    for (final entry in oldPlayer.physicalAbilities.entries) {
      final oldValue = entry.value;
      final newValue = newPlayer.physicalAbilities[entry.key] ?? oldValue;
      if (newValue != oldValue) return true;
    }
    
    return false;
  }
  
  // 最初の成長した選手の詳細ログを出力
  static void _logFirstPlayerGrowth(Player oldPlayer, Player newPlayer) {
    print('GameStateManager: 最初の成長した選手の詳細 - ${newPlayer.name}');
    
    // 技術面能力値の変化をチェック
    for (final entry in oldPlayer.technicalAbilities.entries) {
      final oldValue = entry.value;
      final newValue = newPlayer.technicalAbilities[entry.key] ?? oldValue;
      if (newValue != oldValue) {
        print('  ${entry.key.name}: $oldValue → $newValue (${newValue > oldValue ? '+' : ''}${newValue - oldValue})');
      }
    }
    
    // メンタル面能力値の変化をチェック
    for (final entry in oldPlayer.mentalAbilities.entries) {
      final oldValue = entry.value;
      final newValue = newPlayer.mentalAbilities[entry.key] ?? oldValue;
      if (newValue != oldValue) {
        print('  ${entry.key.name}: $oldValue → $newValue (${newValue > oldValue ? '+' : ''}${newValue - oldValue})');
      }
    }
    
    // フィジカル面能力値の変化をチェック
    for (final entry in oldPlayer.physicalAbilities.entries) {
      final oldValue = entry.value;
      final newValue = newPlayer.physicalAbilities[entry.key] ?? oldValue;
      if (newValue != oldValue) {
        print('  ${entry.key.name}: $oldValue → $newValue (${newValue > oldValue ? '+' : ''}${newValue - oldValue})');
      }
    }
  }
} 