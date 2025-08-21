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
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rounds.map((round) {
          return SizedBox(
            width: 160, // 幅を小さく
            child: _buildRoundColumn(round),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoundColumn(GameRound round) {
    final roundGames = tournament.games.where((game) => game.round == round).toList();
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

  Widget _buildGameTile(TournamentGame game) {
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
