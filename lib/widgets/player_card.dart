import 'package:flutter/material.dart';
import '../models/player/player.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;

  const PlayerCard({super.key, required this.player, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(player.name),
        subtitle: Text(' {player.position}（ {player.school}）'),
        trailing: Text('知名度:  {player.fame}'),
        onTap: onTap,
      ),
    );
  }
} 