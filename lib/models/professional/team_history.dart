import 'package:flutter/foundation.dart';

// 球団履歴クラス
class TeamHistory {
  final int? id;
  final String teamId; // ProfessionalTeamテーブルのID
  final int year; // 年度
  final String league; // リーグ（'central' or 'pacific'）
  final String division; // 地区（'east', 'west', 'central'）
  final int games; // 試合数
  final int wins; // 勝利数
  final int losses; // 敗戦数
  final int ties; // 引き分け数
  final double winningPercentage; // 勝率
  final double gamesBehind; // ゲーム差
  final int rank; // 順位
  final int runsScored; // 得点数
  final int runsAllowed; // 失点数
  final int runDifferential; // 得失点差
  final int homeWins; // ホーム勝利数
  final int homeLosses; // ホーム敗戦数
  final int awayWins; // アウェイ勝利数
  final int awayLosses; // アウェイ敗戦数
  final DateTime createdAt;
  final DateTime updatedAt;

  // 関連データ
  final String? teamName;
  final String? teamShortName;

  TeamHistory({
    this.id,
    required this.teamId,
    required this.year,
    required this.league,
    required this.division,
    required this.games,
    required this.wins,
    required this.losses,
    this.ties = 0,
    required this.winningPercentage,
    this.gamesBehind = 0.0,
    required this.rank,
    this.runsScored = 0,
    this.runsAllowed = 0,
    this.runDifferential = 0,
    this.homeWins = 0,
    this.homeLosses = 0,
    this.awayWins = 0,
    this.awayLosses = 0,
    required this.createdAt,
    required this.updatedAt,
    this.teamName,
    this.teamShortName,
  });

  // リーグの文字列表現
  String get leagueText {
    switch (league) {
      case 'central':
        return 'セ・リーグ';
      case 'pacific':
        return 'パ・リーグ';
      default:
        return league;
    }
  }

  // 地区の文字列表現
  String get divisionText {
    switch (division) {
      case 'east':
        return '東地区';
      case 'west':
        return '西地区';
      case 'central':
        return '中地区';
      default:
        return division;
    }
  }

  // 勝率の計算
  double get calculatedWinningPercentage {
    if (games == 0) return 0.0;
    return wins / games;
  }

  // 得失点差の計算
  int get calculatedRunDifferential {
    return runsScored - runsAllowed;
  }

  // ホーム勝率
  double get homeWinningPercentage {
    final homeGames = homeWins + homeLosses;
    if (homeGames == 0) return 0.0;
    return homeWins / homeGames;
  }

  // アウェイ勝率
  double get awayWinningPercentage {
    final awayGames = awayWins + awayLosses;
    if (awayGames == 0) return 0.0;
    return awayWins / awayGames;
  }

  // 順位の文字列表現
  String get rankText {
    if (rank == 1) return '1位';
    if (rank == 2) return '2位';
    if (rank == 3) return '3位';
    if (rank == 4) return '4位';
    if (rank == 5) return '5位';
    if (rank == 6) return '6位';
    return '${rank}位';
  }

  // 成績の評価
  String get performanceEvaluation {
    if (winningPercentage >= 0.600) return '優秀';
    if (winningPercentage >= 0.500) return '良好';
    if (winningPercentage >= 0.400) return '普通';
    if (winningPercentage >= 0.300) return '不振';
    return '低迷';
  }

  // 得失点差の評価
  String get runDifferentialEvaluation {
    if (runDifferential >= 100) return '圧倒的';
    if (runDifferential >= 50) return '優秀';
    if (runDifferential >= 0) return '良好';
    if (runDifferential >= -50) return '普通';
    return '不振';
  }

  // ホーム・アウェイの成績評価
  String get homeAwayEvaluation {
    final homeDiff = homeWinningPercentage - awayWinningPercentage;
    if (homeDiff >= 0.200) return 'ホーム強し';
    if (homeDiff >= 0.100) return 'ホーム有利';
    if (homeDiff >= -0.100) return 'バランス型';
    if (homeDiff >= -0.200) return 'アウェイ有利';
    return 'アウェイ強し';
  }

