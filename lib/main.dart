import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'dart:math';
import 'game_models.dart';
import 'game_system.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ScoutGameApp());
}

class ScoutGameApp extends StatelessWidget {
  const ScoutGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scout - フリーランススカウト',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlue],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // タイトル
              const Text(
                'Scout',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'フリーランススカウト',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 80),
              // メニューボタン
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const GameScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('ニューゲーム'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _showLoadGameDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      child: const Text('つづきから'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('ゲームについて'),
                              content: const Text(
                                '高校野球スカウトとして、優秀な選手を発掘し、'
                                'プロ野球界に送り出すことを目指すゲームです。\n\n'
                                '1週間を1ターンとし、52週で1年が終わります。\n'
                                'AP（アクションポイント）と予算を使って、'
                                '様々なスカウト活動を行ってください。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('閉じる'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text(
                        'ゲームについて',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<SaveSlot>>(
          future: _getSaveSlots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }

            final saveSlots = snapshot.data ?? [];
            return AlertDialog(
              title: const Text('セーブデータを選択'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 自動セーブスロット
                    Card(
                      color: Colors.blue.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.auto_awesome, color: Colors.blue),
                        title: const Text('自動セーブ'),
                        subtitle: saveSlots[0]?.hasData == true
                            ? Text('${saveSlots[0]!.year}年 ${saveSlots[0]!.week}週目')
                            : const Text('自動セーブなし'),
                        trailing: saveSlots[0]?.hasData == true
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteSaveSlot(context, 0),
                              )
                            : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const GameScreen(saveSlotIndex: 0),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 手動セーブスロット
                    for (int i = 1; i < 4; i++)
                      Card(
                        child: ListTile(
                          title: Text('手動セーブ ${i}'),
                          subtitle: saveSlots[i]?.hasData == true
                              ? Text('${saveSlots[i]!.year}年 ${saveSlots[i]!.week}週目')
                              : const Text('空のスロット'),
                          trailing: saveSlots[i]?.hasData == true
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSaveSlot(context, i),
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => GameScreen(saveSlotIndex: i),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<SaveSlot>> _getSaveSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final slots = <SaveSlot>[];
    
    for (int i = 0; i < 4; i++) { // 0-3の4スロット
      final jsonStr = prefs.getString('save_data_$i');
      if (jsonStr != null) {
        try {
          final map = jsonDecode(jsonStr);
          final gameState = GameState.fromJson(map);
          slots.add(SaveSlot(
            hasData: true,
            year: gameState.currentYear,
            week: gameState.currentWeek,
          ));
        } catch (_) {
          slots.add(SaveSlot(hasData: false));
        }
      } else {
        slots.add(SaveSlot(hasData: false));
      }
    }
    
    return slots;
  }

  Future<void> _deleteSaveSlot(BuildContext context, int index) async {
    final slotName = index == 0 ? '自動セーブ' : '手動セーブ ${index}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: Text('$slotName のデータを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('save_data_$index');
      Navigator.of(context).pop();
      _showLoadGameDialog(context);
    }
  }
}

class SaveSlot {
  final bool hasData;
  final int? year;
  final int? week;

  SaveSlot({
    required this.hasData,
    this.year,
    this.week,
  });
}

class GameScreen extends StatefulWidget {
  final int? saveSlotIndex;
  const GameScreen({super.key, this.saveSlotIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late ScoutGame _game;
  bool _loading = true;
  int _currentSaveSlot = 0;

  @override
  void initState() {
    super.initState();
    _currentSaveSlot = widget.saveSlotIndex ?? 0;
    _initGame();
  }

  Future<void> _initGame() async {
    if (widget.saveSlotIndex != null) {
      final loaded = await _loadGameState(widget.saveSlotIndex!);
      if (loaded != null) {
        _game = ScoutGame(gameState: loaded);
      } else {
        // セーブデータがなければ新規
        _game = ScoutGame();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('セーブデータが見つかりません'), backgroundColor: Colors.orange),
          );
        });
      }
    } else {
      _game = ScoutGame();
    }
    setState(() { _loading = false; });
  }

  Future<void> _saveGameState([int? slotIndex]) async {
    final prefs = await SharedPreferences.getInstance();
    final saveSlot = slotIndex ?? _currentSaveSlot;
    final jsonStr = jsonEncode(_game.gameState.toJson());
    await prefs.setString('save_data_$saveSlot', jsonStr);
    
    String slotName;
    if (saveSlot == 0) {
      slotName = '自動セーブ';
    } else {
      slotName = '手動セーブ $saveSlot';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$slotNameにセーブしました'), backgroundColor: Colors.blue),
    );
  }

  Future<GameState?> _loadGameState(int slotIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('save_data_$slotIndex');
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr);
      return GameState.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('手動セーブスロットを選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 1; i < 4; i++) // 手動セーブはスロット1-3のみ
                ListTile(
                  title: Text('手動セーブ $i'),
                  subtitle: i == _currentSaveSlot ? const Text('現在のスロット') : null,
                  trailing: i == _currentSaveSlot ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    _saveGameState(i);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scout - フリーランススカウト'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showSaveDialog,
            icon: const Icon(Icons.save),
            tooltip: 'セーブ',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.home),
            tooltip: 'メインメニューに戻る',
          ),
        ],
      ),
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'button_overlay': (context, game) => ButtonOverlay(
            game: game as ScoutGame,
            onAdvanceWeek: () => _autoSave(),
          ),
        },
      ),
    );
  }

  Future<void> _autoSave() async {
    await _saveGameState(0); // 自動セーブは常にスロット0
  }
}

