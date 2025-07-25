import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/news_service.dart';
import '../services/data_service.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    final newsService = Provider.of<NewsService>(context);
    final game = gameManager.currentGame;

    if (game == null) {
      return const Scaffold(
        body: Center(child: Text('ゲームが開始されていません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${game.scoutName}のダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final gameManager = Provider.of<GameManager>(context, listen: false);
              final dataService = Provider.of<DataService>(context, listen: false);
              await gameManager.saveGame(dataService);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('セーブしました')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () async {
              final gameManager = Provider.of<GameManager>(context, listen: false);
              final dataService = Provider.of<DataService>(context, listen: false);
              final loaded = await gameManager.loadGame(dataService);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loaded ? 'ロードしました' : 'セーブデータがありません')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ゲーム情報カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ゲーム情報',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('日付: ${game.getFormattedDate()}'),
                    Text('レベル: ${game.level}'),
                    Text('経験値: ${game.experience}'),
                    Text('予算: ¥${game.budget.toString()}'),
                    Text('評判: ${game.reputation}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 統計情報カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '統計',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('発掘選手: ${game.discoveredPlayers.length}人'),
                    Text('注目選手: ${game.watchedPlayers.length}人'),
                    Text('お気に入り: ${game.favoritePlayers.length}人'),
                    Text('ニュース: ${newsService.newsList.length}件'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // アクションボタン
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'アクション',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/players');
                            },
                            icon: const Icon(Icons.people),
                            label: const Text('選手リスト'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/news');
                            },
                            icon: const Icon(Icons.article),
                            label: const Text('ニュース'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final gameManager = Provider.of<GameManager>(context, listen: false);
                              final newsService = Provider.of<NewsService>(context, listen: false);
                              final player = gameManager.scoutNewPlayer(newsService);
                              if (player != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${player.name}選手を発掘しました！')),
                                );
                              }
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('スカウト'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final gameManager = Provider.of<GameManager>(context, listen: false);
                              final newsService = Provider.of<NewsService>(context, listen: false);
                              gameManager.advanceDay(newsService);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('日付を進めました')),
                              );
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('次の日'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 