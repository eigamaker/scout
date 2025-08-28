import 'dart:math';
import '../models/game/pennant_race.dart';
import '../models/professional/professional_team.dart';
import '../models/professional/professional_player.dart';
import '../models/professional/depth_chart.dart';
import '../models/professional/player_stats.dart';
import 'depth_chart_service.dart';

class PennantRaceService {
  static const int _seasonStartMonth = 4; // 4月開始
  static const int _seasonStartWeek = 1; // 1週目開始
  static const int _seasonEndMonth = 10; // 10月終了
  static const int _seasonEndWeek = 2; // 2週目終了

  /// ペナントレースのスケジュールを生成
  static PennantRaceSchedule generateSchedule(int year, List<ProfessionalTeam> teams) {
    final games = <GameSchedule>[];
    final random = Random(year); // 年度をシードとして使用
    
    // セ・リーグとパ・リーグに分ける
    final centralTeams = teams.where((t) => t.league == League.central).toList();
    final pacificTeams = teams.where((t) => t.league == League.pacific).toList();
    
    // 各リーグ内でスケジュールを生成（週3試合）
    final centralGames = _generateLeagueSchedule(centralTeams, League.central, year, random);
    final pacificGames = _generateLeagueSchedule(pacificTeams, League.pacific, year, random);
    
    games.addAll(centralGames);
    games.addAll(pacificGames);
    
    // リーグ間交流戦を追加（週2試合）
    final interleagueGames = _generateInterleagueGames(centralTeams, pacificTeams, year, random);
    games.addAll(interleagueGames);
    
    // スケジュールを週ごとに並び替え
    games.sort((a, b) {
      if (a.month != b.month) return a.month.compareTo(b.month);
      if (a.week != b.week) return a.week.compareTo(b.week);
      return a.dayOfWeek.compareTo(b.dayOfWeek);
    });
    
    final schedule = PennantRaceSchedule(
      year: year,
      games: games,
      seasonStart: DateTime(year, _seasonStartMonth, 1),
      seasonEnd: DateTime(year, _seasonEndMonth, 15),
    );
    
    return schedule;
  }

  /// リーグ内のスケジュールを生成
  static List<GameSchedule> _generateLeagueSchedule(
    List<ProfessionalTeam> teams, 
    League league, 
    int year, 
    Random random
  ) {
    final games = <GameSchedule>[];
    final teamCount = teams.length;
    
    if (teamCount < 2) {
      return games;
    }
    
    // 各チームが週5試合になるようにスケジュールを生成
    for (int month = _seasonStartMonth; month <= _seasonEndMonth; month++) {
      for (int week = 1; week <= 4; week++) {
        if (month == _seasonStartMonth && week < _seasonStartWeek) continue;
        if (month == _seasonEndMonth && week > _seasonEndWeek) continue;
        
        // その週の試合を生成（リーグ内3試合）
        final weekGames = _generateWeekGames(teams, month, week, league, year, random);
        games.addAll(weekGames);
      }
    }
    
    return games;
  }

  /// 1週間分の試合を生成
  static List<GameSchedule> _generateWeekGames(
    List<ProfessionalTeam> teams,
    int month,
    int week,
    League league,
    int year,
    Random random
  ) {
    final games = <GameSchedule>[];
    final teamCount = teams.length;
    
    // 各チームが週5試合になるように調整
    // リーグ内で3試合 + リーグ間交流戦で2試合
    
    // リーグ内試合（3試合）
    final leagueGames = _generateLeagueGames(teams, month, week, league, year, random, 3);
    games.addAll(leagueGames);
    
    // リーグ間交流戦（2試合）は別途処理
    
    return games;
  }
  
