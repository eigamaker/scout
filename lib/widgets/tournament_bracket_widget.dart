import 'package:flutter/material.dart';
import '../models/game/high_school_tournament.dart';
import '../models/school/school.dart';

class TournamentBracketWidget extends StatelessWidget {
  final HighSchoolTournament tournament;
  final List<School> schools;

  const TournamentBracketWidget({
    super.key,
    required this.tournament,
    required this.schools,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getTournamentName(tournament.type)}トーナメント表'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildTournamentInfo(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildTournamentBracket(),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentInfo() {
    final tournamentName = _getTournamentName(tournament.type);
    final progress = tournament.isCompleted 
        ? '大会終了' 
        : '${tournament.completedGames.length}/${tournament.games.length}試合完了';
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tournamentName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text('進捗: $progress'),
            if (tournament.championSchoolName != null)
              Text('優勝: ${tournament.championSchoolName}'),
            if (tournament.runnerUpSchoolName != null)
              Text('準優勝: ${tournament.runnerUpSchoolName}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentBracket() {
    final rounds = [
      GameRound.firstRound,
      GameRound.secondRound,
      GameRound.thirdRound,
      GameRound.quarterFinal,
      GameRound.semiFinal,
      GameRound.championship,
    ];

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rounds.asMap().entries.map((entry) {
            final index = entry.key;
            final round = entry.value;
            final isLastRound = index == rounds.length - 1;
            
            return Row(
              children: [
                SizedBox(
                  width: 160,
                  child: _buildRoundColumn(round),
                ),
                // 最後のラウンド以外は接続線を表示
                if (!isLastRound)
                  SizedBox(
                    width: 40,
                    child: _buildConnectionLines(round),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// ラウンド間の接続線を表示
  Widget _buildConnectionLines(GameRound round) {
    final nextRound = _getNextRound(round);
    if (nextRound == null) return const SizedBox.shrink();
    
    final currentGames = _getRoundGames(round);
    final nextGames = _getRoundGames(nextRound);
    // 推定の縦サイズ（各カード約64px間隔）を与えて無限高さを回避
    final estimatedHeight = (currentGames.length > nextGames.length
            ? currentGames.length
            : nextGames.length) * 64.0;
    final finiteHeight = estimatedHeight > 0 ? estimatedHeight : 64.0;

    return SizedBox(
      height: finiteHeight,
      child: CustomPaint(
        size: Size(40, finiteHeight),
        painter: TournamentConnectionPainter(
          currentGameCount: currentGames.length,
          nextGameCount: nextGames.length,
        ),
      ),
    );
  }

  /// 次のラウンドを取得
  GameRound? _getNextRound(GameRound round) {
    final rounds = [
      GameRound.firstRound,
      GameRound.secondRound,
      GameRound.thirdRound,
      GameRound.quarterFinal,
      GameRound.semiFinal,
      GameRound.championship,
    ];
    
    final currentIndex = rounds.indexOf(round);
    if (currentIndex < rounds.length - 1) {
      return rounds[currentIndex + 1];
    }
    return null;
  }

  Widget _buildRoundColumn(GameRound round) {
    final roundGames = _getRoundGames(round);
    final roundName = _getRoundName(round);
    
    return Column(
      children: [
        // 段階名
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.red[100],
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Text(
            roundName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 試合
        ...roundGames.map((game) => _buildGameTile(game)),
      ],
    );
  }

  /// 各ラウンドの試合を取得（勝ち上がり構造に基づいて）
  List<TournamentGame?> _getRoundGames(GameRound round) {
    switch (round) {
      case GameRound.firstRound:
        // 1回戦は参加校数に基づいて試合数を決定
        final firstRoundGames = tournament.games
            .where((game) => game.round == GameRound.firstRound)
            .toList();
        return firstRoundGames;
        
      case GameRound.secondRound:
        // 2回戦は1回戦の勝者数に基づいて試合数を決定
        final firstRoundWinners = _getWinnersFromRound(GameRound.firstRound);
        final secondRoundGames = tournament.games
            .where((game) => game.round == GameRound.secondRound)
            .toList();
        
        // 2回戦の試合数が不足している場合は空のカードを追加
        final neededGames = (firstRoundWinners.length / 2).ceil();
        return _fillRoundGames(secondRoundGames, neededGames);
        
      case GameRound.thirdRound:
        // 3回戦は2回戦の勝者数に基づいて試合数を決定
        final secondRoundWinners = _getWinnersFromRound(GameRound.secondRound);
        final thirdRoundGames = tournament.games
            .where((game) => game.round == GameRound.thirdRound)
            .toList();
        
        final neededGames = (secondRoundWinners.length / 2).ceil();
        return _fillRoundGames(thirdRoundGames, neededGames);
        
      case GameRound.quarterFinal:
        // 準々決勝は3回戦の勝者数に基づいて試合数を決定
        final thirdRoundWinners = _getWinnersFromRound(GameRound.thirdRound);
        final quarterFinalGames = tournament.games
            .where((game) => game.round == GameRound.quarterFinal)
            .toList();
        
        final neededGames = (thirdRoundWinners.length / 2).ceil();
        return _fillRoundGames(quarterFinalGames, neededGames);
        
      case GameRound.semiFinal:
        // 準決勝は準々決勝の勝者数に基づいて試合数を決定
        final quarterFinalWinners = _getWinnersFromRound(GameRound.quarterFinal);
        final semiFinalGames = tournament.games
            .where((game) => game.round == GameRound.semiFinal)
            .toList();
        
        final neededGames = (quarterFinalWinners.length / 2).ceil();
        return _fillRoundGames(semiFinalGames, neededGames);
        
      case GameRound.championship:
        // 決勝は準決勝の勝者数に基づいて試合数を決定
        final semiFinalWinners = _getWinnersFromRound(GameRound.semiFinal);
        final championshipGames = tournament.games
            .where((game) => game.round == GameRound.championship)
            .toList();
        
        final neededGames = (semiFinalWinners.length / 2).ceil();
        return _fillRoundGames(championshipGames, neededGames);
    }
  }

  /// 指定ラウンドの勝者を取得
  List<String> _getWinnersFromRound(GameRound round) {
    final roundGames = tournament.games.where((game) => game.round == round).toList();
    final winners = <String>[];
    
    for (final game in roundGames) {
      if (game.isCompleted && game.result != null) {
        final winnerId = game.winnerSchoolId;
        if (winnerId != null) {
          winners.add(winnerId);
        }
      }
    }
    
    return winners;
  }

  /// ラウンドの試合数を必要な数に合わせて調整（不足分は空のカードで埋める）
  List<TournamentGame?> _fillRoundGames(List<TournamentGame> games, int neededGames) {
    final result = <TournamentGame?>[];
    
    // 既存の試合を追加
    for (final game in games) {
      result.add(game);
    }
    
    // 不足分を空のカードで埋める
    while (result.length < neededGames) {
      result.add(null);
    }
    
    return result;
  }

  Widget _buildGameTile(TournamentGame? game) {
    if (game == null) {
      // 決まっていない対戦はブランクのカードを表示
      return Container(
        margin: const EdgeInsets.only(bottom: 4.0),
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[50],
        ),
      );
    }

    final homeSchool = _getSchoolName(game.homeSchoolId);
    final awaySchool = _getSchoolName(game.awaySchoolId);
    final isCompleted = game.isCompleted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCompleted ? Colors.green : Colors.grey[300]!,
          width: isCompleted ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isCompleted ? Colors.green[50] : Colors.grey[50],
      ),
      child: Column(
        children: [
          // ホームチーム
          Row(
            children: [
              Expanded(
                child: Text(
                  homeSchool,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCompleted && game.result != null)
                Text(
                  '${game.result!.homeScore}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          // vs
          const Text(
            'vs',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          // アウェイチーム
          Row(
            children: [
              Expanded(
                child: Text(
                  awaySchool,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCompleted && game.result != null)
                Text(
                  '${game.result!.awayScore}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSchoolName(String schoolId) {
    final school = schools.firstWhere(
      (s) => s.id == schoolId,
      orElse: () => School(
        id: schoolId,
        name: '不明',
        shortName: '不明',
        location: '不明',
        prefecture: '不明',
        rank: SchoolRank.weak,
        players: [],
        coachTrust: 50,
        coachName: '不明',
      ),
    );
    return school.shortName;
  }

  String _getRoundName(GameRound round) {
    switch (round) {
      case GameRound.firstRound:
        return '1回戦';
      case GameRound.secondRound:
        return '2回戦';
      case GameRound.thirdRound:
        return '3回戦';
      case GameRound.quarterFinal:
        return '準々決勝';
      case GameRound.semiFinal:
        return '準決勝';
      case GameRound.championship:
        return '決勝';
    }
  }

  String _getTournamentName(TournamentType type) {
    switch (type) {
      case TournamentType.spring:
        return '春の大会';
      case TournamentType.summer:
        return '夏の大会';
      case TournamentType.autumn:
        return '秋の大会';
      case TournamentType.springNational:
        return '春の全国大会';
    }
  }
}

/// トーナメントの接続線を描画するカスタムペインター
class TournamentConnectionPainter extends CustomPainter {
  final int currentGameCount;
  final int nextGameCount;

  TournamentConnectionPainter({
    required this.currentGameCount,
    required this.nextGameCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 各試合から次のラウンドへの接続線を描画
    for (int i = 0; i < currentGameCount; i++) {
      final startY = (i * 64.0) + 32.0; // 試合カードの中心位置
      final endY = _calculateNextRoundPosition(i, currentGameCount, nextGameCount);
      
      // 水平線
      canvas.drawLine(
        Offset(0, startY),
        Offset(size.width * 0.5, startY),
        paint,
      );
      
      // 垂直線
      canvas.drawLine(
        Offset(size.width * 0.5, startY),
        Offset(size.width * 0.5, endY),
        paint,
      );
      
      // 次のラウンドへの水平線
      canvas.drawLine(
        Offset(size.width * 0.5, endY),
        Offset(size.width, endY),
        paint,
      );
    }
  }

  /// 次のラウンドでの位置を計算
  double _calculateNextRoundPosition(int currentIndex, int currentCount, int nextCount) {
    if (nextCount == 0) return 0;
    if (currentCount <= 1) {
      // 単一カードのときは中央へ
      return 32.0;
    }
    // 現在の位置を次のラウンドの範囲にマッピング
    final ratio = currentIndex / (currentCount - 1);
    return ratio * ((nextCount - 1) * 64.0) + 32.0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
