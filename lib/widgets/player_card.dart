import 'package:flutter/material.dart';
import 'package:scout_game/models/player/player.dart';
import 'package:scout_game/models/player/player_abilities.dart';
import 'package:provider/provider.dart';
import 'package:scout_game/services/game_manager.dart';
import 'package:scout_game/models/game/game.dart';

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
                  '能力値（推定）:',
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
                  '隠し情報（推定）:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildHiddenInfoDisplay(context),
              ],
              
              // アクションボタンエリア（発掘済み選手の場合のみ）
              if (player.isDiscovered) ...[
                const SizedBox(height: 12),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // アクションボタンエリア
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _addScrimmageAction(context),
            icon: const Icon(Icons.sports_baseball, size: 16),
            label: const Text('練習試合観戦'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(0, 32),
              backgroundColor: Colors.orange[100],
              foregroundColor: Colors.orange[800],
            ),
          ),
        ),
      ],
    );
  }

  // 練習試合観戦アクションを追加
  void _addScrimmageAction(BuildContext context) {
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

    // 練習試合観戦アクションを作成
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'scrimmage',
      schoolId: schoolId,
      playerId: player.id,
      apCost: 2,
      budgetCost: 30000,
      params: {},
    );

    // APと予算が足りるかチェック
    if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name}の練習試合観戦を計画に追加しました（AP: ${action.apCost}, 予算: ¥${action.budgetCost}）'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 投手能力値
        if (player.isPitcher) ...[
          _buildAbilityChip('球速', '${player.getFastballVelocityKmh()}km/h'),
          _buildAbilityChip('制球', '${player.getTechnicalAbility(TechnicalAbility.control)}'),
          _buildAbilityChip('スタミナ', '${player.getPhysicalAbility(PhysicalAbility.stamina)}'),
        ],
        
        // 投手能力値（変化球）
        if (player.isPitcher) ...[
          _buildAbilityChip('変化球', '${player.getTechnicalAbility(TechnicalAbility.breakingBall)}'),
        ],
        
        // 野手能力値
        if (!player.isPitcher) ...[
          _buildAbilityChip('パワー', '${player.getTechnicalAbility(TechnicalAbility.power)}'),
          _buildAbilityChip('バットコントロール', '${player.getTechnicalAbility(TechnicalAbility.batControl)}'),
          _buildAbilityChip('走力', '${player.getPhysicalAbility(PhysicalAbility.pace)}'),
        ],
        
        // 守備能力値
        if (!player.isPitcher) ...[
          _buildAbilityChip('守備', '${player.getTechnicalAbility(TechnicalAbility.fielding)}'),
          _buildAbilityChip('肩', '${player.getTechnicalAbility(TechnicalAbility.throwing)}'),
        ],
      ],
    );
  }

  Widget _buildAbilityChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
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