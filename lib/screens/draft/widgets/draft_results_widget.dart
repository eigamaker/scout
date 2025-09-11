import 'package:flutter/material.dart';

/// ドラフト結果表示ウィジェット
class DraftResultsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> draftResults;
  final int currentRound;
  final int currentPick;

  const DraftResultsWidget({
    Key? key,
    required this.draftResults,
    required this.currentRound,
    required this.currentPick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ドラフト結果',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (draftResults.isEmpty)
              _buildEmptyState()
            else
              _buildResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        children: [
          Icon(
            Icons.sports_baseball,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'まだ選択された選手はいません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: draftResults.length,
      itemBuilder: (context, index) {
        final result = draftResults[index];
        return _buildResultItem(result, index);
      },
    );
  }

  Widget _buildResultItem(Map<String, dynamic> result, int index) {
    final round = result['round'] as int;
    final pick = result['pick'] as int;
    final teamName = result['teamName'] as String;
    final playerName = result['playerName'] as String;
    final playerPosition = result['playerPosition'] as String;
    final playerSchool = result['playerSchool'] as String;
    final playerTalent = result['playerTalent'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          _buildPickInfo(round, pick),
          const SizedBox(width: 16),
          Expanded(
            child: _buildPlayerInfo(
              teamName,
              playerName,
              playerPosition,
              playerSchool,
              playerTalent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickInfo(int round, int pick) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${round}巡目',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${pick}位',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(
    String teamName,
    String playerName,
    String playerPosition,
    String playerSchool,
    int playerTalent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                playerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTalentColor(playerTalent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '才能${playerTalent}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$playerPosition / $playerSchool',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '→ $teamName',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getTalentColor(int talent) {
    switch (talent) {
      case 5:
        return Colors.purple;
      case 4:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
