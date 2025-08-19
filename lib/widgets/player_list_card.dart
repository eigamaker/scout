import 'package:flutter/material.dart';
import '../models/player/player.dart';

class PlayerListCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  
  const PlayerListCard({
    super.key, 
    required this.player, 
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 選手の基本情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 選手名
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 学校名とポジション
                    Text(
                      '${player.school} - ${player.position}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 学年と才能
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '才能: ${player.talent}',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // マーク類
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 注目選手マーク（スター）
                  if (player.isPubliclyKnown)
                    const Icon(
                      Icons.star,
                      color: Colors.orange,
                      size: 24,
                    ),
                  // お気に入りマーク（ハート）
                  if (player.isScoutFavorite) ...[
                    if (player.isPubliclyKnown) const SizedBox(width: 8),
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 24,
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
}
