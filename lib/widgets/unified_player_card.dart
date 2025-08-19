import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player/player.dart';
import '../models/game/game.dart';
import '../services/game_manager.dart';

class UnifiedPlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final bool showActions; // アクションボタンを表示するかどうか
  final bool showSchool; // 学校名を表示するかどうか
  
  const UnifiedPlayerCard({
    super.key, 
    required this.player, 
    this.onTap,
    this.showActions = false,
    this.showSchool = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                             // 1行目: 名前、ポジション、学年、マーク
               Row(
                 children: [
                   // 選手名
                   Expanded(
                     child: Text(
                       player.name,
                       style: const TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                       ),
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   
                   const SizedBox(width: 8),
                   
                   // ポジション
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.blue[100],
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text(
                       player.position,
                       style: TextStyle(
                         color: Colors.blue[800],
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                   
                   const SizedBox(width: 8),
                   
                   // 学年
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.green[100],
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text(
                       '${player.grade}年生',
                       style: TextStyle(
                         color: Colors.green[800],
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                   
                   const SizedBox(width: 8),
                   
                   // 注目選手マーク（スター）
                   if (player.isPubliclyKnown)
                     const Icon(
                       Icons.star,
                       color: Colors.orange,
                       size: 20,
                     ),
                   // お気に入りマーク（ハート）
                   if (player.isScoutFavorite)
                     const Icon(
                       Icons.favorite,
                       color: Colors.red,
                       size: 20,
                     ),
                 ],
               ),
               
               const SizedBox(height: 8),
               
               // 2行目: 学校名とアクションボタン
               Row(
                 children: [
                   // 学校名
                   if (showSchool && player.school.isNotEmpty) ...[
                     Expanded(
                       child: Text(
                         player.school,
                         style: TextStyle(
                           color: Colors.grey[600],
                           fontSize: 12,
                         ),
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                   ] else ...[
                     const Spacer(),
                   ],
                   
                   // アクションボタン（必要に応じて表示）
                   if (showActions) ...[
                     _buildActionButtons(context),
                   ],
                 ],
               ),
              
              
            ],
          ),
        ),
      ),
    );
  }
  
  // アクションボタンを構築
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            Icons.chat,
            'インタビュー',
            Colors.green,
            () => _addInterviewAction(context),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _buildActionButton(
            context,
            Icons.video_library,
            'ビデオ分析',
            Colors.purple,
            () => _addVideoAnalyzeAction(context),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color.withOpacity(0.8),
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

    // ビデオ分析アクションを作成
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'videoAnalyze',
      schoolId: schoolId,
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
}
