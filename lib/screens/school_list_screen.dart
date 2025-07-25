import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../models/game/game.dart';

class SchoolListScreen extends StatelessWidget {
  const SchoolListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    final game = gameManager.currentGame;
    if (game == null) {
      return const Scaffold(body: Center(child: Text('ゲームが開始されていません')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('学校リスト')),
      body: ListView.builder(
        itemCount: game.schools.length,
        itemBuilder: (context, index) {
          final school = game.schools[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(school.name),
              subtitle: Text('所在地: ${school.location}'),
              trailing: ElevatedButton(
                onPressed: game.ap >= 2 && game.budget >= 20000
                    ? () {
                        final action = GameAction(
                          id: UniqueKey().toString(),
                          type: 'PRAC_WATCH',
                          schoolId: index,
                          playerId: null,
                          apCost: 2,
                          budgetCost: 20000,
                          params: {},
                        );
                        gameManager.addActionToGame(action);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${school.name}の練習視察を計画に追加しました')),
                        );
                      }
                    : null,
                child: const Text('練習視察(AP2/¥20k)'),
              ),
            ),
          );
        },
      ),
    );
  }
} 