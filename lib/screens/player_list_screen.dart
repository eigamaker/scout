import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player/player.dart';
import '../services/game_manager.dart';
import '../widgets/player_card.dart';

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    // 仮の選手リスト（本来はgameManager.currentGame?.discoveredPlayersなどを使う）
    final List<Player> players = gameManager.currentGame?.discoveredPlayers ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('選手リスト'),
      ),
      body: players.isEmpty
          ? const Center(child: Text('選手がいません'))
          : ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return PlayerCard(
                  player: player,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/playerDetail',
                      arguments: player,
                    );
                  },
                );
              },
            ),
    );
  }
} 