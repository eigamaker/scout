import 'package:flutter/material.dart';
import '../models/professional/professional_player.dart';
import '../models/player/player.dart';

class ProfessionalPlayerCard extends StatelessWidget {
  final ProfessionalPlayer professionalPlayer;
  final VoidCallback? onTap;

  const ProfessionalPlayerCard({
    super.key,
    required this.professionalPlayer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final player = professionalPlayer.player;
    if (player == null) {
      return const Card(
        child: ListTile(
          title: Text('選手情報なし'),
          subtitle: Text('選手データが見つかりません'),
        ),
      );
    }

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
                  // ポジションアイコン
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPositionColor(player.position),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        _getPositionShort(player.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 選手名とポジション
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${player.position} | ${player.school}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 契約情報
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getContractTypeColor(professionalPlayer.contractType),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          professionalPlayer.contractTypeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${professionalPlayer.salary}万円',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 詳細情報
              Row(
                children: [
                  // ドラフト情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ドラフト',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          professionalPlayer.draftInfo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 在籍年数
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '在籍年数',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${professionalPlayer.yearsInTeam}年',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 才能ランク
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '才能ランク',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${player.talent}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getTalentColor(player.talent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 成績情報（簡易表示）
              if (player.fame > 0) ...[
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      '知名度: ${player.fame}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    if (player.isFamous)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '注目選手',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case '投手':
        return Colors.red;
      case '捕手':
        return Colors.orange;
      case '一塁手':
      case '二塁手':
      case '三塁手':
      case '遊撃手':
        return Colors.blue;
      case '左翼手':
      case '中堅手':
      case '右翼手':
      case '外野手':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPositionShort(String position) {
    switch (position) {
      case '投手':
        return '投';
      case '捕手':
        return '捕';
      case '一塁手':
        return '一';
      case '二塁手':
        return '二';
      case '三塁手':
        return '三';
      case '遊撃手':
        return '遊';
      case '左翼手':
        return '左';
      case '中堅手':
        return '中';
      case '右翼手':
        return '右';
      case '外野手':
        return '外';
      default:
        return position.substring(0, 1);
    }
  }

  Color _getContractTypeColor(ContractType contractType) {
    switch (contractType) {
      case ContractType.regular:
        return Colors.blue;
      case ContractType.minor:
        return Colors.orange;
      case ContractType.freeAgent:
        return Colors.purple;
    }
  }

  Color _getTalentColor(int talent) {
    if (talent >= 6) return Colors.red;
    if (talent >= 4) return Colors.orange;
    if (talent >= 2) return Colors.blue;
    return Colors.grey;
  }
}
