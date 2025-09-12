import 'package:flutter/material.dart';
import '../models/professional/player_stats.dart';
import '../models/professional/professional_player.dart';

/// 選手成績表示ウィジェット
class PlayerStatsWidget extends StatelessWidget {
  final ProfessionalPlayer player;
  final PlayerSeasonStats? stats;

  const PlayerStatsWidget({
    Key? key,
    required this.player,
    this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 選手基本情報
            _buildPlayerHeader(),
            const SizedBox(height: 16),
            
            // 打者成績
            if (stats?.batterStats != null) ...[
              _buildBatterStats(),
              const SizedBox(height: 16),
            ],
            
            // 投手成績
            if (stats?.pitcherStats != null) ...[
              _buildPitcherStats(),
            ],
            
            // 成績がない場合
            if (stats == null) ...[
              const Center(
                child: Text(
                  '成績データがありません',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            player.player?.name.substring(0, 1) ?? '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.player?.name ?? '不明な選手',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${player.player?.position ?? '不明'} | ${player.teamName ?? '不明なチーム'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatterStats() {
    final batterStats = stats!.batterStats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '打者成績',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        
        // 基本成績
        _buildStatsRow('試合数', '${batterStats.games}試合'),
        _buildStatsRow('打席数', '${batterStats.atBats}打席'),
        _buildStatsRow('安打数', '${batterStats.hits}安打'),
        _buildStatsRow('打率', _formatAverage(batterStats.battingAverage)),
        _buildStatsRow('本塁打', '${batterStats.homeRuns}本'),
        _buildStatsRow('打点', '${batterStats.runsBattedIn}点'),
        _buildStatsRow('得点', '${batterStats.runs}点'),
        _buildStatsRow('四球', '${batterStats.walks}個'),
        _buildStatsRow('三振', '${batterStats.strikeouts}個'),
        
        const SizedBox(height: 8),
        
        // 詳細成績
        _buildStatsRow('出塁率', _formatAverage(batterStats.onBasePercentage)),
        _buildStatsRow('長打率', _formatAverage(batterStats.sluggingPercentage)),
        _buildStatsRow('OPS', _formatAverage(batterStats.ops)),
      ],
    );
  }

  Widget _buildPitcherStats() {
    final pitcherStats = stats!.pitcherStats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '投手成績',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        
        // 基本成績
        _buildStatsRow('試合数', '${pitcherStats.games}試合'),
        _buildStatsRow('先発数', '${pitcherStats.gamesStarted}試合'),
        _buildStatsRow('投球回', '${pitcherStats.inningsPitched.toStringAsFixed(1)}回'),
        _buildStatsRow('勝利', '${pitcherStats.wins}勝'),
        _buildStatsRow('敗戦', '${pitcherStats.losses}敗'),
        _buildStatsRow('勝率', _formatAverage(pitcherStats.winningPercentage)),
        _buildStatsRow('防御率', _formatEra(pitcherStats.earnedRunAverage)),
        
        const SizedBox(height: 8),
        
        // 詳細成績
        _buildStatsRow('被安打', '${pitcherStats.hits}本'),
        _buildStatsRow('失点', '${pitcherStats.runs}点'),
        _buildStatsRow('自責点', '${pitcherStats.earnedRuns}点'),
        _buildStatsRow('被本塁打', '${pitcherStats.homeRuns}本'),
        _buildStatsRow('与四球', '${pitcherStats.walks}個'),
        _buildStatsRow('奪三振', '${pitcherStats.strikeouts}個'),
        _buildStatsRow('WHIP', _formatAverage(pitcherStats.whip)),
        _buildStatsRow('K/9', _formatAverage(pitcherStats.strikeoutsPerNine)),
        _buildStatsRow('BB/9', _formatAverage(pitcherStats.walksPerNine)),
      ],
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAverage(double value) {
    if (value == 0.0) return '.000';
    return value.toStringAsFixed(3).substring(1); // 0.XXX形式
  }

  String _formatEra(double value) {
    if (value == 0.0) return '0.00';
    return value.toStringAsFixed(2);
  }
}

/// チーム成績一覧表示ウィジェット
class TeamStatsWidget extends StatelessWidget {
  final Map<String, PlayerSeasonStats> playerStats;
  final List<ProfessionalPlayer> players;

  const TeamStatsWidget({
    Key? key,
    required this.playerStats,
    required this.players,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 打者成績ランキング
        _buildBatterRankings(),
        const SizedBox(height: 16),
        
        // 投手成績ランキング
        _buildPitcherRankings(),
      ],
    );
  }

  Widget _buildBatterRankings() {
    final batters = players.where((p) => 
      p.player?.position != '投手' && 
      playerStats.containsKey(p.playerId.toString()) &&
      playerStats[p.playerId.toString()]!.batterStats != null
    ).toList();

    if (batters.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('打者成績データがありません'),
        ),
      );
    }

    // 打率順にソート
    batters.sort((a, b) {
      final aStats = playerStats[a.playerId.toString()]!.batterStats!;
      final bStats = playerStats[b.playerId.toString()]!.batterStats!;
      return bStats.battingAverage.compareTo(aStats.battingAverage);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '打者成績ランキング（打率順）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            ...batters.take(10).map((player) {
              final stats = playerStats[player.playerId.toString()]!.batterStats!;
              return _buildBatterRankingItem(player, stats);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPitcherRankings() {
    final pitchers = players.where((p) => 
      p.player?.position == '投手' && 
      playerStats.containsKey(p.playerId.toString()) &&
      playerStats[p.playerId.toString()]!.pitcherStats != null
    ).toList();

    if (pitchers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('投手成績データがありません'),
        ),
      );
    }

    // 防御率順にソート
    pitchers.sort((a, b) {
      final aStats = playerStats[a.playerId.toString()]!.pitcherStats!;
      final bStats = playerStats[b.playerId.toString()]!.pitcherStats!;
      return aStats.earnedRunAverage.compareTo(bStats.earnedRunAverage);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '投手成績ランキング（防御率順）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ...pitchers.take(10).map((player) {
              final stats = playerStats[player.playerId.toString()]!.pitcherStats!;
              return _buildPitcherRankingItem(player, stats);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBatterRankingItem(ProfessionalPlayer player, BatterStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              player.player?.name ?? '不明な選手',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${stats.battingAverage.toStringAsFixed(3).substring(1)} (${stats.hits}/${stats.atBats})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitcherRankingItem(ProfessionalPlayer player, PitcherStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              player.player?.name ?? '不明な選手',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${stats.earnedRunAverage.toStringAsFixed(2)} (${stats.wins}勝${stats.losses}敗)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