  /// リーグ内試合を生成
  static List<GameSchedule> _generateLeagueGames(
    List<ProfessionalTeam> teams,
    int month,
    int week,
    League league,
    int year,
    Random random,
    int gameCount
  ) {
    final games = <GameSchedule>[];
    final availableTeams = List<ProfessionalTeam>.from(teams);
    
    // 各チームが指定された試合数を消化するように調整
    final teamGameCount = <String, int>{};
    for (final team in teams) {
      teamGameCount[team.id] = 0;
    }
    
    while (games.length < gameCount * teams.length / 2) {
      // 最も試合数が少ないチームを優先
      final availableTeams = teams.where((t) => teamGameCount[t.id]! < gameCount).toList();
      if (availableTeams.length < 2) break;
      
      // 試合数が少ないチームから順に選択
      availableTeams.sort((a, b) => teamGameCount[a.id]!.compareTo(teamGameCount[b.id]!));
      
      final homeTeam = availableTeams.first;
      final awayTeam = availableTeams.where((t) => t.id != homeTeam.id).first;
      
      // 試合スケジュールを作成
      final gameId = '${league.name}_${month}_${week}_${games.length + 1}';
      final dayOfWeek = _getRandomDayOfWeek(random);
      
      final game = GameSchedule(
        id: gameId,
        homeTeamId: homeTeam.id,
        awayTeamId: awayTeam.id,
        month: month,
        week: week,
        dayOfWeek: dayOfWeek,
        homeTeamGameType: GameType.home,
        awayTeamGameType: GameType.away,
      );
      
      games.add(game);
      teamGameCount[homeTeam.id] = teamGameCount[homeTeam.id]! + 1;
      teamGameCount[awayTeam.id] = teamGameCount[awayTeam.id]! + 1;
      
    }
    
    return games;
  }
  
  /// リーグ間交流戦を生成
  static List<GameSchedule> _generateInterleagueGames(
    List<ProfessionalTeam> centralTeams,
    List<ProfessionalTeam> pacificTeams,
    int year,
    Random random
  ) {
    final games = <GameSchedule>[];
    
    // 各チームが週2試合のリーグ間交流戦を消化するように調整
    for (int month = _seasonStartMonth; month <= _seasonEndMonth; month++) {
      for (int week = 1; week <= 4; week++) {
        if (month == _seasonStartMonth && week < _seasonStartWeek) continue;
        if (month == _seasonEndMonth && week > _seasonEndWeek) continue;
        
        // その週のリーグ間交流戦を生成
        final weekGames = _generateWeekInterleagueGames(
          centralTeams, pacificTeams, month, week, year, random, 2
        );
        games.addAll(weekGames);
      }
    }
    
    return games;
  }
  
  /// 1週間分のリーグ間交流戦を生成
  static List<GameSchedule> _generateWeekInterleagueGames(
    List<ProfessionalTeam> centralTeams,
    List<ProfessionalTeam> pacificTeams,
    int month,
    int week,
    int year,
    Random random,
    int gameCount
  ) {
    final games = <GameSchedule>[];
    
    // 各チームが指定された試合数を消化するように調整
    final centralTeamGameCount = <String, int>{};
    final pacificTeamGameCount = <String, int>{};
    
    for (final team in centralTeams) {
      centralTeamGameCount[team.id] = 0;
    }
    for (final team in pacificTeams) {
      pacificTeamGameCount[team.id] = 0;
    }
    
    // セ・リーグとパ・リーグのチームをマッチング
    while (games.length < gameCount * centralTeams.length) {
      // 最も試合数が少ないセ・リーグチームを選択
      final availableCentralTeams = centralTeams.where((t) => centralTeamGameCount[t.id]! < gameCount).toList();
      if (availableCentralTeams.isEmpty) break;
      
      availableCentralTeams.sort((a, b) => centralTeamGameCount[a.id]!.compareTo(centralTeamGameCount[b.id]!));
      final centralTeam = availableCentralTeams.first;
      
      // 最も試合数が少ないパ・リーグチームを選択
      final availablePacificTeams = pacificTeams.where((t) => pacificTeamGameCount[t.id]! < gameCount).toList();
      if (availablePacificTeams.isEmpty) break;
      
      availablePacificTeams.sort((a, b) => pacificTeamGameCount[a.id]!.compareTo(pacificTeamGameCount[b.id]!));
      final pacificTeam = availablePacificTeams.first;
      
      // 試合スケジュールを作成
      final gameId = 'interleague_${month}_${week}_${games.length + 1}';
      final dayOfWeek = _getRandomDayOfWeek(random);
      
      // ホームチームをランダムに決定
      final isCentralHome = random.nextBool();
      final homeTeam = isCentralHome ? centralTeam : pacificTeam;
      final awayTeam = isCentralHome ? pacificTeam : centralTeam;
      
      final game = GameSchedule(
        id: gameId,
        homeTeamId: homeTeam.id,
        awayTeamId: awayTeam.id,
        month: month,
        week: week,
        dayOfWeek: dayOfWeek,
        homeTeamGameType: GameType.home,
        awayTeamGameType: GameType.away,
      );
      
      games.add(game);
      centralTeamGameCount[centralTeam.id] = centralTeamGameCount[centralTeam.id]! + 1;
      pacificTeamGameCount[pacificTeam.id] = pacificTeamGameCount[pacificTeam.id]! + 1;
      
    }
    
    return games;
  }

