import 'dart:math';
import '../models/game/pennant_race.dart';
import '../models/professional/professional_team.dart';
import '../models/professional/professional_player.dart';
import '../models/professional/depth_chart.dart';
import '../models/professional/player_stats.dart';
import '../models/professional/enums.dart';
import 'depth_chart_service.dart';
import 'stats_calculation_service.dart';
import 'pennant_race/schedule_generator.dart';
import 'pennant_race/game_simulator.dart';

class PennantRaceService {
  static const int _seasonStartMonth = 4; // 4月開始
  static const int _seasonStartWeek = 1; // 1週目開始
  static const int _seasonEndMonth = 10; // 10月終了
  static const int _seasonEndWeek = 2; // 2週目終了

  /// ペナントレースのスケジュールを生成
  static PennantRaceSchedule generateSchedule(int year, List<ProfessionalTeam> teams) {
    return ScheduleGenerator.generateSchedule(year, teams);
  }

  /// ペナントレースの初期状態を作成
  static PennantRace createInitialPennantRace(int year, List<ProfessionalTeam> teams) {
    final schedule = generateSchedule(year, teams);
    final standings = _createInitialStandings(teams);
    
    final pennantRace = PennantRace(
      year: year,
      schedule: schedule,
      completedGames: [],
      standings: standings,
      currentMonth: _seasonStartMonth,
      currentWeek: _seasonStartWeek,
      isSeasonComplete: false,
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
        wins: 0,
        losses: 0,
        ties: 0,
        winningPercentage: 0.0,
        gamesBehind: 0.0,
        runsScored: 0,
        runsAllowed: 0,
        runDifferential: 0,
      );
    }
    
