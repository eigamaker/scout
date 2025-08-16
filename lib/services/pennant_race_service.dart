import 'dart:math';
import '../models/game/pennant_race.dart';
import '../models/professional/professional_team.dart';
import '../models/professional/professional_player.dart';
import '../models/professional/depth_chart.dart';
import '../models/professional/player_stats.dart';
import 'depth_chart_service.dart';

class PennantRaceService {
  static const int _gamesPerWeek = 5; // 週5試合
  static const int _seasonStartMonth = 4; // 4月開始
  static const int _seasonStartWeek = 1; // 1週目開始
  static const int _seasonEndMonth = 10; // 10月終了
  static const int _seasonEndWeek = 2; // 2週目終了

  /// ペナントレースのスケジュールを生成
  static PennantRaceSchedule generateSchedule(int year, List<ProfessionalTeam> teams) {
    print('PennantRaceService.generateSchedule: 開始 - 年度: $year, 総チーム数: ${teams.length}');
    
    final games = <GameSchedule>[];
    final random = Random(year); // 年度をシードとして使用
    
    // セ・リーグとパ・リーグに分ける
    final centralTeams = teams.where((t) => t.league == League.central).toList();
    final pacificTeams = teams.where((t) => t.league == League.pacific).toList();
    
    print('PennantRaceService.generateSchedule: セ・リーグ: ${centralTeams.length}チーム, パ・リーグ: ${pacificTeams.length}チーム');
    
    // 各リーグ内でスケジュールを生成
    final centralGames = _generateLeagueSchedule(centralTeams, League.central, year, random);
    final pacificGames = _generateLeagueSchedule(pacificTeams, League.pacific, year, random);
    
    games.addAll(centralGames);
    games.addAll(pacificGames);
    
    print('PennantRaceService.generateSchedule: セ・リーグ試合数: ${centralGames.length}, パ・リーグ試合数: ${pacificGames.length}');
    
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
    
    print('PennantRaceService.generateSchedule: 完了 - 総試合数: ${games.length}試合');
    
    // 週別の試合数を確認
    for (int month = _seasonStartMonth; month <= _seasonEndMonth; month++) {
      for (int week = 1; week <= 4; week++) {
        if (month == _seasonStartMonth && week < _seasonStartWeek) continue;
        if (month == _seasonEndMonth && week > _seasonEndWeek) continue;
        
        final weekGames = schedule.getGamesForWeek(month, week);
        print('PennantRaceService.generateSchedule: ${month}月${week}週: ${weekGames.length}試合');
      }
    }
    
    return schedule;
  }