  /// ランダムな曜日を取得（月曜日=1, 日曜日=7）
  static int _getRandomDayOfWeek(Random random) {
    // 平日（月-金）の確率を高くする
    final weights = [0, 20, 20, 20, 20, 20, 0]; // 土日は0、平日は20
    final totalWeight = weights.reduce((a, b) => a + b);
    final randomValue = random.nextInt(totalWeight);
    
    int currentWeight = 0;
    for (int i = 1; i <= 7; i++) {
      currentWeight += weights[i - 1];
      if (randomValue < currentWeight) {
        return i;
      }
    }
    
    return 2; // デフォルトは火曜日
  }

  /// ペナントレースの初期状態を作成
  static PennantRace createInitialPennantRace(int year, List<ProfessionalTeam> teams) {
    final schedule = generateSchedule(year, teams);
    final standings = _createInitialStandings(teams);
    
    // 各チームのdepth chartを初期化
    final teamDepthCharts = <String, TeamDepthChart>{};
    final playerStats = <String, PlayerSeasonStats>{};
    
    for (final team in teams) {
      if (team.professionalPlayers != null && team.professionalPlayers!.isNotEmpty) {
        // depth chartを作成
        final depthChart = DepthChartService.initializeTeamDepthChart(
          team.id,
          team.professionalPlayers!,
        );
        teamDepthCharts[team.id] = depthChart;
        
        // 各選手のシーズン成績を初期化
        for (final player in team.professionalPlayers!) {
          final playerId = player.id?.toString() ?? 'player_${player.playerId}';
          final statsKey = '${playerId}_${year}';
          
          playerStats[statsKey] = PlayerSeasonStats(
            playerId: playerId,
            teamId: team.id,
            season: year,
            lastUpdated: DateTime.now(),
          );
        }
      } else {
      }
    }
    
    final pennantRace = PennantRace(
      year: year,
      schedule: schedule,
      completedGames: [],
      standings: standings,
      currentMonth: _seasonStartMonth,
      currentWeek: _seasonStartWeek,
      teamDepthCharts: teamDepthCharts,
      playerStats: playerStats,
    );
    
    return pennantRace;
  }

  /// 初期順位表を作成
  static Map<String, TeamStanding> _createInitialStandings(List<ProfessionalTeam> teams) {
    final standings = <String, TeamStanding>{};
    
    for (final team in teams) {
      standings[team.id] = TeamStanding(
        teamId: team.id,
        teamName: team.name,
        teamShortName: team.shortName,
        league: team.league,
        division: team.division,
        games: 0,
        wins: 0,
        losses: 0,
        ties: 0,
        winningPercentage: 0.0,
        gamesBehind: 0.0,
        rank: 0,
        runsScored: 0,
        runsAllowed: 0,
        runDifferential: 0,
        homeWins: 0,
        homeLosses: 0,
        awayWins: 0,
        awayLosses: 0,
      );
    }
    
    return standings;
  }

