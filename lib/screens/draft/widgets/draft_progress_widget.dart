import 'package:flutter/material.dart';

/// ドラフト進捗表示ウィジェット
class DraftProgressWidget extends StatelessWidget {
  final int currentRound;
  final int currentPick;
  final int totalRounds;
  final int totalPicksPerRound;
  final bool isDraftInProgress;
  final bool isDraftCompleted;

  const DraftProgressWidget({
    Key? key,
    required this.currentRound,
    required this.currentPick,
    required this.totalRounds,
    required this.totalPicksPerRound,
    required this.isDraftInProgress,
    required this.isDraftCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ドラフト進捗',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressInfo(),
            const SizedBox(height: 16),
            _buildProgressBar(),
            const SizedBox(height: 16),
            _buildStatusInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo() {
    final totalPicks = totalRounds * totalPicksPerRound;
    final completedPicks = (currentRound - 1) * totalPicksPerRound + currentPick;
    final progressPercentage = totalPicks > 0 ? (completedPicks / totalPicks) * 100 : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoItem('現在の巡目', '$currentRound / $totalRounds'),
        _buildInfoItem('現在の選択', '$currentPick / $totalPicksPerRound'),
        _buildInfoItem('進捗率', '${progressPercentage.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final totalPicks = totalRounds * totalPicksPerRound;
    final completedPicks = (currentRound - 1) * totalPicksPerRound + currentPick;
    final progress = totalPicks > 0 ? completedPicks / totalPicks : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '全体進捗',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${completedPicks} / $totalPicks 選択完了',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    String status;
    Color statusColor;

    if (isDraftCompleted) {
      status = 'ドラフト完了';
      statusColor = Colors.green;
    } else if (isDraftInProgress) {
      status = 'ドラフト進行中';
      statusColor = Colors.blue;
    } else {
      status = 'ドラフト待機中';
      statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDraftCompleted ? Icons.check_circle : 
            isDraftInProgress ? Icons.play_circle : Icons.pause_circle,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