  /// リーグ内のスケジュールを生成
  static List<GameSchedule> _generateLeagueSchedule(
    List<ProfessionalTeam> teams, 
    League league, 
    int year, 
    Random random
  ) {
    print('PennantRaceService._generateLeagueSchedule: 開始 - リーグ: ${league.name}, チーム数: ${teams.length}');
    
    final games = <GameSchedule>[];
    final teamCount = teams.length;
    
    if (teamCount < 2) {
      print('PennantRaceService._generateLeagueSchedule: チーム数が不足しています (${teamCount}チーム)');
      return games;
    }
    
    // 各チームが週5試合になるようにスケジュールを生成
    for (int month = _seasonStartMonth; month <= _seasonEndMonth; month++) {
      for (int week = 1; week <= 4; week++) {
        if (month == _seasonStartMonth && week < _seasonStartWeek) continue;
        if (month == _seasonEndMonth && week > _seasonEndWeek) continue;
        
        print('PennantRaceService._generateLeagueSchedule: ${month}月${week}週の試合生成開始');
        
        // その週の試合を生成
        final weekGames = _generateWeekGames(teams, month, week, league, year, random);
        games.addAll(weekGames);
        
        print('PennantRaceService._generateLeagueSchedule: ${month}月${week}週の試合生成完了 - ${weekGames.length}試合');
      }
    }
    
    print('PennantRaceService._generateLeagueSchedule: 完了 - 総試合数: ${games.length}試合');
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
    print('PennantRaceService._generateWeekGames: 開始 - ${month}月${week}週, リーグ: ${league.name}, チーム数: ${teams.length}');
    
    final games = <GameSchedule>[];
    final teamCount = teams.length;
    final availableTeams = List<ProfessionalTeam>.from(teams);
    
    print('PennantRaceService._generateWeekGames: 利用可能チーム数: ${availableTeams.length}');
    
    // 各チームが週5試合になるように調整
    while (availableTeams.length >= 2) {
      // ランダムに2チームを選択
      final homeTeamIndex = random.nextInt(availableTeams.length);
      final homeTeam = availableTeams[homeTeamIndex];
      availableTeams.removeAt(homeTeamIndex);
      
      if (availableTeams.isEmpty) break;
      
      final awayTeamIndex = random.nextInt(availableTeams.length);
      final awayTeam = availableTeams[awayTeamIndex];
      availableTeams.removeAt(awayTeamIndex);
      
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
      print('PennantRaceService._generateWeekGames: 試合生成 - ${homeTeam.shortName} vs ${awayTeam.shortName}');
    }
    
    print('PennantRaceService._generateWeekGames: 生成完了 - ${games.length}試合');
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
    print('PennantRaceService.createInitialPennantRace: 開始 - 年度: $year, チーム数: ${teams.length}');
    
    final schedule = generateSchedule(year, teams);
    final standings = _createInitialStandings(teams);
    
    // 各チームのdepth chartを初期化
    final teamDepthCharts = <String, TeamDepthChart>{};
    final playerStats = <String, PlayerSeasonStats>{};
    
    for (final team in teams) {
      print('PennantRaceService.createInitialPennantRace: ${team.shortName}のdepth chart初期化開始');
      print('PennantRaceService.createInitialPennantRace: ${team.shortName}のprofessionalPlayers数: ${team.professionalPlayers?.length ?? 0}');
      
      if (team.professionalPlayers != null && team.professionalPlayers!.isNotEmpty) {
        // depth chartを作成
        final depthChart = DepthChartService.initializeTeamDepthChart(
          team.id,
          team.professionalPlayers!,
        );
        teamDepthCharts[team.id] = depthChart;
        
        print('PennantRaceService.createInitialPennantRace: ${team.shortName}のdepth chart作成完了 - ポジション数: ${depthChart.positionCharts.length}');
        
        // 各選手のシーズン成績を初期化
        for (final player in team.professionalPlayers!) {
          final playerId = player.id.toString();
          final statsKey = '${playerId}_${year}';
          
          playerStats[statsKey] = PlayerSeasonStats(
            playerId: playerId,
            teamId: team.id,
            season: year,
            lastUpdated: DateTime.now(),
          );
        }
        
        print('PennantRaceService.createInitialPennantRace: ${team.shortName}の選手成績初期化完了 - ${team.professionalPlayers!.length}名');
      } else {
        print('PennantRaceService.createInitialPennantRace: ${team.shortName}のprofessionalPlayersが空のため、depth chartを作成できません');
      }
    }
    
    print('PennantRaceService.createInitialPennantRace: depth chart初期化完了 - 作成されたチーム数: ${teamDepthCharts.length}');
    
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
    
    print('PennantRaceService.createInitialPennantRace: 完了');
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
    print('PennantRaceService.executeWeekGames: 開始 - ${month}月${week}週');
    
    // 今週の試合スケジュールを取得
    final weekGames = pennantRace.schedule.getGamesForWeek(month, week);
    print('PennantRaceService.executeWeekGames: 今週の試合数: ${weekGames.length}試合');
    
    // 未完了の試合を確認
    final uncompletedGames = weekGames.where((game) => !game.isCompleted).toList();
    print('PennantRaceService.executeWeekGames: 未完了試合数: ${uncompletedGames.length}試合');
    
    if (uncompletedGames.isEmpty) {
      print('PennantRaceService.executeWeekGames: 今週の試合は全て完了済みです');
      return pennantRace;
    }
    
    // ペナントレースのexecuteWeekGamesを呼び出し
    final result = pennantRace.executeWeekGames(month, week, teams);
    
    // 実行後の完了試合数を確認
    final completedGamesAfter = result.schedule.getGamesForWeek(month, week)
        .where((game) => game.isCompleted).toList();
    print('PennantRaceService.executeWeekGames: 実行後の完了試合数: ${completedGamesAfter.length}試合');
    
    print('PennantRaceService.executeWeekGames: 完了');
    return result;
  }

  /// ペナントレースの進行状況を取得
  static String getSeasonProgress(PennantRace pennantRace) {
    final totalWeeks = _calculateTotalWeeks();
    final currentWeek = _calculateCurrentWeek(pennantRace.currentMonth, pennantRace.currentWeek);
    final progress = (currentWeek / totalWeeks * 100).round();
    
    return '$progress% ($currentWeek/$totalWeeks週)';
  }

  /// 総週数を計算
  static int _calculateTotalWeeks() {
    int totalWeeks = 0;
    for (int month = _seasonStartMonth; month <= _seasonEndMonth; month++) {
      if (month == _seasonStartMonth) {
        totalWeeks += (5 - _seasonStartWeek + 1); // 4月は開始週から
      } else if (month == _seasonEndMonth) {
        totalWeeks += _seasonEndWeek; // 10月は終了週まで
      } else {
        totalWeeks += 4; // 通常月は4週
      }
    }
    return totalWeeks;
  }

  /// 現在の週数を計算
  static int _calculateCurrentWeek(int month, int week) {
    int currentWeek = 0;
    for (int m = _seasonStartMonth; m < month; m++) {
      if (m == _seasonStartMonth) {
        currentWeek += (5 - _seasonStartWeek + 1);
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
