// ドラフト関連のデータモデル
import 'dart:math';
import 'player.dart';
import 'team.dart';

// ドラフト指名クラス
class DraftPick {
  final int year;
  final int round;
  final Team team;
  final Player player;
  final String? notes; // 球団のコメントなど

  DraftPick({
    required this.year,
    required this.round,
    required this.team,
    required this.player,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'round': round,
    'team': team.name,
    'player': player.name,
    'notes': notes,
  };

  factory DraftPick.fromJson(Map<String, dynamic> json, Team team, Player player) => DraftPick(
    year: json['year'],
    round: json['round'],
    team: team,
    player: player,
    notes: json['notes'],
  );
}

// ドラフト会議クラス
class DraftMeeting {
  final int year;
  final List<DraftPick> picks;
  final List<Player> eligiblePlayers; // ドラフト対象選手

  DraftMeeting({
    required this.year,
    required this.picks,
    required this.eligiblePlayers,
  });

  // ドラフト会議を実行
  static DraftMeeting executeDraft(int year, List<Player> eligiblePlayers, List<Team> teams) {
    final picks = <DraftPick>[];
    final random = Random();
    
    // 高校生を優先的に指名（現実のドラフトに近い）
    final highSchoolPlayers = eligiblePlayers.where((p) => p.isHighSchoolStudent).toList();
    final otherPlayers = eligiblePlayers.where((p) => !p.isHighSchoolStudent).toList();
    
    // 高校生を先に指名
    for (int round = 1; round <= 3; round++) {
      for (int i = 0; i < teams.length && i < highSchoolPlayers.length; i++) {
        final team = teams[i];
        final player = highSchoolPlayers[i];
        
        picks.add(DraftPick(
          year: year,
          round: round,
          team: team,
          player: player,
          notes: '${round}巡目指名',
        ));
      }
    }
    
    // 大学生・社会人を指名
    for (int round = 4; round <= 6; round++) {
      for (int i = 0; i < teams.length && i < otherPlayers.length; i++) {
        final team = teams[i];
        final player = otherPlayers[i];
        
        picks.add(DraftPick(
          year: year,
          round: round,
          team: team,
          player: player,
          notes: '${round}巡目指名',
        ));
      }
    }
    
    return DraftMeeting(
      year: year,
      picks: picks,
      eligiblePlayers: eligiblePlayers,
    );
  }

  Map<String, dynamic> toJson() => {
    'year': year,
    'picks': picks.map((p) => p.toJson()).toList(),
    'eligiblePlayers': eligiblePlayers.map((p) => p.name).toList(),
  };

  factory DraftMeeting.fromJson(Map<String, dynamic> json, List<Team> teams, List<Player> allPlayers) {
    final picks = <DraftPick>[];
    for (final pickJson in json['picks']) {
      final teamName = pickJson['team'];
      final playerName = pickJson['player'];
      
      final team = teams.firstWhere((t) => t.name == teamName);
      final player = allPlayers.firstWhere((p) => p.name == playerName);
      
      picks.add(DraftPick.fromJson(pickJson, team, player));
    }
    
    final eligiblePlayerNames = List<String>.from(json['eligiblePlayers']);
    final eligiblePlayers = allPlayers.where((p) => eligiblePlayerNames.contains(p.name)).toList();
    
    return DraftMeeting(
      year: json['year'],
      picks: picks,
      eligiblePlayers: eligiblePlayers,
    );
  }
} 