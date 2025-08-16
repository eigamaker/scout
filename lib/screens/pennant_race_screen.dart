import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../models/game/pennant_race.dart';
import '../models/professional/professional_team.dart';

class PennantRaceScreen extends StatefulWidget {
  const PennantRaceScreen({super.key});

  @override
  State<PennantRaceScreen> createState() => _PennantRaceScreenState();
}

class _PennantRaceScreenState extends State<PennantRaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'rank';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('ペナントレース'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'セ・リーグ'),
            Tab(text: 'パ・リーグ'),
            Tab(text: '今週の試合'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ペナントレース進行状況
          Consumer<GameManager>(
            builder: (context, gameManager, child) {
              final progress = gameManager.pennantRaceProgress;
              final isActive = gameManager.isPennantRaceActive;
              
              return Container(
                padding: const EdgeInsets.all(16),
                color: isActive ? Colors.green[50] : Colors.grey[50],
                child: Row(
                  children: [
                    Icon(
                      isActive ? Icons.sports_baseball : Icons.schedule,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isActive ? 'ペナントレース進行中' : 'ペナントレース未開始',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green[800] : Colors.grey[600],
                            ),
                          ),
                          Text(
                            progress,
                            style: TextStyle(
                              color: isActive ? Colors.green[600] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeagueView(League.central),
                _buildLeagueView(League.pacific),
                _buildThisWeekGames(),
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
        if (game == null || game.pennantRace == null) {
          return const Center(child: Text('ペナントレースデータが見つかりません'));
        }

        final pennantRace = game.pennantRace!;
        final standings = pennantRace.getLeagueStandings(league);
        
        if (standings.isEmpty) {
          return const Center(child: Text('順位表データがありません'));
        }

        return Column(
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
                      DropdownMenuItem(value: 'rank', child: Text('順位順')),
                      DropdownMenuItem(value: 'winRate', child: Text('勝率順')),
                      DropdownMenuItem(value: 'gamesBehind', child: Text('ゲーム差順')),
                      DropdownMenuItem(value: 'runsScored', child: Text('得点順')),
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
            // 順位表
            Expanded(
              child: _buildStandingsTable(standings),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStandingsTable(List<TeamStanding> standings) {
    // ソート
    List<TeamStanding> sortedStandings = List.from(standings);
    switch (_sortBy) {
      case 'rank':
        sortedStandings.sort((a, b) => a.rank.compareTo(b.rank));
        break;
      case 'winRate':
        sortedStandings.sort((a, b) => b.winningPercentage.compareTo(a.winningPercentage));
        break;
      case 'gamesBehind':
        sortedStandings.sort((a, b) => a.gamesBehind.compareTo(b.gamesBehind));
        break;
      case 'runsScored':
        sortedStandings.sort((a, b) => b.runsScored.compareTo(a.runsScored));
        break;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('順位')),
          DataColumn(label: Text('チーム')),
          DataColumn(label: Text('試合')),
          DataColumn(label: Text('勝')),
          DataColumn(label: Text('敗')),
          DataColumn(label: Text('分')),
          DataColumn(label: Text('勝率')),
          DataColumn(label: Text('ゲーム差')),
          DataColumn(label: Text('得点')),
          DataColumn(label: Text('失点')),
          DataColumn(label: Text('得失差')),
        ],
        rows: sortedStandings.map((standing) {
          return DataRow(
            cells: [
              DataCell(Text('${standing.rank}')),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      standing.teamShortName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      standing.teamName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text('${standing.games}')),
              DataCell(Text('${standing.wins}')),
              DataCell(Text('${standing.losses}')),
              DataCell(Text('${standing.ties}')),
              DataCell(Text('${(standing.winningPercentage * 100).toStringAsFixed(3)}')),
              DataCell(Text(standing.gamesBehind == 0.0 ? '-' : '${standing.gamesBehind.toStringAsFixed(1)}')),
              DataCell(Text('${standing.runsScored}')),
              DataCell(Text('${standing.runsAllowed}')),
              DataCell(Text('${standing.runDifferential}')),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThisWeekGames() {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final game = gameManager.currentGame;
        if (game == null || game.pennantRace == null) {
          return const Center(child: Text('ペナントレースデータが見つかりません'));
        }

        final pennantRace = game.pennantRace!;
        final month = game.currentMonth;
        final week = game.currentWeekOfMonth;
        final weekGames = pennantRace.schedule.getGamesForWeek(month, week);

        if (weekGames.isEmpty) {
          return const Center(child: Text('今週の試合はありません'));
        }

        return ListView.builder(
          itemCount: weekGames.length,
          itemBuilder: (context, index) {
            final gameSchedule = weekGames[index];
            return _buildGameCard(gameSchedule, pennantRace);
          },
        );
      },
    );
  }

  Widget _buildGameCard(GameSchedule gameSchedule, PennantRace pennantRace) {
    final homeTeam = _getTeamById(gameSchedule.homeTeamId);
    final awayTeam = _getTeamById(gameSchedule.awayTeamId);
    
    if (homeTeam == null || awayTeam == null) {
      return const Card(
        margin: EdgeInsets.all(8),
        child: ListTile(
          title: Text('チーム情報が見つかりません'),
        ),
      );
    }

    final isCompleted = gameSchedule.isCompleted;
    final result = gameSchedule.result;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 試合日
            Text(
              gameSchedule.gameDateDisplay,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            // 対戦カード
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        awayTeam.shortName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        awayTeam.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // スコアまたはVS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isCompleted && result != null
                      ? Text(
                          result.scoreDisplay,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        homeTeam.shortName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        homeTeam.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 試合結果の詳細
            if (isCompleted && result != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      result.isExtraInnings ? Icons.schedule : Icons.sports_baseball,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${result.inning}回${result.isExtraInnings ? '延長' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ProfessionalTeam? _getTeamById(String teamId) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    if (game == null) return null;
    
    try {
      return game.professionalTeams.teams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }
}
