import 'package:flutter/material.dart';
import '../../../models/player/player.dart' hide PlayerType;
import '../../../models/scouting/scout_report.dart';

/// 基本評価ウィジェット
class BasicEvaluationWidget extends StatelessWidget {
  final Player player;
  final FuturePotential futurePotential;
  final ExpectedDraftPosition expectedDraftPosition;
  final PlayerType playerType;
  final double? overallRating;

  const BasicEvaluationWidget({
    Key? key,
    required this.player,
    required this.futurePotential,
    required this.expectedDraftPosition,
    required this.playerType,
    required this.overallRating,
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
              '基本評価',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEvaluationRow(
              '将来性',
              _getFuturePotentialText(futurePotential),
              _getFuturePotentialColor(futurePotential),
            ),
            const SizedBox(height: 8),
            _buildEvaluationRow(
              'ドラフト予想順位',
              _getExpectedDraftPositionText(expectedDraftPosition),
              _getExpectedDraftPositionColor(expectedDraftPosition),
            ),
            const SizedBox(height: 8),
            _buildEvaluationRow(
              '選手タイプ',
              _getPlayerTypeText(playerType),
              Colors.blue,
            ),
            const SizedBox(height: 8),
            if (overallRating != null)
              _buildEvaluationRow(
                '総合評価',
                '${overallRating!.toStringAsFixed(1)}/100',
                _getOverallRatingColor(overallRating!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFuturePotentialText(FuturePotential potential) {
    switch (potential) {
      case FuturePotential.A:
        return '優秀';
      case FuturePotential.B:
        return '良好';
      case FuturePotential.C:
        return '平均';
      case FuturePotential.D:
        return '低い';
      case FuturePotential.E:
        return '非常に低い';
    }
  }

  Color _getFuturePotentialColor(FuturePotential potential) {
    switch (potential) {
      case FuturePotential.A:
        return Colors.green;
      case FuturePotential.B:
        return Colors.lightGreen;
      case FuturePotential.C:
        return Colors.orange;
      case FuturePotential.D:
        return Colors.red;
      case FuturePotential.E:
        return Colors.red[800]!;
    }
  }

  String _getExpectedDraftPositionText(ExpectedDraftPosition position) {
    switch (position) {
      case ExpectedDraftPosition.first:
        return '1巡目';
      case ExpectedDraftPosition.second:
        return '2巡目';
      case ExpectedDraftPosition.third:
        return '3巡目';
      case ExpectedDraftPosition.fourth:
        return '4巡目以降';
      case ExpectedDraftPosition.fifth:
        return '5巡目以降';
      case ExpectedDraftPosition.sixthOrLater:
        return 'ドラフト外';
    }
  }

  Color _getExpectedDraftPositionColor(ExpectedDraftPosition position) {
    switch (position) {
      case ExpectedDraftPosition.first:
        return Colors.purple;
      case ExpectedDraftPosition.second:
        return Colors.blue;
      case ExpectedDraftPosition.third:
        return Colors.green;
      case ExpectedDraftPosition.fourth:
        return Colors.orange;
      case ExpectedDraftPosition.fifth:
        return Colors.orange[600]!;
      case ExpectedDraftPosition.sixthOrLater:
        return Colors.red;
    }
  }

  String _getPlayerTypeText(PlayerType type) {
    switch (type) {
      case PlayerType.powerHitter:
        return 'パワーヒッター';
      case PlayerType.contactHitter:
        return 'コンタクトヒッター';
      case PlayerType.speedster:
        return 'スピードスター';
      case PlayerType.defensiveSpecialist:
        return '守備職人';
      case PlayerType.startingPitcher:
        return 'エース級投手';
      case PlayerType.reliefPitcher:
        return 'リリーフ投手';
      case PlayerType.utilityPlayer:
        return 'ユーティリティプレイヤー';
      case PlayerType.closer:
        return 'クローザー';
      case PlayerType.utilityPitcher:
        return 'ユーティリティ投手';
    }
  }

  Color _getOverallRatingColor(double rating) {
    if (rating >= 80) return Colors.purple;
    if (rating >= 70) return Colors.blue;
    if (rating >= 60) return Colors.green;
    if (rating >= 50) return Colors.orange;
    return Colors.red;
  }
}