class ButtonOverlay extends StatelessWidget {
  final ScoutGame game;
  final VoidCallback onAdvanceWeek;
  
  const ButtonOverlay({super.key, required this.game, required this.onAdvanceWeek});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 50,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('翌週に進むボタンが押されました！');
                    game.advanceWeek();
                    onAdvanceWeek(); // 自動セーブを実行
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('翌週に進む'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    print('ダッシュボードを開きます');
                    _showDashboard(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('ダッシュボード'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showDashboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                // ヘッダー
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'スカウトダッシュボード',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // タブ
                Expanded(
                  child: DefaultTabController(
                    length: 4,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          tabs: [
                            Tab(text: '概要'),
                            Tab(text: 'スカウト'),
                            Tab(text: '学校'),
                            Tab(text: '選手'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildOverviewTab(context),
                              _buildScoutingTab(),
                              _buildSchoolsTab(context),
                              _buildPlayersTab(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 最新ニュース
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.newspaper, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        '最新ニュース',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showNewsDialog(context),
                        child: const Text('すべて見る'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (game.gameState.news.isNotEmpty) ...[
                    _buildNewsCard(context, game.gameState.news.last),
                    if (game.gameState.news.length > 1) ...[
                      const SizedBox(height: 8),
                      _buildNewsCard(context, game.gameState.news[game.gameState.news.length - 2]),
                    ],
                    if (game.gameState.news.length > 2) ...[
                      const SizedBox(height: 8),
                      _buildNewsCard(context, game.gameState.news[game.gameState.news.length - 3]),
                    ],
                  ] else ...[
                    const Text(
                      'ニュースはありません',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 最新試合結果
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_baseball, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        '最新試合結果',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showGameResultsDialog(context),
                        child: const Text('すべて見る'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (game.gameState.gameResults.isNotEmpty) ...[
                    _buildGameResultCard(context, game.gameState.gameResults.last),
                    if (game.gameState.gameResults.length > 1) ...[
                      const SizedBox(height: 8),
                      _buildGameResultCard(context, game.gameState.gameResults[game.gameState.gameResults.length - 2]),
                    ],
                    if (game.gameState.gameResults.length > 2) ...[
                      const SizedBox(height: 8),
                      _buildGameResultCard(context, game.gameState.gameResults[game.gameState.gameResults.length - 3]),
                    ],
                  ] else ...[
                    const Text(
                      '試合結果はありません',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // ゲーム統計
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'ゲーム統計',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '総試合数',
                          '${game.gameState.gameResults.length}',
                          Icons.sports_baseball,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          '発見選手',
                          '${game.gameState.discoveredPlayers.length}',
                          Icons.person_search,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '総学校数',
                          '${game.gameState.schools.length}',
                          Icons.school,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          '総選手数',
                          '${game.gameState.schools.fold(0, (sum, school) => sum + school.players.length)}',
                          Icons.people,
                          Colors.purple,
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
    );
  }
  
  Widget _buildGameResultCard(BuildContext context, GameResult gameResult) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showGameDetailDialog(context, gameResult),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ホームチーム
              Expanded(
                child: Text(
                  gameResult.homeTeam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: gameResult.isHomeWin ? FontWeight.bold : FontWeight.normal,
                    color: gameResult.isHomeWin ? Colors.red : Colors.black,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              // スコア
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${gameResult.homeScore} - ${gameResult.awayScore}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // アウェイチーム
              Expanded(
                child: Text(
                  gameResult.awayTeam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: !gameResult.isHomeWin ? FontWeight.bold : FontWeight.normal,
                    color: !gameResult.isHomeWin ? Colors.red : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
            Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            ),
          ],
        ),
    );
  }
  
  void _showGameResultsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // ヘッダー
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '⚾ 試合結果一覧',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // 試合結果リスト
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: game.gameState.gameResults.length,
                    itemBuilder: (context, index) {
                      final gameResult = game.gameState.gameResults[game.gameState.gameResults.length - 1 - index];
                      return _buildGameResultCard(context, gameResult);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showGameDetailDialog(BuildContext context, GameResult gameResult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.sports_baseball, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text('${gameResult.homeTeam} vs ${gameResult.awayTeam}')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // スコア
                Center(
                  child: Text(
                    '${gameResult.homeScore} - ${gameResult.awayScore}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${gameResult.winner} 勝利',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 試合情報
                Text('試合種別: ${gameResult.gameType}'),
                Text('試合日: ${_formatTimestamp(gameResult.gameDate)}'),
                const SizedBox(height: 16),
                
                // 選手成績（上位3名）
                const Text(
                  '注目選手',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...gameResult.performances.take(3).map((performance) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${performance.playerName} (${performance.school}) - ${performance.position}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  )
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return '今';
    }
  }

  Widget _buildSchoolsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '学校一覧',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...game.gameState.schools.map((school) => Card(
            child: ListTile(
              title: Text(school.name),
              subtitle: Text('選手: ${school.players.length}名'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('監督: ${school.coachName}'),
                  Text('信頼度: ${school.coachTrust}'),
                ],
              ),
              onTap: () => _showSchoolDetails(context, school),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildPlayersTab(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '注目選手'),
              Tab(text: '人気選手'),
              Tab(text: '全選手'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildWatchedPlayersTab(context),
                _buildFamousPlayersTab(context),
                _buildAllPlayersTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchedPlayersTab(BuildContext context) {
    final watchedPlayers = game.gameState.schools
        .expand((school) => school.players)
        .where((player) => player.isWatched)
        .toList();
    
    if (watchedPlayers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '注目している選手はいません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '選手をタップして「注目する」を選択してください',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: watchedPlayers.length,
      itemBuilder: (context, index) {
        final player = watchedPlayers[index];
        return _buildPlayerCard(context, player, true);
      },
    );
  }

  Widget _buildFamousPlayersTab(BuildContext context) {
    final allPlayers = game.gameState.schools
        .expand((school) => school.players)
        .toList();
    
    // 知名度でソート（上位20名）
    allPlayers.sort((a, b) => b.fame.compareTo(a.fame));
    final famousPlayers = allPlayers.take(20).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: famousPlayers.length,
      itemBuilder: (context, index) {
        final player = famousPlayers[index];
        return _buildPlayerCard(context, player, false);
      },
    );
  }

  Widget _buildAllPlayersTab(BuildContext context) {
    final allPlayers = game.gameState.schools
        .expand((school) => school.players)
        .toList();
    
    // 学校・学年・名前でソート
    allPlayers.sort((a, b) {
      if (a.school != b.school) return a.school.compareTo(b.school);
      if (a.grade != b.grade) return b.grade.compareTo(a.grade); // 上級生優先
      return a.name.compareTo(b.name);
    });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allPlayers.length,
      itemBuilder: (context, index) {
        final player = allPlayers[index];
        return _buildPlayerCard(context, player, false);
      },
    );
  }

  Widget _buildPlayerCard(BuildContext context, Player player, bool isWatched) {
    // スカウトスキルをゲーム状態から取得
    final scoutSkill = game.gameState.scoutSkills.observation; // 観察スキルを使用
    final visibleAbility = player.getVisibleAbility(scoutSkill);
    final generalEvaluation = player.getGeneralEvaluation();
    final potentialEvaluation = player.getPotentialEvaluation(scoutSkill);
    final evaluationColor = _getEvaluationColor(generalEvaluation);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: evaluationColor,
          child: Text(
            generalEvaluation,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${player.name} (${player.grade}年)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isWatched)
              const Icon(Icons.visibility, color: Colors.blue, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${player.school} - ${player.position}'),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                Text('知名度: ${player.fame}'),
                const SizedBox(width: 16),
                Text('性格: ${player.personality}'),
              ],
            ),
            Text(
              'ポテンシャル: $potentialEvaluation',
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '評価: $generalEvaluation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: evaluationColor,
              ),
            ),
            Text(
              '能力: $visibleAbility',
              style: const TextStyle(fontSize: 12),
            ),
            if (player.scoutEvaluation != null)
              Text(
                '個人評価: ${player.scoutEvaluation}',
                style: const TextStyle(fontSize: 10, color: Colors.blue),
              ),
          ],
        ),
        onTap: () => _showPlayerDetails(context, player),
        onLongPress: () => _showPlayerActionMenu(context, player),
      ),
    );
  }

  Color _getEvaluationColor(String evaluation) {
    switch (evaluation) {
      case 'S': return Colors.purple;
      case 'A': return Colors.red;
      case 'B': return Colors.orange;
      case 'C': return Colors.yellow.shade700;
      case 'D': return Colors.grey;
      default: return Colors.grey;
    }
  }

  void _showPlayerActionMenu(BuildContext context, Player player) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(player.isWatched ? Icons.visibility_off : Icons.visibility),
                title: Text(player.isWatched ? '注目を外す' : '注目する'),
                onTap: () {
                  player.isWatched = !player.isWatched;
                  Navigator.of(context).pop();
                  // UIを更新
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(player.isWatched ? '${player.name}を注目しました' : '${player.name}の注目を外しました'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('詳細を見る'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showPlayerDetails(context, player);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSchoolDetails(BuildContext context, School school) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(school.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('監督: ${school.coachName}'),
                Text('監督信頼度: ${school.coachTrust}'),
                Text('選手数: ${school.players.length}名'),
                const SizedBox(height: 16),
                const Text('選手一覧:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...school.players.take(5).map((player) => 
                  ListTile(
                    title: Text('${player.name} (${player.grade}年)'),
                    subtitle: Text('${player.position} - 評価: ${player.isPitcher ? player.getPitcherEvaluation() : player.getBatterEvaluation()}'),
                    dense: true,
                  )
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showPlayerDetails(BuildContext context, Player player) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text('${player.name} (${player.grade}年)')),
              if (player.isWatched)
                const Icon(Icons.visibility, color: Colors.blue),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('学校: ${player.school}'),
                Text('ポジション: ${player.position}'),
                Text('評価: ${player.isPitcher ? player.getPitcherEvaluation() : player.getBatterEvaluation()}'),
                Text('総合能力: ${player.getVisibleAbility(game.gameState.scoutSkills.observation)}'),
                Text('知名度: ${player.fame}'),
                Text('性格: ${player.personality}'),
                Text('ポテンシャル: ${player.getPotentialEvaluation(game.gameState.scoutSkills.observation)}'),
                if (player.scoutEvaluation != null) ...[
                  const SizedBox(height: 8),
                  const Text('スカウト評価:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('評価: ${player.scoutEvaluation}'),
                  if (player.scoutNotes != null)
                    Text('メモ: ${player.scoutNotes}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // デバッグ用のSnackBarを追加
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('スカウトアクションボタンがタップされました - AP: ${game.gameState.actionPoints}, 予算: ¥${(game.gameState.budget / 1000).toStringAsFixed(0)}k'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                _showScoutActionsDialog(context, player);
              },
              child: const Text('スカウトアクション'),
            ),
            TextButton(
              onPressed: () {
                _showScoutEvaluationDialog(context, player);
              },
              child: const Text('スカウト評価'),
            ),
            TextButton(
              onPressed: () {
                player.isWatched = !player.isWatched;
                Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(player.isWatched ? '${player.name}を注目しました' : '${player.name}の注目を外しました'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(player.isWatched ? '注目を外す' : '注目する'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showNewsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // ヘッダー
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📰 ニュース一覧',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // ニュースリスト
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: game.gameState.news.length,
                    itemBuilder: (context, index) {
                      final news = game.gameState.news[game.gameState.news.length - 1 - index];
                      return _buildNewsCard(context, news);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsItem news) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showNewsDetail(context, news),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー（カテゴリ、重要度、時間）
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: news.getCategoryColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: news.getCategoryColor()),
                    ),
                    child: Text(
                      news.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: news.getCategoryColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: news.getImportanceColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(news.importance, (index) => 
                        Icon(Icons.star, size: 12, color: news.getImportanceColor())
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(news.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 見出し
              Row(
                children: [
                  Text(
                    news.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      news.headline,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // 本文（短縮版）
              if (news.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  news.content,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // 関連情報
              if (news.school != null || news.player != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (news.school != null) ...[
                      const Icon(Icons.school, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        news.school!,
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ],
                    if (news.school != null && news.player != null) ...[
                      const SizedBox(width: 16),
                    ],
                    if (news.player != null) ...[
                      const Icon(Icons.person, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        news.player!,
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNewsDetail(BuildContext context, NewsItem news) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(news.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(child: Text(news.headline)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // メタ情報
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: news.getCategoryColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: news.getCategoryColor()),
                      ),
                      child: Text(
                        news.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: news.getCategoryColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: news.getImportanceColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(news.importance, (index) => 
                          Icon(Icons.star, size: 12, color: news.getImportanceColor())
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 本文
                if (news.content.isNotEmpty) ...[
                  Text(
                    news.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
                // 関連情報
                if (news.school != null || news.player != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  if (news.school != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.school, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('関連学校: ${news.school}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (news.player != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('関連選手: ${news.player}'),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                Text(
                  '公開日時: ${_formatTimestamp(news.timestamp)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showScoutEvaluationDialog(BuildContext context, Player player) {
    final evaluationController = TextEditingController(text: player.scoutEvaluation ?? '');
    final notesController = TextEditingController(text: player.scoutNotes ?? '');
    final scoutSkill = 50; // 仮のスカウトスキル
    final potentialEvaluation = player.getPotentialEvaluation(scoutSkill);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${player.name}のスカウト評価'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 現在の評価情報
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '現在の評価情報',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                      const SizedBox(height: 8),
                      Text('一般的評価: ${player.getGeneralEvaluation()}'),
                      Text('推定能力: ${player.getVisibleAbility(scoutSkill)}'),
                      Text('ポテンシャル: $potentialEvaluation'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // スカウト評価入力
              TextField(
                controller: evaluationController,
                decoration: const InputDecoration(
                  labelText: 'スカウト評価',
                  hintText: '例: S級候補、有望株、要観察',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                  hintText: '選手についてのメモを記入',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // ポテンシャル評価の提案
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ポテンシャル評価の提案',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                      const SizedBox(height: 8),
                      Text('現在の評価: $potentialEvaluation'),
                      const SizedBox(height: 4),
                      Text(
                        '※この評価はスカウトスキルに基づいて算出されています',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                player.setScoutEvaluation(
                  evaluationController.text,
                  notesController.text,
                );
                Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('スカウト評価を保存しました'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('保存'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  void _showScoutActionsDialog(BuildContext context, Player player) {
    // デバッグ情報を表示
    print('スカウトアクションダイアログを開く');
    print('現在のAP: ${game.gameState.actionPoints}');
    print('現在の予算: ${game.gameState.budget}');
    print('スカウトスキル: ${game.gameState.scoutSkills.exploration}, ${game.gameState.scoutSkills.observation}, ${game.gameState.scoutSkills.analysis}, ${game.gameState.scoutSkills.insight}, ${game.gameState.scoutSkills.communication}, ${game.gameState.scoutSkills.negotiation}, ${game.gameState.scoutSkills.stamina}');
    
    // 利用可能なスカウトアクションを定義
    final availableActions = [
      ScoutingAction(
        id: 'PRAC_WATCH',
        name: '練習視察',
        apCost: 2,
        budgetCost: 20000,
        description: '地元校の練習を見学し、選手の基本能力を確認',
        category: '視察',
        requiredSkills: ['observation'],
        primarySkills: ['observation', 'exploration'],
        baseSuccessRate: 0.60,
        skillModifiers: {'observation': 0.3},
      ),
      ScoutingAction(
        id: 'INTERVIEW',
        name: 'インタビュー',
        apCost: 1,
        budgetCost: 10000,
        description: '選手にインタビューし、性格と動機を確認',
        category: '面談',
        requiredSkills: ['communication'],
        primarySkills: ['communication', 'insight'],
        baseSuccessRate: 0.65,
        skillModifiers: {'communication': 0.4},
      ),
      ScoutingAction(
        id: 'VIDEO_ANALYZE',
        name: 'ビデオ分析',
        apCost: 2,
        budgetCost: 0,
        description: '映像を分析し、技術的なメカニクスを確認',
        category: '分析',
        requiredSkills: ['analysis'],
        primarySkills: ['analysis', 'insight'],
        baseSuccessRate: 0.70,
        skillModifiers: {'analysis': 0.3},
      ),
      ScoutingAction(
        id: 'TEAM_VISIT',
        name: '球団訪問',
        apCost: 1,
        budgetCost: 0,
        description: '球団を訪問し、ニーズと指名候補を確認',
        category: '交渉',
        requiredSkills: ['negotiation'],
        primarySkills: ['negotiation', 'communication'],
        baseSuccessRate: 0.90,
        skillModifiers: {'negotiation': 0.1},
      ),
      ScoutingAction(
        id: 'INFO_SWAP',
        name: '情報交換',
        apCost: 1,
        budgetCost: 0,
        description: '他地域のスカウトと情報交換',
        category: '情報収集',
        requiredSkills: ['communication'],
        primarySkills: ['communication', 'insight'],
        baseSuccessRate: 0.70,
        skillModifiers: {'insight': 0.2},
      ),
      ScoutingAction(
        id: 'NEWS_CHECK',
        name: 'ニュース確認',
        apCost: 0,
        budgetCost: 0,
        description: '最新のニュースを確認',
        category: '情報収集',
        requiredSkills: [],
        primarySkills: ['exploration'],
        baseSuccessRate: 1.0,
        skillModifiers: {},
      ),
    ];
    
    final scoutSkills = game.gameState.scoutSkills;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('スカウトアクション'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 現在のリソース状況
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '現在のリソース',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text('AP: ${game.gameState.actionPoints}'),
                        Text('予算: ¥${(game.gameState.budget / 1000).toStringAsFixed(0)}k'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // スカウトスキル表示
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'スカウトスキル',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text('探索: ${scoutSkills.exploration}'),
                        Text('観察: ${scoutSkills.observation}'),
                        Text('分析: ${scoutSkills.analysis}'),
                        Text('洞察: ${scoutSkills.insight}'),
                        Text('コミュニケーション: ${scoutSkills.communication}'),
                        Text('交渉: ${scoutSkills.negotiation}'),
                        Text('体力: ${scoutSkills.stamina}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 利用可能なアクション
                Text(
                  '利用可能なアクション',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...availableActions.map((action) {
                  final canExecute = action.canExecute(
                    scoutSkills,
                    game.gameState.actionPoints,
                    game.gameState.budget,
                  );
                  
                  // デバッグ情報を追加
                  final debugInfo = 'AP: ${game.gameState.actionPoints}/${action.apCost}, '
                      '予算: ¥${(game.gameState.budget / 1000).toStringAsFixed(0)}k/¥${(action.budgetCost / 1000).toStringAsFixed(0)}k, '
                      'スキル: ${action.requiredSkills.map((skill) => '${skill}:${scoutSkills.getSkill(skill)}').join(', ')}';
                  
                  // 実行可能性の詳細をログに出力
                  print('アクション: ${action.name}');
                  print('  AP: ${game.gameState.actionPoints} >= ${action.apCost} = ${game.gameState.actionPoints >= action.apCost}');
                  print('  予算: ${game.gameState.budget} >= ${action.budgetCost} = ${game.gameState.budget >= action.budgetCost}');
                  for (final skill in action.requiredSkills) {
                    final skillValue = scoutSkills.getSkill(skill);
                    print('  スキル $skill: $skillValue >= 20 = ${skillValue >= 20}');
                  }
                  print('  実行可能: $canExecute');
                  
                  return Card(
                    color: canExecute ? Colors.white : Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  action.name,
                                  style: TextStyle(
                                    color: canExecute ? Colors.black : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (canExecute)
                                ElevatedButton(
                                  onPressed: () {
                                    _showActionTargetDialog(context, action, player);
                                  },
                                  child: const Text('実行'),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('実行不可', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(action.description),
                          const SizedBox(height: 4),
                          Text('AP: ${action.apCost} | ¥${(action.budgetCost / 1000).toStringAsFixed(0)}k'),
                          Text('成功率: ${(action.baseSuccessRate * 100).toStringAsFixed(0)}%'),
                          // デバッグ情報を表示
                          Text(
                            debugInfo,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
  
  // アクションの対象選択ダイアログ
  void _showActionTargetDialog(BuildContext context, ScoutingAction action, Player player) {
    Navigator.of(context).pop(); // 前のダイアログを閉じる
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${action.name}の対象選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${action.name}を実行する対象を選択してください'),
              const SizedBox(height: 16),
              // 対象選択ボタン
              if (action.id == 'PRAC_WATCH' || action.id == 'INTERVIEW' || action.id == 'VIDEO_ANALYZE') ...[
                // 選手個人に対するアクション
                ElevatedButton(
                  onPressed: () {
                    final target = ScoutingTarget(
                      type: 'player',
                      name: player.name,
                      description: '${player.school}の${player.name}',
                    );
                    _executeActionWithTarget(context, action, target);
                  },
                  child: Text('${player.name}（個人）'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final target = ScoutingTarget(
                      type: 'school',
                      name: player.school,
                      description: '${player.school}全体',
                    );
                    _executeActionWithTarget(context, action, target);
                  },
                  child: Text('${player.school}（学校全体）'),
                ),
              ] else if (action.id == 'TEAM_VISIT') ...[
                // 球団訪問
                ElevatedButton(
                  onPressed: () {
                    final target = ScoutingTarget(
                      type: 'team',
                      name: 'プロ野球球団',
                      description: 'プロ野球球団への訪問',
                    );
                    _executeActionWithTarget(context, action, target);
                  },
                  child: const Text('プロ野球球団'),
                ),
              ] else if (action.id == 'INFO_SWAP') ...[
                // 情報交換
                ...['関東', '関西', '中部', '九州', '東北', '北海道'].map((region) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        final target = ScoutingTarget(
                          type: 'region',
                          name: region,
                          description: '${region}地域のスカウト',
                        );
                        _executeActionWithTarget(context, action, target);
                      },
                      child: Text('${region}地域'),
                    ),
                  ),
                ),
              ] else if (action.id == 'NEWS_CHECK') ...[
                // ニュース確認
                ElevatedButton(
                  onPressed: () {
                    final target = ScoutingTarget(
                      type: 'news',
                      name: '最新ニュース',
                      description: '最新のニュース情報',
                    );
                    _executeActionWithTarget(context, action, target);
                  },
                  child: const Text('最新ニュースを確認'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }
  
  // アクションを実行
  void _executeActionWithTarget(BuildContext context, ScoutingAction action, ScoutingTarget target) {
    Navigator.of(context).pop(); // 対象選択ダイアログを閉じる
    
    final result = game.gameState.executeAction(action, target);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'アクション成功: ${result.result}' : 'アクション失敗: ${result.result}'),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // 成功時は詳細結果を表示
      if (result.success && result.additionalData != null) {
        _showActionResultDetails(context, result);
      }
    }
  }
  
  // アクション結果の詳細表示
  void _showActionResultDetails(BuildContext context, ActionResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${result.actionName}の結果'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(result.result),
                if (result.additionalData != null) ...[
                  const SizedBox(height: 16),
                  const Text('詳細情報:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...result.additionalData!.entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${entry.key}: ${entry.value}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}

class ScoutGame extends FlameGame {
  late TextComponent titleText;
  late TextComponent timeText;
  late TextComponent yearText;
  late TextComponent apText;
  late TextComponent budgetText;
  late TextComponent reputationText;
  late TextComponent newsText;
  
  late GameState gameState;
  final bool isNewGame;
  
  ScoutGame({GameState? gameState}) : isNewGame = gameState == null {
    this.gameState = gameState ?? GameState(
      currentWeek: 1,
      currentYear: 2025,
      actionPoints: 6,
      budget: 1000000,
      reputation: 0,
      schools: [],
      discoveredPlayers: [],
      news: [],
      lastWeekActions: [],
      thisWeekSchedule: [],
      gameResults: [],
    );
  }
  
  @override
  Color backgroundColor() => const Color(0xFF1a1a2e); // ダークブルーの背景
  
  @override
  Future<void> onLoad() async {
    // 新規ゲーム時のみ学校を初期化
    if (isNewGame) {
      _initializeSchools();
    }
    
    // タイトル
    titleText = TextComponent(
      text: 'Scout - フリーランススカウト',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
    titleText.position = Vector2(size.x / 2, 40);
    titleText.anchor = Anchor.center;
    add(titleText);
    
    // 時間表示
    timeText = TextComponent(
      text: '${gameState.getCurrentMonth()}${gameState.getWeekInMonth()}週目',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    );
    timeText.position = Vector2(size.x / 2, 80);
    timeText.anchor = Anchor.center;
    add(timeText);
    
    // 年表示
    yearText = TextComponent(
      text: '${gameState.currentYear}年度',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
    yearText.position = Vector2(size.x / 2, 105);
    yearText.anchor = Anchor.center;
    add(yearText);
    
    // ステータス表示エリア
    _createStatusDisplay();
    
    // 今週の予定表示
    _createScheduleDisplay();
    
    // 先週のアクション結果表示
    _createActionResultsDisplay();
    
    // ニュース表示
    newsText = TextComponent(
      text: gameState.news.isNotEmpty ? '📰 ${gameState.news.last.headline}' : '📰 ニュース: なし',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.cyan,
        ),
      ),
    );
    newsText.position = Vector2(size.x / 2, 200);
    newsText.anchor = Anchor.center;
    add(newsText);
    
    // オーバーレイを表示
    overlays.add('button_overlay');
  }
  
  void _createStatusDisplay() {
    // AP表示
    apText = TextComponent(
      text: '⚡ AP: ${gameState.actionPoints}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    apText.position = Vector2(100, 140);
    apText.anchor = Anchor.center;
    add(apText);
    
    // 予算表示
    budgetText = TextComponent(
      text: '💰 ¥${(gameState.budget / 1000).toStringAsFixed(0)}k',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    budgetText.position = Vector2(250, 140);
    budgetText.anchor = Anchor.center;
    add(budgetText);
    
    // 信頼度表示
    reputationText = TextComponent(
      text: '⭐ ${gameState.reputation}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    reputationText.position = Vector2(400, 140);
    reputationText.anchor = Anchor.center;
    add(reputationText);
  }
  
  void _createScheduleDisplay() {
    // 今週の予定タイトル
    final scheduleTitle = TextComponent(
      text: '📅 今週の予定',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    scheduleTitle.position = Vector2(100, 160);
    scheduleTitle.anchor = Anchor.center;
    add(scheduleTitle);
    
    // 今週の予定内容
    if (gameState.thisWeekSchedule.isNotEmpty) {
      final schedule = gameState.thisWeekSchedule.first;
      final scheduleText = TextComponent(
        text: '${schedule.type}: ${schedule.title}',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 12,
            color: Colors.lightBlue,
          ),
        ),
      );
      scheduleText.position = Vector2(100, 180);
      scheduleText.anchor = Anchor.center;
      add(scheduleText);
    } else {
      final scheduleText = TextComponent(
        text: '予定なし',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      );
      scheduleText.position = Vector2(100, 180);
      scheduleText.anchor = Anchor.center;
      add(scheduleText);
    }
  }
  
  void _createActionResultsDisplay() {
    // 先週のアクション結果タイトル
    final resultsTitle = TextComponent(
      text: '📋 先週の結果',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    resultsTitle.position = Vector2(300, 160);
    resultsTitle.anchor = Anchor.center;
    add(resultsTitle);
    
    // 先週のアクション結果内容
    if (gameState.lastWeekActions.isNotEmpty) {
      final result = gameState.lastWeekActions.first;
      final resultText = TextComponent(
        text: '${result.actionName}: ${result.success ? "成功" : "失敗"}',
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 12,
            color: result.success ? Colors.lightGreen : Colors.red,
          ),
        ),
      );
      resultText.position = Vector2(300, 180);
      resultText.anchor = Anchor.center;
      add(resultText);
    } else {
      final resultText = TextComponent(
        text: 'アクションなし',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      );
      resultText.position = Vector2(300, 180);
      resultText.anchor = Anchor.center;
      add(resultText);
    }
  }
  
  void _initializeSchools() {
    final schoolNames = [
      '横浜高校', '慶應義塾高校', '桐光学園高校', '東海大相模高校', 
      '神奈川工科大学附属高校', '横浜隼人高校', '横浜商科大学高校', 
      '横浜創英高校', '横浜清風高校', '横浜翠嵐高校'
    ];
    
    for (String schoolName in schoolNames) {
      final players = <Player>[];
      for (int i = 0; i < 15; i++) {
        players.add(_generateInitialPlayer(schoolName));
      }
      
      gameState.schools.add(School(
        name: schoolName,
        location: '神奈川県',
        players: players,
        coachTrust: Random().nextInt(50) + 20,
        coachName: '監督${Random().nextInt(999) + 1}',
      ));
    }
  }
  
  Player _generateInitialPlayer(String schoolName) {
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final personalities = ['真面目', '明るい', 'クール', 'リーダー', '努力家'];
    
    final isPitcher = Random().nextBool();
    final position = positions[Random().nextInt(positions.length)];
    
    // ポジション適性を生成
    final positionFit = <String, int>{};
    for (String pos in positions) {
      positionFit[pos] = Random().nextInt(50) + 20;
    }
    
    if (isPitcher) {
      return Player(
        name: names[Random().nextInt(names.length)] + 
              (Random().nextInt(999) + 1).toString().padLeft(3, '0'),
        school: schoolName,
        grade: Random().nextInt(3) + 1,
        position: position,
        personality: personalities[Random().nextInt(personalities.length)],
        mentalGrit: Random().nextDouble() * 0.3 - 0.15,
        growthRate: Random().nextDouble() * 0.3 + 0.85,
        peakAbility: Random().nextInt(50) + 100,
        positionFit: positionFit,
        // 投手能力値
        fastballVelo: Random().nextInt(25) + 130, // 130-155km/h
        control: Random().nextInt(50) + 20,
        stamina: Random().nextInt(50) + 20,
        breakAvg: Random().nextInt(50) + 20,
        pitches: [
          Pitch(type: 'ストレート', breakAmount: 0, breakPot: 0, unlocked: true),
          Pitch(type: 'カーブ', breakAmount: Random().nextInt(30) + 10, breakPot: Random().nextInt(30) + 40, unlocked: true),
          Pitch(type: 'スライダー', breakAmount: Random().nextInt(30) + 10, breakPot: Random().nextInt(30) + 40, unlocked: true),
        ],
      );
    } else {
      return Player(
        name: names[Random().nextInt(names.length)] + 
              (Random().nextInt(999) + 1).toString().padLeft(3, '0'),
        school: schoolName,
        grade: Random().nextInt(3) + 1,
        position: position,
        personality: personalities[Random().nextInt(personalities.length)],
        mentalGrit: Random().nextDouble() * 0.3 - 0.15,
        growthRate: Random().nextDouble() * 0.3 + 0.85,
        peakAbility: Random().nextInt(50) + 100,
        positionFit: positionFit,
        // 野手能力値
        batPower: Random().nextInt(50) + 20,
        batControl: Random().nextInt(50) + 20,
        run: Random().nextInt(50) + 20,
        field: Random().nextInt(50) + 20,
        arm: Random().nextInt(50) + 20,
      );
    }
  }
  
  void advanceWeek() {
    print('ボタンが押されました！'); // デバッグログ
    gameState.advanceWeek();
    
    // 選手の成長
    for (var school in gameState.schools) {
      for (var player in school.players) {
        player.grow();
      }
    }
    
    // テキストを更新
    timeText.text = '${gameState.getCurrentMonth()}${gameState.getWeekInMonth()}週目';
    yearText.text = '${gameState.currentYear}年度';
    apText.text = '⚡ AP: ${gameState.actionPoints}';
    budgetText.text = '💰 ¥${(gameState.budget / 1000).toStringAsFixed(0)}k';
    reputationText.text = '⭐ ${gameState.reputation}';
    newsText.text = gameState.news.isNotEmpty ? '📰 ${gameState.news.last.headline}' : '📰 ニュース: なし';
    
    // 今週の予定と先週の結果を再表示
    _updateScheduleAndResults();
    
    print('週が進みました: 週${gameState.currentWeek}, 年${gameState.currentYear}'); // デバッグログ
  }
  
  void _updateScheduleAndResults() {
    // 既存のスケジュールとアクション結果表示を削除
    removeAll(children.where((component) => 
      component is TextComponent && 
      (component.text.contains('📅') || 
       component.text.contains('📋') ||
       component.text.contains('今週の予定') ||
       component.text.contains('先週の結果') ||
       component.text.contains('予定なし') ||
       component.text.contains('アクションなし') ||
       (component.text.contains(':') && (component.text.contains('試合') || component.text.contains('練習') || component.text.contains('視察'))) ||
       (component.text.contains('成功') || component.text.contains('失敗')))
    ));
    
    // 新しい表示を作成
    _createScheduleDisplay();
    _createActionResultsDisplay();
  }
}

Widget _buildScoutingTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '利用可能なスカウトアクション',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...availableActions.map((action) => Card(
          child: ListTile(
            title: Text(action.name),
            subtitle: Text(action.description),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('AP: ${action.apCost}'),
                Text('¥${(action.budgetCost / 1000).toStringAsFixed(0)}k'),
              ],
            ),
          ),
        )).toList(),
      ],
    ),
  );
}
