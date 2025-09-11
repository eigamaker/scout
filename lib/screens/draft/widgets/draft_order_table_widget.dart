import 'package:flutter/material.dart';

/// ドラフト順位表ウィジェット
class DraftOrderTableWidget extends StatelessWidget {
  final List<String> draftOrder;
  final Map<String, dynamic> draftOrderDetails;
  final int currentRound;
  final int currentPick;

  const DraftOrderTableWidget({
    Key? key,
    required this.draftOrder,
    required this.draftOrderDetails,
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
              'ドラフト順位表',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOrderTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('順位')),
          DataColumn(label: Text('チーム名')),
          DataColumn(label: Text('リーグ')),
          DataColumn(label: Text('地区')),
          DataColumn(label: Text('戦力')),
          DataColumn(label: Text('予算')),
          DataColumn(label: Text('状態')),
        ],
        rows: _buildOrderRows(),
      ),
    );
  }

  List<DataRow> _buildOrderRows() {
    final rows = <DataRow>[];
    
    for (int i = 0; i < draftOrder.length; i++) {
      final teamId = draftOrder[i];
      final teamDetails = draftOrderDetails[teamId] as Map<String, dynamic>?;
      
      if (teamDetails != null) {
        final isCurrentPick = _isCurrentPick(i);
        final isCompleted = _isPickCompleted(i);
        
        rows.add(DataRow(
          color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (isCurrentPick) return Colors.blue.withOpacity(0.1);
              if (isCompleted) return Colors.green.withOpacity(0.1);
              return null;
            },
          ),
          cells: [
            DataCell(
              Text(
                '${i + 1}位',
                style: TextStyle(
                  fontWeight: isCurrentPick ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentPick ? Colors.blue : null,
                ),
              ),
            ),
            DataCell(
              Text(
                teamDetails['name'] ?? '不明',
                style: TextStyle(
                  fontWeight: isCurrentPick ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            DataCell(Text(teamDetails['league'] ?? '不明')),
            DataCell(Text(teamDetails['division'] ?? '不明')),
            DataCell(Text(teamDetails['strength'] ?? '不明')),
            DataCell(Text(teamDetails['budget'] ?? '不明')),
            DataCell(
              _buildStatusChip(isCurrentPick, isCompleted),
            ),
          ],
        ));
      }
    }
    
    return rows;
  }

  Widget _buildStatusChip(bool isCurrentPick, bool isCompleted) {
    if (isCurrentPick) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '選択中',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (isCompleted) {
      return Container(
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
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '待機中',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  bool _isCurrentPick(int index) {
    final totalPicksPerRound = draftOrder.length;
    final currentPickIndex = (currentRound - 1) * totalPicksPerRound + currentPick;
    return index == currentPickIndex;
  }

  bool _isPickCompleted(int index) {
    final totalPicksPerRound = draftOrder.length;
    final currentPickIndex = (currentRound - 1) * totalPicksPerRound + currentPick;
    return index < currentPickIndex;
  }
}
