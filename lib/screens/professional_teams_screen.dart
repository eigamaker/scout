import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game/game.dart';
import '../models/professional/professional_team.dart';
import '../services/game_manager.dart';
import 'team_detail_screen.dart';

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
        backgroundColor: Colors.blue,
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

        List<ProfessionalTeam> teams =
            game.professionalTeams.getTeamsByLeague(league);

        // ソート
        switch (_sortBy) {
          case 'draftOrder':
            teams.sort((a, b) => a.draftOrder.compareTo(b.draftOrder));
            break;
          case 'strength':
            teams.sort((a, b) => b.totalStrength.compareTo(a.totalStrength));
            break;
          case 'budget':
            teams.sort((a, b) => b.budget.compareTo(a.budget));
            break;
          case 'popularity':
            teams.sort((a, b) => b.popularity.compareTo(a.popularity));
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailScreen(team: team),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getTeamColor(team.league),
                radius: 25,
                child: Text(
                  team.shortName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.characteristics,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStrengthIndicator(team.totalStrength),
                        const SizedBox(width: 8),
                        Text('ドラフト${team.draftOrder}位'),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
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
}