    return standings;
  }

  /// 指定週の試合を実行
  static PennantRace executeWeekGames(
    PennantRace pennantRace,
    List<ProfessionalTeam> teams,
  ) {
    if (pennantRace.isSeasonComplete) {
      return pennantRace;
    }
    
    // 現在の週の試合を取得
    final weekGames = pennantRace.schedule.games.where((game) =>
      game.month == pennantRace.currentMonth &&
      game.week == pennantRace.currentWeek &&
      !game.isCompleted
    ).toList();
    
    if (weekGames.isEmpty) {
      // 試合がない場合は次の週に進む
      return _advanceToNextWeek(pennantRace);
    }
    
    // 試合を実行
    final updatedPennantRace = _executeWeekGamesDirectly(pennantRace, weekGames, teams);
    
    // 次の週に進む
    return _advanceToNextWeek(updatedPennantRace);
  }

  /// 直接試合を実行（循環呼び出しを避ける）
  static PennantRace _executeWeekGamesDirectly(
    PennantRace pennantRace,
    List<GameSchedule> weekGames,
    List<ProfessionalTeam> teams,
  ) {
    final updatedStandings = Map<String, TeamStanding>.from(pennantRace.standings);
    final updatedGames = <GameSchedule>[];
    final updatedPlayerStats = Map<String, PlayerSeasonStats>.from(pennantRace.playerStats);
    
    // チーム別選手リストを作成
    final teamPlayers = <String, List<ProfessionalPlayer>>{};
    for (final team in teams) {
      if (team.professionalPlayers != null) {
        teamPlayers[team.id] = team.professionalPlayers!;
      }
    }
    
    for (final game in weekGames) {
      // 試合をシミュレート
      final result = _simulateGame(game, teams);
      
      // 順位表を更新
      _updateStandings(updatedStandings, result, teams);
      
      // 選手の成績を計算・更新
      final gamePlayerStats = StatsCalculationService.calculateGameStats(
        gameResult: result,
        teamPlayers: teamPlayers,
        teamDepthCharts: pennantRace.teamDepthCharts,
        currentPlayerStats: updatedPlayerStats,
        season: pennantRace.year,
      );
      updatedPlayerStats.addAll(gamePlayerStats);
      
      // 試合結果を記録
      final updatedGame = GameSchedule(
        id: game.id,
        homeTeamId: game.homeTeamId,
        awayTeamId: game.awayTeamId,
        month: game.month,
        week: game.week,
        dayOfWeek: game.dayOfWeek,
        homeTeamGameType: game.homeTeamGameType,
        awayTeamGameType: game.awayTeamGameType,
        isCompleted: true,
        result: result,
      );
      
      updatedGames.add(updatedGame);
    }
    
    // スケジュールを更新
    final updatedSchedule = PennantRaceSchedule(
      year: pennantRace.schedule.year,
      games: updatedGames,
      seasonStart: pennantRace.schedule.seasonStart,
      seasonEnd: pennantRace.schedule.seasonEnd,
    );
    
    return pennantRace.copyWith(
      schedule: updatedSchedule,
      standings: updatedStandings,
      playerStats: updatedPlayerStats,
    );
  }

  /// 試合をシミュレート
  static GameResult _simulateGame(GameSchedule game, List<ProfessionalTeam> teams) {
    return GameSimulator.simulateGame(game, teams);
  }

  /// 順位表を更新
  static void _updateStandings(Map<String, TeamStanding> standings, GameResult result, List<ProfessionalTeam> teams) {
    GameSimulator.updateStandings(standings, result, teams);
  }

  /// 次の週に進む
  static PennantRace _advanceToNextWeek(PennantRace pennantRace) {
    int nextMonth = pennantRace.currentMonth;
    int nextWeek = pennantRace.currentWeek + 1;
    
    if (nextWeek > 4) {
      nextWeek = 1;
      nextMonth++;
    }
    
    if (nextMonth > _seasonEndMonth) {
      // シーズン終了
      return pennantRace.copyWith(
        currentMonth: nextMonth,
        currentWeek: nextWeek,
        isSeasonComplete: true,
      );
    }
    
    return pennantRace.copyWith(
      currentMonth: nextMonth,
      currentWeek: nextWeek,
    );
  }

  /// ペナントレースの進行状況を取得
  static String getSeasonProgress(PennantRace pennantRace) {
    final totalWeeks = _calculateTotalWeeks();
    final currentWeek = _calculateCurrentWeek(pennantRace.currentMonth, pennantRace.currentWeek);
    final progress = (currentWeek / totalWeeks * 100).round();
    
    return '${pennantRace.currentMonth}月${pennantRace.currentWeek}週目 (${progress}%)';
  }

  /// 総週数を計算（4週固定）
  static int _calculateTotalWeeks() {
    int totalWeeks = 0;
    for (int month = _seasonStartMonth; month <= _seasonEndMonth; month++) {
      totalWeeks += 4; // 各月4週
    }
    return totalWeeks;
  }

  /// 現在の週数を計算（4週固定）
  static int _calculateCurrentWeek(int month, int week) {
    int currentWeek = 0;
    for (int m = _seasonStartMonth; m < month; m++) {
      currentWeek += 4; // 各月4週
    }
    currentWeek += week;
    return currentWeek;
  }

  /// 指定チームの試合結果サマリーを取得
  static String getTeamResultSummary(PennantRace pennantRace, String teamId) {
    final standing = pennantRace.standings[teamId];
    if (standing == null) return 'データなし';
    
    return '${standing.wins}勝${standing.losses}敗${standing.ties}分 (勝率: ${(standing.winningPercentage * 100).toStringAsFixed(1)}%)';
  }

  /// リーグの順位表を取得（勝率順）
  static List<TeamStanding> getLeagueStandings(PennantRace pennantRace, League league) {
    return pennantRace.standings.values
        .where((standing) => standing.league == league)
        .toList()
        ..sort((a, b) => b.winningPercentage.compareTo(a.winningPercentage));
  }

  /// 指定チームの直近の試合結果を取得
  static List<GameResult> getRecentTeamResults(PennantRace pennantRace, String teamId, {int limit = 5}) {
    final teamGames = pennantRace.schedule.games.where((game) =>
      (game.homeTeamId == teamId || game.awayTeamId == teamId) &&
      game.isCompleted
    ).toList();
    
    // 日付順でソート（新しい順）
    teamGames.sort((a, b) {
      final dateA = DateTime(2024, a.month, a.dayOfWeek);
      final dateB = DateTime(2024, b.month, b.dayOfWeek);
      return dateB.compareTo(dateA);
    });
    
    return teamGames.take(limit).map((game) => GameResult(
      homeTeamId: game.homeTeamId,
      awayTeamId: game.awayTeamId,
      homeScore: 0,
      awayScore: 0,
      inning: 9,
      gameDate: DateTime.now(),
    )).toList();
  }

  /// 指定チームの今週の試合を取得
  static List<GameSchedule> getThisWeekTeamGames(PennantRace pennantRace, String teamId) {
    return pennantRace.schedule.games.where((game) =>
      (game.homeTeamId == teamId || game.awayTeamId == teamId) &&
      game.month == pennantRace.currentMonth &&
      game.week == pennantRace.currentWeek
    ).toList();
  }

  /// ペナントレースが終了しているかチェック
  static bool isSeasonComplete(PennantRace pennantRace) {
    return pennantRace.isSeasonComplete;
  }

  /// 日本シリーズの対戦カードを決定
  static List<String> determineJapanSeriesMatchup(PennantRace pennantRace) {
    final centralStandings = getLeagueStandings(pennantRace, League.central);
    final pacificStandings = getLeagueStandings(pennantRace, League.pacific);
    
    if (centralStandings.isEmpty || pacificStandings.isEmpty) {
      return [];
    }
    
    final centralChampion = centralStandings.first.teamId;
    final pacificChampion = pacificStandings.first.teamId;
    
    return [centralChampion, pacificChampion];
  }
}
