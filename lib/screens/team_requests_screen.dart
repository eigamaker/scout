import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game/game.dart';
import '../models/scouting/team_request.dart';
import '../models/player/player.dart';
import '../services/game_manager.dart';

class TeamRequestsScreen extends StatefulWidget {
  const TeamRequestsScreen({Key? key}) : super(key: key);

  @override
  State<TeamRequestsScreen> createState() => _TeamRequestsScreenState();
}

class _TeamRequestsScreenState extends State<TeamRequestsScreen> {
  TeamRequest? selectedRequest;
  Player? selectedPlayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('球団からの要望'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Consumer<GameManager>(
        builder: (context, gameManager, child) {
          final game = gameManager.currentGame;
          if (game == null) {
            return const Center(child: Text('ゲームデータが見つかりません'));
          }

          final activeRequests = game.teamRequests.getActiveRequests();
          final completedRequests = game.teamRequests.getCompletedRequests();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: '進行中'),
                    Tab(text: '完了済み'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildActiveRequestsTab(activeRequests, game),
                      _buildCompletedRequestsTab(completedRequests, game),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveRequestsTab(List<TeamRequest> requests, Game game) {
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('現在進行中の要望はありません', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getRequestTypeIcon(request.type),
                      color: _getRequestTypeColor(request.type),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDeadlineColor(request),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '残り${request.remainingDays}日',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  request.description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '報酬: ¥${request.reward.toString()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showPlayerSelectionDialog(context, request, game),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('選手を推薦'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedRequestsTab(List<TeamRequest> requests, Game game) {
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('完了した要望はありません', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final player = game.discoveredPlayers.firstWhere(
          (p) => p.id.toString() == request.completedPlayerId,
          orElse: () => game.discoveredPlayers.first,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '完了',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '推薦選手: ${player.name}',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  '報酬: ¥${request.reward.toString()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlayerSelectionDialog(BuildContext context, TeamRequest request, Game game) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${request.title} - 選手選択'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Text(
                  request.description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: game.discoveredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = game.discoveredPlayers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(player.name[0]),
                        ),
                        title: Text(player.name),
                        subtitle: Text('${player.school} - ${player.position}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _createReport(context, request, player);
                            Navigator.of(context).pop();
                          },
                          child: const Text('推薦'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  void _createReport(BuildContext context, TeamRequest request, Player player) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    
    if (game != null) {
      // レポート作成アクションを追加
      final action = GameAction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'reportWrite',
        schoolId: 0, // 不要だが必須パラメータ
        playerId: player.id,
        apCost: 2,
        budgetCost: 0,
        params: {
          'requestId': request.id,
        },
      );

      gameManager.addActionToGame(action);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name}選手を${request.title}として推薦しました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  IconData _getRequestTypeIcon(TeamRequestType type) {
    switch (type) {
      case TeamRequestType.immediateImpact:
        return Icons.flash_on;
      case TeamRequestType.futureCleanup:
        return Icons.sports_baseball;
      case TeamRequestType.futureSecond:
        return Icons.sports_baseball;
      case TeamRequestType.futureAce:
        return Icons.sports_baseball;
      default:
        return Icons.assignment;
    }
  }

  Color _getRequestTypeColor(TeamRequestType type) {
    switch (type) {
      case TeamRequestType.immediateImpact:
        return Colors.orange;
      case TeamRequestType.futureCleanup:
        return Colors.red;
      case TeamRequestType.futureSecond:
        return Colors.blue;
      case TeamRequestType.futureAce:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getDeadlineColor(TeamRequest request) {
    if (request.remainingDays <= 7) {
      return Colors.red;
    } else if (request.remainingDays <= 14) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
} 