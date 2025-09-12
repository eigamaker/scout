import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../models/game/game.dart';
import '../models/professional/professional_team.dart';
import '../models/professional/enums.dart';
import '../models/professional/depth_chart.dart';
import '../models/professional/player_stats.dart';
import '../models/professional/professional_player.dart';
import '../services/game_manager.dart';
import '../services/pennant_race_service.dart';
import '../services/depth_chart_service.dart';
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
        print('TeamDetailScreen._buildDepthChartTab: game = ${game != null ? "loaded" : "null"}');
        print('TeamDetailScreen._buildDepthChartTab: pennantRace = ${game?.pennantRace != null ? "loaded" : "null"}');
        print('TeamDetailScreen._buildDepthChartTab: teamDepthCharts = ${game?.pennantRace?.teamDepthCharts != null ? "loaded" : "null"}');
        
        // ペナントレースが開始されていない場合の処理
        if (game?.pennantRace?.teamDepthCharts == null) {
          print('TeamDetailScreen._buildDepthChartTab: ペナントレースが開始されていません');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ペナントレースが開始されていません',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // ペナントレースを開始する処理
                    _startPennantRace(context, gameManager);
                  },
                  child: const Text('ペナントレースを開始'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'または、現在のチーム構成でdepth chartを表示',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // 現在のチーム構成でdepth chartを表示
                    setState(() {});
                  },
                  child: const Text('現在の構成を表示'),
                ),
              ],
            ),
          );
        }

        final depthChart = game!.pennantRace!.teamDepthCharts[widget.team.id];
        print('TeamDetailScreen._buildDepthChartTab: ${widget.team.shortName}のdepthChart = ${depthChart != null ? "loaded" : "null"}');
        
        if (depthChart == null) {
          print('TeamDetailScreen._buildDepthChartTab: ${widget.team.shortName}のデプスチャートが見つかりません');
          print('TeamDetailScreen._buildDepthChartTab: 利用可能なチームID: ${game.pennantRace!.teamDepthCharts.keys.toList()}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('デプスチャートが見つかりません'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // depth chartを再初期化
                    _reinitializeDepthChart(context, gameManager);
                  },
                  child: const Text('Depth Chartを再初期化'),
                ),
              ],
            ),
          );
        }

        print('TeamDetailScreen._buildDepthChartTab: ${widget.team.shortName}のdepthChart詳細 - ポジション数: ${depthChart.positionCharts.length}');
        print('TeamDetailScreen._buildDepthChartTab: ポジション一覧: ${depthChart.positionCharts.keys.toList()}');
        
        for (final entry in depthChart.positionCharts.entries) {
          final position = entry.key;
          final chart = entry.value;
          print('TeamDetailScreen._buildDepthChartTab: $position - 選手数: ${chart.playerIds.length}');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '出場選手構成',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // depth chartを更新
                      _updateDepthChart(context, gameManager);
                    },
                    child: const Text('更新'),
                  ),
                ],
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

  Widget _buildPitcherRotationSection(PitcherRotation pitcherRotation) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final game = gameManager.currentGame;
        if (game?.pennantRace?.teamDepthCharts == null) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('データが読み込めません')));
        }
        
        final depthChart = game!.pennantRace!.teamDepthCharts[widget.team.id];
        if (depthChart == null) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('デプスチャートが見つかりません')));
        }
        
        // チームのプロ野球選手リストを取得
        final professionalPlayers = widget.team.professionalPlayers ?? [];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 先発投手
                if (pitcherRotation.startingPitcherIds.isNotEmpty) ...[
                  const Text(
                    '先発投手',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...pitcherRotation.startingPitcherIds.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pitcherId = entry.value;
                    final isCurrent = index == pitcherRotation.currentRotationIndex;
                    
                    // 投手の名前を取得
                    ProfessionalPlayer? pitcher;
                    if (pitcherId.startsWith('player_')) {
                      // player_123形式のIDからplayerIdを抽出
                      final playerIdNum = int.tryParse(pitcherId.substring(7));
                      if (playerIdNum != null) {
                        pitcher = professionalPlayers.where(
                          (p) => p.playerId == playerIdNum,
                        ).firstOrNull;
                      }
                    } else {
                      // 通常のID検索
                      final pitcherList = professionalPlayers.where(
                        (p) => p.id.toString() == pitcherId,
                      ).toList();
                      pitcher = pitcherList.isNotEmpty ? pitcherList.first : null;
                    }
                    final pitcherName = pitcher?.player?.name ?? '不明な投手';
                    final pitcherAbility = pitcher?.player?.trueTotalAbility ?? 0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.red : Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pitcherName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '能力値: $pitcherAbility',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '次回先発',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
                
                // リリーフ投手
                if (pitcherRotation.reliefPitcherIds.isNotEmpty) ...[
                  const Text(
                    'リリーフ投手',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...pitcherRotation.reliefPitcherIds.take(5).map((pitcherId) {
                    final pitcherList = professionalPlayers.where(
                      (p) => p.id.toString() == pitcherId,
                    ).toList();
                    final pitcher = pitcherList.isNotEmpty ? pitcherList.first : null;
                    final pitcherName = pitcher?.player?.name ?? '不明な投手';
                    final pitcherAbility = pitcher?.player?.trueTotalAbility ?? 0;
                    final usage = pitcherRotation.pitcherUsage[pitcherId] ?? 0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sports_baseball,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pitcherName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '能力値: $pitcherAbility',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '使用: $usage回',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionDepthChartSection(String position, PositionDepthChart chart) {
    print('TeamDetailScreen._buildPositionDepthChartSection: $position - 選手数: ${chart.playerIds.length}');
    print('TeamDetailScreen._buildPositionDepthChartSection: $position - 選手ID一覧: ${chart.playerIds}');
    print('TeamDetailScreen._buildPositionDepthChartSection: $position - 出場時間割合: ${chart.playingTimePercentages}');
    
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final game = gameManager.currentGame;
        if (game?.pennantRace?.teamDepthCharts == null) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('データが読み込めません')));
        }
        
        final depthChart = game!.pennantRace!.teamDepthCharts[widget.team.id];
        if (depthChart == null) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('デプスチャートが見つかりません')));
        }
        
        // チームのプロ野球選手リストを取得
        final professionalPlayers = widget.team.professionalPlayers ?? [];
        print('TeamDetailScreen._buildPositionDepthChartSection: ${widget.team.shortName}のプロ野球選手数: ${professionalPlayers.length}');
        
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
                    
                    // ProfessionalPlayerから選手情報を取得
                    ProfessionalPlayer? professionalPlayer;
                    if (playerId.startsWith('player_')) {
                      // player_123形式のIDからplayerIdを抽出
                      final playerIdNum = int.tryParse(playerId.substring(7));
                      if (playerIdNum != null) {
                        professionalPlayer = professionalPlayers.where(
                          (p) => p.playerId == playerIdNum,
                        ).firstOrNull;
                      }
                    } else {
                      // 通常のID検索
                      final professionalPlayerList = professionalPlayers.where(
                        (p) => p.id.toString() == playerId,
                      ).toList();
                      professionalPlayer = professionalPlayerList.isNotEmpty ? professionalPlayerList.first : null;
                    }
                    
                    final playerName = professionalPlayer?.player?.name ?? '不明な選手';
                    final playerAbility = professionalPlayer?.player?.trueTotalAbility ?? 0;
                    
                    print('TeamDetailScreen._buildPositionDepthChartSection: $position - 選手$index: ID=$playerId, 名前=$playerName, 能力値=$playerAbility, 出場時間=${percentage.toStringAsFixed(1)}%');
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: index == 0 ? Colors.red : Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '能力値: $playerAbility',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
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
                  DataColumn(label: Text('選手名')),
                  DataColumn(label: Text('試合')),
                  DataColumn(label: Text('打率')),
                  DataColumn(label: Text('安打')),
                  DataColumn(label: Text('本塁打')),
                  DataColumn(label: Text('打点')),
                  DataColumn(label: Text('出塁率')),
                ],
                rows: batters.map((stats) {
                  final batterStats = stats.batterStats!;
                  
                  // 選手名を取得
                  String playerName = '不明な選手';
                  if (widget.team.professionalPlayers != null) {
                    final playerIdNum = int.tryParse(stats.playerId.replaceFirst('player_', ''));
                    if (playerIdNum != null) {
                      final professionalPlayer = widget.team.professionalPlayers!.firstWhere(
                        (p) => p.playerId == playerIdNum,
                        orElse: () => widget.team.professionalPlayers!.first,
                      );
                      playerName = professionalPlayer.player?.name ?? '不明な選手';
                    }
                  }
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(playerName)),
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
                  DataColumn(label: Text('選手名')),
                  DataColumn(label: Text('試合')),
                  DataColumn(label: Text('先発')),
                  DataColumn(label: Text('勝利')),
                  DataColumn(label: Text('敗戦')),
                  DataColumn(label: Text('防御率')),
                  DataColumn(label: Text('奪三振')),
                ],
                rows: pitchers.map((stats) {
                  final pitcherStats = stats.pitcherStats!;
                  
                  // 選手名を取得
                  String playerName = '不明な選手';
                  if (widget.team.professionalPlayers != null) {
                    final playerIdNum = int.tryParse(stats.playerId.replaceFirst('player_', ''));
                    if (playerIdNum != null) {
                      final professionalPlayer = widget.team.professionalPlayers!.firstWhere(
                        (p) => p.playerId == playerIdNum,
                        orElse: () => widget.team.professionalPlayers!.first,
                      );
                      playerName = professionalPlayer.player?.name ?? '不明な選手';
                    }
                  }
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(playerName)),
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

  /// ペナントレースを開始
  void _startPennantRace(BuildContext context, GameManager gameManager) {
    // ペナントレースの初期化処理
    final currentYear = gameManager.currentGame?.currentYear ?? DateTime.now().year;
    final teams = gameManager.currentGame?.professionalTeams.teams ?? [];
    
    if (teams.isNotEmpty) {
      // ペナントレースを開始
      final pennantRace = PennantRaceService.createInitialPennantRace(currentYear, teams);
      gameManager.updatePennantRace(pennantRace);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ペナントレースを開始しました')),
      );
      
      setState(() {});
    }
  }

  /// Depth Chartを再初期化
  void _reinitializeDepthChart(BuildContext context, GameManager gameManager) {
    final game = gameManager.currentGame;
    if (game?.pennantRace != null && game?.professionalTeams.teams.isNotEmpty == true) {
      final team = game!.professionalTeams.teams.firstWhere((t) => t.id == widget.team.id);
      
      if (team.professionalPlayers?.isNotEmpty == true) {
        // depth chartを再作成
        final depthChart = DepthChartService.initializeTeamDepthChart(
          team.id,
          team.professionalPlayers!,
        );
        
        // ペナントレースのdepth chartを更新
        final updatedDepthCharts = Map<String, TeamDepthChart>.from(game.pennantRace!.teamDepthCharts);
        updatedDepthCharts[team.id] = depthChart;
        
        final updatedPennantRace = game.pennantRace!.copyWith(
          teamDepthCharts: updatedDepthCharts,
        );
        
        gameManager.updatePennantRace(updatedPennantRace);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Depth Chartを再初期化しました')),
        );
        
        setState(() {});
      }
    }
  }

  /// Depth Chartを更新
  void _updateDepthChart(BuildContext context, GameManager gameManager) {
    final game = gameManager.currentGame;
    if (game?.pennantRace != null && game?.professionalTeams.teams.isNotEmpty == true) {
      final team = game!.professionalTeams.teams.firstWhere((t) => t.id == widget.team.id);
      
      if (team.professionalPlayers?.isNotEmpty == true) {
        // 現在の選手構成でdepth chartを更新
        final depthChart = DepthChartService.initializeTeamDepthChart(
          team.id,
          team.professionalPlayers!,
        );
        
        // ペナントレースのdepth chartを更新
        final updatedDepthCharts = Map<String, TeamDepthChart>.from(game.pennantRace!.teamDepthCharts);
        updatedDepthCharts[team.id] = depthChart;
        
        final updatedPennantRace = game.pennantRace!.copyWith(
          teamDepthCharts: updatedDepthCharts,
        );
        
        gameManager.updatePennantRace(updatedPennantRace);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Depth Chartを更新しました')),
        );
        
        setState(() {});
      }
    }
  }
}
