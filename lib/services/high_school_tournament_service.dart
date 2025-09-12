import 'dart:math';
import '../models/game/high_school_tournament.dart';
import '../models/school/school.dart';
import '../models/player/player.dart';

class HighSchoolTournamentService {
  static const int _maxPrefecturalSchools = 32; // 県大会出場校数

  /// 都道府県別の大会を作成
  static HighSchoolTournament createPrefecturalTournament(
    int year,
    String prefecture,
    List<School> schools,
    int month,
    int week,
    TournamentType type,
  ) {
    final tournamentId = '${type.name}_${prefecture}_${year}_${month}_${week}';
    final participatingSchools = _selectParticipatingSchools(schools, _maxPrefecturalSchools);
    
    
    final schedule = _generatePrefecturalSchedule(
      year,
      month,
      week,
      participatingSchools,
      type,
    );
    
    final standings = _createInitialStandings(participatingSchools);
    
    return HighSchoolTournament(
      id: tournamentId,
      year: year,
      type: type,
      stage: TournamentStage.prefectural,
      games: schedule.games,
      completedGames: [],
      standings: standings,
      participatingSchools: participatingSchools.map((s) => s.id).toList(),
      eliminatedSchools: [],
      championSchoolId: null,
      runnerUpSchoolId: null,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 春の全国大会を作成
  static HighSchoolTournament createSpringNationalTournament(
    int year,
    List<String> qualifiedSchoolIds,
    List<School> allSchools,
    int month,
    int week,
  ) {
    final tournamentId = 'spring_national_${year}_${month}_${week}';
    final qualifiedSchools = allSchools.where((s) => qualifiedSchoolIds.contains(s.id)).toList();
    
    final schedule = _generateNationalSchedule(
      year,
      month,
      week,
      qualifiedSchools,
      TournamentType.springNational,
    );
    
    final standings = _createInitialStandings(qualifiedSchools);
    
    return HighSchoolTournament(
      id: tournamentId,
      year: year,
      type: TournamentType.springNational,
      stage: TournamentStage.national,
      games: schedule.games,
      completedGames: [],
      standings: standings,
      participatingSchools: qualifiedSchoolIds,
      eliminatedSchools: [],
      championSchoolId: null,
      runnerUpSchoolId: null,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 夏の全国大会を作成
  static HighSchoolTournament createSummerNationalTournament(
    int year,
    List<String> qualifiedSchoolIds,
    List<School> allSchools,
    int month,
    int week,
  ) {
    final tournamentId = 'summer_national_${year}_${month}_${week}';
    final qualifiedSchools = allSchools.where((s) => qualifiedSchoolIds.contains(s.id)).toList();
    
    final schedule = _generateNationalSchedule(
      year,
      month,
      week,
      qualifiedSchools,
      TournamentType.summer,
    );
    
    final standings = _createInitialStandings(qualifiedSchools);
    
    return HighSchoolTournament(
      id: tournamentId,
      year: year,
      type: TournamentType.summer,
      stage: TournamentStage.national,
      games: schedule.games,
      completedGames: [],
      standings: standings,
      participatingSchools: qualifiedSchoolIds,
      eliminatedSchools: [],
      championSchoolId: null,
      runnerUpSchoolId: null,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 指定週の試合を実行（32校シンプルトーナメント）
  static HighSchoolTournament executeWeekGames(
    HighSchoolTournament tournament,
    int month,
    int week,
    List<School> schools,
  ) {
    final weekGames = tournament.getUncompletedGamesForWeek(month, week);
    if (weekGames.isEmpty) return tournament;
    
    
    final newCompletedGames = <TournamentGame>[];
    final newStandings = Map<String, SchoolStanding>.from(tournament.standings);
    final newEliminatedSchools = List<String>.from(tournament.eliminatedSchools);
    
    // 全試合スケジュールをコピー
    var allGames = List<TournamentGame>.from(tournament.games);
    
    // 今週の試合を実行
      for (int j = 0; j < allGames.length; j++) {
        final g = allGames[j];
      if (g.month == month && g.week == week && !g.isCompleted) {
        
          final r = _simulateGame(g, schools);
        final cg = g.completeTournamentGame(r);
          allGames[j] = cg;
          newCompletedGames.add(cg);
          _updateStandings(newStandings, r, schools);
        newEliminatedSchools.add(r.loserSchoolId);
      }
    }
    
    // 勝者を次のラウンドに進出させる
    _updateNextRoundParticipants(allGames, newCompletedGames);
    
    // 大会完了判定
    final isCompleted = allGames.every((g) => g.isCompleted);
    String? championSchoolId;
    String? runnerUpSchoolId;
    
    if (isCompleted) {
      final championshipGame = allGames.firstWhere((g) => g.round == GameRound.championship);
      championSchoolId = championshipGame.winnerSchoolId;
      runnerUpSchoolId = championshipGame.loserSchoolId;
    }
    
    return tournament.copyWith(
      games: allGames,
      completedGames: [...tournament.completedGames, ...newCompletedGames],
      standings: newStandings,
      eliminatedSchools: newEliminatedSchools,
      championSchoolId: championSchoolId,
      runnerUpSchoolId: runnerUpSchoolId,
      isCompleted: isCompleted,
      updatedAt: DateTime.now(),
    );
  }

  /// 勝者を次のラウンドに進出させる
  static void _updateNextRoundParticipants(List<TournamentGame> allGames, List<TournamentGame> completedGames) {
    for (final completedGame in completedGames) {
      final winnerId = completedGame.winnerSchoolId;
      if (winnerId == null) continue;
      
      // 次のラウンドの試合を探して勝者を設定
      final nextRound = _getNextRound(completedGame.round);
      if (nextRound == null) continue;
      
      // この試合の勝者が参加する次のラウンドの試合を探す
      final nextRoundGames = allGames.where((game) => 
        game.round == nextRound && 
        !game.isCompleted &&
        (game.homeSchoolId.startsWith('winner_') || game.awaySchoolId.startsWith('winner_'))
      ).toList();
      
      // 最初に見つかった未割り当ての試合に勝者を割り当て
      for (final nextGame in nextRoundGames) {
        bool updated = false;
        
        // ホーム校が未割り当ての場合
        if (nextGame.homeSchoolId.startsWith('winner_') && !updated) {
          final gameIndex = allGames.indexOf(nextGame);
          if (gameIndex != -1) {
            allGames[gameIndex] = nextGame.copyWith(homeSchoolId: winnerId);
            updated = true;
          }
        }
        
        // アウェイ校が未割り当ての場合
        if (nextGame.awaySchoolId.startsWith('winner_') && !updated) {
          final gameIndex = allGames.indexOf(nextGame);
          if (gameIndex != -1) {
            allGames[gameIndex] = nextGame.copyWith(awaySchoolId: winnerId);
            updated = true;
          }
        }
        
        // 1つの試合に割り当てたら終了
        if (updated) break;
      }
    }
  }
  
  /// 次のラウンドを取得
  static GameRound? _getNextRound(GameRound currentRound) {
    switch (currentRound) {
      case GameRound.firstRound:
        return GameRound.secondRound;
      case GameRound.secondRound:
        return GameRound.quarterFinal; // 県大会の場合
      case GameRound.thirdRound:
        return GameRound.quarterFinal; // 全国大会の場合
      case GameRound.quarterFinal:
        return GameRound.semiFinal;
      case GameRound.semiFinal:
        return GameRound.championship;
      case GameRound.championship:
        return null; // 決勝が最後
    }
  }

  /// 参加校を選択
  static List<School> _selectParticipatingSchools(List<School> schools, int maxSchools) {
    if (schools.length <= maxSchools) return schools;
    
    // ランク順にソートして上位校を選択
    final sortedSchools = List<School>.from(schools);
    sortedSchools.sort((a, b) => b.rank.compareTo(a.rank));
    
    return sortedSchools.take(maxSchools).toList();
  }

  /// 県大会スケジュールを生成（32校シンプルトーナメント、3週間）
  static TournamentSchedule _generatePrefecturalSchedule(
    int year,
    int month,
    int week,
    List<School> schools,
    TournamentType type,
  ) {
    final games = <TournamentGame>[];
    final random = Random(year * 1000 + month * 100 + week);
    
    // 32校シンプルトーナメント（5週間、1週1ラウンド）
    // 週1: 1回戦（16試合）
    // 週2: 2回戦（8試合）
    // 週3: 準々決勝（4試合）
    // 週4: 準決勝（2試合）
    // 週5: 決勝（1試合）
    
    // 週1: 1回戦（16試合）
    final firstWeekGames = _generateFirstRoundGames(schools, month, week, random);
    games.addAll(firstWeekGames);
    
    // 週2: 2回戦（8試合）
    int secondWeek = week + 1;
    int secondMonth = month;
    if (secondWeek > 4) {
      secondWeek = 1;
      secondMonth++;
    }
    final secondWeekGames = _generateSecondRoundGames(schools, secondMonth, secondWeek, random);
    games.addAll(secondWeekGames);
    
    // 週3: 準々決勝（4試合）
    int thirdWeek = secondWeek + 1;
    int thirdMonth = secondMonth;
    if (thirdWeek > 4) {
      thirdWeek = 1;
      thirdMonth++;
    }
    final quarterFinalGames = _generateQuarterFinalGames(schools, thirdMonth, thirdWeek, random);
    games.addAll(quarterFinalGames);
    
    // 週4: 準決勝（2試合）
    int fourthWeek = thirdWeek + 1;
    int fourthMonth = thirdMonth;
    if (fourthWeek > 4) {
      fourthWeek = 1;
      fourthMonth++;
    }
    final semiFinalGames = _generateSemiFinalGames(schools, fourthMonth, fourthWeek, random);
    games.addAll(semiFinalGames);
    
    // 週5: 決勝（1試合）
    int fifthWeek = fourthWeek + 1;
    int fifthMonth = fourthMonth;
    if (fifthWeek > 4) {
      fifthWeek = 1;
      fifthMonth++;
    }
    final championshipGames = _generateChampionshipGames(schools, fifthMonth, fifthWeek, random);
    games.addAll(championshipGames);
    
    return TournamentSchedule(
      id: 'schedule_${year}_${type.name}',
      year: year,
      type: type,
      stage: TournamentStage.prefectural,
      games: games,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 全国大会スケジュールを生成（47校、シードあり）
  static TournamentSchedule _generateNationalSchedule(
    int year,
    int month,
    int week,
    List<School> schools,
    TournamentType type,
  ) {
    final games = <TournamentGame>[];
    final random = Random(year * 1000 + month * 100 + week);
    
    // 47校の全国大会（シードあり、6週間、1週1ラウンド）
    // 週1: 1回戦（30校、15試合）
    // 週2: 2回戦（32校、16試合）
    // 週3: 3回戦（16校、8試合）
    // 週4: 準々決勝（8校、4試合）
    // 週5: 準決勝（4校、2試合）
    // 週6: 決勝（2校、1試合）
    
    // 週1: 1回戦（30校、15試合）
    final firstRoundSchools = schools.take(30).toList();
    for (int i = 0; i < 30; i += 2) {
      final game = TournamentGame(
        id: 'game_${month}_${week}_firstRound_${i ~/ 2}',
        homeSchoolId: firstRoundSchools[i].id,
        awaySchoolId: firstRoundSchools[i + 1].id,
        round: GameRound.firstRound,
        month: month,
        week: week,
        dayOfWeek: (i ~/ 2) % 7 + 1,
        isCompleted: false,
        result: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      games.add(game);
    }
    
    // 週2: 2回戦（32校、16試合）
    int secondWeek = week + 1;
    int secondMonth = month;
    if (secondWeek > 4) {
      secondWeek = 1;
      secondMonth++;
    }
    
    // シード校（17校）と1回戦の勝者（15校）を組み合わせ
    final seededSchools = schools.skip(30).take(17).toList();
    final firstRoundWinners = schools.take(15).toList(); // 1回戦の勝者（仮）
    
    for (int i = 0; i < 16; i++) {
      final game = TournamentGame(
        id: 'game_${secondMonth}_${secondWeek}_secondRound_${i}',
        homeSchoolId: i < 17 ? seededSchools[i].id : firstRoundWinners[i - 17].id,
        awaySchoolId: i < 15 ? firstRoundWinners[i].id : seededSchools[i - 15].id,
        round: GameRound.secondRound,
        month: secondMonth,
        week: secondWeek,
        dayOfWeek: i % 7 + 1,
        isCompleted: false,
        result: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      games.add(game);
    }
    
    // 週3: 3回戦（16校、8試合）
    int thirdWeek = secondWeek + 1;
    int thirdMonth = secondMonth;
    if (thirdWeek > 4) {
      thirdWeek = 1;
      thirdMonth++;
    }
    final thirdRoundGames = _generateThirdRoundGames(schools, thirdMonth, thirdWeek, random);
    games.addAll(thirdRoundGames);
    
    // 週4: 準々決勝（8校、4試合）
    int fourthWeek = thirdWeek + 1;
    int fourthMonth = thirdMonth;
    if (fourthWeek > 4) {
      fourthWeek = 1;
      fourthMonth++;
    }
    final quarterFinalGames = _generateQuarterFinalGames(schools, fourthMonth, fourthWeek, random);
    games.addAll(quarterFinalGames);
    
    // 週5: 準決勝（4校、2試合）
    int fifthWeek = fourthWeek + 1;
    int fifthMonth = fourthMonth;
    if (fifthWeek > 4) {
      fifthWeek = 1;
      fifthMonth++;
    }
    final semiFinalGames = _generateSemiFinalGames(schools, fifthMonth, fifthWeek, random);
    games.addAll(semiFinalGames);
    
    // 週6: 決勝（2校、1試合）
    int sixthWeek = fifthWeek + 1;
    int sixthMonth = fifthMonth;
    if (sixthWeek > 4) {
      sixthWeek = 1;
      sixthMonth++;
    }
    final championshipGames = _generateChampionshipGames(schools, sixthMonth, sixthWeek, random);
    games.addAll(championshipGames);
    
    return TournamentSchedule(
      id: 'schedule_${year}_${type.name}_national',
      year: year,
      type: type,
      stage: TournamentStage.national,
      games: games,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 1回戦の試合を生成（16試合）
  static List<TournamentGame> _generateFirstRoundGames(
    List<School> schools,
    int month,
    int week,
    Random random,
  ) {
    final games = <TournamentGame>[];
    
    // 32校をランダムにシャッフル
    final shuffledSchools = List<School>.from(schools)..shuffle(random);
    
    // 1回戦の組み合わせ（16試合）
    for (int i = 0; i < 32; i += 2) {
            final game = TournamentGame(
        id: 'game_${month}_${week}_firstRound_${i ~/ 2}',
        homeSchoolId: shuffledSchools[i].id,
        awaySchoolId: shuffledSchools[i + 1].id,
        round: GameRound.firstRound,
              month: month,
              week: week,
              dayOfWeek: (i ~/ 2) % 7 + 1,
              isCompleted: false,
              result: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            games.add(game);
    }
    
    return games;
  }

  /// 2回戦の試合を生成（8試合）
  static List<TournamentGame> _generateSecondRoundGames(
    List<School> schools,
    int month,
    int week,
    Random random,
  ) {
    final games = <TournamentGame>[];
    
    // 2回戦の組み合わせ（8試合）
    // 1回戦の勝者16校をプレースホルダーIDで組み合わせ
    for (int i = 0; i < 16; i += 2) {
          final game = TournamentGame(
        id: 'game_${month}_${week}_secondRound_${i ~/ 2}',
        homeSchoolId: 'winner_${i}_first',
        awaySchoolId: 'winner_${i + 1}_first',
        round: GameRound.secondRound,
            month: month,
            week: week,
        dayOfWeek: (i ~/ 2) % 7 + 1,
            isCompleted: false,
            result: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          games.add(game);
        }
        
    return games;
  }

  /// 3回戦の試合を生成（8試合）
  static List<TournamentGame> _generateThirdRoundGames(
    List<School> schools,
    int month,
    int week,
    Random random,
  ) {
    final games = <TournamentGame>[];
    
    // 3回戦の組み合わせ（8試合）
    // 2回戦の勝者16校をプレースホルダーIDで組み合わせ
    for (int i = 0; i < 16; i += 2) {
          final game = TournamentGame(
        id: 'game_${month}_${week}_thirdRound_${i ~/ 2}',
        homeSchoolId: 'winner_${i}_second',
        awaySchoolId: 'winner_${i + 1}_second',
        round: GameRound.thirdRound,
            month: month,
            week: week,
        dayOfWeek: (i ~/ 2) % 7 + 1,
            isCompleted: false,
            result: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          games.add(game);
        }
    
    return games;
  }

  /// 準々決勝の試合を生成（4試合）
  static List<TournamentGame> _generateQuarterFinalGames(
    List<School> schools,
    int month,
    int week,
    Random random,
  ) {
    final games = <TournamentGame>[];
    
    // 準々決勝の組み合わせ（4試合）
    // 前ラウンドの勝者8校をプレースホルダーIDで組み合わせ
    for (int i = 0; i < 8; i += 2) {
          final game = TournamentGame(
        id: 'game_${month}_${week}_quarterFinal_${i ~/ 2}',
        homeSchoolId: 'winner_${i}_previous',
        awaySchoolId: 'winner_${i + 1}_previous',
        round: GameRound.quarterFinal,
            month: month,
            week: week,
        dayOfWeek: (i ~/ 2) % 7 + 1,
            isCompleted: false,
            result: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          games.add(game);
        }
    
    return games;
  }

  /// 準決勝の試合を生成（2試合）
  static List<TournamentGame> _generateSemiFinalGames(
    List<School> schools,
    int month,
    int week,
    Random random,
  ) {
    final games = <TournamentGame>[];
    
    // 準決勝の組み合わせ（2試合）
    // 準々決勝の勝者4校をプレースホルダーIDで組み合わせ
    for (int i = 0; i < 4; i += 2) {
        final game = TournamentGame(
        id: 'game_${month}_${week}_semiFinal_${i ~/ 2}',
        homeSchoolId: 'winner_${i}_quarter',
        awaySchoolId: 'winner_${i + 1}_quarter',
        round: GameRound.semiFinal,
          month: month,
          week: week,
        dayOfWeek: (i ~/ 2) % 7 + 1,
          isCompleted: false,
          result: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        games.add(game);
    }
    
    return games;
  }

  /// 決勝の試合を生成（1試合）
  static List<TournamentGame> _generateChampionshipGames(
    List<School> schools,
    int month,
    int week,
    Random random,
  ) {
    final games = <TournamentGame>[];
    
    // 決勝の組み合わせ（1試合）
    // 準決勝の勝者2校をプレースホルダーIDで組み合わせ
    final game = TournamentGame(
      id: 'game_${month}_${week}_championship_0',
      homeSchoolId: 'winner_0_semi',
      awaySchoolId: 'winner_1_semi',
      round: GameRound.championship,
          month: month,
          week: week,
      dayOfWeek: 1,
          isCompleted: false,
          result: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
    );
    games.add(game);
    
    return games;
  }

  /// 初期順位表を作成
  static Map<String, SchoolStanding> _createInitialStandings(List<School> schools) {
    final standings = <String, SchoolStanding>{};
    
    for (final school in schools) {
      standings[school.id] = SchoolStanding(
        schoolId: school.id,
        schoolName: school.name,
        schoolShortName: school.shortName,
        games: 0,
        wins: 0,
        losses: 0,
        winningPercentage: 0.0,
        runsScored: 0,
        runsAllowed: 0,
        runDifferential: 0,
        bestResult: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    return standings;
  }

  /// 試合をシミュレート
  static TournamentGameResult _simulateGame(TournamentGame game, List<School> schools) {
    final homeSchool = schools.firstWhere((s) => s.id == game.homeSchoolId);
    final awaySchool = schools.firstWhere((s) => s.id == game.awaySchoolId);
    
    // 学校の能力値を考慮したシミュレーション
    final random = Random();
    
    // チーム強度を計算（学校ランクベース + 生成選手のボーナス）
    final homeTeamStrength = _calculateTeamStrength(homeSchool);
    final awayTeamStrength = _calculateTeamStrength(awaySchool);
    
    // ホームアドバンテージを適用（5%のボーナス）
    final homeStrength = homeTeamStrength * 1.05;
    final awayStrength = awayTeamStrength;
    
    // 能力値に基づいた得点計算
    final homeScore = _calculateScore(homeStrength, random);
    final awayScore = _calculateScore(awayStrength, random);
    
    // 勝敗判定（引き分けの場合は延長戦をシミュレート）
    String winnerSchoolId;
    String loserSchoolId;
    
    if (homeScore > awayScore) {
      winnerSchoolId = homeSchool.id;
      loserSchoolId = awaySchool.id;
    } else if (awayScore > homeScore) {
      winnerSchoolId = awaySchool.id;
      loserSchoolId = homeSchool.id;
    } else {
      // 引き分けの場合は延長戦（追加得点）
      final homeExtraScore = _calculateScore(homeStrength * 0.8, random);
      final awayExtraScore = _calculateScore(awayStrength * 0.8, random);
      
      if (homeExtraScore > awayExtraScore) {
        winnerSchoolId = homeSchool.id;
        loserSchoolId = awaySchool.id;
      } else if (awayExtraScore > homeExtraScore) {
        winnerSchoolId = awaySchool.id;
        loserSchoolId = homeSchool.id;
      } else {
        // 再延長でも引き分けの場合は、ランクの高い方が勝者
        if (homeSchool.rank.value >= awaySchool.rank.value) {
          winnerSchoolId = homeSchool.id;
          loserSchoolId = awaySchool.id;
        } else {
          winnerSchoolId = awaySchool.id;
          loserSchoolId = homeSchool.id;
        }
      }
    }
    
    return TournamentGameResult(
      homeScore: homeScore,
      awayScore: awayScore,
      homeSchoolId: homeSchool.id,
      awaySchoolId: awaySchool.id,
      winnerSchoolId: winnerSchoolId,
      loserSchoolId: loserSchoolId,
      createdAt: DateTime.now(),
    );
  }

  /// チーム強度を計算（学校ランクベース + 生成選手のボーナス）
  static double _calculateTeamStrength(School school) {
    // 学校ランクに基づく基本強度
    final baseStrength = _getBaseStrengthFromRank(school.rank);
    
    // 生成選手（スカウトが発見した有望選手）のボーナスを計算
    final generatedPlayerBonus = _calculateGeneratedPlayerBonus(school);
    
    return baseStrength + generatedPlayerBonus;
  }
  
  /// 学校ランクから基本強度を取得
  static double _getBaseStrengthFromRank(SchoolRank rank) {
    switch (rank) {
      case SchoolRank.elite:
        return 70.0;  // 名門校
      case SchoolRank.strong:
        return 60.0;  // 強豪校
      case SchoolRank.average:
        return 50.0;  // 中堅校
      case SchoolRank.weak:
        return 40.0;  // 弱小校
    }
  }
  
  /// 生成選手（スカウトが発見した有望選手）のボーナスを計算
  static double _calculateGeneratedPlayerBonus(School school) {
    if (school.players.isEmpty) {
      return 0.0;
    }
    
    // 学校ランクに応じた基準overall値を設定
    final schoolStandardOverall = _getSchoolStandardOverall(school.rank);
    
    // 生成選手の総合能力値の平均を計算（overall値を使用）
    double totalOverall = 0.0;
    for (final player in school.players) {
      totalOverall += player.overall;
    }
    
    final averageOverall = totalOverall / school.players.length;
    
    // 学校の基準値以上の選手のみがボーナスを与える
    if (averageOverall <= schoolStandardOverall) {
      return 0.0; // 基準値以下または同等の場合は影響なし
    }
    
    // 基準値を超えた分の1/2をボーナスとして追加
    final bonus = (averageOverall - schoolStandardOverall) * 0.5;
    
    return bonus;
  }
  
  /// 学校ランクに応じた基準overall値を取得
  static double _getSchoolStandardOverall(SchoolRank rank) {
    switch (rank) {
      case SchoolRank.elite:
        return 70.0;  // 名門校の基準
      case SchoolRank.strong:
        return 60.0;  // 強豪校の基準
      case SchoolRank.average:
        return 50.0;  // 中堅校の基準
      case SchoolRank.weak:
        return 40.0;  // 弱小校の基準
    }
  }
  
  /// 能力値に基づいた得点を計算
  static int _calculateScore(double strength, Random random) {
    // 基本得点（能力値に比例、より現実的な範囲）
    final baseScore = (strength * 0.15).round(); // 40-70の強度で6-10点程度
    
    // ランダム変動（-3から+3）
    final randomVariation = random.nextInt(7) - 3;
    
    final finalScore = (baseScore + randomVariation).clamp(0, 15);
    return finalScore;
  }

  /// 順位表を更新
  static void _updateStandings(
    Map<String, SchoolStanding> standings,
    TournamentGameResult result,
    List<School> schools,
  ) {
    final homeSchool = schools.firstWhere((s) => s.id == result.homeSchoolId);
    final awaySchool = schools.firstWhere((s) => s.id == result.awaySchoolId);
    
    // ホーム校の更新
    final homeStanding = standings[homeSchool.id]!;
    standings[homeSchool.id] = homeStanding.copyWith(
      games: homeStanding.games + 1,
      wins: homeStanding.wins + (result.homeScore > result.awayScore ? 1 : 0),
      losses: homeStanding.losses + (result.homeScore < result.awayScore ? 1 : 0),
      runsScored: homeStanding.runsScored + result.homeScore,
      runsAllowed: homeStanding.runsAllowed + result.awayScore,
      runDifferential: (homeStanding.runsScored + result.homeScore) - (homeStanding.runsAllowed + result.awayScore),
        updatedAt: DateTime.now(),
      );
      
    // アウェイ校の更新
    final awayStanding = standings[awaySchool.id]!;
    standings[awaySchool.id] = awayStanding.copyWith(
      games: awayStanding.games + 1,
      wins: awayStanding.wins + (result.awayScore > result.homeScore ? 1 : 0),
      losses: awayStanding.losses + (result.awayScore < result.homeScore ? 1 : 0),
      runsScored: awayStanding.runsScored + result.awayScore,
      runsAllowed: awayStanding.runsAllowed + result.homeScore,
      runDifferential: (awayStanding.runsScored + result.awayScore) - (awayStanding.runsAllowed + result.homeScore),
      updatedAt: DateTime.now(),
    );
  }

  /// トーナメントの効率を評価
  static TournamentEfficiency evaluateTournamentEfficiency(
    HighSchoolTournament tournament,
    int currentMonth,
    int currentWeek,
  ) {
    if (tournament.isCompleted) {
      return TournamentEfficiency(
        efficiencyScore: 1.0,
        efficiencyLevel: '完了',
        overallProgressRate: 1.0,
        isOnSchedule: true,
        estimatedRemainingWeeks: 0,
        recommendations: ['大会が完了しました'],
        detailedAnalysis: '全ての試合が完了しています',
      );
    }
    
    final totalGames = tournament.games.length;
    final completedGames = tournament.completedGames.length;
    
    if (totalGames == 0) {
      return TournamentEfficiency(
        efficiencyScore: 0.0,
        efficiencyLevel: '未開始',
        overallProgressRate: 0.0,
        isOnSchedule: true,
        estimatedRemainingWeeks: 3,
        recommendations: ['大会を開始してください'],
        detailedAnalysis: '試合がまだ開始されていません',
      );
    }
    
    final progressRate = completedGames / totalGames;
    final remainingGames = totalGames - completedGames;
    final estimatedWeeks = (remainingGames / 2).ceil(); // 1週間で2ラウンド想定
    
    String efficiencyLevel;
    List<String> recommendations;
    
    if (progressRate >= 0.8) {
      efficiencyLevel = '良好';
      recommendations = ['順調に進行しています'];
    } else if (progressRate >= 0.5) {
      efficiencyLevel = '普通';
      recommendations = ['ペースを維持してください'];
        } else {
      efficiencyLevel = '遅延';
      recommendations = ['進行を加速する必要があります'];
    }
    
    return TournamentEfficiency(
      efficiencyScore: progressRate,
      efficiencyLevel: efficiencyLevel,
      overallProgressRate: progressRate,
      isOnSchedule: estimatedWeeks <= 2,
      estimatedRemainingWeeks: estimatedWeeks,
      recommendations: recommendations,
      detailedAnalysis: '完了試合: $completedGames/$totalGames (${(progressRate * 100).toStringAsFixed(1)}%)',
    );
  }
}

/// トーナメント効率評価結果
class TournamentEfficiency {
  final double efficiencyScore;
  final String efficiencyLevel;
  final double overallProgressRate;
  final bool isOnSchedule;
  final int estimatedRemainingWeeks;
  final List<String> recommendations;
  final String detailedAnalysis;

  const TournamentEfficiency({
    required this.efficiencyScore,
    required this.efficiencyLevel,
    required this.overallProgressRate,
    required this.isOnSchedule,
    required this.estimatedRemainingWeeks,
    required this.recommendations,
    required this.detailedAnalysis,
  });
}