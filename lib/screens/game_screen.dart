import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/news_service.dart';
import '../services/data_service.dart';
import '../models/game/game.dart';
import '../models/scouting/action.dart' as scouting;
import '../models/scouting/scout.dart';
import '../models/scouting/scouting_history.dart';
import '../models/scouting/skill.dart';
import '../services/scouting/action_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<List<String>> _weekLogs = [];
  ScoutingHistory? _scoutingHistory;
  List<String> _actionLogMessages = [];

  @override
  void initState() {
    super.initState();
    _initializeScoutingHistory();
  }

  void _initializeScoutingHistory() {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    if (game != null) {
      _scoutingHistory = ScoutingHistory.create(
        scoutId: '1',
        targetId: 'player_1',
        targetType: 'player',
      );
    }
  }

  void _executeScoutAction(scouting.Action action) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    if (game == null) return;

    // ゲームのスカウト情報を取得（仮の実装）
    final scout = Scout.createDefault(id: '1', name: game.scoutName);
    
    final result = ActionService.executeAction(
      action: action,
      scout: scout,
      targetId: 'player_1',
      targetType: 'player',
      history: _scoutingHistory,
      currentWeek: game.currentWeekOfMonth,
    );

    setState(() {
      if (result.isSuccessful && result.record != null) {
        _scoutingHistory = _scoutingHistory?.addRecord(result.record!);
      }

      // ログメッセージを追加
      final message = result.isSuccessful
          ? '${action.name}: 成功 (精度: ${result.accuracy?.toStringAsFixed(1)}%)'
          : '${action.name}: 失敗 (${result.failureReason})';
      
      _actionLogMessages.insert(0, message);
      if (_actionLogMessages.length > 10) {
        _actionLogMessages.removeLast();
      }
    });
  }

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
              title: const Text('スカウトテスト'),
              onTap: () => _showScoutTestDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('セーブ'),
              onTap: () async {
                final dataService = Provider.of<DataService>(context, listen: false);
                final gameManager = Provider.of<GameManager>(context, listen: false);
                final slot = await showDialog<int>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('セーブスロットを選択'),
                    children: [
                      for (int i = 1; i <= 3; i++)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, i),
                          child: Text('スロット$i'),
                        ),
                    ],
                  ),
                );
                if (slot != null) {
                  await dataService.saveGameDataToSlot(gameManager.currentGame!.toJson(), slot);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('スロット$slotにセーブしました')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('ロード'),
              onTap: () async {
                final dataService = Provider.of<DataService>(context, listen: false);
                final loaded = await gameManager.loadGame(dataService);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loaded ? 'ロードしました' : 'セーブデータがありません')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('ホームに戻る'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/mainMenu', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要ステータス
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusCard(Icons.calendar_today, '日付', game.getFormattedDate()),
                  _statusCard(Icons.flash_on, 'AP', game.ap.toString()),
                  _statusCard(Icons.attach_money, '予算', '¥${game.budget ~/ 1000}k'),
                  _statusCard(Icons.star, '評判', game.reputation.toString()),
                  _statusCard(Icons.trending_up, '経験値', game.experience.toString()),
                  _statusCard(Icons.leaderboard, 'レベル', game.level.toString()),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 今週の計画
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.list_alt),
                        SizedBox(width: 8),
                        Text('今週の計画', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: game.weeklyActions.isEmpty
                        ? const Center(child: Text('今週の行動は未設定'))
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: game.weeklyActions.map((a) => Card(
                              color: Colors.blue[50],
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_actionTypeToText(a.type), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(_getSchoolName(a.schoolId, game)),
                                    Text('AP:${a.apCost} / ¥${a.budgetCost ~/ 1000}k'),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 統計
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBlock('発掘選手', game.discoveredPlayers.length.toString()),
                    _statBlock('注目選手', game.watchedPlayers.length.toString()),
                    _statBlock('お気に入り', game.favoritePlayers.length.toString()),
                    _statBlock('ニュース', newsService.newsList.length.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ニュース
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.article),
                        SizedBox(width: 8),
                        Text('最新ニュース', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: newsService.newsList.isEmpty
                        ? const Text('ニュースはありません')
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: newsService.newsList.take(3).map((n) => Card(
                              color: Colors.white, // 明るい背景色
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                    Text(n.getFormattedDate(), style: const TextStyle(fontSize: 12, color: Colors.black)),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // アクション履歴（週送りリザルトログ）
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.history),
                          SizedBox(width: 8),
                          Text('アクション履歴', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _weekLogs.isEmpty
                          ? const Center(child: Text('まだ履歴がありません'))
                          : ListView.builder(
                              itemCount: _weekLogs.length,
                              itemBuilder: (context, i) {
                                final week = _weekLogs.length - i;
                                final logs = _weekLogs[i];
                                return Card(
                                  color: Colors.grey[100],
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text('第${week}週リザルト'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: logs.map((l) => Text(l)).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final gameManager = Provider.of<GameManager>(context, listen: false);
          final newsService = Provider.of<NewsService>(context, listen: false);
          final dataService = Provider.of<DataService>(context, listen: false);
          final results = await gameManager.advanceWeekWithResults(newsService, dataService);
          setState(() {
            _weekLogs.insert(0, results);
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

  Widget _statusCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
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

  void _showScoutTestDialog(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    if (game == null) return;

    final scout = Scout.createDefault(id: '1', name: game.scoutName);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 700,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'スカウトテスト',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // スカウト情報
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'スカウト: ${scout.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('レベル: ${scout.level}'),
                                Text('AP: ${scout.actionPoints}/${scout.maxActionPoints}'),
                                Text('体力: ${scout.stamina}/${scout.maxStamina}'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('所持金: ¥${scout.money.toStringAsFixed(0)}'),
                                Text('信頼度: ${scout.trustLevel}'),
                                Text('成功率: ${(scout.successRate * 100).toStringAsFixed(1)}%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // スキル表示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'スキル',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: Skill.values.map((skill) {
                          final value = scout.getSkill(skill);
                          return Chip(
                            label: Text('${skill.displayName}: $value'),
                            backgroundColor: value >= 7 
                                ? Colors.green[100] 
                                : value >= 5 
                                    ? Colors.orange[100] 
                                    : Colors.grey[100],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // アクションボタン
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'アクション',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: scouting.Action.getAll().length,
                        itemBuilder: (context, index) {
                          final action = scouting.Action.getAll()[index];
                          final canExecute = scout.actionPoints >= action.actionPoints &&
                                           scout.money >= action.cost &&
                                           scout.stamina >= action.actionPoints * 5;
                          
                          return ElevatedButton(
                            onPressed: canExecute ? () => _executeScoutAction(action) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canExecute ? null : Colors.grey[300],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  action.name,
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'AP: ${action.actionPoints} ¥: ${action.cost}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // ログ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '実行ログ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          itemCount: _actionLogMessages.length,
                          itemBuilder: (context, index) {
                            final message = _actionLogMessages[index];
                            final isSuccess = message.contains('成功');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                message,
                                style: TextStyle(
                                  color: isSuccess ? Colors.green : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 