  /// 指定週の試合を実行
  static PennantRace executeWeekGames(
    PennantRace pennantRace,
    int month,
    int week,
    List<ProfessionalTeam> teams
  ) {
    
    // 今週の試合スケジュールを取得
    final weekGames = pennantRace.schedule.getGamesForWeek(month, week);
    
    // 未完了の試合を確認
    final uncompletedGames = weekGames.where((game) => !game.isCompleted).toList();
    
    if (uncompletedGames.isEmpty) {
      return pennantRace;
    }
    
    // 直接試合を実行（循環呼び出しを避ける）
    final result = _executeWeekGamesDirectly(pennantRace, month, week, teams);
    
    // 実行後の完了試合数を確認
    final completedGamesAfter = result.schedule.getGamesForWeek(month, week)
        .where((game) => game.isCompleted).toList();
    
    return result;
  }

  /// 直接試合を実行（循環呼び出しを避ける）
  static PennantRace _executeWeekGamesDirectly(
    PennantRace pennantRace,
    int month,
    int week,
    List<ProfessionalTeam> teams
  ) {
    
    final weekGames = pennantRace.schedule.getGamesForWeek(month, week);
    final newCompletedGames = <GameResult>[];
    final newStandings = Map<String, TeamStanding>.from(pennantRace.standings);
    
    // 全試合スケジュールをコピー（他の週の試合を保持）
    final allGames = List<GameSchedule>.from(pennantRace.schedule.games);
    
    // 今週の試合のインデックスを見つけて更新
    for (int i = 0; i < allGames.length; i++) {
      final game = allGames[i];
      if (game.month == month && game.week == week) {
        if (!game.isCompleted) {
          final result = _simulateGame(game, teams);
          newCompletedGames.add(result);
          
          // 試合完了後のスケジュールを作成
          final completedGame = game.completeGame(result);
          allGames[i] = completedGame; // 既存のリストを更新
          
          // 順位表を更新
          _updateStandings(newStandings, result, teams);
        }
      }
    }

    // スケジュールを更新（全試合を保持）
    final updatedSchedule = pennantRace.schedule.copyWith(games: allGames);
    
    final result = PennantRace(
      year: pennantRace.year,
      schedule: updatedSchedule,
      completedGames: [...pennantRace.completedGames, ...newCompletedGames],
      standings: newStandings,
      currentMonth: month,
      currentWeek: week,
      isSeasonComplete: month == 10 && week == 2,
      teamDepthCharts: pennantRace.teamDepthCharts,
      playerStats: pennantRace.playerStats,
    );
    
    return result;
  }

  /// 試合をシミュレート
  static GameResult _simulateGame(GameSchedule game, List<ProfessionalTeam> teams) {
    final homeTeam = teams.firstWhere((t) => t.id == game.homeTeamId);
    final awayTeam = teams.firstWhere((t) => t.id == game.awayTeamId);
    
    // 簡単なシミュレーション（チームの総合力ベース）
    final random = Random();
    final homeBaseScore = (homeTeam.totalStrength / 20).round();
    final awayBaseScore = (awayTeam.totalStrength / 20).round();
    
    // ランダム要素を追加
    final homeScore = (homeBaseScore + random.nextInt(5)).clamp(0, 15);
    final awayScore = (awayBaseScore + random.nextInt(5)).clamp(0, 15);
    
    return GameResult(
      homeTeamId: game.homeTeamId,
      awayTeamId: game.awayTeamId,
      homeScore: homeScore,
      awayScore: awayScore,
      inning: 9,
      isExtraInnings: false,
      gameDate: DateTime.now(),
    );
  }