  // シーズン結果の要約
  String get seasonSummary {
    final performance = performanceEvaluation;
    final rank = rankText;
    final winLoss = '$wins勝$losses敗';
    final winRate = '${(winningPercentage * 100).toStringAsFixed(1)}%';
    
    return '$performance - $rank ($winLoss $winRate)';
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'team_id': teamId,
    'year': year,
    'league': league,
    'division': division,
    'games': games,
    'wins': wins,
    'losses': losses,
    'ties': ties,
    'winning_percentage': winningPercentage,
    'games_behind': gamesBehind,
    'rank': rank,
    'runs_scored': runsScored,
    'runs_allowed': runsAllowed,
    'run_differential': runDifferential,
    'home_wins': homeWins,
    'home_losses': homeLosses,
    'away_wins': awayWins,
    'away_losses': awayLosses,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory TeamHistory.fromJson(Map<String, dynamic> json) {
    return TeamHistory(
      id: json['id'] as int?,
      teamId: json['team_id'] as String,
      year: json['year'] as int,
      league: json['league'] as String,
      division: json['division'] as String,
      games: json['games'] as int,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      ties: json['ties'] as int? ?? 0,
      winningPercentage: (json['winning_percentage'] as num).toDouble(),
      gamesBehind: (json['games_behind'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int,
      runsScored: json['runs_scored'] as int? ?? 0,
      runsAllowed: json['runs_allowed'] as int? ?? 0,
      runDifferential: json['run_differential'] as int? ?? 0,
      homeWins: json['home_wins'] as int? ?? 0,
      homeLosses: json['home_losses'] as int? ?? 0,
      awayWins: json['away_wins'] as int? ?? 0,
      awayLosses: json['away_losses'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // コピーメソッド
  TeamHistory copyWith({
    int? id,
    String? teamId,
    int? year,
    String? league,
    String? division,
    int? games,
    int? wins,
    int? losses,
    int? ties,
    double? winningPercentage,
    double? gamesBehind,
    int? rank,
    int? runsScored,
    int? runsAllowed,
    int? runDifferential,
    int? homeWins,
    int? homeLosses,
    int? awayWins,
    int? awayLosses,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? teamName,
    String? teamShortName,
  }) {
    return TeamHistory(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      year: year ?? this.year,
      league: league ?? this.league,
      division: division ?? this.division,
      games: games ?? this.games,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      ties: ties ?? this.ties,
      winningPercentage: winningPercentage ?? this.winningPercentage,
      gamesBehind: gamesBehind ?? this.gamesBehind,
      rank: rank ?? this.rank,
      runsScored: runsScored ?? this.runsScored,
      runsAllowed: runsAllowed ?? this.runsAllowed,
      runDifferential: runDifferential ?? this.runDifferential,
      homeWins: homeWins ?? this.homeWins,
      homeLosses: homeLosses ?? this.homeLosses,
      awayWins: awayWins ?? this.awayWins,
      awayLosses: awayLosses ?? this.awayLosses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      teamName: teamName ?? this.teamName,
      teamShortName: teamShortName ?? this.teamShortName,
    );
  }

  // 成績を更新
  TeamHistory updateStats({
    int? games,
    int? wins,
    int? losses,
    int? ties,
    int? runsScored,
    int? runsAllowed,
    int? homeWins,
    int? homeLosses,
    int? awayWins,
    int? awayLosses,
  }) {
    return copyWith(
      games: games ?? this.games,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      ties: ties ?? this.ties,
      runsScored: runsScored ?? this.runsScored,
      runsAllowed: runsAllowed ?? this.runsAllowed,
      homeWins: homeWins ?? this.homeWins,
      homeLosses: homeLosses ?? this.homeLosses,
      awayWins: awayWins ?? this.awayWins,
      awayLosses: awayLosses ?? this.awayLosses,
      updatedAt: DateTime.now(),
    );
  }
}

// 球団履歴管理クラス
class TeamHistoryManager {
  final List<TeamHistory> histories;
  
  TeamHistoryManager({List<TeamHistory>? histories}) : histories = histories ?? [];

  // 全履歴を取得
  List<TeamHistory> getAllHistories() => histories;

  // 特定の球団の履歴を取得
  List<TeamHistory> getHistoriesByTeam(String teamId) {
    return histories.where((history) => history.teamId == teamId).toList();
  }

  // 特定の年度の履歴を取得
  List<TeamHistory> getHistoriesByYear(int year) {
    return histories.where((history) => history.year == year).toList();
  }

  // 特定のリーグの履歴を取得
  List<TeamHistory> getHistoriesByLeague(String league) {
    return histories.where((history) => history.league == league).toList();
  }

  // 特定の地区の履歴を取得
  List<TeamHistory> getHistoriesByDivision(String division) {
    return histories.where((history) => history.division == division).toList();
  }

  // 球団の年度別履歴を取得（昇順）
  List<TeamHistory> getTeamYearlyHistories(String teamId) {
    final teamHistories = getHistoriesByTeam(teamId);
    teamHistories.sort((a, b) => a.year.compareTo(b.year));
    return teamHistories;
  }

  // 球団の最新履歴を取得
  TeamHistory? getTeamLatestHistory(String teamId) {
    final teamHistories = getHistoriesByTeam(teamId);
    if (teamHistories.isEmpty) return null;
    
    teamHistories.sort((a, b) => b.year.compareTo(a.year));
    return teamHistories.first;
  }

  // 特定年度のリーグ順位を取得
  List<TeamHistory> getLeagueStandings(int year, String league) {
    final leagueHistories = histories
        .where((history) => history.year == year && history.league == league)
        .toList();
    
    leagueHistories.sort((a, b) => a.rank.compareTo(b.rank));
    return leagueHistories;
  }

  // 特定年度の地区順位を取得
  List<TeamHistory> getDivisionStandings(int year, String league, String division) {
    final divisionHistories = histories
        .where((history) => 
            history.year == year && 
            history.league == league && 
            history.division == division)
        .toList();
    
    divisionHistories.sort((a, b) => a.rank.compareTo(b.rank));
    return divisionHistories;
  }

  // 球団の連続優勝年数を取得
  int getTeamConsecutiveChampionships(String teamId) {
    final teamHistories = getTeamYearlyHistories(teamId);
    int consecutive = 0;
    
    for (final history in teamHistories.reversed) {
      if (history.rank == 1) {
        consecutive++;
      } else {
        break;
      }
    }
    
    return consecutive;
  }

  // 球団の最長連続優勝記録を取得
  int getTeamLongestChampionshipStreak(String teamId) {
    final teamHistories = getTeamYearlyHistories(teamId);
    int currentStreak = 0;
    int longestStreak = 0;
    
    for (final history in teamHistories) {
      if (history.rank == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }
    
    return longestStreak;
  }

  // 球団の通算成績を計算
  Map<String, dynamic> getTeamCareerStats(String teamId) {
    final teamHistories = getHistoriesByTeam(teamId);
    if (teamHistories.isEmpty) {
      return {
        'totalGames': 0,
        'totalWins': 0,
        'totalLosses': 0,
        'totalTies': 0,
        'careerWinningPercentage': 0.0,
        'championships': 0,
        'bestRank': 0,
        'worstRank': 0,
      };
    }

    int totalGames = 0;
    int totalWins = 0;
    int totalLosses = 0;
    int totalTies = 0;
    int championships = 0;
    int bestRank = 6;
    int worstRank = 1;

    for (final history in teamHistories) {
      totalGames += history.games;
      totalWins += history.wins;
      totalLosses += history.losses;
      totalTies += history.ties;
      
      if (history.rank == 1) championships++;
      
      if (history.rank < bestRank) bestRank = history.rank;
      if (history.rank > worstRank) worstRank = history.rank;
    }

    final careerWinningPercentage = totalGames > 0 ? totalWins / totalGames : 0.0;

    return {
      'totalGames': totalGames,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      'totalTies': totalTies,
      'careerWinningPercentage': careerWinningPercentage,
      'championships': championships,
      'bestRank': bestRank,
      'worstRank': worstRank,
    };
  }

  // 履歴を追加
  void addHistory(TeamHistory history) {
    histories.add(history);
  }

  // 履歴を更新
  void updateHistory(TeamHistory updatedHistory) {
    final index = histories.indexWhere((history) => history.id == updatedHistory.id);
    if (index != -1) {
      histories[index] = updatedHistory;
    }
  }

  // 履歴を削除
  void removeHistory(int historyId) {
    histories.removeWhere((history) => history.id == historyId);
  }

  // 特定年度・リーグ・地区の履歴を取得
  TeamHistory? getHistory(int year, String league, String division, String teamId) {
    try {
      return histories.firstWhere((history) => 
          history.year == year && 
          history.league == league && 
          history.division == division && 
          history.teamId == teamId);
    } catch (e) {
      return null;
    }
  }
}
