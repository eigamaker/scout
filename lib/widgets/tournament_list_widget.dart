import 'package:flutter/material.dart';
import '../models/game/high_school_tournament.dart';
import '../models/school/school.dart';
import 'tournament_bracket_widget.dart';

class TournamentListWidget extends StatefulWidget {
  final List<HighSchoolTournament> tournaments;
  final List<School> schools;

  const TournamentListWidget({
    Key? key,
    required this.tournaments,
    required this.schools,
  }) : super(key: key);

  @override
  State<TournamentListWidget> createState() => _TournamentListWidgetState();
}

class _TournamentListWidgetState extends State<TournamentListWidget> {
  String? _selectedPrefecture;
  String? _selectedYear;
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final activeTournaments = _getActiveTournaments();
    final filteredTournaments = _filterTournaments(activeTournaments);

    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: filteredTournaments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: filteredTournaments.length,
                  itemBuilder: (context, index) {
                    return _buildTournamentCard(filteredTournaments[index]);
                  },
                ),
        ),
      ],
    );
  }

  List<HighSchoolTournament> _getActiveTournaments() {
    if (_showArchived) {
      return widget.tournaments;
    } else {
      // 最新の大会のみを表示（完了済みの大会は除外）
      // ゲーム内の最新年を取得
      final latestYear = widget.tournaments.isNotEmpty 
          ? widget.tournaments.map((t) => t.year).reduce((a, b) => a > b ? a : b)
          : DateTime.now().year;
      return widget.tournaments
          .where((t) => t.year == latestYear && !t.isCompleted)
          .toList();
    }
  }

  List<HighSchoolTournament> _filterTournaments(List<HighSchoolTournament> tournaments) {
    return tournaments.where((tournament) {
      // 都道府県フィルター
      if (_selectedPrefecture != null && _selectedPrefecture != '全国') {
        if (tournament.stage == TournamentStage.national) return false;
        // 県大会の場合、IDから都道府県を抽出
        final tournamentPrefecture = _extractPrefectureFromId(tournament.id);
        if (tournamentPrefecture != _selectedPrefecture) return false;
      }
      
      // 年フィルター
      if (_selectedYear != null) {
        if (tournament.year.toString() != _selectedYear) return false;
      }
      
      return true;
    }).toList();
  }

  String? _extractPrefectureFromId(String tournamentId) {
    // 県大会のID形式: "spring_都道府県名_年_月_週"
    final parts = tournamentId.split('_');
    if (parts.length >= 3 && parts[1] != '全国') {
      return parts[1];
    }
    return null;
  }

  Widget _buildFilterSection() {
    final prefectures = ['全国', ...widget.schools.map((s) => s.prefecture).toSet().toList()..sort()];
    // 年フィルターは大会に含まれる年のみを表示
    final years = widget.tournaments.isNotEmpty 
        ? (widget.tournaments.map((t) => t.year.toString()).toSet().toList()..sort())
        : <String>[];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPrefecture,
              decoration: const InputDecoration(
                labelText: '都道府県',
                border: OutlineInputBorder(),
              ),
              items: prefectures.map((prefecture) {
                return DropdownMenuItem(
                  value: prefecture,
                  child: Text(prefecture),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPrefecture = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedYear,
              decoration: const InputDecoration(
                labelText: '年',
                border: OutlineInputBorder(),
              ),
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedYear = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
            icon: Icon(_showArchived ? Icons.archive : Icons.unarchive),
            tooltip: _showArchived ? '最新の大会を表示' : '過去の大会を表示',
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(HighSchoolTournament tournament) {
    final prefecture = _getPrefectureName(tournament);
    final tournamentName = _getTournamentName(tournament);
    final currentRound = _getCurrentRound(tournament);
    final championInfo = _getChampionInfo(tournament);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentBracketWidget(
                tournament: tournament,
                schools: widget.schools,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prefecture,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    tournamentName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '現在：$currentRound',
                style: const TextStyle(fontSize: 14),
              ),
              if (championInfo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  championInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getPrefectureName(HighSchoolTournament tournament) {
    if (tournament.stage == TournamentStage.national) {
      return '全国大会';
    } else {
      // 県大会の場合、IDから都道府県を抽出
      final prefecture = _extractPrefectureFromId(tournament.id);
      return prefecture ?? '不明';
    }
  }

  String _getTournamentName(HighSchoolTournament tournament) {
    final year = tournament.year;
    switch (tournament.type) {
      case TournamentType.spring:
        return '$year年春の大会';
      case TournamentType.summer:
        return '$year年夏の大会';
      case TournamentType.autumn:
        return '$year年秋の大会';
      case TournamentType.springNational:
        return '$year年春の全国大会';
      default:
        return '$year年大会';
    }
  }

  String _getCurrentRound(HighSchoolTournament tournament) {
    if (tournament.isCompleted) {
      return '大会終了';
    }

    final totalGames = tournament.games.length;
    final completedGames = tournament.completedGames.length;
    
    if (completedGames == 0) return '1回戦';
    if (completedGames < totalGames * 0.25) return '1回戦';
    if (completedGames < totalGames * 0.5) return '2回戦';
    if (completedGames < totalGames * 0.75) return '準々決勝';
    if (completedGames < totalGames) return '準決勝';
    return '決勝';
  }

  String _getChampionInfo(HighSchoolTournament tournament) {
    if (tournament.isCompleted && tournament.championSchoolId != null) {
      final championSchool = widget.schools.firstWhere(
        (s) => s.id == tournament.championSchoolId,
        orElse: () => School(
          id: 'unknown', 
          name: '不明', 
          shortName: '不明',
          location: '不明',
          prefecture: '不明', 
          rank: SchoolRank.weak, 
          players: [],
          coachTrust: 50,
          coachName: '不明'
        ),
      );
      return '優勝校：${championSchool.name}';
    }
    return '';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_baseball,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showArchived ? '過去の大会はありません' : '現在開催中の大会はありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
