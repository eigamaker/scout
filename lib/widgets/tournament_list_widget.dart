import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game/high_school_tournament.dart';
import '../models/school/school.dart';
import '../services/game_manager.dart';
import 'tournament_bracket_widget.dart';

class TournamentListWidget extends StatefulWidget {
  const TournamentListWidget({super.key});

  @override
  State<TournamentListWidget> createState() => _TournamentListWidgetState();
}

class _TournamentListWidgetState extends State<TournamentListWidget> {
  String? _selectedPrefecture;
  TournamentStage? _selectedStage;
  bool? _selectedProgress; // null: すべて, true: 進行中, false: 終了

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    final game = gameManager.currentGame;
    
    if (game == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('高校野球大会'),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('ゲームが開始されていません'),
        ),
      );
    }
    
    final allTournaments = game.highSchoolTournaments;
    final allSchools = game.schools;
    
    // フィルタリング
    final filteredTournaments = _filterTournaments(allTournaments, allSchools);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('高校野球大会'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterSection(allSchools),
          Expanded(
            child: filteredTournaments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredTournaments.length,
                    itemBuilder: (context, index) {
                      return _buildTournamentCard(context, filteredTournaments[index], allSchools);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(List<School> schools) {
    // 都道府県の一覧を取得（重複を除去してソート）
    final prefectures = schools.map((s) => s.prefecture).toSet().toList()..sort();
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'フィルター',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 都道府県フィルター
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPrefecture,
                  decoration: const InputDecoration(
                    labelText: '都道府県',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('すべて'),
                    ),
                    ...prefectures.map((pref) => DropdownMenuItem(
                      value: pref,
                      child: Text(pref),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPrefecture = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // 大会種別フィルター
              Expanded(
                child: DropdownButtonFormField<TournamentStage>(
                  value: _selectedStage,
                  decoration: const InputDecoration(
                    labelText: '大会種別',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('すべて'),
                    ),
                    const DropdownMenuItem(
                      value: TournamentStage.prefectural,
                      child: Text('県大会'),
                    ),
                    const DropdownMenuItem(
                      value: TournamentStage.national,
                      child: Text('全国大会'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStage = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 進捗状況フィルター
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _selectedProgress,
                  decoration: const InputDecoration(
                    labelText: '進捗状況',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('すべて'),
                    ),
                    const DropdownMenuItem(
                      value: true,
                      child: Text('進行中'),
                    ),
                    const DropdownMenuItem(
                      value: false,
                      child: Text('終了'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProgress = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // フィルターリセットボタン
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedPrefecture = null;
                    _selectedStage = null;
                    _selectedProgress = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('リセット'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<HighSchoolTournament> _filterTournaments(
    List<HighSchoolTournament> tournaments,
    List<School> schools,
  ) {
    return tournaments.where((tournament) {
      // 都道府県フィルター
      if (_selectedPrefecture != null) {
        final hasSchoolInPrefecture = tournament.participatingSchools.any((schoolId) {
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
          return school.prefecture == _selectedPrefecture;
        });
        if (!hasSchoolInPrefecture) return false;
      }

      // 大会種別フィルター
      if (_selectedStage != null && tournament.stage != _selectedStage) {
        return false;
      }

      // 進捗状況フィルター
      if (_selectedProgress != null) {
        if (_selectedProgress! && tournament.isCompleted) return false;
        if (!_selectedProgress! && !tournament.isCompleted) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_baseball,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '条件に合う大会がありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'フィルター条件を変更してください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, HighSchoolTournament tournament, List<School> schools) {
    final tournamentName = _getTournamentName(tournament.type);
    final stageName = _getStageName(tournament.stage);
    final progress = _getProgressText(tournament);
    final statusColor = _getStatusColor(tournament);
    final statusText = _getStatusText(tournament);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      child: InkWell(
        onTap: () => _showTournamentBracket(context, tournament, schools),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 大会名と段階
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tournamentName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stageName,
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 進捗情報
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progress,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 参加校数と優勝校
              Row(
                children: [
                  Text(
                    '参加校: ${tournament.participatingSchools.length}校',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (tournament.championSchoolName != null)
                    Text(
                      '優勝: ${tournament.championSchoolName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              
              // 現在の段階
              if (!tournament.isCompleted && tournament.currentRound != null)
                Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '現在: ${_getRoundName(tournament.currentRound!)}',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTournamentBracket(BuildContext context, HighSchoolTournament tournament, List<School> schools) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentBracketWidget(
          tournament: tournament,
          schools: schools,
        ),
      ),
    );
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

  String _getStageName(TournamentStage stage) {
    switch (stage) {
      case TournamentStage.prefectural:
        return '県大会';
      case TournamentStage.national:
        return '全国大会';
    }
  }

  String _getProgressText(HighSchoolTournament tournament) {
    if (tournament.isCompleted) {
      return '大会終了';
    }
    
    final totalGames = tournament.games.length;
    final completedGames = tournament.completedGames.length;
    final percentage = (completedGames / totalGames * 100).round();
    
    return '$percentage%完了 ($completedGames/$totalGames試合)';
  }

  Color _getStatusColor(HighSchoolTournament tournament) {
    if (tournament.isCompleted) {
      return Colors.grey;
    }
    
    final progress = tournament.completedGames.length / tournament.games.length;
    if (progress < 0.3) {
      return Colors.blue;
    } else if (progress < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText(HighSchoolTournament tournament) {
    if (tournament.isCompleted) {
      return '終了';
    }
    
    final progress = tournament.completedGames.length / tournament.games.length;
    if (progress < 0.3) {
      return '序盤';
    } else if (progress < 0.7) {
      return '中盤';
    } else {
      return '終盤';
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
}
