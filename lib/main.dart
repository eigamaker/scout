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
import 'models/scouting_action.dart';
import 'models/scout_skills.dart';
import 'models/player.dart' show Player;
import 'models/pitch.dart' show Pitch;
import 'models/scout_report.dart';

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
      body: Column(
        children: [
          // メインコンテンツ
          Expanded(
            child: GameWidget(
              game: _game,
              overlayBuilderMap: {
                'button_overlay': (context, game) => ButtonOverlay(
                  game: game as ScoutGame,
                  onAdvanceWeek: () => _autoSave(),
                ),
              },
            ),
          ),
          // 選択されたアクションリスト
          _buildSelectedActionsList(),
        ],
      ),
    );
  }

  Future<void> _autoSave() async {
    await _saveGameState(0); // 自動セーブは常にスロット0
  }
  
  // 選択されたアクションを実行
  void _executeSelectedActions(BuildContext context) {
    final selectedActions = _game.gameState.selectedActionManager.selectedActions;
    
    if (selectedActions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('実行するアクションがありません'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // APと予算の確認
    final totalApCost = _game.gameState.selectedActionManager.totalApCost;
    final totalBudgetCost = _game.gameState.selectedActionManager.totalBudgetCost;
    
    if (totalApCost > _game.gameState.actionPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APが不足しています'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (totalBudgetCost > _game.gameState.budget) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('予算が不足しています'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // アクションを実行
    final results = <ActionResult>[];
    for (final selectedAction in selectedActions) {
      final result = _executeSingleAction(selectedAction.action, selectedAction.target);
      results.add(result);
      
      // スキル成長
      _game.gameState.scoutSkills.growFromAction(selectedAction.action.id, result.success);
      
      // 結果を保存
      _game.gameState.addActionResult(result);
    }
    
    // コストを消費
    _game.gameState.actionPoints -= totalApCost;
    _game.gameState.budget -= totalBudgetCost;
    
    // アクションリストをクリア
    _game.gameState.selectedActionManager.clearAll();
    
    // 結果表示ダイアログ
    _showActionResultsDialog(context, results);
    
    // UIを更新
    setState(() {});
  }
  
  // 単一アクションの実行
  ActionResult _executeSingleAction(ScoutingAction action, ScoutingTarget target) {
    final random = Random();
    final successRate = _calculateSuccessRate(action, target);
    final success = random.nextDouble() < successRate;
    
    String resultText = '';
    Map<String, dynamic>? additionalData;
    
    switch (action.id) {
      case 'PRAC_WATCH':
        if (target.type == 'school') {
          // 学校全体の練習視察
          resultText = _executeSchoolPracticeWatch(target.name, success);
        } else if (target.type == 'player') {
          // 特定選手の練習視察
          resultText = _executePlayerPracticeWatch(target.name, success);
        }
        break;
        
      case 'INTERVIEW':
        resultText = success 
          ? '${target.name}へのインタビューが成功しました。選手の性格や考え方が分かりました。'
          : '${target.name}へのインタビューは失敗しました。話を聞けませんでした。';
        break;
        
      case 'VIDEO_ANALYZE':
        resultText = success 
          ? '${target.name}の動画分析が完了しました。詳細な技術分析ができました。'
          : '${target.name}の動画分析は失敗しました。質の良い映像がありませんでした。';
        break;
        
      case 'TEAM_VISIT':
        resultText = success 
          ? 'プロ野球球団への訪問が成功しました。球団関係者との関係が深まりました。'
          : 'プロ野球球団への訪問は失敗しました。関係者に会えませんでした。';
        break;
        
      case 'INFO_SWAP':
        resultText = success 
          ? '${target.name}地域のスカウトとの情報交換が成功しました。新しい情報を得ました。'
          : '${target.name}地域のスカウトとの情報交換は失敗しました。有用な情報がありませんでした。';
        break;
        
      case 'NEWS_CHECK':
        resultText = success 
          ? '最新ニュースの確認が完了しました。重要な情報を得ました。'
          : '最新ニュースの確認は失敗しました。新しい情報はありませんでした。';
        break;
    }
    
    return ActionResult(
      actionName: action.name,
      result: resultText,
      school: target.type == 'school' ? target.name : '不明',
      player: target.type == 'player' ? target.name : null,
      apUsed: action.apCost,
      budgetUsed: action.budgetCost,
      timestamp: DateTime.now(),
      success: success,
      additionalData: additionalData,
    );
  }
  
  // 成功率の計算
  double _calculateSuccessRate(ScoutingAction action, ScoutingTarget target) {
    double baseRate = 0.7; // 基本成功率70%
    
    // アクションタイプによる調整
    switch (action.id) {
      case 'PRAC_WATCH':
        baseRate = 0.8;
        break;
      case 'INTERVIEW':
        baseRate = 0.6;
        break;
      case 'VIDEO_ANALYZE':
        baseRate = 0.75;
        break;
      case 'TEAM_VISIT':
        baseRate = 0.5;
        break;
      case 'INFO_SWAP':
        baseRate = 0.65;
        break;
      case 'NEWS_CHECK':
        baseRate = 0.9;
        break;
    }
    
    // ランダム要素を追加
    final random = Random();
    final variation = (random.nextDouble() - 0.5) * 0.2; // ±10%
    
    return (baseRate + variation).clamp(0.1, 0.95);
  }
  
  // アクション結果表示ダイアログ
  void _showActionResultsDialog(BuildContext context, List<ActionResult> results) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('アクション実行結果'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: results.map((result) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    result.success ? Icons.check_circle : Icons.error,
                    color: result.success ? Colors.green : Colors.red,
                  ),
                  title: Text('${result.actionName} - ${result.school}'),
                  subtitle: Text(result.result),
                  onTap: () => _showActionResultDetails(context, result),
                ),
              )).toList(),
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
  
  // 学校全体の練習視察を実行
  String _executeSchoolPracticeWatch(String schoolName, bool success) {
    if (!success) {
      return '${schoolName}の練習視察は失敗しました。情報が得られませんでした。';
    }
    
    // 学校を探す
    final school = _game.gameState.schools.firstWhere(
      (s) => s.name == schoolName,
      orElse: () => throw Exception('学校が見つかりません: $schoolName'),
    );
    
    final discoveredPlayers = <String>[];
    final improvedPlayers = <String>[];
    final playerComments = <String>[];
    
    // 学校の選手をランダムに選んで処理
    final random = Random();
    final players = List<Player>.from(school.players);
    players.shuffle(random);
    
    // 最大5人まで処理
    final maxPlayers = players.length > 5 ? 5 : players.length;
    
    for (int i = 0; i < maxPlayers; i++) {
      final player = players[i];
      
      if (!player.isDiscovered) {
        // 未発掘選手を発掘
        player.discover('あなた');
        discoveredPlayers.add(player.name);
        
        // 発掘時に基本的な能力値を把握
        _improvePlayerKnowledge(player, 10, 15);
        
        // 選手の特徴的なコメントを生成
        playerComments.add(_generatePlayerDiscoveryComment(player));
      } else {
        // 発掘済み選手の能力値を少し向上
        _improvePlayerKnowledge(player, 5, 10);
        improvedPlayers.add(player.name);
      }
    }
    
    // 結果テキストを生成
    String resultText = '${schoolName}の練習を視察しました。\n';
    
    if (discoveredPlayers.isNotEmpty) {
      resultText += '新たに発掘した選手: ${discoveredPlayers.join(', ')}\n';
      if (playerComments.isNotEmpty) {
        resultText += '${playerComments.first}'; // 最初の選手のコメントを表示
      }
    }
    
    if (improvedPlayers.isNotEmpty) {
      resultText += '能力を再確認した選手: ${improvedPlayers.join(', ')}';
    }
    
    return resultText;
  }
  
  // 選手発見時のコメントを生成
  String _generatePlayerDiscoveryComment(Player player) {
    final random = Random();
    final comments = <String>[];
    
    if (player.isPitcher) {
      final velo = player.getDisplayFastballVelo() ?? 0;
      if (velo >= 145) {
        comments.add('${player.name}君は球速がかなり速い！');
      } else if (velo >= 140) {
        comments.add('${player.name}君の球速はまずまずのレベル');
      }
      
      final control = player.getDisplayControl() ?? 0;
      if (control >= 80) {
        comments.add('${player.name}君の制球力が印象的');
      }
    } else {
      final run = player.getDisplayRun() ?? 0;
      if (run >= 80) {
        comments.add('${player.name}君は足がかなり速い！');
      } else if (run >= 70) {
        comments.add('${player.name}君の走力は良好');
      }
      
      final batPower = player.getDisplayBatPower() ?? 0;
      if (batPower >= 80) {
        comments.add('${player.name}君の打撃力が目立つ');
      }
    }
    
    // 性格によるコメント
    switch (player.personality) {
      case '真面目':
        comments.add('${player.name}君は真面目な性格で練習熱心');
        break;
      case '明るい':
        comments.add('${player.name}君は明るい性格でチームの雰囲気を良くしている');
        break;
      case 'クール':
        comments.add('${player.name}君はクールな性格で試合での冷静さが期待できる');
        break;
      case 'リーダー':
        comments.add('${player.name}君はリーダーシップがあり、チームを引っ張っている');
        break;
      case '努力家':
        comments.add('${player.name}君は努力家で、地道な練習を積んでいる');
        break;
    }
    
    // ランダムに1つのコメントを選択
    if (comments.isNotEmpty) {
      return comments[random.nextInt(comments.length)];
    }
    
    return '${player.name}君が気になりました';
  }
  
  // 特定選手の練習視察を実行
  String _executePlayerPracticeWatch(String playerName, bool success) {
    if (!success) {
      return '${playerName}の練習視察は失敗しました。情報が得られませんでした。';
    }
    
    // 選手を探す
    Player? targetPlayer;
    for (final school in _game.gameState.schools) {
      try {
        targetPlayer = school.players.firstWhere(
          (p) => p.name == playerName,
        );
        break;
      } catch (e) {
        // 選手が見つからない場合は次の学校をチェック
        continue;
      }
    }
    
    if (targetPlayer == null) {
      return '選手が見つかりませんでした: $playerName';
    }
    
    // 選手を発掘（未発掘の場合）
    if (!targetPlayer.isDiscovered) {
      targetPlayer.discover('あなた');
    }
    
    // 能力値の把握度を大幅に向上
    _improvePlayerKnowledge(targetPlayer, 20, 30);
    
    // 詳細なコメントを生成
    final comment = _generateDetailedPlayerComment(targetPlayer);
    
    return '${playerName}の練習を詳細に視察しました。\n$comment';
  }
  
  // 選手の詳細コメントを生成
  String _generateDetailedPlayerComment(Player player) {
    final comments = <String>[];
    
    if (player.isPitcher) {
      final velo = player.getDisplayFastballVelo() ?? 0;
      if (velo >= 150) {
        comments.add('球速は${velo}km/hと非常に速い！');
      } else if (velo >= 145) {
        comments.add('球速は${velo}km/hとかなり速い');
      } else if (velo >= 140) {
        comments.add('球速は${velo}km/hでまずまずのレベル');
      }
      
      final control = player.getDisplayControl() ?? 0;
      if (control >= 85) {
        comments.add('制球力が非常に優秀');
      } else if (control >= 75) {
        comments.add('制球力は良好');
      }
      
      final stamina = player.getDisplayStamina() ?? 0;
      if (stamina >= 80) {
        comments.add('スタミナが豊富で長いイニングを投げられる');
      }
    } else {
      final run = player.getDisplayRun() ?? 0;
      if (run >= 85) {
        comments.add('足が非常に速い！盗塁の期待ができる');
      } else if (run >= 75) {
        comments.add('走力は良好で、機動力がある');
      }
      
      final batPower = player.getDisplayBatPower() ?? 0;
      if (batPower >= 85) {
        comments.add('打撃力が非常に優秀で、長打力がある');
      } else if (batPower >= 75) {
        comments.add('打撃力は良好');
      }
      
      final field = player.getDisplayField() ?? 0;
      if (field >= 80) {
        comments.add('守備力が優秀で、安定した守備が期待できる');
      }
    }
    
    // 性格によるコメント
    switch (player.personality) {
      case '真面目':
        comments.add('真面目な性格で、練習への取り組みが素晴らしい');
        break;
      case '明るい':
        comments.add('明るい性格で、チームの雰囲気を良くしている');
        break;
      case 'クール':
        comments.add('クールな性格で、試合での冷静さが期待できる');
        break;
      case 'リーダー':
        comments.add('リーダーシップがあり、チームを引っ張っている');
        break;
      case '努力家':
        comments.add('努力家で、地道な練習を積んでいる');
        break;
    }
    
    // 複数のコメントを組み合わせて返す
    if (comments.length >= 2) {
      return '${comments[0]}\n${comments[1]}';
    } else if (comments.isNotEmpty) {
      return comments[0];
    }
    
    return '選手の能力を深く把握できました';
  }
  
  // 選手の能力値把握度を向上させる
  void _improvePlayerKnowledge(Player player, int basicImprovement, int focusedImprovement) {
    final random = Random();
    
    if (player.isPitcher) {
      // 投手の場合
      final abilities = ['fastballVelo', 'control', 'stamina', 'breakAvg'];
      abilities.shuffle(random);
      
      // 1つの能力値を重点的に向上
      player.improveKnowledge(abilities[0], focusedImprovement);
      
      // 他の能力値を少し向上
      for (int i = 1; i < abilities.length; i++) {
        player.improveKnowledge(abilities[i], basicImprovement);
      }
    } else {
      // 野手の場合
      final abilities = ['batPower', 'batControl', 'run', 'field', 'arm'];
      abilities.shuffle(random);
      
      // 1つの能力値を重点的に向上
      player.improveKnowledge(abilities[0], focusedImprovement);
      
      // 他の能力値を少し向上
      for (int i = 1; i < abilities.length; i++) {
        player.improveKnowledge(abilities[i], basicImprovement);
      }
    }
    
    // 隠し能力値も少し向上
    player.improveKnowledge('mentalGrit', basicImprovement ~/ 2);
    player.improveKnowledge('growthRate', basicImprovement ~/ 2);
    player.improveKnowledge('peakAbility', basicImprovement ~/ 4);
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
  
    // 選択されたアクションリストを表示
  Widget _buildSelectedActionsList() {
    // 毎回最新の状態を取得
    final selectedActions = _game.gameState.selectedActionManager.selectedActions;
    final totalApCost = _game.gameState.selectedActionManager.totalApCost;
    final totalBudgetCost = _game.gameState.selectedActionManager.totalBudgetCost;
    
    return GestureDetector(
      onTap: () => _showSelectedActionsDialog(context),
      child: Container(
        height: selectedActions.isEmpty ? 60 : 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: selectedActions.isEmpty 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.playlist_add_check, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '選択されたアクション (0)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'AP: 0/${_game.gameState.actionPoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '¥0k',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_less, color: Colors.white, size: 20),
                ],
              ),
            )
          : Column(
              children: [
                // ヘッダー
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.playlist_add_check, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '選択されたアクション (${selectedActions.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'AP: $totalApCost/${_game.gameState.actionPoints}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¥${(totalBudgetCost / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _executeSelectedActions(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: const Text('実行', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          _game.gameState.selectedActionManager.clearAll();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear, color: Colors.white, size: 20),
                        tooltip: '全てクリア',
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.expand_less, color: Colors.white, size: 20),
                    ],
                  ),
                ),
                // アクションリスト
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: selectedActions.length,
                    itemBuilder: (context, index) {
                      final selectedAction = selectedActions[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            selectedAction.action.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedAction.target.name,
                                style: const TextStyle(fontSize: 10),
                              ),
                              Text(
                                'AP: ${selectedAction.action.apCost} | ¥${(selectedAction.action.budgetCost / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              _game.gameState.selectedActionManager.removeAction(index);
                              setState(() {});
                            },
                            icon: const Icon(Icons.remove_circle, color: Colors.red, size: 16),
                            tooltip: '削除',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }

  // アクションリスト拡大ダイアログ
  void _showSelectedActionsDialog(BuildContext context) {
    final selectedActions = _game.gameState.selectedActionManager.selectedActions;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('選択中のアクション一覧'),
          content: SizedBox(
            width: 400,
            child: selectedActions.isEmpty
                ? const Text('現在アクションは選択されていません。')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: selectedActions.length,
                    itemBuilder: (context, index) {
                      final action = selectedActions[index];
                      return ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.blue),
                        title: Text(action.action.name),
                        subtitle: Text('対象: ${action.target.name}\nAP: ${action.action.apCost} | ¥${(action.action.budgetCost / 1000).toStringAsFixed(0)}k'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () {
                            _game.gameState.selectedActionManager.removeAction(index);
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
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
                              _buildScoutingTab(context),
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
  
  Widget _buildScoutingTab(BuildContext context) {
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('AP: ${action.apCost}'),
                      Text('¥${(action.budgetCost / 1000).toStringAsFixed(0)}k'),
                    ],
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showActionTargetDialog(context, action, null),
                    child: const Text('追加'),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
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
              leading: game.gameState.scoutReportManager.isSchoolUpdated(school.name)
                ? const Icon(Icons.new_releases, color: Colors.orange, size: 20)
                : null,
              title: Row(
                children: [
                  Expanded(child: Text(school.name)),
                  if (game.gameState.scoutReportManager.isSchoolUpdated(school.name))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text('選手: ${school.players.length}名'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('監督: ${school.coachName}'),
                  Text('信頼度: ${school.coachTrust}'),
                ],
              ),
              onTap: () {
                // 更新マークをクリア
                game.gameState.scoutReportManager.clearSchoolUpdate(school.name);
                _showSchoolDetails(context, school);
              },
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildPlayersTab(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '注目選手'),
              Tab(text: '人気選手'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildWatchedPlayersTab(context),
                _buildFamousPlayersTab(context),
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



  Widget _buildPlayerCard(BuildContext context, Player player, bool isWatched) {
    // スカウトスキルをゲーム状態から取得
    final scoutSkill = game.gameState.scoutSkills.observation; // 観察スキルを使用
    final visibleAbility = player.getVisibleAbility(scoutSkill);
    final generalEvaluation = player.getGeneralEvaluation();
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(player.getDiscoveryStatus()),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.getDiscoveryStatus(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            if (game.gameState.scoutReportManager.isPlayerUpdated(player.name))
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'UPD',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isWatched)
              const Icon(Icons.visibility, color: Colors.blue, size: 20),
          ],
        ),
        subtitle: Text('${player.school} - ${player.position}'),
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
          ],
        ),
        onTap: () {
          // 更新マークをクリア
          game.gameState.scoutReportManager.clearPlayerUpdate(player.name);
          _showPlayerDetails(context, player);
        },
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
  
  Color _getStatusColor(String status) {
    switch (status) {
      case '世間注目': return Colors.red;
      case 'お気に入り': return Colors.purple;
      case '発掘済み': return Colors.blue;
      case '未発掘': return Colors.grey;
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
          title: Row(
            children: [
              Expanded(child: Text(school.name)),
              if (game.gameState.scoutReportManager.isSchoolUpdated(school.name))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 500,
            child: Column(
              children: [
                // 学校基本情報
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '学校情報',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text('監督: ${school.coachName}'),
                        Text('監督信頼度: ${school.coachTrust}'),
                        Text('選手数: ${school.players.length}名'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 選手リスト
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '選手一覧 (${school.players.length}名)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              _showSchoolScoutActionsDialog(context, school);
                            },
                            child: const Text('学校視察'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: school.players.length,
                          itemBuilder: (context, index) {
                            final player = school.players[index];
                            final scoutSkill = game.gameState.scoutSkills.observation;
                            final visibleAbility = player.getVisibleAbility(scoutSkill);
                            final generalEvaluation = player.getGeneralEvaluation();
                            final evaluationColor = _getEvaluationColor(generalEvaluation);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: evaluationColor,
                                  child: Text(
                                    generalEvaluation,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                                    if (game.gameState.scoutReportManager.isPlayerUpdated(player.name))
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'UPD',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (player.isWatched)
                                      const Icon(Icons.visibility, color: Colors.blue, size: 20),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${player.position} - 能力: $visibleAbility'),
                                    Text('性格: ${player.personality}'),
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
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '知名度: ${player.fame}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // 更新マークをクリア
                                  game.gameState.scoutReportManager.clearPlayerUpdate(player.name);
                                  Navigator.of(context).pop();
                                  _showPlayerDetails(context, player);
                                },
                                onLongPress: () {
                                  Navigator.of(context).pop();
                                  _showPlayerActionMenu(context, player);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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
    final scoutSkill = game.gameState.scoutSkills.observation;
    final visibleAbility = player.getVisibleAbility(scoutSkill);
    final generalEvaluation = player.getGeneralEvaluation();
    final potentialEvaluation = player.getPotentialEvaluation(scoutSkill);
    final evaluationColor = _getEvaluationColor(generalEvaluation);
    
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
                // 基本情報
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '基本情報',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                        const SizedBox(height: 8),
                        Text('学校: ${player.school}'),
                        Text('ポジション: ${player.position}'),
                        Text('性格: ${player.personality}'),
                        Row(
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.amber),
                            Text('知名度: ${player.fame}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 評価・能力情報
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '評価・能力',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('評価: '),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: evaluationColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                generalEvaluation,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text('総合能力: $visibleAbility'),
                        Text(
                          'ポテンシャル: $potentialEvaluation',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // スカウト評価（設定されている場合のみ表示）
                if (player.scoutEvaluation != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'スカウト評価',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                          ),
                          const SizedBox(height: 8),
                          Text('評価: ${player.scoutEvaluation}'),
                          if (player.scoutNotes != null)
                            Text('メモ: ${player.scoutNotes}'),
                        ],
                      ),
                    ),
                  ),
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
                        Row(
                          children: [
                            Text(
                              'スカウトスキル',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                            ),
                            const Spacer(),
                            Text(
                              '平均: ${scoutSkills.averageSkill.toStringAsFixed(1)}',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _showSkillsDetailsDialog(context),
                              child: const Text('詳細', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSkillBar('探索', scoutSkills.exploration, scoutSkills.getSkillLevel('exploration')),
                        _buildSkillBar('観察', scoutSkills.observation, scoutSkills.getSkillLevel('observation')),
                        _buildSkillBar('分析', scoutSkills.analysis, scoutSkills.getSkillLevel('analysis')),
                        _buildSkillBar('洞察', scoutSkills.insight, scoutSkills.getSkillLevel('insight')),
                        _buildSkillBar('コミュニケーション', scoutSkills.communication, scoutSkills.getSkillLevel('communication')),
                        _buildSkillBar('交渉', scoutSkills.negotiation, scoutSkills.getSkillLevel('negotiation')),
                        _buildSkillBar('体力', scoutSkills.stamina, scoutSkills.getSkillLevel('stamina')),
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
  void _showActionTargetDialog(BuildContext context, ScoutingAction action, Player? player) {
    if (player != null) {
      Navigator.of(context).pop(); // 前のダイアログを閉じる
    }
    
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
                if (player != null) ...[
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
                ] else ...[
                  // 選手が指定されていない場合、学校を選択
                  ...game.gameState.schools.map((school) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          final target = ScoutingTarget(
                            type: 'school',
                            name: school.name,
                            description: '${school.name}全体',
                          );
                          _executeActionWithTarget(context, action, target);
                        },
                        child: Text('${school.name}'),
                      ),
                    ),
                  ),
                ],
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
    
    // 選択されたアクションリストに追加
    game.gameState.selectedActionManager.addAction(action, target);
    
    // UIを更新
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${action.name}を${target.name}に追加しました'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // 親ウィジェットのsetStateを呼び出してUIを更新
      if (context.findAncestorStateOfType<_GameScreenState>() != null) {
        context.findAncestorStateOfType<_GameScreenState>()!.setState(() {});
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

  void _showSchoolScoutActionsDialog(BuildContext context, School school) {
    final scoutSkills = game.gameState.scoutSkills;
    final availableActions = [
      ScoutingAction(
        id: 'PRAC_WATCH',
        name: '練習視察',
        apCost: 2,
        budgetCost: 20000,
        description: '学校全体の練習を視察し、選手を発掘・能力を把握',
        category: '視察',
        requiredSkills: ['observation'],
        primarySkills: ['observation', 'exploration'],
        baseSuccessRate: 0.60,
        skillModifiers: {'observation': 0.3},
      ),
    ];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${school.name}の視察アクション'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableActions.map((action) {
              final canExecute = action.canExecute(
                scoutSkills,
                game.gameState.actionPoints,
                game.gameState.budget,
              );
              return ListTile(
                title: Text(action.name),
                subtitle: Text(action.description),
                trailing: canExecute ? null : const Icon(Icons.lock, color: Colors.grey),
                enabled: canExecute,
                onTap: canExecute
                    ? () {
                        final target = ScoutingTarget(type: 'school', name: school.name);
                        Navigator.of(context).pop();
                        game.gameState.selectedActionManager.addAction(action, target);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${action.name}を${target.name}に追加しました'),
                            backgroundColor: Colors.blue,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
              );
            }).toList(),
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

  Widget _buildSkillBar(String skillName, int skillValue, String skillLevel) {
    final percentage = skillValue / 100.0;
    Color barColor;
    
    if (skillValue >= 80) {
      barColor = Colors.green;
    } else if (skillValue >= 60) {
      barColor = Colors.blue;
    } else if (skillValue >= 40) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              skillName,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  height: 16,
                  width: 120 * percentage,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$skillValue',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                skillLevel,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSkillsDetailsDialog(BuildContext context) {
    final scoutSkills = game.gameState.scoutSkills;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('スカウトスキル詳細'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailedSkillInfo('探索', scoutSkills.exploration, '未登録校・選手を発見する能力'),
                _buildDetailedSkillInfo('観察', scoutSkills.observation, '実パフォーマンス計測の精度'),
                _buildDetailedSkillInfo('分析', scoutSkills.analysis, 'データ統合と将来予測の能力'),
                _buildDetailedSkillInfo('洞察', scoutSkills.insight, '潜在才能・怪我リスクを察知する能力'),
                _buildDetailedSkillInfo('コミュニケーション', scoutSkills.communication, '面談・信頼構築の能力'),
                _buildDetailedSkillInfo('交渉', scoutSkills.negotiation, '利害調整・提案採用率'),
                _buildDetailedSkillInfo('体力', scoutSkills.stamina, '遠征疲労耐性'),
                const SizedBox(height: 16),
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'スキル成長について',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• アクションを実行すると、関連するスキルが成長します\n'
                          '• 成功したアクションではより多くの経験値を得られます\n'
                          '• 体力は全アクションで少しずつ成長します',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
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
  
  Widget _buildDetailedSkillInfo(String skillName, int skillValue, String description) {
    final skillLevel = game.gameState.scoutSkills.getSkillLevel(skillName.toLowerCase());
    Color levelColor;
    
    if (skillValue >= 80) {
      levelColor = Colors.green;
    } else if (skillValue >= 60) {
      levelColor = Colors.blue;
    } else if (skillValue >= 40) {
      levelColor = Colors.orange;
    } else {
      levelColor = Colors.red;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  skillName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: levelColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$skillValue ($skillLevel)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
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
    scheduleTitle.position = Vector2(100, 220);
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
      scheduleText.position = Vector2(100, 280);
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
      scheduleText.position = Vector2(100, 280);
      scheduleText.anchor = Anchor.center;
      add(scheduleText);
    }
  }
  
  void _createActionResultsDisplay() {
    // スカウトレポートタイトル
    final reportsTitle = TextComponent(
      text: '📊 スカウトレポート',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    reportsTitle.position = Vector2(300, 120);
    reportsTitle.anchor = Anchor.center;
    add(reportsTitle);
    
    // 最新のレポートを表示
    final recentReports = gameState.scoutReportManager.getAllReports();
    if (recentReports.isNotEmpty) {
      int yOffset = 140;
      // 最新の3件を表示
      final displayReports = recentReports.take(3).toList();
      
      for (final report in displayReports) {
        // レポートタイトル
        final titleText = TextComponent(
          text: report.title,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: 11,
              color: report.getColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        titleText.position = Vector2(300, yOffset.toDouble());
        titleText.anchor = Anchor.center;
        add(titleText);
        
        // レポートの説明（1行のみ）
        final descText = TextComponent(
          text: report.description.length > 25 
            ? '${report.description.substring(0, 25)}...' 
            : report.description,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        );
        descText.position = Vector2(300, (yOffset + 15).toDouble());
        descText.anchor = Anchor.center;
        add(descText);
        
        yOffset += 40; // 行間を広げる
      }
      
      // レポート詳細ボタン
      final detailButton = ButtonComponent(
        button: RectangleComponent(
          size: Vector2(120, 25),
          paint: Paint()..color = Colors.blue.withOpacity(0.8),
        ),
        onPressed: () => _showScoutReportsDialog(),
      );
      detailButton.position = Vector2(300, (yOffset + 10).toDouble());
      detailButton.anchor = Anchor.center;
      add(detailButton);
      
      final detailText = TextComponent(
        text: '詳細を見る',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
          ),
        ),
      );
      detailText.position = Vector2(300, (yOffset + 10).toDouble());
      detailText.anchor = Anchor.center;
      add(detailText);
    } else {
      final noReportsText = TextComponent(
        text: 'レポートなし',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      );
      noReportsText.position = Vector2(300, 140);
      noReportsText.anchor = Anchor.center;
      add(noReportsText);
    }
  }
  
  // アクション結果から詳細な報告テキストを生成
  String _generateActionResultText(ActionResult result) {
    if (!result.success) {
      return '${result.actionName}: 失敗 - 情報が得られませんでした';
    }
    
    switch (result.actionName) {
      case '練習視察':
        return _generatePracticeWatchText(result);
      case 'インタビュー':
        return _generateInterviewText(result);
      case '試合観戦':
        return _generateGameWatchText(result);
      case 'ビデオ分析':
        return _generateVideoAnalyzeText(result);
      default:
        return '${result.actionName}: 成功';
    }
  }
  
  // 練習視察の結果テキストを生成
  String _generatePracticeWatchText(ActionResult result) {
    final school = result.school;
    final player = result.player;
    
    if (player != null) {
      // 特定選手の視察結果
      final playerObj = _findPlayer(player);
      if (playerObj != null) {
        if (!playerObj.isDiscovered) {
          return '${school}の${player}君を発見！\n${_generatePlayerComment(playerObj)}';
        } else {
          return '${player}君の能力を再確認\n${_generatePlayerComment(playerObj)}';
        }
      }
    } else {
      // 学校全体の視察結果
      final schoolObj = _findSchool(school);
      if (schoolObj != null) {
        final discoveredPlayers = schoolObj.players.where((p) => p.isDiscovered).length;
        final totalPlayers = schoolObj.players.length;
        return '${school}を視察\n発掘済み: ${discoveredPlayers}/${totalPlayers}名';
      }
    }
    
    return '${school}の練習を視察しました';
  }
  
  // インタビューの結果テキストを生成
  String _generateInterviewText(ActionResult result) {
    final player = result.player;
    if (player != null) {
      final playerObj = _findPlayer(player);
      if (playerObj != null) {
        return '${player}君と面談\n性格: ${playerObj.personality}';
      }
    }
    return 'インタビューを実施しました';
  }
  
  // 試合観戦の結果テキストを生成
  String _generateGameWatchText(ActionResult result) {
    final school = result.school;
    return '${school}の試合を観戦\n実戦での活躍を確認';
  }
  
  // ビデオ分析の結果テキストを生成
  String _generateVideoAnalyzeText(ActionResult result) {
    final player = result.player;
    if (player != null) {
      return '${player}君の映像分析\n技術的な詳細を把握';
    }
    return 'ビデオ分析を実施しました';
  }
  
  // 選手の能力に基づくコメントを生成
  String _generatePlayerComment(Player player) {
    if (player.isPitcher) {
      final velo = player.getDisplayFastballVelo() ?? 0;
      if (velo >= 145) return '球速がかなり速い！';
      if (velo >= 140) return '球速はまずまず';
      return '制球力に期待';
    } else {
      final run = player.getDisplayRun() ?? 0;
      if (run >= 80) return '足がかなり速い！';
      if (run >= 70) return '走力は良好';
      return '打撃に期待';
    }
  }
  
  // スカウトレポート詳細ダイアログを表示
  void _showScoutReportsDialog() {
    final reports = gameState.scoutReportManager.getAllReports();
    
    // FlameのOverlayシステムを使用してダイアログを表示
    overlays.add('scoutReports');
  }

  // 選手を名前で検索
  Player? _findPlayer(String playerName) {
    for (final school in gameState.schools) {
      try {
        return school.players.firstWhere((p) => p.name == playerName);
      } catch (e) {
        continue;
      }
    }
    return null;
  }
  
  // 学校を名前で検索
  School? _findSchool(String schoolName) {
    try {
      return gameState.schools.firstWhere((s) => s.name == schoolName);
    } catch (e) {
      return null;
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


