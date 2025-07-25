import 'package:flutter/material.dart';
import '../models/player/player.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name}の詳細'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('名前: ${player.name}', style: Theme.of(context).textTheme.titleLarge),
            Text('学校: ${player.school}'),
            Text('学年: ${player.grade}'),
            Text('ポジション: ${player.position}'),
            Text('性格: ${player.personality}'),
            Text('知名度: ${player.fame}'),
            // 必要に応じて他の情報も追加
          ],
        ),
      ),
    );
  }
} 