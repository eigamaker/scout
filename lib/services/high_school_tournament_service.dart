import 'dart:math';
import '../models/game/high_school_tournament.dart';
import '../models/school/school.dart';

class HighSchoolTournamentService {
  static const int _maxPrefecturalSchools = 50; // 県大会出場校数
  static const int _maxNationalSchools = 47; // 全国大会出場校数
  static const int _seededSchools = 17; // 全国大会シード校数

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

  /// 春の大会を作成
  static HighSchoolTournament createSpringTournament(
    int year,
    List<School> schools,
    int month,
    int week,
  ) {
    final tournamentId = 'spring_${year}_${month}_${week}';
    final participatingSchools = _selectParticipatingSchools(schools, _maxPrefecturalSchools);
    
    final schedule = _generatePrefecturalSchedule(
      year,
      month,
      week,
      participatingSchools,
      TournamentType.spring,
    );
    
    final standings = _createInitialStandings(participatingSchools);
    
    return HighSchoolTournament(
      id: tournamentId,
      year: year,
      type: TournamentType.spring,
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

  /// 夏の大会を作成
  static HighSchoolTournament createSummerTournament(
    int year,
    List<School> schools,
    int month,
    int week,
  ) {
            final tournamentId = 'summer_${year}_${month}_${week}';
    final participatingSchools = _selectParticipatingSchools(schools, _maxPrefecturalSchools);
    
    final schedule = _generatePrefecturalSchedule(
      year,
      month,
      week,
      participatingSchools,
      TournamentType.summer,
    );
    
    final standings = _createInitialStandings(participatingSchools);
    
    return HighSchoolTournament(
      id: tournamentId,
      year: year,
      type: TournamentType.summer,
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

  /// 秋の大会を作成
  static HighSchoolTournament createAutumnTournament(
    int year,
    List<School> schools,
    int month,
    int week,
  ) {
            final tournamentId = 'autumn_${year}_${month}_${week}';
    final participatingSchools = _selectParticipatingSchools(schools, _maxPrefecturalSchools);
    
    final schedule = _generatePrefecturalSchedule(
      year,
      month,
      week,
      participatingSchools,
      TournamentType.autumn,
    );
    
    final standings = _createInitialStandings(participatingSchools);
    
    return HighSchoolTournament(
      id: tournamentId,
      year: year,
      type: TournamentType.autumn,
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

  /// 指定週の試合を実行
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
    final allGames = List<TournamentGame>.from(tournament.games);
    
    // 今週の試合を実行
    for (int i = 0; i < allGames.length; i++) {
      final game = allGames[i];
      if (game.month == month && game.week == week && !game.isCompleted) {
        final result = _simulateGame(game, schools);
        final completedGame = game.completeGame(result);
        allGames[i] = completedGame;
        newCompletedGames.add(completedGame);
        
        // 順位表を更新
        _updateStandings(newStandings, result, schools);
        
        // 敗者校を敗退校リストに追加
        if (result.loserSchoolId != null) {
          newEliminatedSchools.add(result.loserSchoolId!);
        }
      }
    }
    
    // 大会が完了したかチェック
    final isCompleted = allGames.every((game) => game.isCompleted);
    String? championSchoolId;
    String? runnerUpSchoolId;
    
    if (isCompleted) {
      final finalGame = allGames.last;
      if (finalGame.result != null) {
        championSchoolId = finalGame.result!.winnerSchoolId;
        runnerUpSchoolId = finalGame.result!.loserSchoolId;
      }
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

  /// トーナメントの進行状況を取得
  static TournamentProgress getTournamentProgress(HighSchoolTournament tournament) {
    final allGames = tournament.games;
    final completedGames = allGames.where((game) => game.isCompleted).toList();
    final uncompletedGames = allGames.where((game) => !game.isCompleted).toList();
    
    // 現在のラウンドを特定
    GameRound? currentRound;
    GameRound? nextRound;
    
    if (uncompletedGames.isNotEmpty) {
      // 未完了の試合のうち、最も早いラウンドが現在のラウンド
      final earliestUncompletedRound = uncompletedGames
          .map((game) => game.round)
          .reduce((a, b) => a.index < b.index ? a : b);
      currentRound = earliestUncompletedRound;
      
      // 次のラウンドを特定
      final roundOrder = [
        GameRound.firstRound,
        GameRound.secondRound,
        GameRound.thirdRound,
        GameRound.quarterFinal,
        GameRound.semiFinal,
        GameRound.championship,
      ];
      
      final currentIndex = roundOrder.indexOf(currentRound);
      if (currentIndex < roundOrder.length - 1) {
        nextRound = roundOrder[currentIndex + 1];
      }
    }
    
    // 各ラウンドの進行状況を計算
    final roundProgress = <GameRound, RoundProgress>{};
    for (final round in GameRound.values) {
      final roundGames = allGames.where((game) => game.round == round).toList();
      final completedRoundGames = roundGames.where((game) => game.isCompleted).toList();
      
      roundProgress[round] = RoundProgress(
        round: round,
        totalGames: roundGames.length,
        completedGames: completedRoundGames.length,
        isCompleted: completedRoundGames.length == roundGames.length,
        remainingGames: roundGames.length - completedRoundGames.length,
      );
    }
    
    // 次の試合予定を取得
    final nextGames = <TournamentGame>[];
    if (uncompletedGames.isNotEmpty) {
      // 日付順でソートして、最も早い未完了試合を取得
      final sortedUncompleted = List<TournamentGame>.from(uncompletedGames);
      sortedUncompleted.sort((a, b) {
        if (a.month != b.month) return a.month.compareTo(b.month);
        if (a.week != b.week) return a.week.compareTo(b.week);
        return a.dayOfWeek.compareTo(b.dayOfWeek);
      });
      
      // 次の3試合を取得
      nextGames.addAll(sortedUncompleted.take(3));
    }
    
    return TournamentProgress(
      currentRound: currentRound,
      nextRound: nextRound,
      totalGames: allGames.length,
      completedGames: completedGames.length,
      remainingGames: uncompletedGames.length,
      roundProgress: roundProgress,
      nextGames: nextGames,
      isCompleted: tournament.isCompleted,
      championSchoolId: tournament.championSchoolId,
      runnerUpSchoolId: tournament.runnerUpSchoolId,
    );
  }

  /// 指定ラウンドの進行状況を取得
  static RoundProgress getRoundProgress(HighSchoolTournament tournament, GameRound round) {
    final roundGames = tournament.games.where((game) => game.round == round).toList();
    final completedGames = roundGames.where((game) => game.isCompleted).toList();
    
    return RoundProgress(
      round: round,
      totalGames: roundGames.length,
      completedGames: completedGames.length,
      isCompleted: completedGames.length == roundGames.length,
      remainingGames: roundGames.length - completedGames.length,
    );
  }

  /// 次の試合予定を取得
  static List<TournamentGame> getNextGames(HighSchoolTournament tournament, {int limit = 5}) {
    final uncompletedGames = tournament.games.where((game) => !game.isCompleted).toList();
    
    if (uncompletedGames.isEmpty) return [];
    
    // 日付順でソート
    final sortedGames = List<TournamentGame>.from(uncompletedGames);
    sortedGames.sort((a, b) {
      if (a.month != b.month) return a.month.compareTo(b.month);
      if (a.week != b.week) return a.week.compareTo(b.week);
      return a.dayOfWeek.compareTo(b.dayOfWeek);
    });
    
    return sortedGames.take(limit).toList();
  }

  /// 大会の完了予定日を取得
  static DateTime? getEstimatedCompletionDate(HighSchoolTournament tournament) {
    final uncompletedGames = tournament.games.where((game) => !game.isCompleted).toList();
    
    if (uncompletedGames.isEmpty) return null;
    
    // 最も遅い未完了試合の日付を取得
    final latestGame = uncompletedGames.reduce((a, b) {
      if (a.month != b.month) return a.month > b.month ? a : b;
      if (a.week != b.week) return a.week > b.week ? a : b;
      return a.dayOfWeek > b.dayOfWeek ? a : b;
    });
    
    // 仮の年を設定（実際のゲーム年を使用）
    final year = tournament.year;
    final month = latestGame.month;
    final week = latestGame.week;
    
    // 週の開始日を計算（簡易的な計算）
    final daysFromStart = (month - 1) * 28 + (week - 1) * 7;
    return DateTime(year, 1, 1).add(Duration(days: daysFromStart));
  }

  /// 大会の進行状況を予測
  static TournamentProgressPrediction predictTournamentProgress(
    HighSchoolTournament tournament,
    int currentMonth,
    int currentWeek,
  ) {
    final progress = getTournamentProgress(tournament);
    final uncompletedGames = tournament.games.where((game) => !game.isCompleted).toList();
    
    if (uncompletedGames.isEmpty) {
      return TournamentProgressPrediction(
        estimatedCompletionMonth: currentMonth,
        estimatedCompletionWeek: currentWeek,
        estimatedRemainingWeeks: 0,
        isOnSchedule: true,
        recommendedActions: [],
      );
    }
    
    // 未完了試合を日付順でソート
    final sortedGames = List<TournamentGame>.from(uncompletedGames);
    sortedGames.sort((a, b) {
      if (a.month != b.month) return a.month.compareTo(b.month);
      if (a.week != b.week) return a.week.compareTo(b.week);
      return a.dayOfWeek.compareTo(b.dayOfWeek);
    });
    
    // 最も遅い試合の予定日を取得
    final latestGame = sortedGames.last;
    final estimatedCompletionMonth = latestGame.month;
    final estimatedCompletionWeek = latestGame.week;
    
    // 現在から完了予定までの週数を計算
    final currentTotalWeeks = (currentMonth - 1) * 4 + currentWeek;
    final completionTotalWeeks = (estimatedCompletionMonth - 1) * 4 + estimatedCompletionWeek;
    final estimatedRemainingWeeks = completionTotalWeeks - currentTotalWeeks;
    
    // スケジュール通りに進行しているかチェック
    final isOnSchedule = estimatedRemainingWeeks >= 0;
    
    // 推奨アクションを生成
    final recommendedActions = <String>[];
    
    if (!isOnSchedule) {
      recommendedActions.add('進行が遅れています。今週の試合を集中して実行してください。');
    }
    
    if (estimatedRemainingWeeks > 4) {
      recommendedActions.add('大会完了まで${estimatedRemainingWeeks}週かかります。');
    }
    
    // 現在のラウンドが長期間停滞している場合
    if (progress.currentRound != null) {
      final currentRoundProgress = progress.getRoundProgress(progress.currentRound!);
      if (currentRoundProgress != null && currentRoundProgress.remainingGames > 0) {
        final weeksInCurrentRound = _estimateWeeksInRound(progress.currentRound!);
        if (weeksInCurrentRound > 2) {
          recommendedActions.add('${progress.currentRoundName}が長期間停滞しています。');
        }
      }
    }
    
    return TournamentProgressPrediction(
      estimatedCompletionMonth: estimatedCompletionMonth,
      estimatedCompletionWeek: estimatedCompletionWeek,
      estimatedRemainingWeeks: estimatedRemainingWeeks,
      isOnSchedule: isOnSchedule,
      recommendedActions: recommendedActions,
    );
  }

  /// ラウンドに必要な週数を推定
  static int _estimateWeeksInRound(GameRound round) {
    switch (round) {
      case GameRound.firstRound:
        return 2; // 1回戦は2週程度
      case GameRound.secondRound:
        return 2; // 2回戦は2週程度
      case GameRound.thirdRound:
        return 1; // 3回戦は1週程度
      case GameRound.quarterFinal:
        return 1; // 準々決勝は1週程度
      case GameRound.semiFinal:
        return 1; // 準決勝は1週程度
      case GameRound.championship:
        return 1; // 決勝は1週程度
    }
  }

  /// 進行が遅れている大会を自動調整
  static HighSchoolTournament autoAdjustSlowTournament(
    HighSchoolTournament tournament,
    int currentMonth,
    int currentWeek,
  ) {
    final prediction = predictTournamentProgress(tournament, currentMonth, currentWeek);
    
    if (prediction.isOnSchedule) {
      return tournament; // 調整不要
    }
    
    print('HighSchoolTournamentService.autoAdjustSlowTournament: 進行遅延を検出 - 完了予定: ${prediction.estimatedCompletionMonth}月${prediction.estimatedCompletionWeek}週');
    
    // 未完了試合を現在の週に集中させる
    final uncompletedGames = tournament.games.where((game) => !game.isCompleted).toList();
    final adjustedGames = <TournamentGame>[];
    
    for (final game in tournament.games) {
      if (game.isCompleted) {
        adjustedGames.add(game);
      } else {
        // 未完了試合を現在の週に移動
        final adjustedGame = game.copyWith(
          month: currentMonth,
          week: currentWeek,
          dayOfWeek: (adjustedGames.length % 7) + 1, // 曜日を分散
        );
        adjustedGames.add(adjustedGame);
      }
    }
    
    return tournament.copyWith(
      games: adjustedGames,
      updatedAt: DateTime.now(),
    );
  }

  /// 大会の進行効率を評価
  static TournamentEfficiencyRating evaluateTournamentEfficiency(
    HighSchoolTournament tournament,
    int currentMonth,
    int currentWeek,
  ) {
    final progress = getTournamentProgress(tournament);
    final prediction = predictTournamentProgress(tournament, currentMonth, currentWeek);
    
    // 効率性スコアを計算（0.0 ~ 1.0）
    double efficiencyScore = 1.0;
    
    // 進行率に基づくスコア
    efficiencyScore *= progress.overallProgressRate;
    
    // スケジュール遵守度に基づくスコア
    if (prediction.isOnSchedule) {
      efficiencyScore *= 1.0;
    } else {
      efficiencyScore *= 0.5; // 遅延している場合は減点
    }
    
    // ラウンド進行の効率性
    final roundEfficiency = _calculateRoundEfficiency(progress);
    efficiencyScore *= roundEfficiency;
    
    // 効率性レベルを判定
    String efficiencyLevel;
    if (efficiencyScore >= 0.8) {
      efficiencyLevel = '優秀';
    } else if (efficiencyScore >= 0.6) {
      efficiencyLevel = '良好';
    } else if (efficiencyScore >= 0.4) {
      efficiencyLevel = '普通';
    } else if (efficiencyScore >= 0.2) {
      efficiencyLevel = '要改善';
    } else {
      efficiencyLevel = '問題あり';
    }
    
    return TournamentEfficiencyRating(
      efficiencyScore: efficiencyScore,
      efficiencyLevel: efficiencyLevel,
      overallProgressRate: progress.overallProgressPercentage,
      isOnSchedule: prediction.isOnSchedule,
      estimatedRemainingWeeks: prediction.estimatedRemainingWeeks,
      recommendations: prediction.recommendedActions,
    );
  }

  /// ラウンド進行の効率性を計算
  static double _calculateRoundEfficiency(TournamentProgress progress) {
    if (progress.roundProgress.isEmpty) return 1.0;
    
    double totalEfficiency = 0.0;
    int roundCount = 0;
    
    for (final roundProgress in progress.roundProgress.values) {
      if (roundProgress.totalGames > 0) {
        totalEfficiency += roundProgress.progressRate;
        roundCount++;
      }
    }
    
    return roundCount > 0 ? totalEfficiency / roundCount : 1.0;
  }

  /// 出場校を選択
  static List<School> _selectParticipatingSchools(List<School> schools, int maxSchools) {
    // 学校のランクに基づいて選択
    final sortedSchools = List<School>.from(schools);
    sortedSchools.sort((a, b) => b.rank.compareTo(a.rank));
    
    return sortedSchools.take(maxSchools).toList();
  }

  /// 県大会スケジュールを生成
  static TournamentSchedule _generatePrefecturalSchedule(
    int year,
    int month,
    int week,
    List<School> schools,
    TournamentType type,
  ) {
    final games = <TournamentGame>[];
    final random = Random(year * 1000 + month * 100 + week);
    
    // トーナメント方式でスケジュールを生成
    final rounds = [
      GameRound.firstRound,
      GameRound.secondRound,
      GameRound.thirdRound,
      GameRound.quarterFinal,
      GameRound.semiFinal,
      GameRound.championship,
    ];
    
    // 固定スケジュール: 3週間で6試合を配分
    // 1週目: 1回戦・2回戦
    // 2週目: 3回戦・準々決勝  
    // 3週目: 準決勝・決勝
    
    // 1週目: 1回戦・2回戦
    final firstWeekGames = [
      ..._generateRoundGames(GameRound.firstRound, schools, month, week, random),
      ..._generateRoundGames(GameRound.secondRound, schools, month, week, random),
    ];
    games.addAll(firstWeekGames);
    
    // 2週目: 3回戦・準々決勝
    int secondWeek = week + 1;
    int secondMonth = month;
    if (secondWeek > 4) {
      secondWeek = 1;
      secondMonth++;
    }
    
    final secondWeekGames = [
      ..._generateRoundGames(GameRound.thirdRound, schools, secondMonth, secondWeek, random),
      ..._generateRoundGames(GameRound.quarterFinal, schools, secondMonth, secondWeek, random),
    ];
    games.addAll(secondWeekGames);
    
    // 3週目: 準決勝・決勝
    int thirdWeek = secondWeek + 1;
    int thirdMonth = secondMonth;
    if (thirdWeek > 4) {
      thirdWeek = 1;
      thirdMonth++;
    }
    
    final thirdWeekGames = [
      ..._generateRoundGames(GameRound.semiFinal, schools, thirdMonth, thirdWeek, random),
      ..._generateRoundGames(GameRound.championship, schools, thirdMonth, thirdWeek, random),
    ];
    games.addAll(thirdWeekGames);
    
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

  /// 全国大会スケジュールを生成
  static TournamentSchedule _generateNationalSchedule(
    int year,
    int month,
    int week,
    List<School> schools,
    TournamentType type,
  ) {
    final games = <TournamentGame>[];
    final random = Random(year * 1000 + month * 100 + week);
    
    // 全国大会も同様の固定スケジュール
    // 1週目: 1回戦・2回戦
    // 2週目: 3回戦・準々決勝
    // 3週目: 準決勝・決勝
    
    // 1週目: 1回戦・2回戦
    final firstWeekGames = [
      ..._generateRoundGames(GameRound.firstRound, schools, month, week, random),
      ..._generateRoundGames(GameRound.secondRound, schools, month, week, random),
    ];
    games.addAll(firstWeekGames);
    
    // 2週目: 3回戦・準々決勝
    int secondWeek = week + 1;
    int secondMonth = month;
    if (secondWeek > 4) {
      secondWeek = 1;
      secondMonth++;
    }
    
    final secondWeekGames = [
      ..._generateRoundGames(GameRound.thirdRound, schools, secondMonth, secondWeek, random),
      ..._generateRoundGames(GameRound.quarterFinal, schools, secondMonth, secondWeek, random),
    ];
    games.addAll(secondWeekGames);
    
    // 3週目: 準決勝・決勝
    int thirdWeek = secondWeek + 1;
    int thirdMonth = secondMonth;
    if (thirdWeek > 4) {
      thirdWeek = 1;
      thirdMonth++;
    }
    
    final thirdWeekGames = [
      ..._generateRoundGames(GameRound.semiFinal, schools, thirdMonth, thirdWeek, random),
      ..._generateRoundGames(GameRound.championship, schools, thirdMonth, thirdWeek, random),
    ];
    games.addAll(thirdWeekGames);
    
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

  /// 指定段階の試合を生成
  static List<TournamentGame> _generateRoundGames(
    GameRound round,
    List<School> schools,
    int month,
    int week,
    Random random,
  ) {
    final games = <TournamentGame>[];
    
    switch (round) {
      case GameRound.firstRound:
        // 1回戦: 36校 + 14校シード
        final firstRoundSchools = schools.take(36).toList();
        final seededSchools = schools.skip(36).take(14).toList();
        
        // 1回戦の組み合わせ
        for (int i = 0; i < firstRoundSchools.length; i += 2) {
          if (i + 1 < firstRoundSchools.length) {
            final game = TournamentGame(
              id: 'game_${month}_${week}_${round.name}_${i ~/ 2}',
              homeSchoolId: firstRoundSchools[i].id,
              awaySchoolId: firstRoundSchools[i + 1].id,
              round: round,
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
        }
        break;
        
      case GameRound.secondRound:
        // 2回戦: 32校
        final secondRoundSchools = schools.take(32).toList();
        for (int i = 0; i < secondRoundSchools.length; i += 2) {
          if (i + 1 < secondRoundSchools.length) {
            final game = TournamentGame(
              id: 'game_${month}_${week}_${round.name}_${i ~/ 2}',
              homeSchoolId: secondRoundSchools[i].id,
              awaySchoolId: secondRoundSchools[i + 1].id,
              round: round,
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
        }
        break;
        
      case GameRound.thirdRound:
        // 3回戦: 16校
        final thirdRoundSchools = schools.take(16).toList();
        for (int i = 0; i < thirdRoundSchools.length; i += 2) {
          if (i + 1 < thirdRoundSchools.length) {
            final game = TournamentGame(
              id: 'game_${month}_${week}_${round.name}_${i ~/ 2}',
              homeSchoolId: thirdRoundSchools[i].id,
              awaySchoolId: thirdRoundSchools[i + 1].id,
              round: round,
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
        }
        break;
        
      case GameRound.quarterFinal:
        // 準々決勝: 8校
        final quarterFinalSchools = schools.take(8).toList();
        for (int i = 0; i < quarterFinalSchools.length; i += 2) {
          if (i + 1 < quarterFinalSchools.length) {
            final game = TournamentGame(
              id: 'game_${month}_${week}_${round.name}_${i ~/ 2}',
              homeSchoolId: quarterFinalSchools[i].id,
              awaySchoolId: quarterFinalSchools[i + 1].id,
              round: round,
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
        }
        break;
        
      case GameRound.semiFinal:
        // 準決勝: 4校
        final semiFinalSchools = schools.take(4).toList();
        for (int i = 0; i < semiFinalSchools.length; i += 2) {
          if (i + 1 < semiFinalSchools.length) {
            final game = TournamentGame(
              id: 'game_${month}_${week}_${round.name}_${i ~/ 2}',
              homeSchoolId: semiFinalSchools[i].id,
              awaySchoolId: semiFinalSchools[i + 1].id,
              round: round,
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
        }
        break;
        
      case GameRound.championship:
        // 決勝: 2校
        if (schools.length >= 2) {
          final game = TournamentGame(
            id: 'game_${month}_${week}_${round.name}_0',
            homeSchoolId: schools[0].id,
            awaySchoolId: schools[1].id,
            round: round,
            month: month,
            week: week,
            dayOfWeek: 1,
            isCompleted: false,
            result: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          games.add(game);
        }
        break;
    }
    
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
  static GameResult _simulateGame(TournamentGame game, List<School> schools) {
    final homeSchool = schools.firstWhere((s) => s.id == game.homeSchoolId);
    final awaySchool = schools.firstWhere((s) => s.id == game.awaySchoolId);
    
    // 学校の戦力を計算
    final homeStrength = _calculateSchoolStrength(homeSchool);
    final awayStrength = _calculateSchoolStrength(awaySchool);
    
    // ランダム要素を加える
    final random = Random();
    final homeBonus = (random.nextDouble() - 0.5) * 0.2; // ±10%
    final awayBonus = (random.nextDouble() - 0.5) * 0.2;
    
    final adjustedHomeStrength = homeStrength * (1 + homeBonus);
    final adjustedAwayStrength = awayStrength * (1 + awayBonus);
    
    // 得点を計算
    final homeScore = _calculateScore(adjustedHomeStrength, random);
    final awayScore = _calculateScore(adjustedAwayStrength, random);
    
    final isHomeWin = homeScore > awayScore;
    
    // ヒット数とエラー数を計算
    final homeHits = _calculateHits(adjustedHomeStrength, random);
    final awayHits = _calculateHits(adjustedAwayStrength, random);
    final homeErrors = _calculateErrors(adjustedHomeStrength, random);
    final awayErrors = _calculateErrors(adjustedAwayStrength, random);
    
    // ハイライトを生成
    final homeHighlights = _generateHighlights(homeSchool, homeScore, random);
    final awayHighlights = _generateHighlights(awaySchool, awayScore, random);
    
    return GameResult(
      homeSchoolId: game.homeSchoolId,
      awaySchoolId: game.awaySchoolId,
      homeScore: homeScore,
      awayScore: awayScore,
      isHomeWin: isHomeWin,
      homeHits: homeHits,
      awayHits: awayHits,
      homeErrors: homeErrors,
      awayErrors: awayErrors,
      homeHighlights: homeHighlights,
      awayHighlights: awayHighlights,
      createdAt: DateTime.now(),
    );
  }

  /// 学校の戦力を計算
  static double _calculateSchoolStrength(School school) {
    if (school.players.isEmpty) return 50.0; // デフォルト値
    
    // 3年生の選手のみを対象とする
    final seniorPlayers = school.players.where((p) => p.grade == 3).toList();
    if (seniorPlayers.isEmpty) return 30.0; // 3年生がいない場合は低い戦力
    
    double totalStrength = 0.0;
    int playerCount = 0;
    
    for (final player in seniorPlayers) {
      if (player.scoutAnalysisData != null) {
        // スカウト分析データから能力値を取得
        final pitching = player.scoutAnalysisData!['投球'] ?? 50;
        final control = player.scoutAnalysisData!['制球'] ?? 50;
        final stamina = player.scoutAnalysisData!['スタミナ'] ?? 50;
        final contact = player.scoutAnalysisData!['コンタクト'] ?? 50;
        final power = player.scoutAnalysisData!['パワー'] ?? 50;
        final speed = player.scoutAnalysisData!['走力'] ?? 50;
        final fielding = player.scoutAnalysisData!['守備'] ?? 50;
        
        // 投手能力と野手能力の平均を計算
        final pitcherStrength = (pitching + control + stamina) / 3.0;
        final batterStrength = (contact + power + speed + fielding) / 4.0;
        final playerStrength = (pitcherStrength + batterStrength) / 2.0;
        
        totalStrength += playerStrength;
        playerCount++;
      }
    }
    
    if (playerCount == 0) return 50.0;
    
    // 学校のランクによる補正
    final rankBonus = (school.rank.value - 3) * 5.0; // ランクが高いほど補正
    
    return (totalStrength / playerCount) + rankBonus;
  }

  /// 得点を計算
  static int _calculateScore(double strength, Random random) {
    // 戦力に基づいて得点を計算
    final baseScore = (strength / 100.0) * 8.0; // 基本得点
    final variance = random.nextDouble() * 4.0 - 2.0; // ±2点の変動
    
    return (baseScore + variance).round().clamp(0, 15);
  }

  /// ヒット数を計算
  static int _calculateHits(double strength, Random random) {
    final baseHits = (strength / 100.0) * 10.0;
    final variance = random.nextDouble() * 4.0 - 2.0;
    
    return (baseHits + variance).round().clamp(3, 15);
  }

  /// エラー数を計算
  static int _calculateErrors(double strength, Random random) {
    final baseErrors = (100.0 - strength) / 100.0 * 3.0;
    final variance = random.nextDouble() * 2.0 - 1.0;
    
    return (baseErrors + variance).round().clamp(0, 5);
  }

  /// ハイライトを生成
  static List<String> _generateHighlights(School school, int score, Random random) {
    final highlights = <String>[];
    
    if (score >= 5) {
      highlights.add('${school.shortName}の打線が爆発');
    }
    if (score >= 3) {
      highlights.add('${school.shortName}の適時打');
    }
    if (random.nextDouble() < 0.3) {
      highlights.add('${school.shortName}の好守備');
    }
    
    return highlights;
  }

  /// 順位表を更新
  static void _updateStandings(
    Map<String, SchoolStanding> standings,
    GameResult result,
    List<School> schools,
  ) {
    // ホームチームの更新
    final homeStanding = standings.values.firstWhere((s) => s.schoolId == (result.isHomeWin ? result.winnerSchoolId : result.loserSchoolId));
    final updatedHomeStanding = homeStanding.copyWith(
      games: homeStanding.games + 1,
      wins: homeStanding.wins + (result.isHomeWin ? 1 : 0),
      losses: homeStanding.losses + (result.isHomeWin ? 0 : 1),
      runsScored: homeStanding.runsScored + result.homeScore,
      runsAllowed: homeStanding.runsAllowed + result.awayScore,
      updatedAt: DateTime.now(),
    );
    
    standings[homeStanding.schoolId] = updatedHomeStanding
        .updateWinningPercentage()
        .updateRunDifferential();
    
    // アウェイチームの更新
    final awayStanding = standings.values.firstWhere((s) => s.schoolId == (result.isHomeWin ? result.loserSchoolId : result.winnerSchoolId));
    final updatedAwayStanding = awayStanding.copyWith(
      games: awayStanding.games + 1,
      wins: awayStanding.wins + (result.isHomeWin ? 0 : 1),
      losses: awayStanding.losses + (result.isHomeWin ? 1 : 0),
      runsScored: awayStanding.runsScored + result.awayScore,
      runsAllowed: awayStanding.runsAllowed + result.homeScore,
      updatedAt: DateTime.now(),
    );
    
    standings[awayStanding.schoolId] = updatedAwayStanding
        .updateWinningPercentage()
        .updateRunDifferential();
  }

  /// 大会が進行中かチェック
  static bool isTournamentActive(HighSchoolTournament tournament, int month, int week) {
    if (tournament.isCompleted) return false;
    
    switch (tournament.type) {
      case TournamentType.spring:
        return month == 4 && week >= 3 || month == 5 && week == 1;
      case TournamentType.summer:
        if (tournament.stage == TournamentStage.prefectural) {
          return month == 7 && week >= 2 && week <= 4;
        } else {
          return month == 8 && week >= 1 && week <= 3;
        }
      case TournamentType.autumn:
        return month == 10 && week >= 1 && week <= 3;
      case TournamentType.springNational:
        return month == 3 && week >= 1 && week <= 3;
    }
  }
}
