import 'dart:math' as math;
import 'dart:math';
import '../../models/game/pennant_race.dart';
import '../../models/professional/professional_team.dart';
import '../../models/professional/enums.dart';

/// ペナントレースのスケジュール生成を担当するクラス
class ScheduleGenerator {
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
    Random random,
  ) {
    final games = <GameSchedule>[];
    
    // 4月から10月まで（4週固定）
    for (int month = _seasonStartMonth; month <= _seasonEndMonth; month++) {
      for (int week = 1; week <= 4; week++) {
        final weekGames = _generateWeekGames(teams, league, year, month, week, random);
        games.addAll(weekGames);
      }
    }
    
    return games;
  }

  /// 1週間分の試合を生成
  static List<GameSchedule> _generateWeekGames(
    List<ProfessionalTeam> teams,
    League league,
    int year,
    int month,
    int week,
    Random random,
  ) {
    final games = <GameSchedule>[];
    
    // 週3試合（火曜日、木曜日、土曜日）
    final gameDays = [2, 4, 6]; // 火曜日、木曜日、土曜日
    
    for (final dayOfWeek in gameDays) {
      final leagueGames = _generateLeagueGames(teams, league, year, month, week, dayOfWeek, random);
      games.addAll(leagueGames);
    }
    
    return games;
  }

  /// リーグ内試合を生成
  static List<GameSchedule> _generateLeagueGames(
    List<ProfessionalTeam> teams,
    League league,
    int year,
    int month,
    int week,
    int dayOfWeek,
    Random random,
  ) {
    final games = <GameSchedule>[];
    
    if (teams.length < 2) return games;
    
    // チームをシャッフル
    final shuffledTeams = List<ProfessionalTeam>.from(teams);
    shuffledTeams.shuffle(random);
    
    // ペアを作成
    for (int i = 0; i < shuffledTeams.length - 1; i += 2) {
      final homeTeam = shuffledTeams[i];
      final awayTeam = shuffledTeams[i + 1];
      
      // ホーム・アウェイをランダムに決定
      final isHomeAway = random.nextBool();
      final finalHomeTeam = isHomeAway ? homeTeam : awayTeam;
      final finalAwayTeam = isHomeAway ? awayTeam : homeTeam;
      
      final game = GameSchedule(
        id: '${year}_${month}_${week}_${dayOfWeek}_${finalHomeTeam.id}_${finalAwayTeam.id}',
        homeTeamId: finalHomeTeam.id,
        awayTeamId: finalAwayTeam.id,
        month: month,
        week: week,
        dayOfWeek: dayOfWeek,
        homeTeamGameType: GameType.regular,
        awayTeamGameType: GameType.regular,
        isCompleted: false,
      );
      
      games.add(game);
    }
    
    return games;
  }

  /// リーグ間交流戦を生成
  static List<GameSchedule> _generateInterleagueGames(
    List<ProfessionalTeam> centralTeams,
    List<ProfessionalTeam> pacificTeams,
    int year,
    Random random,
  ) {
    final games = <GameSchedule>[];
    
    // 6月と7月にリーグ間交流戦を実施
    for (int month = 6; month <= 7; month++) {
      for (int week = 1; week <= 4; week++) {
        final weekGames = _generateWeekInterleagueGames(
          centralTeams,
          pacificTeams,
          year,
          month,
          week,
          random,
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
    int year,
    int month,
    int week,
    Random random,
  ) {
    final games = <GameSchedule>[];
    
    // 週2試合（水曜日、金曜日）
    final gameDays = [3, 5]; // 水曜日、金曜日
    
    for (final dayOfWeek in gameDays) {
      // セ・リーグとパ・リーグのチームをランダムにマッチング
      final shuffledCentral = List<ProfessionalTeam>.from(centralTeams);
      final shuffledPacific = List<ProfessionalTeam>.from(pacificTeams);
      shuffledCentral.shuffle(random);
      shuffledPacific.shuffle(random);
      
      final minTeams = math.min(shuffledCentral.length, shuffledPacific.length);
      
      for (int i = 0; i < minTeams; i++) {
        final centralTeam = shuffledCentral[i];
        final pacificTeam = shuffledPacific[i];
        
        // ホーム・アウェイをランダムに決定
        final isCentralHome = random.nextBool();
        final homeTeam = isCentralHome ? centralTeam : pacificTeam;
        final awayTeam = isCentralHome ? pacificTeam : centralTeam;
        
        final game = GameSchedule(
          id: '${year}_${month}_${week}_${dayOfWeek}_${homeTeam.id}_${awayTeam.id}',
          homeTeamId: homeTeam.id,
          awayTeamId: awayTeam.id,
          month: month,
          week: week,
          dayOfWeek: dayOfWeek,
          homeTeamGameType: GameType.regular,
          awayTeamGameType: GameType.regular,
          isCompleted: false,
        );
        
        games.add(game);
      }
    }
    
    return games;
  }

  /// ランダムな曜日を取得（月曜日=1, 日曜日=7）
  static int _getRandomDayOfWeek(Random random) {
    // 平日（月曜日-金曜日）を優先
    final weekdays = [1, 2, 3, 4, 5]; // 月曜日-金曜日
    final weekends = [6, 7]; // 土曜日、日曜日
    
    // 80%の確率で平日、20%の確率で週末
    if (random.nextDouble() < 0.8) {
      return weekdays[random.nextInt(weekdays.length)];
    } else {
      return weekends[random.nextInt(weekends.length)];
    }
  }
}
