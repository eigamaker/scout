import 'dart:math';
import '../models/game/game.dart';
import '../models/player/player.dart';
import '../models/news/news_item.dart';
import 'news_service.dart';

class GameStateManager {
  
  // 選手を発掘済みとして登録
  static Game discoverPlayer(Game game, Player player) {
    // フラグベースのシステムに変更（重複テーブルは削除）
    // 選手のisScoutedフラグをtrueに設定する必要があるが、Playerクラスはimmutableなので、ここでは何もしない
    return game;
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
    
    // 更新された選手のIDリストを作成
    final updatedPlayerIds = updatedPlayers.map((p) => p.id!).toList();
    // フラグベースのシステムに変更（重複テーブルは削除）
    return game;
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


} 