  /// 順位表を更新
  static void _updateStandings(Map<String, TeamStanding> standings, GameResult result, List<ProfessionalTeam> teams) {
    // チーム情報を取得
    final homeTeam = teams.firstWhere((t) => t.id == result.homeTeamId);
    final awayTeam = teams.firstWhere((t) => t.id == result.awayTeamId);
    
    // ホームチームの順位を更新
    final homeStanding = standings.putIfAbsent(result.homeTeamId, () => TeamStanding(
      teamId: result.homeTeamId,
      teamName: homeTeam.name,
      teamShortName: homeTeam.shortName,
      league: homeTeam.league,
      division: homeTeam.division,
      games: 0,
      wins: 0,
      losses: 0,
      ties: 0,
      winningPercentage: 0.0,
      gamesBehind: 0.0,
      rank: 0,
      runsScored: 0,
      runsAllowed: 0,
      runDifferential: 0,
      homeWins: 0,
      homeLosses: 0,
      awayWins: 0,
      awayLosses: 0,
    ));
    
    // アウェイチームの順位を更新
    final awayStanding = standings.putIfAbsent(result.awayTeamId, () => TeamStanding(
      teamId: result.awayTeamId,
      teamName: awayTeam.name,
      teamShortName: awayTeam.shortName,
      league: awayTeam.league,
      division: awayTeam.division,
      games: 0,
      wins: 0,
      losses: 0,
      ties: 0,
      winningPercentage: 0.0,
      gamesBehind: 0.0,
      rank: 0,
      runsScored: 0,
      runsAllowed: 0,
      runDifferential: 0,
      homeWins: 0,
      homeLosses: 0,
      awayWins: 0,
      awayLosses: 0,
    ));
    
    // 試合数を更新
    final updatedHomeStanding = homeStanding.copyWith(
      games: homeStanding.games + 1,
      runsScored: homeStanding.runsScored + result.homeScore,
      runsAllowed: homeStanding.runsAllowed + result.awayScore,
    );
    
    final updatedAwayStanding = awayStanding.copyWith(
      games: awayStanding.games + 1,
      runsScored: awayStanding.runsScored + result.awayScore,
      runsAllowed: awayStanding.runsAllowed + result.homeScore,
    );
    
    // 勝敗を判定して更新
    if (result.homeScore > result.awayScore) {
      // ホームチーム勝利
      standings[result.homeTeamId] = updatedHomeStanding.copyWith(
        wins: updatedHomeStanding.wins + 1,
        homeWins: updatedHomeStanding.homeWins + 1,
      );
      standings[result.awayTeamId] = updatedAwayStanding.copyWith(
        losses: updatedAwayStanding.losses + 1,
        awayLosses: updatedAwayStanding.awayLosses + 1,
      );
    } else if (result.awayScore > result.homeScore) {
      // アウェイチーム勝利
      standings[result.awayTeamId] = updatedAwayStanding.copyWith(
        wins: updatedAwayStanding.wins + 1,
        awayWins: updatedAwayStanding.awayWins + 1,
      );
      standings[result.homeTeamId] = updatedHomeStanding.copyWith(
        losses: updatedHomeStanding.losses + 1,
        homeLosses: updatedHomeStanding.homeLosses + 1,
      );
    } else {
      // 引き分け
      standings[result.homeTeamId] = updatedHomeStanding.copyWith(
        ties: updatedHomeStanding.ties + 1,
      );
      standings[result.awayTeamId] = updatedAwayStanding.copyWith(
        ties: updatedAwayStanding.ties + 1,
      );
    }
    
    // 勝率を更新
    _updateWinningPercentage(standings[result.homeTeamId]!, standings);
    _updateWinningPercentage(standings[result.awayTeamId]!, standings);
  }
  
  /// 勝率を更新
  static void _updateWinningPercentage(TeamStanding standing, Map<String, TeamStanding> standings) {
    final totalGames = standing.wins + standing.losses + standing.ties;
    if (totalGames > 0) {
      final winningPercentage = standing.wins / totalGames;
      final runDifferential = standing.runsScored - standing.runsAllowed;
      standings[standing.teamId] = standing.copyWith(
        winningPercentage: winningPercentage,
        runDifferential: runDifferential,
      );
    }
  }

