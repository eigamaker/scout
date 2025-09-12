import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news/news_item.dart';
import '../models/player/player.dart';
import '../models/game/game.dart';
import '../services/game_manager.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(news.getFormattedDate(), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(news.content, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('カテゴリ: ${news.getCategoryText()}'),
            Text('重要度: ${news.getImportanceText()}'),
            
            // 関連選手がいる場合は選手情報とアクションボタンを表示
            if (news.relatedPlayerId != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '関連選手',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildRelatedPlayerInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  // 関連選手の情報とアクションボタンを表示
  Widget _buildRelatedPlayerInfo(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final game = gameManager.currentGame;
        if (game == null || news.relatedPlayerId == null) {
          return const Text('選手情報が見つかりません');
        }

        // 全学校から関連選手を検索
        Player? relatedPlayer;
        for (final school in game.schools) {
          try {
            relatedPlayer = school.players.firstWhere(
              (p) => p.id.toString() == news.relatedPlayerId,
            );
            break;
          } catch (e) {
            continue;
          }
        }

        if (relatedPlayer == null) {
          return const Text('選手が見つかりません');
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 選手の基本情報
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            relatedPlayer.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${relatedPlayer.school} ${relatedPlayer.grade}年'),
                          Text('ポジション: ${relatedPlayer.position}'),
                        ],
                      ),
                    ),
                    // 知名度バッジ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getFameLevelColor(relatedPlayer.fameLevel),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        relatedPlayer.fameLevelName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // アクションボタン（発掘済みまたは注目選手の場合）
                if (relatedPlayer.isScouted || relatedPlayer.fameLevel >= 3) ...[
                  Text(
                    'スカウトアクション',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNewsActionButtons(context, relatedPlayer),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ニュース詳細画面用のアクションボタン
  Widget _buildNewsActionButtons(BuildContext context, Player player) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _addScrimmageAction(context, player),
                icon: const Icon(Icons.sports_baseball, size: 16),
                label: const Text('練習試合観戦'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: const Size(0, 32),
                  backgroundColor: Colors.orange[100],
                  foregroundColor: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _addInterviewAction(context, player),
                icon: const Icon(Icons.chat, size: 16),
                label: const Text('インタビュー'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: const Size(0, 32),
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[800],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _addVideoAnalyzeAction(context, player),
                icon: const Icon(Icons.video_library, size: 16),
                label: const Text('ビデオ分析'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: const Size(0, 32),
                  backgroundColor: Colors.purple[100],
                  foregroundColor: Colors.purple[800],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 練習試合観戦アクションを追加
  void _addScrimmageAction(BuildContext context, Player player) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    
    if (game == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ゲームが読み込まれていません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 選手の学校IDを取得
    int? schoolId;
    for (int i = 0; i < game.schools.length; i++) {
      if (game.schools[i].name == player.school) {
        schoolId = i;
        break;
      }
    }

    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選手の学校が見つかりません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 練習試合観戦アクションを作成
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'scrimmage',
      schoolId: schoolId,
      playerId: player.id,
      apCost: 2,
      budgetCost: 30000,
      params: {},
    );

    // APと予算が足りるかチェック
    if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name}の練習試合観戦を計画に追加しました（AP: ${action.apCost}, 予算: ¥${action.budgetCost}）'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APまたは予算が不足しています'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // インタビューアクションを追加
  void _addInterviewAction(BuildContext context, Player player) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    
    if (game == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ゲームが読み込まれていません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 選手の学校IDを取得
    int? schoolId;
    for (int i = 0; i < game.schools.length; i++) {
      if (game.schools[i].name == player.school) {
        schoolId = i;
        break;
      }
    }

    if (schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選手の学校が見つかりません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // インタビューアクションを作成
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'interview',
      schoolId: schoolId,
      playerId: player.id,
      apCost: 1,
      budgetCost: 10000,
      params: {},
    );

    // APと予算が足りるかチェック
    if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name}のインタビューを計画に追加しました（AP: ${action.apCost}, 予算: ¥${action.budgetCost}）'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APまたは予算が不足しています'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ビデオ分析アクションを追加
  void _addVideoAnalyzeAction(BuildContext context, Player player) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    
    if (game == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ゲームが読み込まれていません'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ビデオ分析アクションを作成
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'videoAnalyze',
      schoolId: 0, // ビデオ分析は学校に依存しない
      playerId: player.id,
      apCost: 2,
      budgetCost: 0,
      params: {},
    );

    // APが足りるかチェック
    if (game.ap >= action.apCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name}のビデオ分析を計画に追加しました（AP: ${action.apCost}）'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APが不足しています'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 知名度レベルに基づく色を取得
  Color _getFameLevelColor(int fameLevel) {
    switch (fameLevel) {
      case 5: return Colors.red;      // 超有名
      case 4: return Colors.orange;   // 有名
      case 3: return Colors.yellow;   // 知られている
      case 2: return Colors.green;    // 少し知られている
      case 1: return Colors.grey;     // 無名
      default: return Colors.grey;
    }
  }
} 