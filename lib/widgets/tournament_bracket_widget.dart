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
            if (tournament.championSchoolName != null || tournament.runnerUpSchoolName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (tournament.championSchoolName != null)
                    Text('優勝: ${tournament.championSchoolName}'),
                  if (tournament.championSchoolName != null && tournament.runnerUpSchoolName != null)
                    const SizedBox(width: 16),
                  if (tournament.runnerUpSchoolName != null)
                    Text('準優勝: ${tournament.runnerUpSchoolName}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 大会種別に応じたラウンドを取得
  List<GameRound> _getRoundsForTournament() {
    if (tournament.stage == TournamentStage.national) {
      // 全国大会は6ラウンド
      return [
        GameRound.firstRound,
        GameRound.secondRound,
        GameRound.thirdRound,
        GameRound.quarterFinal,
        GameRound.semiFinal,
        GameRound.championship,
      ];
    } else {
      // 県大会は5ラウンド
      return [
        GameRound.firstRound,
        GameRound.secondRound,
        GameRound.quarterFinal,
        GameRound.semiFinal,
        GameRound.championship,
      ];
    }
  }

  Widget _buildTournamentBracket() {
    final rounds = _getRoundsForTournament();

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rounds.map((round) {
            
            return SizedBox(
              width: 160,
              child: _buildRoundColumn(round),
            );
          }).toList(),
        ),
      ),
    );
  }




  Widget _buildRoundColumn(GameRound round) {
    final roundGames = _getRoundGames(round);
    final roundName = _getRoundName(round);
    
    // 前のラウンドが完了しているかチェック
    final isRoundAvailable = _isRoundAvailable(round);
    
    return Column(
      children: [
        // 段階名
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          decoration: BoxDecoration(
            color: isRoundAvailable ? Colors.red[100] : Colors.grey[200],
            border: Border.all(color: isRoundAvailable ? Colors.red[300]! : Colors.grey[400]!),
          ),
          child: Text(
            roundName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRoundAvailable ? Colors.red : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 試合
        if (isRoundAvailable)
          ...roundGames.map((game) => _buildGameTile(game))
        else
          _buildUndecidedCard(),
      ],
    );
  }

  /// ラウンドが利用可能かチェック（前のラウンドが完了しているか）
  bool _isRoundAvailable(GameRound round) {
    final rounds = _getRoundsForTournament();
    final currentIndex = rounds.indexOf(round);
    
    // 1回戦は常に利用可能
    if (currentIndex == 0) return true;
    
    // 前のラウンドが完了しているかチェック
    final previousRound = rounds[currentIndex - 1];
    final previousRoundGames = tournament.games.where((game) => game.round == previousRound).toList();
    final completedPreviousGames = previousRoundGames.where((game) => game.isCompleted).toList();
    
    return completedPreviousGames.length == previousRoundGames.length;
  }
  
  /// 未定カードを表示
  Widget _buildUndecidedCard() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          '未定',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// ホームスコアを取得（型安全）
  int _getHomeScore(dynamic result) {
    if (result is GameResult) {
      return result.homeScore;
    } else if (result is TournamentGameResult) {
      return result.homeScore;
    }
    return 0;
  }

  /// アウェイスコアを取得（型安全）
  int _getAwayScore(dynamic result) {
    if (result is GameResult) {
      return result.awayScore;
    } else if (result is TournamentGameResult) {
      return result.awayScore;
    }
    return 0;
  }

  /// 各ラウンドの試合を取得（シンプルな実装）
  List<TournamentGame?> _getRoundGames(GameRound round) {
    // 指定されたラウンドの試合を取得
    final roundGames = tournament.games
        .where((game) => game.round == round)
        .toList();

    // ゲームをID順にソート
    roundGames.sort((a, b) => a.id.compareTo(b.id));

    return roundGames;
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

    // 対戦相手が決まっていない場合はブランク表示
    if (game.awaySchoolId == null || game.awaySchoolId.isEmpty) {
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
    
    // 1回戦でのシード判定：対戦相手が「未定」の場合はシード校
    final isSeed = game.round == GameRound.firstRound && game.awaySchoolId == '未定';
    
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
          if (isSeed) ...[
            // シードの場合：1チームのみ表示
            Row(
              children: [
                Expanded(
                  child: Text(
                    homeSchool,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'シード',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 通常の対戦：2チーム表示
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
                    '${_getHomeScore(game.result)}',
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
                    '${_getAwayScore(game.result)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }



  String _getSchoolName(String schoolId) {
    // 無効なIDの場合は空文字を返す
    if (schoolId.isEmpty) return '';
    
    try {
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
        ),
      );
      return school.shortName;
    } catch (e) {
      // エラーが発生した場合は空文字を返す
      return '';
    }
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


