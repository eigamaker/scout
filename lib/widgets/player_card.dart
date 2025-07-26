import 'package:flutter/material.dart';
import '../models/player/player.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;

  const PlayerCard({super.key, required this.player, this.onTap});

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
              // 選手名と基本情報
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${player.position}（${player.school} ${player.grade}年）',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // 知名度バッジと発掘状態
                  Column(
                    children: [
                      // 知名度バッジ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getFameColor(player.fameLevel),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          player.fameLevelName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // 発掘状態バッジ
                      if (player.isDiscovered) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '発掘済み',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 実績表示
              if (player.achievements.isNotEmpty) ...[
                Text(
                  '実績:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: player.achievements.take(3).map((achievement) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Text(
                        achievement.name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (player.achievements.length > 3)
                  Text(
                    '他${player.achievements.length - 3}件',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
              
              // 能力値の簡易表示（発掘済みまたは知名度が高い場合）
              if (player.isDiscovered || player.fameLevel >= 2) ...[
                Text(
                  '能力値:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildAbilityDisplay(context),
              ],
              
              // 隠し情報の表示（発掘済みの場合のみ）
              if (player.isDiscovered) ...[
                const SizedBox(height: 8),
                Text(
                  '隠し情報:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildHiddenInfoDisplay(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 知名度に応じた色を取得
  Color _getFameColor(int fameLevel) {
    switch (fameLevel) {
      case 5: return Colors.red;      // 超有名
      case 4: return Colors.orange;   // 有名
      case 3: return Colors.blue;     // 知られている
      case 2: return Colors.green;    // 少し知られている
      case 1: return Colors.grey;     // 無名
      default: return Colors.grey;
    }
  }

  // 能力値表示
  Widget _buildAbilityDisplay(BuildContext context) {
    if (player.isPitcher) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (player.fastballVelo != null)
                _buildAbilityChip('球速', '${player.fastballVelo}km/h'),
              if (player.control != null)
                _buildAbilityChip('制球', '${player.control}'),
              if (player.stamina != null)
                _buildAbilityChip('スタミナ', '${player.stamina}'),
            ],
          ),
          if (player.breakAvg != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                _buildAbilityChip('変化球', '${player.breakAvg}'),
              ],
            ),
          ],
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (player.batPower != null)
                _buildAbilityChip('パワー', '${player.batPower}'),
              if (player.batControl != null)
                _buildAbilityChip('バットコントロール', '${player.batControl}'),
              if (player.run != null)
                _buildAbilityChip('走力', '${player.run}'),
            ],
          ),
          if (player.field != null || player.arm != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (player.field != null)
                  _buildAbilityChip('守備', '${player.field}'),
                if (player.arm != null)
                  _buildAbilityChip('肩', '${player.arm}'),
              ],
            ),
          ],
        ],
      );
    }
  }

  Widget _buildAbilityChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  // 隠し情報表示
  Widget _buildHiddenInfoDisplay(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildHiddenInfoChip('才能ランク', '${player.talent}'),
            _buildHiddenInfoChip('成長タイプ', player.growthType),
            _buildHiddenInfoChip('ポテンシャル', '${player.peakAbility}'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildHiddenInfoChip('精神力', '${(player.mentalGrit * 100).round()}'),
            _buildHiddenInfoChip('成長スピード', '${(player.growthRate * 100).round()}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildHiddenInfoChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.orange,
        ),
      ),
    );
  }
} 