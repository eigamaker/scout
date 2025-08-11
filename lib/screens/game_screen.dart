import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/news_service.dart';
import '../services/data_service.dart';
import '../models/game/game.dart';


class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<List<String>> _weekLogs = [];
  
  // アコーディオンの展開状態管理
  bool _newsExpanded = false;
  bool _historyExpanded = false;
  bool _actionsExpanded = false;

  @override
  void initState() {
    super.initState();
    print('GameScreen: initState called');
  }

  @override
  Widget build(BuildContext context) {
    print('GameScreen: build called');
    final gameManager = Provider.of<GameManager>(context);
    final newsService = Provider.of<NewsService>(context);
    final game = gameManager.currentGame;

    print('GameScreen: currentGame = ${game != null ? "loaded" : "null"}');
    print('GameScreen: gameManager = ${gameManager}');
    print('GameScreen: gameManager.currentGame = ${gameManager.currentGame}');

    if (game == null) {
      print('GameScreen: No game loaded, showing error screen');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ゲームが開始されていません', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/mainMenu');
                },
                child: const Text('メインメニューに戻る'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${game.scoutName}のダッシュボード'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.scoutName, style: const TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text('ランク: Freelance', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('学校リスト'),
              onTap: () => Navigator.pushNamed(context, '/schools'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('選手リスト'),
              onTap: () => Navigator.pushNamed(context, '/players'),
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('ニュース'),
              onTap: () => Navigator.pushNamed(context, '/news'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('スカウトスキル'),
              onTap: () => Navigator.pushNamed(context, '/scoutSkill'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('ゲーム保存'),
              onTap: () async {
                final gameManager = Provider.of<GameManager>(context, listen: false);
                final newsService = Provider.of<NewsService>(context, listen: false);
                await gameManager.saveGameWithNews(newsService);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ゲームを保存しました')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('メインメニュー'),
              onTap: () => Navigator.pushReplacementNamed(context, '/mainMenu'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ゲーム情報カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ゲーム情報',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _infoRow(Icons.calendar_today, '現在の日付', '${game.currentYear}年${game.currentMonth}月${game.currentWeekOfMonth}週目'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.school, '学校数', '${game.schools.length}校'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.people, '発掘済み選手', '${game.discoveredPlayers.length}名'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.favorite, 'お気に入り選手', '${game.favoritePlayers.length}名'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.visibility, '視察済み選手', '${game.watchedPlayers.length}名'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // スカウト情報カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'スカウト情報',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _infoRow(Icons.flash_on, 'アクションポイント', '${game.ap}/15'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.attach_money, '予算', '¥${game.budget.toStringAsFixed(0)}'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.star, '評判', '${game.reputation}'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.trending_up, '経験値', '${game.experience}'),
                        const SizedBox(height: 8),
                        _infoRow(Icons.speed, 'レベル', '${game.level}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ニュース
                _buildExpandableCard(
                  icon: Icons.article,
                  title: '最新ニュース',
                  isExpanded: _newsExpanded,
                  onTap: () => setState(() {
                    _newsExpanded = !_newsExpanded;
                    _historyExpanded = false;
                    _actionsExpanded = false;
                  }),
                  child: _buildNewsContent(newsService),
                ),
                const SizedBox(height: 8),
                
                // アクションキュー
                _buildExpandableCard(
                  icon: Icons.queue,
                  title: '今週のアクションキュー',
                  isExpanded: _actionsExpanded,
                  onTap: () => setState(() {
                    _actionsExpanded = !_actionsExpanded;
                    _newsExpanded = false;
                    _historyExpanded = false;
                  }),
                  child: _buildActionsContent(game),
                ),
                const SizedBox(height: 8),
                
                // アクション履歴
                _buildExpandableCard(
                  icon: Icons.history,
                  title: 'アクション履歴',
                  isExpanded: _historyExpanded,
                  onTap: () => setState(() {
                    _historyExpanded = !_historyExpanded;
                    _newsExpanded = false;
                    _actionsExpanded = false;
                  }),
                  child: _buildHistoryContent(),
                ),
              ],
            ),
          ),
          // 成長処理状態の表示
          if (gameManager.isProcessingGrowth)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        gameManager.growthStatusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final gameManager = Provider.of<GameManager>(context, listen: false);
          final newsService = Provider.of<NewsService>(context, listen: false);
          final dataService = Provider.of<DataService>(context, listen: false);
          final results = await gameManager.advanceWeekWithResults(newsService, dataService);
          setState(() {
            _weekLogs.insert(0, results);
            // 履歴を最新20週分に制限
            if (_weekLogs.length > 20) {
              _weekLogs.removeRange(20, _weekLogs.length);
            }
          });
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('今週の行動リザルト'),
              content: SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: results.isEmpty
                    ? [const Text('今週は行動がありませんでした')] 
                    : results.map((r) => Text(r)).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.skip_next),
        label: const Text('次の週へ進める'),
      ),
    );
  }



  String _actionTypeToText(String type) {
    switch (type) {
      case 'PRAC_WATCH':
        return '練習視察';
      case 'GAME_WATCH':
        return '試合観戦';
      case 'SCOUT_SCHOOL':
        return '学校視察';
      case 'scrimmage':
        return '練習試合観戦';
      case 'interview':
        return 'インタビュー';
      case 'videoAnalyze':
        return 'ビデオ分析';
      case 'PRACTICE_WATCH':
        return '練習視察（単一）';
      default:
        return type;
    }
  }

  String _getSchoolName(int schoolId, Game game) {
    if (schoolId < game.schools.length) {
      return game.schools[schoolId].name;
    }
    return '不明な学校';
  }

  // 情報行ウィジェット
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // 統計チップウィジェット
  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.blue[700])),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700])),
        ],
      ),
    );
  }

  // アコーディオンカードウィジェット
  Widget _buildExpandableCard({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: onTap,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
        ],
      ),
    );
  }

  // ニュースコンテンツ
  Widget _buildNewsContent(NewsService newsService) {
    if (newsService.newsList.isEmpty) {
      return const Text('ニュースはありません');
    }
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: newsService.newsList.length,
        itemBuilder: (context, index) {
          final news = newsService.newsList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(news.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(news.getFormattedDate()),
              onTap: () => Navigator.pushNamed(context, '/newsDetail', arguments: news),
            ),
          );
        },
      ),
    );
  }

  // アクションコンテンツ
  Widget _buildActionsContent(Game game) {
    if (game.weeklyActions.isEmpty) {
      return const Text('今週の行動は未設定');
    }
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: game.weeklyActions.length,
        itemBuilder: (context, index) {
          final action = game.weeklyActions[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(_actionTypeToText(action.type), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${_getSchoolName(action.schoolId, game)} - AP:${action.apCost} / ¥${action.budgetCost ~/ 1000}k'),
            ),
          );
        },
      ),
    );
  }

  // 履歴コンテンツ
  Widget _buildHistoryContent() {
    if (_weekLogs.isEmpty) {
      return const Text('まだ履歴がありません');
    }
    
    // 履歴を最新20週分に制限
    final limitedLogs = _weekLogs.take(20).toList();
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: limitedLogs.length,
        itemBuilder: (context, index) {
          final week = limitedLogs.length - index;
          final logs = limitedLogs[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ExpansionTile(
              title: Text('第${week}週リザルト'),
              children: logs.map((log) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(log),
              )).toList(),
            ),
          );
        },
      ),
    );
  }


} 