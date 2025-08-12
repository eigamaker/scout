import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game/game.dart';
import '../models/professional/professional_team.dart';
import '../services/game_manager.dart';

class ProfessionalTeamsScreen extends StatefulWidget {
  const ProfessionalTeamsScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalTeamsScreen> createState() => _ProfessionalTeamsScreenState();
}

class _ProfessionalTeamsScreenState extends State<ProfessionalTeamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'draftOrder'; // デフォルトはドラフト順

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('プロ野球団'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'セ・リーグ'),
            Tab(text: 'パ・リーグ'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ソートオプション
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('並び順: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'draftOrder', child: Text('ドラフト順')),
                    DropdownMenuItem(value: 'strength', child: Text('戦力順')),
                    DropdownMenuItem(value: 'budget', child: Text('予算順')),
                    DropdownMenuItem(value: 'popularity', child: Text('人気順')),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeagueView(League.central),
                _buildLeagueView(League.pacific),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueView(League league) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final game = gameManager.currentGame;
        if (game == null) {
          return const Center(child: Text('ゲームデータが見つかりません'));
        }

        List<ProfessionalTeam> teams = game.professionalTeams.getTeamsByLeague(league);
        
        // ソート
        switch (_sortBy) {
          case 'draftOrder':
            teams = teams.where((team) => team.league == league).toList()
              ..sort((a, b) => a.draftOrder.compareTo(b.draftOrder));
            break;
          case 'strength':
            teams = teams.where((team) => team.league == league).toList()
              ..sort((a, b) => b.totalStrength.compareTo(a.totalStrength));
            break;
          case 'budget':
            teams = teams.where((team) => team.league == league).toList()
              ..sort((a, b) => b.budget.compareTo(a.budget));
            break;
          case 'popularity':
            teams = teams.where((team) => team.league == league).toList()
              ..sort((a, b) => b.popularity.compareTo(a.popularity));
            break;
        }

        return ListView.builder(
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final team = teams[index];
            return _buildTeamCard(team);
          },
        );
      },
    );
  }

  Widget _buildTeamCard(ProfessionalTeam team) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getTeamColor(team.league),
          child: Text(
            team.shortName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(team.characteristics),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStrengthIndicator(team.totalStrength),
                const SizedBox(width: 8),
                Text('ドラフト${team.draftOrder}位'),
              ],
            ),
          ],
        ),
        children: [
          _buildTeamDetails(team),
        ],
      ),
    );
  }

  Widget _buildTeamDetails(ProfessionalTeam team) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本情報
          _buildInfoSection('基本情報', team.detailedInfo),
          
          const SizedBox(height: 16),
          
          // 戦力状況
          _buildStrengthSection(team),
          
          const SizedBox(height: 16),
          
          // 球団ニーズ
          _buildNeedsSection(team),
          
          const SizedBox(height: 16),
          
          // スカウトとの関係性
          _buildScoutRelationsSection(team),
          
          const SizedBox(height: 16),
          
          // 選手リスト
          _buildPlayersSection(team),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, Map<String, String> info) {
    return Column(
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
    );
  }

  Widget _buildStrengthSection(ProfessionalTeam team) {
    return Column(
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
          children: team.teamStrength.entries.map((entry) {
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
    );
  }

  Widget _buildNeedsSection(ProfessionalTeam team) {
    return Column(
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
          children: team.needs.map((need) {
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
    );
  }

  Widget _buildScoutRelationsSection(ProfessionalTeam team) {
    return Column(
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
        if (team.scoutRelations.isEmpty)
          const Text('まだ関係性が構築されていません')
        else
          ...team.scoutRelations.entries.map((entry) => Padding(
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
  
  Widget _buildPlayersSection(ProfessionalTeam team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '所属選手 (${team.players.length}名)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        if (team.players.isEmpty)
          const Text('選手が登録されていません')
        else
          Column(
            children: [
              // ポジション別選手数
              _buildPositionSummary(team),
              const SizedBox(height: 8),
              // 選手リスト（最初の5名のみ表示）
              _buildPlayersList(team),
            ],
          ),
      ],
    );
  }
  
  Widget _buildPositionSummary(ProfessionalTeam team) {
    final positionCounts = <String, int>{};
    for (final player in team.players) {
      positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: positionCounts.entries.map((entry) => Chip(
        label: Text('${entry.key}: ${entry.value}名'),
        backgroundColor: Colors.blue[100],
      )).toList(),
    );
  }
  
  Widget _buildPlayersList(ProfessionalTeam team) {
    final displayPlayers = team.players.take(5).toList(); // 最初の5名のみ表示
    
    return Column(
      children: displayPlayers.map((player) => ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPlayerPositionColor(player.position),
          child: Text(
            player.position.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(player.name),
        subtitle: Text('${player.position} | 才能ランク${player.talent}'),
        trailing: Text('能力値: ${player.trueTotalAbility}'),
      )).toList(),
    );
  }
  
  Color _getPlayerPositionColor(String position) {
    switch (position) {
      case '投手':
        return Colors.red;
      case '捕手':
        return Colors.orange;
      case '内野手':
      case '一塁手':
      case '二塁手':
      case '三塁手':
      case '遊撃手':
        return Colors.blue;
      case '外野手':
      case '左翼手':
      case '中堅手':
      case '右翼手':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
