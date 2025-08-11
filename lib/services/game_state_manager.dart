import 'dart:math';
import '../models/game/game.dart';
import '../models/player/player.dart';
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

  // 全選手の成長処理（半年ごと - 2月末週から3月1週、8月末週から9月1週）
  static Game growAllPlayers(Game game) {
    print('GameStateManager.growAllPlayers: 全選手の成長処理開始');
    final updatedSchools = game.schools.map((school) {
      final grownPlayers = school.players.map((p) {
        print('GameStateManager.growAllPlayers: 選手ID ${p.id} (${p.name}) の成長処理');
        // GrowthServiceを使用して適切な成長処理を実行
        final grownPlayer = GrowthService.growPlayer(p);
        print('GameStateManager.growAllPlayers: 選手ID ${p.id} (${p.name}) の成長処理完了');
        return grownPlayer;
      }).toList();
      return school.copyWith(players: grownPlayers);
    }).toList();
    
    print('GameStateManager.growAllPlayers: 全選手の成長処理完了');
    return game.copyWith(schools: updatedSchools);
  }
} 