import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/news_service.dart';
import '../services/data_service.dart';
import '../models/game/game.dart';
import '../models/game/high_school_tournament.dart';
import '../models/professional/professional_team.dart';
import '../models/school/school.dart';
import '../models/player/player.dart';
import '../models/news/news_item.dart';
import '../models/game/pennant_race.dart';
import '../widgets/player_list_card.dart';
import '../widgets/news_card.dart';
import '../widgets/tournament_bracket_widget.dart';
import '../widgets/tournament_list_widget.dart';
import '../screens/tournament_screen.dart';


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
  bool _eventsExpanded = false;
  bool _scheduleExpanded = false;
  bool _progressExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final newsService = Provider.of<NewsService>(context, listen: false);
    final game = gameManager.currentGame;

    // デバッグ: ゲームの状態を詳しく確認
    print('GameScreen.build: ゲーム状態確認');
    print('GameScreen.build: gameManager = ${gameManager != null ? "loaded" : "null"}');
    print('GameScreen.build: game = ${game != null ? "loaded" : "null"}');
    if (game != null) {
      print('GameScreen.build: 学校数: ${game.schools.length}');
      print('GameScreen.build: 発掘選手数: ${game.discoveredPlayers.length}');
      print('GameScreen.build: スカウト名: ${game.scoutName}');
    }

    if (game == null) {
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
            ListTile(
              leading: const Icon(Icons.sports_baseball),
              title: const Text('プロ野球団'),
              onTap: () => Navigator.pushNamed(context, '/professionalTeams'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('ペナントレース'),
              onTap: () => Navigator.pushNamed(context, '/pennantRace'),
            ),
            ListTile(
              leading: const Icon(Icons.sports_baseball),
              title: const Text('高校野球大会'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentScreen(
                    tournaments: game.highSchoolTournaments,
                    schools: game.schools,
                  ),
                ),
              ),
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
                        const SizedBox(height: 8),
                        _infoRow(Icons.school, '卒業生', '${game.schools.fold(0, (sum, school) => sum + school.players.where((p) => p.isGraduated).length)}名'),
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
                
                // ペナントレース情報
                if (gameManager.isPennantRaceActive)
                  _buildExpandableCard(
                    icon: Icons.emoji_events,
                    title: 'ペナントレース',
                    isExpanded: false,
                    onTap: () => Navigator.pushNamed(context, '/pennantRace'),
                    child: _buildPennantRaceContent(gameManager),
                  ),
                const SizedBox(height: 8),
                
                // 高校野球大会情報
                if (game.highSchoolTournaments.isNotEmpty)
                  _buildExpandableCard(
                    icon: Icons.sports_baseball,
                    title: '高校野球大会',
                    isExpanded: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentScreen(
                          tournaments: game.highSchoolTournaments,
                          schools: game.schools,
                        ),
                      ),
                    ),
                    child: _buildTournamentContent(game),
                  ),
                const SizedBox(height: 8),
                
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
                
                // 進行中のイベント
                _buildExpandableCard(
                  icon: Icons.event,
                  title: '進行中のイベント',
                  isExpanded: _eventsExpanded,
                  onTap: () => setState(() {
                    _eventsExpanded = !_eventsExpanded;
                    _newsExpanded = false;
                    _actionsExpanded = false;
                    _historyExpanded = false;
                  }),
                  child: _buildEventsContent(),
                ),
                
                // 今週の予定
                _buildExpandableCard(
                  icon: Icons.schedule,
                  title: '今週の予定',
                  isExpanded: _scheduleExpanded,
                  onTap: () => setState(() {
                    _scheduleExpanded = !_scheduleExpanded;
                    _newsExpanded = false;
                    _actionsExpanded = false;
                    _historyExpanded = false;
                    _eventsExpanded = false;
                  }),
                  child: _buildScheduleContent(),
                ),
                
                // 週進行状況
                _buildExpandableCard(
                  icon: Icons.timeline,
                  title: '週進行状況',
                  isExpanded: _progressExpanded,
                  onTap: () => setState(() {
                    _progressExpanded = !_progressExpanded;
                    _newsExpanded = false;
                    _actionsExpanded = false;
                    _historyExpanded = false;
                    _eventsExpanded = false;
                    _scheduleExpanded = false;
                  }),
                  child: _buildProgressContent(),
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
      floatingActionButton: Consumer<GameManager>(
        builder: (context, gameManager, child) {
          final isProcessing = !gameManager.canAdvanceWeek;
          final isAdvancingWeek = gameManager.isAdvancingWeek;
          final statusMessage = gameManager.growthStatusMessage;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 処理状態メッセージ
              if (isProcessing && statusMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Text(
                    statusMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // 週進行中のメッセージ
              if (isAdvancingWeek)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Text(
                    '週進行処理中...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // ドラフト週の場合はドラフトボタンを表示
              if (gameManager.isDraftWeek)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/draft');
                    },
                    icon: const Icon(Icons.sports_baseball),
                    label: const Text('ドラフト会議に参加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              
              // 週送りボタン
              FloatingActionButton.extended(
                onPressed: isProcessing ? null : () async {
                  // 処理中はボタンを無効化
                  if (gameManager.isAdvancingWeek) {
                    print('週送り処理が既に進行中のため、処理をスキップします');
                    return;
                  }
                  
                  try {
                    final newsService = Provider.of<NewsService>(context, listen: false);
                    final dataService = Provider.of<DataService>(context, listen: false);
                    final results = await gameManager.advanceWeekWithResults(newsService, dataService);
                    
                    // 処理完了後にUIを更新
                    if (mounted) {
                      setState(() {
                        _weekLogs.insert(0, results);
                        // 履歴を最新20週分に制限
                        if (_weekLogs.length > 20) {
                          _weekLogs.removeRange(20, _weekLogs.length);
                        }
                      });
                      
                      // 結果ダイアログを表示
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
                    }
                  } catch (e) {
                    // エラーが発生した場合の処理
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('週送り処理中にエラーが発生しました: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    print('週送り処理でエラーが発生しました: $e');
                  }
                },
                icon: Icon(
                  isAdvancingWeek ? Icons.hourglass_empty : (isProcessing ? Icons.hourglass_empty : Icons.skip_next),
                  color: isProcessing ? Colors.grey[400] : null,
                ),
                label: Text(
                  isAdvancingWeek ? '週進行中...' : (isProcessing ? '処理中...' : '次の週へ進める'),
                  style: TextStyle(
                    color: isProcessing ? Colors.grey[400] : null,
                  ),
                ),
                backgroundColor: isProcessing ? Colors.grey[300] : null,
              ),
            ],
          );
        },
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

  // 進行中のイベントコンテンツ
  Widget _buildEventsContent() {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final events = gameManager.getCurrentEvents();
        
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('進行中のイベントはありません', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('今週は特別なイベントがありません', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: Text(event, style: const TextStyle(fontWeight: FontWeight.bold)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            );
          },
        );
      },
    );
  }

  // 今週の予定コンテンツ
  Widget _buildScheduleContent() {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final schedule = gameManager.getThisWeekSchedule();
        
        if (schedule.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('今週の予定はありません', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('今週は試合や大会の予定がありません', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            final scheduleItem = schedule[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: const Icon(Icons.schedule, color: Colors.green),
                title: Text(scheduleItem, style: const TextStyle(fontWeight: FontWeight.bold)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            );
          },
        );
      },
    );
  }

  // 週進行状況コンテンツ
  Widget _buildProgressContent() {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final game = gameManager.currentGame;
        if (game == null) return const Text('ゲームデータが読み込まれていません');
        
        final month = game.currentMonth;
        final week = game.currentWeekOfMonth;
        final year = game.currentYear;
        final currentWeek = gameManager.calculateCurrentWeek(month, week);
        final totalWeeks = 52; // 1年52週
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 現在の日付情報
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${year}年${month}月${week}週',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '週 ${currentWeek}/${totalWeeks}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 進行状況バー
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '年間進行状況',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: currentWeek / totalWeeks,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${((currentWeek / totalWeeks) * 100).toStringAsFixed(1)}% 完了',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 今週の状態
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今週の状態',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            gameManager.isAdvancingWeek ? Icons.pause : Icons.play_arrow,
                            color: gameManager.isAdvancingWeek ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            gameManager.isAdvancingWeek ? '週進行処理中' : '週進行可能',
                            style: TextStyle(
                              color: gameManager.isAdvancingWeek ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (gameManager.isProcessingGrowth) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.trending_up, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '成長処理中',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ペナントレースコンテンツ
  Widget _buildPennantRaceContent(GameManager gameManager) {
    final game = gameManager.currentGame;
    if (game?.pennantRace == null) {
      return const Text('ペナントレースデータがありません');
    }

    final pennantRace = game!.pennantRace!;
    final progress = gameManager.pennantRaceProgress;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('進行状況: $progress'),
        const SizedBox(height: 8),
        Text('現在: ${pennantRace.currentMonth}月${pennantRace.currentWeek}週'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('セ・リーグ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('1位: ${_getTeamNameById(pennantRace.getLeagueStandings(League.central).firstOrNull?.teamId, game)}'),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('パ・リーグ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('1位: ${_getTeamNameById(pennantRace.getLeagueStandings(League.pacific).firstOrNull?.teamId, game)}'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/pennantRace'),
          child: const Text('詳細を見る'),
        ),
      ],
    );
  }

  String _getTeamNameById(String? teamId, Game game) {
    if (teamId == null) return '未定';
    try {
      final team = game.professionalTeams.teams.firstWhere((t) => t.id == teamId);
      return team.shortName;
    } catch (e) {
      return '未定';
    }
  }

  // 大会コンテンツ
  Widget _buildTournamentContent(Game game) {
    final activeTournaments = game.highSchoolTournaments.where((t) => !t.isCompleted).toList();
    final completedTournaments = game.highSchoolTournaments.where((t) => t.isCompleted).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeTournaments.isNotEmpty) ...[
          Text('進行中の大会: ${activeTournaments.length}大会', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...activeTournaments.take(3).map((tournament) => _buildTournamentSummary(tournament)),
        ],
        if (completedTournaments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('終了した大会: ${completedTournaments.length}大会', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...completedTournaments.take(2).map((tournament) => _buildTournamentSummary(tournament)),
        ],
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentScreen(
                tournaments: game.highSchoolTournaments,
                schools: game.schools,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('詳細を見る'),
        ),
      ],
    );
  }

  Widget _buildTournamentSummary(HighSchoolTournament tournament) {
    final tournamentName = _getTournamentName(tournament.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tournamentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (tournament.championSchoolName != null || tournament.runnerUpSchoolName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (tournament.championSchoolName != null)
                        Text(
                          '優勝: ${tournament.championSchoolName}',
                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      if (tournament.championSchoolName != null && tournament.runnerUpSchoolName != null)
                        const SizedBox(width: 12),
                      if (tournament.runnerUpSchoolName != null)
                        Text(
                          '準優勝: ${tournament.runnerUpSchoolName}',
                          style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTournamentName(TournamentType type) {
    switch (type) {
      case TournamentType.spring:
        return '春の大会';
      case TournamentType.summer:
        return '夏の大会';
      case TournamentType.autumn:
        return '秋の大会';
      case TournamentType.springNational:
        return '春の全国大会';
    }
  }

} 