  /// ペナントレースの進行状況を取得
  static String getSeasonProgress(PennantRace pennantRace) {
    final totalWeeks = _calculateTotalWeeks();
    final currentWeek = _calculateCurrentWeek(pennantRace.currentMonth, pennantRace.currentWeek);
    final progress = (currentWeek / totalWeeks * 100).round();
    
    return '$progress% ($currentWeek/$totalWeeks週)';
  }

  /// 総週数を計算（4週固定）
  static int _calculateTotalWeeks() {
    int totalWeeks = 0;
    for (int month = _seasonStartMonth; month <= _seasonEndMonth; month++) {
      if (month == _seasonStartMonth) {
        totalWeeks += (4 - _seasonStartWeek + 1); // 4月は開始週から
      } else if (month == _seasonEndMonth) {
        totalWeeks += _seasonEndWeek; // 10月は終了週まで
      } else {
        totalWeeks += 4; // 通常月は4週
      }
    }
    return totalWeeks;
  }

  /// 現在の週数を計算（4週固定）
  static int _calculateCurrentWeek(int month, int week) {
    int currentWeek = 0;
    for (int m = _seasonStartMonth; m < month; m++) {
      if (m == _seasonStartMonth) {
        currentWeek += (4 - _seasonStartWeek + 1);
      } else {
        currentWeek += 4;
      }
    }
    currentWeek += week - _seasonStartWeek + 1;
    return currentWeek;
  }

  /// 指定チームの試合結果サマリーを取得
  static String getTeamResultSummary(PennantRace pennantRace, String teamId) {
    final standing = pennantRace.standings[teamId];
    if (standing == null) return 'データなし';
    
    final wins = standing.wins;
    final losses = standing.losses;
    final ties = standing.ties;
    final games = standing.games;
    final winRate = standing.winningPercentage;
    
    return '$wins勝$losses敗$ties分 ($games試合, 勝率${(winRate * 100).toStringAsFixed(3)})';
  }

  /// リーグの順位表を取得（勝率順）
  static List<TeamStanding> getLeagueStandings(PennantRace pennantRace, League league) {
    return pennantRace.getLeagueStandings(league);
  }

  /// 指定チームの直近の試合結果を取得
  static List<GameResult> getRecentTeamResults(PennantRace pennantRace, String teamId, {int limit = 5}) {
    final teamGames = pennantRace.schedule.getTeamGames(teamId);
    final completedGames = <GameResult>[];
    
    for (final game in teamGames) {
      if (game.isCompleted && game.result != null) {
        completedGames.add(game.result!);
      }
    }
    
    // 最新の試合から順に並べる
    completedGames.sort((a, b) => b.gameDate.compareTo(a.gameDate));
    
    return completedGames.take(limit).toList();
  }

  /// 指定チームの今週の試合を取得
  static List<GameSchedule> getThisWeekTeamGames(PennantRace pennantRace, String teamId) {
    return pennantRace.schedule.getTeamGamesForWeek(
      teamId,
      pennantRace.currentMonth,
      pennantRace.currentWeek,
    );
  }

  /// ペナントレースが終了しているかチェック
  static bool isSeasonComplete(PennantRace pennantRace) {
    return pennantRace.currentMonth == _seasonEndMonth && 
           pennantRace.currentWeek == _seasonEndWeek;
  }

  /// 日本シリーズの対戦カードを決定
  static List<String> determineJapanSeriesMatchup(PennantRace pennantRace) {
    if (!isSeasonComplete(pennantRace)) return [];
    
    final centralStandings = getLeagueStandings(pennantRace, League.central);
    final pacificStandings = getLeagueStandings(pennantRace, League.pacific);
    
    if (centralStandings.isEmpty || pacificStandings.isEmpty) return [];
    
    final centralChampion = centralStandings.first.teamId;
    final pacificChampion = pacificStandings.first.teamId;
    
    return [centralChampion, pacificChampion];
  }
}
