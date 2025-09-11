import 'package:flutter/material.dart';
import '../../../models/player/player.dart' hide PlayerType;

/// 選手情報表示ウィジェット
class PlayerInfoWidget extends StatelessWidget {
  final Player player;

  const PlayerInfoWidget({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '選手情報',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('名前', player.name),
                ),
                Expanded(
                  child: _buildInfoRow('学校', player.school),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('学年', '${player.grade}年生'),
                ),
                Expanded(
                  child: _buildInfoRow('年齢', '${player.age}歳'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('ポジション', player.position),
                ),
                Expanded(
                  child: _buildInfoRow('才能ランク', '${player.talent}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('注目度', '${player.fame}'),
                ),
                Expanded(
                  child: _buildInfoRow('成長率', '${(player.growthRate * 100).toStringAsFixed(1)}%'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('成長タイプ', player.growthType),
                ),
                Expanded(
                  child: _buildInfoRow('メンタル強度', '${(player.mentalGrit * 100).toStringAsFixed(1)}%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
