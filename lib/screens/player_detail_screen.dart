import 'package:flutter/material.dart';
import '../models/player/player.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final tableBg = Colors.black.withOpacity(0.7);
    final textColor = Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name}の詳細'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景グラデーション
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color.fromARGB(180, 0, 0, 0),
                ],
              ),
            ),
          ),
          // メイン内容
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('基本情報', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor)),
                Container(
                  decoration: BoxDecoration(
                    color: tableBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Table(
                    columnWidths: const {0: IntrinsicColumnWidth()},
                    children: [
                      TableRow(children: [Text('名前', style: TextStyle(color: textColor)), Text(player.name, style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('学校', style: TextStyle(color: textColor)), Text(player.school, style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('学年', style: TextStyle(color: textColor)), Text('${player.grade}', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('ポジション', style: TextStyle(color: textColor)), Text(player.position, style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('性格', style: TextStyle(color: textColor)), Text(player.personality, style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('知名度', style: TextStyle(color: textColor)), Text('${player.fame}', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('信頼度', style: TextStyle(color: textColor)), Text('${player.trustLevel}', style: TextStyle(color: textColor))]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('人物・成長', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
                Container(
                  decoration: BoxDecoration(
                    color: tableBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Table(
                    columnWidths: const {0: IntrinsicColumnWidth()},
                    children: [
                      TableRow(children: [Text('才能ランク', style: TextStyle(color: textColor)), Text('${player.talent}', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('成長タイプ', style: TextStyle(color: textColor)), Text(player.growthType, style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('精神力', style: TextStyle(color: textColor)), Text(player.mentalGrit.toStringAsFixed(2), style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('成長スピード', style: TextStyle(color: textColor)), Text(player.growthRate.toStringAsFixed(2), style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('ポテンシャル', style: TextStyle(color: textColor)), Text('${player.peakAbility}', style: TextStyle(color: textColor))]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('投手能力値', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
                Container(
                  decoration: BoxDecoration(
                    color: tableBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Table(
                    columnWidths: const {0: IntrinsicColumnWidth()},
                    children: [
                      TableRow(children: [Text('球速', style: TextStyle(color: textColor)), Text(player.fastballVelo != null ? '${player.fastballVelo} km/h' : '-', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('制球', style: TextStyle(color: textColor)), Text(player.control?.toString() ?? '-', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('スタミナ', style: TextStyle(color: textColor)), Text(player.stamina?.toString() ?? '-', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('変化', style: TextStyle(color: textColor)), Text(player.breakAvg?.toString() ?? '-', style: TextStyle(color: textColor))]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('野手能力値', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
                Container(
                  decoration: BoxDecoration(
                    color: tableBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Table(
                    columnWidths: const {0: IntrinsicColumnWidth()},
                    children: [
                      TableRow(children: [Text('パワー', style: TextStyle(color: textColor)), Text(player.batPower?.toString() ?? '-', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('バットコントロール', style: TextStyle(color: textColor)), Text(player.batControl?.toString() ?? '-', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('走力', style: TextStyle(color: textColor)), Text(player.run?.toString() ?? '-', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('守備', style: TextStyle(color: textColor)), Text(player.field?.toString() ?? '-', style: TextStyle(color: textColor))]),
                      TableRow(children: [Text('肩', style: TextStyle(color: textColor)), Text(player.arm?.toString() ?? '-', style: TextStyle(color: textColor))]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (player.isPitcher && player.pitches != null && player.pitches!.isNotEmpty) ...[
                  Text('球種', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
                  Container(
                    decoration: BoxDecoration(
                      color: tableBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Table(
                      columnWidths: const {0: IntrinsicColumnWidth()},
                      children: player.pitches!.map((p) => TableRow(children: [
                        Text(p.type, style: TextStyle(color: textColor)),
                        Text('変化量: ${p.breakAmount} / 潜在: ${p.breakPot}', style: TextStyle(color: textColor)),
                      ])).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('ポジション適性', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
                Container(
                  decoration: BoxDecoration(
                    color: tableBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Table(
                    columnWidths: const {0: IntrinsicColumnWidth()},
                    children: player.positionFit.entries.map((e) => TableRow(children: [
                      Text(e.key, style: TextStyle(color: textColor)),
                      Text('${e.value}', style: TextStyle(color: textColor)),
                    ])).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (player.scoutEvaluation != null && player.scoutEvaluation!.isNotEmpty)
                  Text('スカウト評価: ${player.scoutEvaluation!}', style: TextStyle(color: textColor)),
                if (player.scoutNotes != null && player.scoutNotes!.isNotEmpty)
                  Text('スカウトメモ: ${player.scoutNotes!}', style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 