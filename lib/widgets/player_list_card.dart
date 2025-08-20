import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player/player.dart';
import '../models/game/game.dart';
import '../services/game_manager.dart';
import '../services/data_service.dart';

class PlayerListCard extends StatefulWidget {
  final Player player;
  final VoidCallback? onTap;
  final bool showActions; // アクションボタンを表示するかどうか
  final bool showSchool; // 学校名を表示するかどうか
  
  const PlayerListCard({
    super.key, 
    required this.player, 
    this.onTap,
    this.showActions = false,
    this.showSchool = true,
  });
  
  @override
  State<PlayerListCard> createState() => _PlayerListCardState();
}

class _PlayerListCardState extends State<PlayerListCard> {
  late Player _player;
  late DataService _dataService;
  
  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _dataService = DataService();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1行目: 名前、学校、マーク（★♡）
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.showSchool) ...[
                    Text(
                      _player.school,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // 注目マーク（★）
                  if (_player.isPubliclyKnown)
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                  const SizedBox(width: 4),
                  // お気に入りマーク（♡）
                  GestureDetector(
                    onTap: () async {
                      final gameManager = Provider.of<GameManager>(context, listen: false);
                      await gameManager.togglePlayerFavorite(_player, _dataService);
                                             setState(() {
                         // 学校リストから選手を検索して更新
                         for (final school in gameManager.currentGame?.schools ?? []) {
                           final updatedPlayer = school.players.firstWhere(
                             (p) => p.id == _player.id,
                             orElse: () => null,
                           );
                           if (updatedPlayer != null) {
                             _player = updatedPlayer;
                             break;
                           }
                         }
                       });
                    },
                    child: Icon(
                      _player.isScoutFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _player.isScoutFavorite ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 2行目: ポジション、学年、アクションボタン
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      _player.position,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_player.grade}年',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.showActions) ...[
                    const Spacer(),
                    // インタビューボタン
                    ElevatedButton.icon(
                      onPressed: () => _addInterviewAction(context),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('インタビュー', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        foregroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ビデオ分析ボタン
                    ElevatedButton.icon(
                      onPressed: () => _addVideoAnalyzeAction(context),
                      icon: const Icon(Icons.video_library, size: 16),
                      label: const Text('ビデオ分析', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        foregroundColor: Colors.purple[700],
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // インタビューアクションを追加
  void _addInterviewAction(BuildContext context) {
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
      if (game.schools[i].name == _player.school) {
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

    // デバッグ：選手IDを確認
    print('インタビューアクション作成: 選手名=${_player.name}, 選手ID=${_player.id}');
    
    // インタビューアクションを作成
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'interview',
      schoolId: schoolId,
      playerId: _player.id,
      playerName: _player.name,
      apCost: 1,
      budgetCost: 10000,
      params: {},
    );

    // APと予算が足りるかチェック
    if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_player.name}のインタビューを計画に追加しました（AP: ${action.apCost}, 予算: ¥${action.budgetCost}）'),
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
  void _addVideoAnalyzeAction(BuildContext context) {
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
      if (game.schools[i].name == _player.school) {
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

    // デバッグ：選手IDを確認
    print('ビデオ分析アクション作成: 選手名=${_player.name}, 選手ID=${_player.id}');
    
    // ビデオ分析アクションを作成
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'videoAnalyze',
      schoolId: schoolId,
      playerId: _player.id,
      playerName: _player.name,
      apCost: 2,
      budgetCost: 0,
      params: {},
    );

    // APが足りるかチェック
    if (game.ap >= action.apCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_player.name}のビデオ分析を計画に追加しました（AP: ${action.apCost}）'),
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
}
