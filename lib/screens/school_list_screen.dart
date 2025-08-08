import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/scouting/action_service.dart';
import '../models/game/game.dart';

class SchoolListScreen extends StatelessWidget {
  const SchoolListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    final game = gameManager.currentGame;
    
    if (game == null) {
      return const Scaffold(
        body: Center(child: Text('ゲームが開始されていません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('学校リスト'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            for (int i = 0; i < game.schools.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.schools[i].name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${game.schools[i].location} • ${game.schools[i].players.length}人',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // 練習視察アクションを追加（AP消費）
                            final action = GameAction(
                              id: UniqueKey().toString(),
                              type: 'PRAC_WATCH',
                              schoolId: i,
                              playerId: null,
                              apCost: 2,
                              budgetCost: 20000,
                              params: {},
                            );
                            
                            // APと予算が足りるかチェック
                            if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
                              gameManager.addActionToGame(action);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${game.schools[i].name}の練習視察を計画に追加しました（AP: ${action.apCost}, 予算: ¥${action.budgetCost}）'),
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
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(60, 32),
                          ),
                          child: const Text('練習視察'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // 練習試合観戦アクションを追加
                            final action = GameAction(
                              id: UniqueKey().toString(),
                              type: 'scrimmage',
                              schoolId: i,
                              playerId: null,
                              apCost: 2,
                              budgetCost: 30000,
                              params: {},
                            );
                            
                            // APと予算が足りるかチェック
                            if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
                              gameManager.addActionToGame(action);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${game.schools[i].name}の練習試合観戦を計画に追加しました（AP: ${action.apCost}, 予算: ¥${action.budgetCost}）'),
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
                          },
                          icon: const Icon(Icons.sports_baseball, size: 16),
                          label: const Text('練習試合観戦'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(60, 32),
                            backgroundColor: Colors.orange[100],
                            foregroundColor: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 