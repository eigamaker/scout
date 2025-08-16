import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game/game.dart';
import '../models/professional/professional_team.dart';
import '../models/professional/depth_chart.dart';
import '../models/professional/player_stats.dart';
import '../services/game_manager.dart';
import '../widgets/professional_player_card.dart';

class TeamDetailScreen extends StatefulWidget {
  final ProfessionalTeam team;
  
  const TeamDetailScreen({
    Key? key,
    required this.team,
  }) : super(key: key);

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
        backgroundColor: _getTeamColor(widget.team.league),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '基本情報'),
            Tab(text: '出場選手構成'),
            Tab(text: '選手成績'),
            Tab(text: '所属選手'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildDepthChartTab(),
          _buildPlayerStatsTab(),
          _buildPlayersTab(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 球団概要カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _getTeamColor(widget.team.league),
                        child: Text(
                          widget.team.shortName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.team.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.team.characteristics,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStrengthIndicator(widget.team.totalStrength),
                                const SizedBox(width: 8),
                                Text('ドラフト${widget.team.draftOrder}位'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 基本情報
          _buildInfoSection('基本情報', widget.team.detailedInfo),
          
          const SizedBox(height: 16),
          
          // 戦力状況
          _buildStrengthSection(),
          
          const SizedBox(height: 16),
          
          // 球団ニーズ
          _buildNeedsSection(),
          
          const SizedBox(height: 16),
          
          // スカウトとの関係性
          _buildScoutRelationsSection(),
        ],
      ),
    );
  }

  Widget _buildDepthChartTab() {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final game = gameManager.currentGame;
        if (game?.pennantRace?.teamDepthCharts == null) {
          return const Center(
            child: Text('ペナントレースが開始されていません'),
          );
        }

        final depthChart = game!.pennantRace!.teamDepthCharts[widget.team.id];
        if (depthChart == null) {
          return const Center(
            child: Text('デプスチャートが見つかりません'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '出場選手構成',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // 投手ローテーション
              _buildPitcherRotationSection(depthChart.pitcherRotation),
              const SizedBox(height: 16),
              
              // ポジション別出場選手
              ...depthChart.positionCharts.entries.map((entry) => 
                _buildPositionDepthChartSection(entry.key, entry.value)
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerStatsTab() {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final game = gameManager.currentGame;
        if (game?.pennantRace?.playerStats == null) {
          return const Center(
            child: Text('ペナントレースが開始されていません'),
          );
        }

        final playerStats = game!.pennantRace!.playerStats;
        final teamPlayerStats = <String, PlayerSeasonStats>{};
        
        // このチームの選手の成績を抽出
        if (widget.team.professionalPlayers != null) {
          for (final professionalPlayer in widget.team.professionalPlayers!) {
            final stats = playerStats[professionalPlayer.playerId.toString()];
            if (stats != null) {
              teamPlayerStats[professionalPlayer.playerId.toString()] = stats;
            }
          }
        }

        if (teamPlayerStats.isEmpty) {
          return const Center(
            child: Text('選手成績がありません'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '選手成績',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // 打者成績
              _buildBatterStatsSection(teamPlayerStats),
              const SizedBox(height: 16),
              
              // 投手成績
              _buildPitcherStatsSection(teamPlayerStats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    if (widget.team.professionalPlayers?.isNotEmpty == true) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.team.professionalPlayers!.length,
        itemBuilder: (context, index) {
          final professionalPlayer = widget.team.professionalPlayers![index];
          return ProfessionalPlayerCard(
            professionalPlayer: professionalPlayer,
            onTap: () {
              // TODO: 選手詳細画面への遷移
            },
          );
        },
      );
    }
    
    return const Center(
      child: Text('プロ野球選手が登録されていません'),
    );
  }

  Widget _buildInfoSection(String title, Map<String, String> info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            ...info.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(child: Text(entry.value)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '戦力状況',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.team.teamStrength.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStrengthColor(entry.value),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '球団ニーズ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.team.needs.map((need) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    need,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoutRelationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スカウトとの関係性',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.team.scoutRelations.isEmpty)
              const Text('まだ関係性が構築されていません')
            else
              ...widget.team.scoutRelations.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text('スカウト${entry.key}:'),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getRelationColor(entry.value),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}%'),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildPitcherRotationSection(PitcherRotation rotation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '投手ローテーション',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            
            // 先発投手
            if (rotation.startingPitcherIds.isNotEmpty) ...[
              Text(
                '先発投手 (${rotation.startingPitcherIds.length}名)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: rotation.startingPitcherIds.asMap().entries.map((entry) {
                  final index = entry.key;
                  final playerId = entry.value;
                  final isCurrent = index == rotation.currentRotationIndex;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.red : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}番手${isCurrent ? '(次)' : ''}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // リリーフ投手
            if (rotation.reliefPitcherIds.isNotEmpty) ...[
              Text(
                'リリーフ投手 (${rotation.reliefPitcherIds.length}名)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: rotation.reliefPitcherIds.map((playerId) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'リリーフ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // クローザー
            if (rotation.closerPitcherIds.isNotEmpty) ...[
              Text(
                'クローザー (${rotation.closerPitcherIds.length}名)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: rotation.closerPitcherIds.map((playerId) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'クローザー',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPositionDepthChartSection(String position, PositionDepthChart chart) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              position,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            
            if (chart.playerIds.isEmpty)
              const Text('選手が登録されていません')
            else
              ...chart.playerIds.asMap().entries.map((entry) {
                final index = entry.key;
                final playerId = entry.value;
                final percentage = chart.playingTimePercentages[playerId] ?? 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: index == 0 ? Colors.amber : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index == 0 ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '選手ID: $playerId',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPlayingTimeColor(percentage),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBatterStatsSection(Map<String, PlayerSeasonStats> playerStats) {
    final batters = playerStats.values.where((stats) => 
      stats.batterStats != null && stats.batterStats!.games > 0
    ).toList();
    
    if (batters.isEmpty) {
      return const SizedBox.shrink();
    }

    // 打率順でソート
    batters.sort((a, b) => (b.batterStats!.battingAverage ?? 0.0)
        .compareTo(a.batterStats!.battingAverage ?? 0.0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '打者成績 (${batters.length}名)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            
            // 成績表
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('選手ID')),
                  DataColumn(label: Text('試合')),
                  DataColumn(label: Text('打率')),
                  DataColumn(label: Text('安打')),
                  DataColumn(label: Text('本塁打')),
                  DataColumn(label: Text('打点')),
                  DataColumn(label: Text('出塁率')),
                ],
                rows: batters.map((stats) {
                  final batterStats = stats.batterStats!;
                  return DataRow(
                    cells: [
                      DataCell(Text(stats.playerId)),
                      DataCell(Text('${batterStats.games}')),
                      DataCell(Text('${(batterStats.battingAverage ?? 0.0).toStringAsFixed(3)}')),
                      DataCell(Text('${batterStats.hits}')),
                      DataCell(Text('${batterStats.homeRuns}')),
                      DataCell(Text('${batterStats.runsBattedIn}')),
                      DataCell(Text('${(batterStats.onBasePercentage ?? 0.0).toStringAsFixed(3)}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitcherStatsSection(Map<String, PlayerSeasonStats> playerStats) {
    final pitchers = playerStats.values.where((stats) => 
      stats.pitcherStats != null && stats.pitcherStats!.games > 0
    ).toList();
    
    if (pitchers.isEmpty) {
      return const SizedBox.shrink();
    }

    // 防御率順でソート
    pitchers.sort((a, b) => (a.pitcherStats!.earnedRunAverage ?? 999.0)
        .compareTo(b.pitcherStats!.earnedRunAverage ?? 999.0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '投手成績 (${pitchers.length}名)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            
            // 成績表
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('選手ID')),
                  DataColumn(label: Text('試合')),
                  DataColumn(label: Text('先発')),
                  DataColumn(label: Text('勝利')),
                  DataColumn(label: Text('敗戦')),
                  DataColumn(label: Text('防御率')),
                  DataColumn(label: Text('奪三振')),
                ],
                rows: pitchers.map((stats) {
                  final pitcherStats = stats.pitcherStats!;
                  return DataRow(
                    cells: [
                      DataCell(Text(stats.playerId)),
                      DataCell(Text('${pitcherStats.games}')),
                      DataCell(Text('${pitcherStats.gamesStarted}')),
                      DataCell(Text('${pitcherStats.wins}')),
                      DataCell(Text('${pitcherStats.losses}')),
                      DataCell(Text('${(pitcherStats.earnedRunAverage ?? 999.0).toStringAsFixed(2)}')),
                      DataCell(Text('${pitcherStats.strikeouts}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(int strength) {
    Color color;
    String label;
    
    if (strength >= 80) {
      color = Colors.red;
      label = '強豪';
    } else if (strength >= 60) {
      color = Colors.orange;
      label = '中堅';
    } else if (strength >= 40) {
      color = Colors.yellow;
      label = '弱小';
    } else {
      color = Colors.grey;
      label = '最下位';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getTeamColor(League league) {
    switch (league) {
      case League.central:
        return Colors.red;
      case League.pacific:
        return Colors.blue;
    }
  }

  Color _getStrengthColor(int strength) {
    if (strength >= 80) return Colors.red;
    if (strength >= 60) return Colors.orange;
    if (strength >= 40) return Colors.yellow;
    return Colors.grey;
  }

  Color _getRelationColor(int relation) {
    if (relation >= 80) return Colors.green;
    if (relation >= 60) return Colors.blue;
    if (relation >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getPlayingTimeColor(double percentage) {
    if (percentage >= 80) return Colors.red;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.yellow;
    if (percentage >= 20) return Colors.blue;
    return Colors.grey;
  }
}
