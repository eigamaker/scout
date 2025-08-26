import 'dart:math';

import '../models/game/game.dart';
import '../models/player/player.dart';

import '../models/player/player_abilities.dart';
import '../models/school/school.dart';

import 'news_service.dart';
import 'data_service.dart';

import 'scouting/action_service.dart' as scouting;
import 'game_data_manager.dart';
import 'game_state_manager.dart';

import '../models/scouting/scout.dart';
import '../models/scouting/team_request.dart';
import '../models/professional/professional_team.dart';
import '../models/professional/professional_player.dart';
import '../models/game/pennant_race.dart';
import '../models/game/high_school_tournament.dart' as high_school_tournament;
import 'growth_service.dart';
import 'pennant_race_service.dart';
import 'high_school_tournament_service.dart';
import 'default_school_data.dart';
import 'school_data_service.dart';
import 'talented_player_generator.dart';
import 'player_assignment_service.dart';



class GameManager {
  Game? _currentGame;
  late final GameDataManager _gameDataManager;

  Scout? _currentScout;
  
  // 週進行処理状態の管理
  bool _isAdvancingWeek = false;
  bool _isProcessingGrowth = false;
  String _growthStatusMessage = '';
  
  // デバッグ用カウンターは削除

  Game? get currentGame => _currentGame;
  Scout? get currentScout => _currentScout;
  
  // 週進行処理状態のゲッター
  bool get isAdvancingWeek => _isAdvancingWeek;
  bool get isProcessingGrowth => _isProcessingGrowth;
  String get growthStatusMessage => _growthStatusMessage;
  
  // 週進行処理中または成長処理中は進行できないかチェック
  bool get canAdvanceWeek => !_isAdvancingWeek && !_isProcessingGrowth;

  // 週進行処理状態を更新するプライベートメソッド
  void _updateAdvancingWeekStatus(bool isAdvancing) {
    _isAdvancingWeek = isAdvancing;
    print('GameManager: 週進行処理状態更新 - $isAdvancing');
  }

  // 成長処理状態を更新するプライベートメソッド
  void _updateGrowthStatus(bool isProcessing, String message) {
    _isProcessingGrowth = isProcessing;
    _growthStatusMessage = message;
    print('GameManager: 成長処理状態更新 - $isProcessing: $message');
  }

  /// ペナントレースを初期化
  void _initializePennantRace() {
    if (_currentGame != null && _currentGame!.pennantRace == null) {
      final pennantRace = PennantRaceService.createInitialPennantRace(
        _currentGame!.currentYear,
        _currentGame!.professionalTeams.teams,
      );
      
      _currentGame = _currentGame!.copyWith(pennantRace: pennantRace);
      print('GameManager: ペナントレースを初期化しました');
    }
  }

  /// ペナントレースの進行状況を取得
  String get pennantRaceProgress {
    if (_currentGame?.pennantRace == null) return '未開始';
    return PennantRaceService.getSeasonProgress(_currentGame!.pennantRace!);
  }

  /// ペナントレースが進行中かチェック
  bool get isPennantRaceActive {
    if (_currentGame?.pennantRace == null) return false;
    final month = _currentGame!.currentMonth;
    final week = _currentGame!.currentWeekOfMonth;
    return month >= 4 && month <= 10 && (month != 4 || week >= 1) && (month != 10 || week <= 2);
  }

  /// ペナントレースを更新
  void updatePennantRace(PennantRace pennantRace) {
    if (_currentGame != null) {
      _currentGame = _currentGame!.copyWith(pennantRace: pennantRace);
      print('GameManager: ペナントレースを更新しました');
    }
  }

  /// ペナントレースを進行させる
  void _advancePennantRace() {
    if (_currentGame?.pennantRace == null) return;
    
    final currentPennantRace = _currentGame!.pennantRace!;
    final month = _currentGame!.currentMonth;
    final week = _currentGame!.currentWeekOfMonth;
    
    // ペナントレースシーズン中の場合のみ進行
    if (month >= 4 && month <= 10 && (month != 4 || week >= 1) && (month != 10 || week <= 2)) {
      print('GameManager._advancePennantRace: ペナントレース進行開始 - ${month}月${week}週');
      
      // 今週の試合スケジュールを確認
      final weekGames = currentPennantRace.schedule.getGamesForWeek(month, week);
      print('GameManager._advancePennantRace: 今週の試合数: ${weekGames.length}試合');
      print('GameManager._advancePennantRace: 総試合数: ${currentPennantRace.schedule.games.length}試合');
      
      // 未完了の試合数を確認
      final uncompletedGames = weekGames.where((game) => !game.isCompleted).toList();
      print('GameManager._advantPennantRace: 未完了試合数: ${uncompletedGames.length}試合');
      
      // 今週の試合を実行
      final updatedPennantRace = PennantRaceService.executeWeekGames(
        currentPennantRace,
        month,
        week,
        _currentGame!.professionalTeams.teams,
      );
      
      // 実行後の完了試合数を確認
      final completedGamesAfter = updatedPennantRace.schedule.getGamesForWeek(month, week)
          .where((game) => game.isCompleted).toList();
      print('GameManager._advancePennantRace: 実行後の完了試合数: ${completedGamesAfter.length}試合');
      
      _currentGame = _currentGame!.copyWith(pennantRace: updatedPennantRace);
      
      // 試合結果のニュースを生成
      _generateGameResultsNews(updatedPennantRace, month, week);
      
      print('GameManager: ペナントレースを進行しました - ${month}月${week}週');
    } else {
      print('GameManager._advancePennantRace: ペナントレースシーズン外 - ${month}月${week}週');
    }
  }

  /// 試合結果のニュースを生成
  void _generateGameResultsNews(PennantRace pennantRace, int month, int week) {
    // 今週完了した試合の結果をニュースとして生成
    final weekGames = pennantRace.schedule.getGamesForWeek(month, week);
    final completedGames = weekGames.where((game) => game.isCompleted).toList();
    
    for (final game in completedGames) {
      if (game.result != null) {
        final homeTeam = _currentGame!.professionalTeams.teams
            .firstWhere((t) => t.id == game.homeTeamId);
        final awayTeam = _currentGame!.professionalTeams.teams
            .firstWhere((t) => t.id == game.awayTeamId);
        
        final result = game.result!;
        final winner = result.isHomeWin ? homeTeam : awayTeam;
        final loser = result.isHomeWin ? awayTeam : homeTeam;
        
        // ログ出力を停止（試合数が多いため）
        // print('GameManager: 試合結果ニュース生成 - ${homeTeam.shortName} ${result.homeScore}-${result.awayScore} ${awayTeam.shortName}');
      }
    }
  }

  /// 高校野球大会を進行
  void _advanceHighSchoolTournaments() {
    if (_currentGame == null) return;
    
    final month = _currentGame!.currentMonth;
    final week = _currentGame!.currentWeekOfMonth;
    final year = _currentGame!.currentYear;
    
    print('GameManager._advanceHighSchoolTournaments: 高校野球大会進行処理開始 - 年: $year, 月: $month, 週: $week');
    
    final updatedTournaments = <high_school_tournament.HighSchoolTournament>[];
    
    for (final tournament in _currentGame!.highSchoolTournaments) {
      if (tournament.isCompleted) {
        updatedTournaments.add(tournament);
        continue;
      }
      
      // 大会を進行
      final updatedTournament = HighSchoolTournamentService.executeWeekGames(
        tournament,
        month,
        week,
        _currentGame!.schools,
      );
      updatedTournaments.add(updatedTournament);
      
      // 大会完了時のニュース生成
      if (updatedTournament.isCompleted && !tournament.isCompleted) {
        _generateTournamentNews([updatedTournament], year, month, week);
      }
    }
    
    // ゲーム状態を更新
    _currentGame = _currentGame!.copyWith(
      highSchoolTournaments: updatedTournaments,
    );
    
    print('GameManager._advanceHighSchoolTournaments: 高校野球大会進行処理完了');
  }

  /// 大会ニュースを生成
  void _generateTournamentNews(List<high_school_tournament.HighSchoolTournament> tournaments, int year, int month, int week) {
    // NewsServiceのインスタンスを取得して大会ニュースを生成
    // 実際の実装では、NewsServiceをDIで注入するか、シングルトンとして使用
    print('GameManager: 大会ニュース生成 - ${month}月${week}週');
  }

  /// 高校野球大会を初期化
  void _initializeHighSchoolTournaments() {
    if (_currentGame == null) return;
    
    final month = _currentGame!.currentMonth;
    final week = _currentGame!.currentWeekOfMonth;
    final year = _currentGame!.currentYear;
    
    print('GameManager._initializeHighSchoolTournaments: 現在の状態 - 年: $year, 月: $month, 週: $week');
    print('GameManager._initializeHighSchoolTournaments: 既存の大会数: ${_currentGame!.highSchoolTournaments.length}');
    
    final tournaments = <high_school_tournament.HighSchoolTournament>[];
    
    // 春の県大会（4月2週〜4週）
    if (month == 4 && week >= 2 && week <= 4) {
      print('GameManager._initializeHighSchoolTournaments: 春の県大会初期化条件を満たしています');
      if (!_currentGame!.highSchoolTournaments.any((t) => t.type == high_school_tournament.TournamentType.spring)) {
        print('GameManager._initializeHighSchoolTournaments: 春の県大会が存在しないため、初期化を開始します');
        // 都道府県別の春の大会を作成
        final prefectures = _currentGame!.schools.map((s) => s.prefecture).toSet().toList();
        for (final prefecture in prefectures) {
          final prefectureSchools = _currentGame!.schools.where((s) => s.prefecture == prefecture).toList();
          if (prefectureSchools.isNotEmpty) {
            final springTournament = HighSchoolTournamentService.createPrefecturalTournament(
              year,
              prefecture,
              prefectureSchools,
              month,
              week,
              high_school_tournament.TournamentType.spring,
            );
            tournaments.add(springTournament);
          }
        }
        print('GameManager: 春の県大会を${prefectures.length}都道府県分初期化しました');
      } else {
        print('GameManager._initializeHighSchoolTournaments: 春の県大会は既に存在しています');
      }
    } else {
      print('GameManager._initializeHighSchoolTournaments: 春の県大会初期化条件を満たしていません - 月: $month, 週: $week');
    }
    
    // 夏の県大会（7月2週〜4週）
    if (month == 7 && week >= 2 && week <= 4) {
      print('GameManager._initializeHighSchoolTournaments: 夏の県大会初期化条件を満たしています');
      print('GameManager._initializeHighSchoolTournaments: 現在の月: $month, 週: $week');
      
      if (!_currentGame!.highSchoolTournaments.any((t) => t.type == high_school_tournament.TournamentType.summer && t.stage == high_school_tournament.TournamentStage.prefectural)) {
        print('GameManager._initializeHighSchoolTournaments: 夏の県大会が存在しないため、初期化を開始します');
        // 都道府県別の夏の大会を作成
        final prefectures = _currentGame!.schools.map((s) => s.prefecture).toSet().toList();
        print('GameManager._initializeHighSchoolTournaments: 都道府県数: ${prefectures.length}');
        
        for (final prefecture in prefectures) {
          final prefectureSchools = _currentGame!.schools.where((s) => s.prefecture == prefecture).toList();
          if (prefectureSchools.isNotEmpty) {
            final summerTournament = HighSchoolTournamentService.createPrefecturalTournament(
              year,
              prefecture,
              prefectureSchools,
              month,
              week,
              high_school_tournament.TournamentType.summer,
            );
            tournaments.add(summerTournament);
          }
        }
        print('GameManager: 夏の県大会を${prefectures.length}都道府県分初期化しました');
      } else {
        print('GameManager._initializeHighSchoolTournaments: 夏の県大会は既に存在しています');
      }
    } else {
      print('GameManager._initializeHighSchoolTournaments: 夏の県大会初期化条件を満たしていません - 月: $month, 週: $week');
    }
    
    // 夏の全国大会（8月1週〜3週）- 夏の県大会完了後に作成
    if (month == 8 && week >= 1 && week <= 3) {
      print('GameManager._initializeHighSchoolTournaments: 夏の全国大会初期化条件を満たしています');
      print('GameManager._initializeHighSchoolTournaments: 現在の月: $month, 週: $week');
      
      if (!_currentGame!.highSchoolTournaments.any((t) => t.type == high_school_tournament.TournamentType.summer && t.stage == high_school_tournament.TournamentStage.national)) {
        print('GameManager._initializeHighSchoolTournaments: 夏の全国大会が存在しないため、初期化を開始します');
        // 夏の県大会の優勝校を取得
        final summerPrefecturalTournaments = _currentGame!.highSchoolTournaments
            .where((t) => t.type == high_school_tournament.TournamentType.summer && 
                         t.stage == high_school_tournament.TournamentStage.prefectural)
            .toList();
        
        print('GameManager._initializeHighSchoolTournaments: 夏の県大会数: ${summerPrefecturalTournaments.length}');
        for (final tournament in summerPrefecturalTournaments) {
          print('GameManager._initializeHighSchoolTournaments: 夏の県大会: ${tournament.id}, 完了: ${tournament.isCompleted}, 優勝校: ${tournament.championSchoolId}');
        }
        
        final summerWinners = summerPrefecturalTournaments
            .where((t) => t.isCompleted)
            .map((t) => t.championSchoolId)
            .where((id) => id != null)
            .cast<String>()
            .toList();
        
        print('GameManager._initializeHighSchoolTournaments: 夏の県大会優勝校数: ${summerWinners.length}');
        
        if (summerWinners.isNotEmpty) {
          final summerNationalTournament = HighSchoolTournamentService.createSummerNationalTournament(
            year,
            summerWinners,
            _currentGame!.schools,
            month,
            week,
          );
          tournaments.add(summerNationalTournament);
          print('GameManager: 夏の全国大会を初期化しました - 出場校数: ${summerWinners.length}校');
        } else {
          print('GameManager._initializeHighSchoolTournaments: 夏の県大会の優勝校が存在しないため、夏の全国大会を初期化できません');
        }
      } else {
        print('GameManager._initializeHighSchoolTournaments: 夏の全国大会は既に存在しています');
      }
    } else {
      print('GameManager._initializeHighSchoolTournaments: 夏の全国大会初期化条件を満たしていません - 月: $month, 週: $week');
    }
    
    // 秋の大会（10月1週〜3週）- 春の全国大会予選
    if (month == 10 && week >= 1 && week <= 3) {
      print('GameManager._initializeHighSchoolTournaments: 秋の大会初期化条件を満たしています');
      
      if (!_currentGame!.highSchoolTournaments.any((t) => t.type == high_school_tournament.TournamentType.autumn)) {
        print('GameManager._initializeHighSchoolTournaments: 秋の大会が存在しないため、初期化を開始します');
        // 都道府県別の秋の大会を作成
        final prefectures = _currentGame!.schools.map((s) => s.prefecture).toSet().toList();
        print('GameManager._initializeHighSchoolTournaments: 秋の大会 - 都道府県数: ${prefectures.length}');
        
        for (final prefecture in prefectures) {
          final prefectureSchools = _currentGame!.schools.where((s) => s.prefecture == prefecture).toList();
          if (prefectureSchools.isNotEmpty) {
            final autumnTournament = HighSchoolTournamentService.createPrefecturalTournament(
              year,
              prefecture,
              prefectureSchools,
              month,
              week,
              high_school_tournament.TournamentType.autumn,
            );
            tournaments.add(autumnTournament);
          }
        }
        print('GameManager: 秋の大会を${prefectures.length}都道府県分初期化しました');
      } else {
        print('GameManager._initializeHighSchoolTournaments: 秋の大会は既に存在しています');
      }
    } else {
      print('GameManager._initializeHighSchoolTournaments: 秋の大会初期化条件を満たしていません - 月: $month, 週: $week');
    }
    
    // 春の全国大会（3月1週〜3週）
    if (month == 3 && week >= 1 && week <= 3) {
      print('GameManager._initializeHighSchoolTournaments: 春の全国大会初期化条件を満たしています');
      if (!_currentGame!.highSchoolTournaments.any((t) => t.type == high_school_tournament.TournamentType.springNational)) {
        print('GameManager._initializeHighSchoolTournaments: 春の全国大会が存在しないため、初期化を開始します');
        // 秋の大会の優勝校を取得
        final autumnWinners = _currentGame!.highSchoolTournaments
            .where((t) => t.type == high_school_tournament.TournamentType.autumn && t.isCompleted)
            .map((t) => t.championSchoolId)
            .where((id) => id != null)
            .cast<String>()
            .toList();
        
        if (autumnWinners.isNotEmpty) {
          final springNationalTournament = HighSchoolTournamentService.createSpringNationalTournament(
            year,
            autumnWinners,
            _currentGame!.schools,
            month,
            week,
          );
          tournaments.add(springNationalTournament);
          print('GameManager: 春の全国大会を初期化しました');
        } else {
          print('GameManager._initializeHighSchoolTournaments: 秋の大会の優勝校が存在しないため、春の全国大会を初期化できません');
        }
      } else {
        print('GameManager._initializeHighSchoolTournaments: 春の全国大会は既に存在しています');
      }
    } else {
      print('GameManager._initializeHighSchoolTournaments: 春の全国大会初期化条件を満たしていません - 月: $month, 週: $week');
    }
    
    if (tournaments.isNotEmpty) {
      _currentGame = _currentGame!.copyWith(
        highSchoolTournaments: [..._currentGame!.highSchoolTournaments, ...tournaments],
      );
      print('GameManager._initializeHighSchoolTournaments: ${tournaments.length}個の大会を初期化しました');
    } else {
      print('GameManager._initializeHighSchoolTournaments: 初期化する大会はありません');
    }
  }

  GameManager(DataService dataService) {
    _gameDataManager = GameDataManager(dataService);
    
  }

  // 新しい選手生成・配属システム
  Future<void> generateInitialStudentsForAllSchoolsDb(DataService dataService) async {
    try {
      print('GameManager.generateInitialStudentsForAllSchoolsDb: 開始');
      print('GameManager.generateInitialStudentsForAllSchoolsDb: 更新前の学校数: ${_currentGame!.schools.length}');
      
      // 1. 47都道府県×50校の学校を生成（デフォルトデータから）
      final allSchools = DefaultSchoolData.getAllSchools();
      print('GameManager.generateInitialStudentsForAllSchoolsDb: DefaultSchoolData.getAllSchools()で生成された学校数: ${allSchools.length}');
      if (allSchools.isNotEmpty) {
        print('GameManager.generateInitialStudentsForAllSchoolsDb: 最初の5校の情報:');
        for (int i = 0; i < allSchools.length && i < 5; i++) {
          final school = allSchools[i];
          print('GameManager.generateInitialStudentsForAllSchoolsDb: 学校$i: ID=${school.id}, 名前=${school.name}, 都道府県=${school.prefecture}');
        }
      }
      
      // 1.5. 学校データをデータベースに挿入
      final db = await dataService.database;
      final schoolDataService = SchoolDataService(db);
      await schoolDataService.insertDefaultSchools();
      
      // 2. 才能のある選手（ランク3以上）を1000人生成
      final talentedPlayerGenerator = TalentedPlayerGenerator(dataService);
      final talentedPlayers = await talentedPlayerGenerator.generateTalentedPlayers();
      
      // 3. 選手を学校に配属
      final playerAssignmentService = PlayerAssignmentService(dataService);
      await playerAssignmentService.assignPlayersToSchools(allSchools, talentedPlayers);
      
      // 4. 学校リストを更新
      print('GameManager.generateInitialStudentsForAllSchoolsDb: _currentGame!.copyWith実行前');
      _currentGame = _currentGame!.copyWith(schools: allSchools);
      print('GameManager.generateInitialStudentsForAllSchoolsDb: _currentGame!.copyWith実行後');
      print('GameManager.generateInitialStudentsForAllSchoolsDb: 更新後の学校数: ${_currentGame!.schools.length}');
      if (_currentGame!.schools.isNotEmpty) {
        print('GameManager.generateInitialStudentsForAllSchoolsDb: 更新後の最初の5校の情報:');
        for (int i = 0; i < _currentGame!.schools.length && i < 5; i++) {
          final school = _currentGame!.schools[i];
          print('GameManager.generateInitialStudentsForAllSchoolsDb: 学校$i: ID=${school.id}, 名前=${school.name}, 都道府県=${school.prefecture}');
        }
      }
      
      // 5. 統計情報を表示
      final stats = await playerAssignmentService.getPlayerDistributionStats(allSchools);
      print('選手配属完了:');

      
    } catch (e) {
      print('選手生成・配属でエラー: $e');
      
      // エラーが発生した場合はゲーム状態をリセット
      _currentGame = null;
      _currentScout = null;
      
      rethrow;
    }
  }

  Future<void> startNewGameWithDb(String scoutName, DataService dataService) async {
    try {
      // 初期データ投入（初回のみ）
      await dataService.insertInitialData();
      
      final db = await dataService.database;
      
      // 学校リストは空で開始（generateInitialStudentsForAllSchoolsDbで生成される）
      final schools = <School>[];
      final players = <Player>[];
      // スカウトインスタンス生成
      _currentScout = Scout.createDefault(scoutName);
      
      // Gameインスタンス生成
      _currentGame = Game(
        scoutName: scoutName,
        scoutSkill: 50,
        currentYear: DateTime.now().year,
        currentMonth: 4,
        currentWeekOfMonth: 1,
        state: GameState.scouting,
        schools: schools,
        discoveredPlayers: players,
        watchedPlayers: [],
        favoritePlayers: [],
        ap: 15,
        budget: 1000000,
        scoutSkills: {
          ScoutSkill.exploration: _currentScout!.getSkill(ScoutSkill.exploration),
          ScoutSkill.observation: _currentScout!.getSkill(ScoutSkill.observation),
          ScoutSkill.analysis: _currentScout!.getSkill(ScoutSkill.analysis),
          ScoutSkill.insight: _currentScout!.getSkill(ScoutSkill.insight),
          ScoutSkill.communication: _currentScout!.getSkill(ScoutSkill.communication),
          ScoutSkill.negotiation: _currentScout!.getSkill(ScoutSkill.negotiation),
          ScoutSkill.stamina: _currentScout!.getSkill(ScoutSkill.stamina),
        },
        reputation: _currentScout!.reputation,
        experience: _currentScout!.experience,
        level: _currentScout!.level,
        weeklyActions: [],
        teamRequests: TeamRequestManager(requests: TeamRequestManager.generateDefaultRequests()),
        newsList: [], // 初期ニュースリストは空
        professionalTeams: ProfessionalTeamManager(teams: ProfessionalTeamManager.generateDefaultTeams()),
      );
      // 全学校に1〜3年生を生成
      await generateInitialStudentsForAllSchoolsDb(dataService);
      
      // プロ野球団に選手を生成（データベースから読み込み）
      await _loadProfessionalPlayersFromDatabase(dataService);
      
      // ペナントレースを初期化
      _initializePennantRace();
      
      // generateInitialStudentsForAllSchoolsDbで更新された学校リストを取得
      final updatedSchools = _currentGame!.schools;
      
      // 全選手をdiscoveredPlayersにも追加
      final allPlayers = <Player>[];
      for (final school in updatedSchools) {
        allPlayers.addAll(school.players);
      }
      _currentGame = _currentGame!.copyWith(discoveredPlayers: allPlayers);
      

      
    } catch (e, stackTrace) {
      print('GameManager.startNewGameWithDb: エラーが発生しました: $e');
      print('GameManager.startNewGameWithDb: スタックトレース: $stackTrace');
      
      // エラーが発生した場合はゲーム状態をリセット
      _currentGame = null;
      _currentScout = null;
      
      rethrow;
    }
  }

  // スカウト実行
  Future<Player?> scoutNewPlayer(NewsService newsService) async {
    if (_currentGame == null || _currentGame!.schools.isEmpty) return null;
    
    // 既存の未発掘選手からランダムに選択
    final undiscoveredPlayers = <Player>[];
    for (final school in _currentGame!.schools) {
      undiscoveredPlayers.addAll(
        school.players.where((p) => !p.isDiscovered && !p.isDefaultPlayer)
      );
    }
    
    if (undiscoveredPlayers.isEmpty) return null;
    
    // ランダムな未発掘選手を選択
    final selectedPlayer = undiscoveredPlayers[Random().nextInt(undiscoveredPlayers.length)];
    final school = _currentGame!.schools.firstWhere((s) => s.players.contains(selectedPlayer));
    
    // 発掘リストに追加
    _currentGame = _currentGame!.discoverPlayer(selectedPlayer);

    // 選手に基づくニュース生成
    newsService.generatePlayerNews(
      selectedPlayer, 
      school,
      year: _currentGame!.currentYear,
      month: _currentGame!.currentMonth,
      weekOfMonth: _currentGame!.currentWeekOfMonth,
    );
    
    return selectedPlayer;
  }

  // 日付進行・イベント
  void triggerRandomEvent(NewsService newsService) {
    if (_currentGame == null) return;
    _currentGame = GameStateManager.triggerRandomEvent(_currentGame!, newsService);
  }

  // 新年度（4月1週）開始時に全学校へ新1年生を生成・配属（DBにもinsert）
  Future<void> generateNewStudentsForAllSchoolsDb(DataService dataService) async {
    if (_currentGame == null) return;
    
    try {
      print('GameManager.generateNewStudentsForAllSchoolsDb: 新年度新1年生生成開始');
      
      // TalentedPlayerGeneratorを使用して新1年生を生成
      final talentedPlayerGenerator = TalentedPlayerGenerator(dataService);
      final newFirstYears = await talentedPlayerGenerator.generateTalentedPlayers();
      
      // 新1年生のみをフィルタリング（学年を1年生に設定）
      final firstYearStudents = newFirstYears.take(2350).map((player) => 
        player.copyWith(grade: 1)
      ).toList();
      
      // 選手を学校に配属
      final playerAssignmentService = PlayerAssignmentService(dataService);
      await playerAssignmentService.assignPlayersToSchools(_currentGame!.schools, firstYearStudents);
      
      // 学校リストを更新
      final updatedSchools = <School>[];
      for (final school in _currentGame!.schools) {
        final schoolPlayers = firstYearStudents.where((p) => p.school == school.name).toList();
        final allPlayers = [...school.players, ...schoolPlayers];
        updatedSchools.add(school.copyWith(players: allPlayers));
      }
      
      _currentGame = _currentGame!.copyWith(schools: updatedSchools);
      print('GameManager.generateNewStudentsForAllSchoolsDb: 新年度新1年生生成完了 - ${firstYearStudents.length}名');
      
    } catch (e) {
      print('GameManager.generateNewStudentsForAllSchoolsDb: エラーが発生しました: $e');
      rethrow;
    }
  }

  // 8月4週→9月1週の週送り時に野球部引退処理（3年生を引退フラグ設定）
  Future<void> graduateThirdYearStudents(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager.graduateThirdYearStudents: 3年生野球部引退処理開始');
    _updateGrowthStatus(true, '3年生の野球部引退処理を実行中...');
    
    try {
      // まずデータベースの重複選手を修復
      print('GameManager.graduateThirdYearStudents: データベース修復を開始...');
      await dataService.repairNumericData();
      print('GameManager.graduateThirdYearStudents: データベース修復完了');
      
      final db = await dataService.database;
      final updatedSchools = <School>[];
      int totalGraduated = 0;
      
      for (final school in _currentGame!.schools) {
        // デフォルト選手以外の3年生のみ卒業処理
        final remaining = school.players.where((p) => p.grade < 3 || p.isDefaultPlayer).toList();
        final graduating = school.players.where((p) => p.grade == 3 && !p.isDefaultPlayer).toList();
        
        print('GameManager.graduateThirdYearStudents: ${school.name} - 引退対象: ${graduating.length}人（デフォルト選手除く）');
        
        // DBで3年生を引退フラグ設定（関連テーブルも含めて更新）
        for (final p in graduating) {
          try {
            // Playerテーブルの引退フラグを更新
            await db.update(
              'Player',
              {
                'is_graduated': 1,
                'graduated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [p.id]
            );
            
                          // PlayerPotentialsとScoutAnalysisテーブルは卒業状態を管理しない
              // これらのテーブルは能力値の上限とスカウト分析データのみを管理
              // 卒業状態はPlayerテーブルのis_graduatedカラムで十分
            
            // 引退した選手をremainingに追加（引退フラグ付き）
            remaining.add(p.copyWith(isGraduated: true, graduatedAt: DateTime.now()));
            totalGraduated++;
            
          } catch (e) {
            print('GameManager.graduateThirdYearStudents: 選手 ${p.name} (ID: ${p.id}) の引退処理でエラー: $e');
            // エラーが発生しても処理を継続
            continue;
          }
        }
        
        updatedSchools.add(school.copyWith(players: remaining));
      }
      
      _currentGame = _currentGame!.copyWith(schools: updatedSchools);
      _updateGrowthStatus(false, '3年生引退処理完了');
      print('GameManager.graduateThirdYearStudents: 全学校の3年生引退処理完了 - 総引退者数: ${totalGraduated}名（デフォルト選手除く）');
      
      // 引退処理後に学校の強さを更新
      await updateSchoolStrengths(dataService);
      
    } catch (e) {
      print('GameManager.graduateThirdYearStudents: 3年生引退処理でエラーが発生しました: $e');
      _updateGrowthStatus(false, '3年生引退処理でエラーが発生しました');
      rethrow;
    }
  }

  // 12月4週→1月1週の週送り時に全選手のgradeを+1（年が変わる時）
  Future<void> promoteAllStudents(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager.promoteAllStudents: 学年アップ処理開始');
    
    try {
      final db = await dataService.database;
      final updatedSchools = <School>[];
      
      // 高校生選手の学年アップ処理
      for (final school in _currentGame!.schools) {
        final promoted = <Player>[];
        
        for (final p in school.players) {
          // デフォルト選手は学年アップしない（固定で2年生）
          if (p.isDefaultPlayer) {
            promoted.add(p);
            continue;
          }
          
          // 卒業した選手は学年アップしない
          if (p.isGraduated) {
            promoted.add(p);
            continue;
          }
          
          // 引退した選手は年齢更新をスキップ
          if (p.isRetired) {
            promoted.add(p);
            continue;
          }
          
          final newGrade = p.grade + 1;
          final newAge = p.age + 1; // 年齢も+1
          
          // 引退判定
          if (newAge > 17) { // 高校卒業後
            final shouldRetire = _shouldPlayerRetire(p, newAge);
            if (shouldRetire) {
              // 引退フラグを設定
              try {
                await db.update(
                  'Player',
                  {
                    'is_retired': 1,
                    'retired_at': DateTime.now().toIso8601String(),
                  },
                  where: 'id = ?',
                  whereArgs: [p.id]
                );
              } catch (e) {
                // エラーが発生しても処理を継続
              }
              
              // 引退選手として追加
              promoted.add(p.copyWith(
                grade: newGrade,
                age: newAge,
                isRetired: true,
                retiredAt: DateTime.now(),
              ));
              continue;
            }
          }
          
          try {
            // DBも更新（idで検索）
            await db.update(
              'Player', 
              {'grade': newGrade, 'age': newAge}, // 年齢も更新
              where: 'id = ?', 
              whereArgs: [p.id]
            );
          } catch (e) {
            // エラーが発生しても処理を継続
          }
          
          promoted.add(p.copyWith(grade: newGrade, age: newAge)); // 年齢も更新
        }
        
        updatedSchools.add(school.copyWith(players: promoted));
      }
      
      _currentGame = _currentGame!.copyWith(schools: updatedSchools);
      print('GameManager.promoteAllStudents: 全学校の学年アップ処理完了（デフォルト選手除く）');
      
    } catch (e) {
      print('GameManager.promoteAllStudents: エラーが発生しました: $e');
      rethrow;
    }
  }

  // プロ野球選手の年齢更新処理
  Future<void> _updateProfessionalPlayersAge(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager._updateProfessionalPlayersAge: プロ野球選手の年齢更新処理開始');
    
    try {
      final db = await dataService.database;
      final batch = db.batch();
      int updateCount = 0;
      
      for (final team in _currentGame!.professionalTeams.teams) {
        if (team.professionalPlayers == null) continue;
        
        for (final proPlayer in team.professionalPlayers!) {
          final player = proPlayer.player;
          if (player == null) continue;
          
          // 引退した選手は年齢更新をスキップ
          if (player.isRetired) continue;
          
          final newAge = player.age + 1;
          print('GameManager._updateProfessionalPlayersAge: プロ選手 ${player.name} の年齢を ${player.age}歳 → ${newAge}歳 に更新');
          
          // 引退判定
          if (newAge >= 18) { // プロ選手は18歳以上
            final shouldRetire = _shouldPlayerRetire(player, newAge);
            if (shouldRetire) {
              print('GameManager._updateProfessionalPlayersAge: プロ選手 ${player.name} が年齢更新時の引退判定で引退');
              
              // 引退フラグを設定
              batch.update(
                'Player',
                {
                  'is_retired': 1,
                  'retired_at': DateTime.now().toIso8601String(),
                  'age': newAge,
                },
                where: 'id = ?',
                whereArgs: [player.id]
              );
              
              // ProfessionalPlayerテーブルも更新
              batch.update(
                'ProfessionalPlayer',
                {
                  'is_active': 0,
                  'left_at': DateTime.now().toIso8601String(),
                },
                where: 'player_id = ?',
                whereArgs: [player.id]
              );
              
              updateCount += 2;
              continue;
            }
          }
          
          // 年齢を更新
          batch.update(
            'Player',
            {'age': newAge},
            where: 'id = ?',
            whereArgs: [player.id]
          );
          
          updateCount++;
        }
      }
      
      // バッチ更新を実行
      if (updateCount > 0) {
        print('GameManager._updateProfessionalPlayersAge: $updateCount件のプロ選手データをバッチ更新で保存中...');
        await batch.commit(noResult: true);
        print('GameManager._updateProfessionalPlayersAge: プロ選手データのバッチ更新完了');
      } else {
        print('GameManager._updateProfessionalPlayersAge: 更新するプロ選手データはありません');
      }
      
    } catch (e) {
      print('GameManager._updateProfessionalPlayersAge: エラーが発生しました: $e');
      rethrow;
    }
  }

  // プロ野球選手の引退処理（12月4週の終了時に実行）
  Future<void> _processProfessionalPlayerRetirements(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager._processProfessionalPlayerRetirements: プロ野球選手引退処理開始');
    
    try {
      final db = await dataService.database;
      final batch = db.batch();
      int retirementCount = 0;
      int ageUpdateCount = 0;
      
      for (final team in _currentGame!.professionalTeams.teams) {
        if (team.professionalPlayers == null) continue;
        
        for (final proPlayer in team.professionalPlayers!) {
          final player = proPlayer.player;
          if (player == null) continue;
          
          // 引退した選手は処理をスキップ
          if (player.isRetired) continue;
          
          final newAge = player.age + 1;
          
          // 引退判定
          if (newAge >= 18) { // プロ選手は18歳以上
            final shouldRetire = _shouldPlayerRetire(player, newAge);
            if (shouldRetire) {
              print('GameManager._processProfessionalPlayerRetirements: プロ選手 ${player.name} が引退判定で引退（年齢: ${newAge}歳）');
              
              // 引退フラグを設定
              batch.update(
                'Player',
                {
                  'is_retired': 1,
                  'retired_at': DateTime.now().toIso8601String(),
                  'age': newAge,
                },
                where: 'id = ?',
                whereArgs: [player.id]
              );
              
              // ProfessionalPlayerテーブルも更新
              batch.update(
                'ProfessionalPlayer',
                {
                  'is_active': 0,
                  'left_at': DateTime.now().toIso8601String(),
                },
                where: 'player_id = ?',
                whereArgs: [player.id]
              );
              
              retirementCount++;
              continue;
            }
          }
          
          // 年齢を更新（引退しない場合）
          batch.update(
            'Player',
            {'age': newAge},
            where: 'id = ?',
            whereArgs: [player.id]
          );
          
          ageUpdateCount++;
        }
      }
      
      // バッチ更新を実行
      if (retirementCount > 0 || ageUpdateCount > 0) {
        print('GameManager._processProfessionalPlayerRetirements: 引退: ${retirementCount}人, 年齢更新: ${ageUpdateCount}人 をバッチ更新で保存中...');
        await batch.commit(noResult: true);
        print('GameManager._processProfessionalPlayerRetirements: プロ選手データのバッチ更新完了');
      } else {
        print('GameManager._processProfessionalPlayerRetirements: 更新するプロ選手データはありません');
      }
      
      print('GameManager._processProfessionalPlayerRetirements: プロ野球選手引退処理完了 - 引退: ${retirementCount}人, 年齢更新: ${ageUpdateCount}人');
      
    } catch (e) {
      print('GameManager._processProfessionalPlayerRetirements: エラーが発生しました: $e');
      rethrow;
    }
  }

  // 選手の引退判定
  bool _shouldPlayerRetire(Player player, int newAge) {
    // 年齢による引退判定
    if (newAge >= 40) return true; // 40歳以上で強制引退
    
    // 高校卒業時（18歳）の引退判定
    if (newAge == 18) {
      final averageAbility = _calculateAverageAbility(player);
      if (averageAbility < 60) {
        print('GameManager: 選手 ${player.name} が高校卒業時に引退（平均能力値: ${averageAbility.toStringAsFixed(1)}）');
        return true; // 平均能力値60未満で引退
      }
    }
    
    // 大学卒業時（23歳）の引退判定
    if (newAge == 23) {
      final averageAbility = _calculateAverageAbility(player);
      if (averageAbility < 85) {
        print('GameManager: 選手 ${player.name} が大学卒業時に引退（平均能力値: ${averageAbility.toStringAsFixed(1)}）');
        return true; // 平均能力値85未満で引退
      }
    }
    
    // 高校卒業後（19歳以上）の能力値による引退判定
    if (newAge > 18) {
      final averageAbility = _calculateAverageAbility(player);
      if (averageAbility < 60) {
        print('GameManager: 選手 ${player.name} が能力値不足で引退（平均能力値: ${averageAbility.toStringAsFixed(1)}）');
        return true; // 平均能力値60未満で引退
      }
    }
    
    // 成長型と年齢による引退確率
    if (newAge >= 35) {
      final random = Random();
      final retirementChance = _getRetirementChance(newAge, player.growthType);
      return random.nextDouble() < retirementChance;
    }
    
    return false;
  }

  // 選手の平均能力値を計算
  double _calculateAverageAbility(Player player) {
    int total = 0;
    int count = 0;
    
    // 技術面能力値（15項目）
    for (final ability in player.technicalAbilities.values) {
      total += ability;
      count++;
    }
    
    // メンタル面能力値（15項目）
    for (final ability in player.mentalAbilities.values) {
      total += ability;
      count++;
    }
    
    // フィジカル面能力値（10項目）
    for (final ability in player.physicalAbilities.values) {
      total += ability;
      count++;
    }
    
    // 合計40項目の平均を計算
    return count > 0 ? total / count : 0.0;
  }

  // 年齢と成長型による引退確率を取得
  double _getRetirementChance(int age, String growthType) {
    if (age >= 37) return 0.8;      // 37歳以上：80%
    if (age >= 35) return 0.6;      // 35-36歳：60%
    if (age >= 33) return 0.4;      // 33-34歳：40%
    if (age >= 30) return 0.2;      // 30-32歳：20%
    return 0.0;                     // 30歳未満：0%
  }

  // 全選手の成長処理（3ヶ月ごと）
  Future<void> growAllPlayers(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager.growAllPlayers: 全選手の成長処理開始');
    _updateGrowthStatus(true, '選手の成長処理を実行中...');
    
    try {
      // 全選手（高校生・プロ選手）の成長処理を統一
      _currentGame = _growAllPlayersUnified(_currentGame!);
      
      // 成長後の選手データをデータベースに保存
      _updateGrowthStatus(true, '成長データをデータベースに保存中...');
      await _saveAllGrownPlayersToDatabase(dataService);
      
      // 成長処理後に学校の強さを更新
      _updateGrowthStatus(true, '学校の強さを更新中...');
      await updateSchoolStrengths(dataService);
      
      _updateGrowthStatus(false, '成長処理完了');
      print('GameManager.growAllPlayers: 全選手の成長処理完了');
    } catch (e) {
      _updateGrowthStatus(false, '成長処理でエラーが発生しました');
      print('GameManager.growAllPlayers: エラーが発生しました: $e');
      rethrow;
    }
  }

  // 全選手（高校生・プロ選手）の成長処理を統一
  Game _growAllPlayersUnified(Game game) {
    print('GameManager._growAllPlayersUnified: 全選手の成長処理開始');
    
    int totalPlayers = 0;
    int grownPlayersCount = 0;
    bool isFirstPlayer = true;
    
    // Playerテーブルから全選手を取得して統一処理
    final allPlayers = <Player>[];
    
    // 高校生選手を追加
    for (final school in game.schools) {
      allPlayers.addAll(school.players);
    }
    
    // プロ選手を追加（ProfessionalPlayerからPlayerを抽出）
    for (final team in game.professionalTeams.teams) {
      if (team.professionalPlayers != null) {
        for (final proPlayer in team.professionalPlayers!) {
          if (proPlayer.player != null) {
            final player = proPlayer.player!;
            // プロ選手のID確認ログ（最初の3件のみ）
            if (allPlayers.length < 3) {
              print('GameManager._growAllPlayersUnified: プロ選手追加 - 名前: ${player.name}, ID: ${player.id}, playerId: ${proPlayer.playerId}');
            }
            allPlayers.add(player);
          }
        }
      }
    }
    
    print('GameManager._growAllPlayersUnified: 全選手数: ${allPlayers.length}');
    
    // 全選手を統一して成長処理
    final updatedPlayers = allPlayers.map((player) {
      // 引退選手とデフォルト選手は成長処理をスキップ
      if (player.isRetired || player.isDefaultPlayer) {
        return player;
      }
      
      totalPlayers++;
      
      // GrowthServiceを使用して成長処理を実行
      final grownPlayer = GrowthService.growPlayer(player);
      
      // プロ選手のみ年齢による能力値減退を適用
      Player finalPlayer = grownPlayer;
      if (player.school == 'プロ野球団') {
        finalPlayer = _applyAgeBasedDecline(grownPlayer);
      }
      
      // 成長があったかチェック
      if (_hasPlayerGrown(player, finalPlayer)) {
        grownPlayersCount++;
        
        // 最初の成長した選手の詳細ログを出力
        if (isFirstPlayer) {
          _logFirstPlayerGrowth(player, finalPlayer);
          isFirstPlayer = false;
        }
      }
      
      return finalPlayer;
    }).toList();
    
    // 更新された選手データを元の構造に戻す
    final updatedSchools = game.schools.map((school) {
      final schoolPlayers = school.players.map((p) {
        final updatedPlayer = updatedPlayers.firstWhere(
          (up) => up.id == p.id,
          orElse: () => p,
        );
        return updatedPlayer;
      }).toList();
      return school.copyWith(players: schoolPlayers);
    }).toList();
    
    final updatedTeams = game.professionalTeams.teams.map((team) {
      final teamPlayers = team.professionalPlayers?.map((proPlayer) {
        if (proPlayer.player != null) {
          final updatedPlayer = updatedPlayers.firstWhere(
            (up) => up.id == proPlayer.player!.id,
            orElse: () => proPlayer.player!,
          );
          return proPlayer.copyWith(player: updatedPlayer);
        }
        return proPlayer;
      }).toList() ?? [];
      return team.copyWith(professionalPlayers: teamPlayers);
    }).toList();
    
    print('GameManager._growAllPlayersUnified: 全選手の成長処理完了 - 総選手数: $totalPlayers, 成長した選手数: $grownPlayersCount');
    
    return game.copyWith(
      schools: updatedSchools,
      professionalTeams: ProfessionalTeamManager(teams: updatedTeams),
    );
  }

  // 選手が成長したかチェック
  static bool _hasPlayerGrown(Player oldPlayer, Player newPlayer) {
    // 技術面能力値の変化をチェック
    for (final ability in oldPlayer.technicalAbilities.keys) {
      final oldValue = oldPlayer.technicalAbilities[ability] ?? 0;
      final newValue = newPlayer.technicalAbilities[ability] ?? 0;
      if (newValue > oldValue) return true;
    }
    
    // メンタル面能力値の変化をチェック
    for (final ability in oldPlayer.mentalAbilities.keys) {
      final oldValue = oldPlayer.mentalAbilities[ability] ?? 0;
      final newValue = newPlayer.mentalAbilities[ability] ?? 0;
      if (newValue > oldValue) return true;
    }
    
    // フィジカル面能力値の変化をチェック
    for (final ability in oldPlayer.physicalAbilities.keys) {
      final oldValue = oldPlayer.physicalAbilities[ability] ?? 0;
      final newValue = newPlayer.physicalAbilities[ability] ?? 0;
      if (newValue > oldValue) return true;
    }
    
    return false;
  }

  // 最初の成長した選手の詳細ログを出力
  void _logFirstPlayerGrowth(Player oldPlayer, Player newPlayer) {
    print('GameManager._logFirstPlayerGrowth: 最初の成長した選手の詳細ログ');
    print('選手名: ${oldPlayer.name}');
    
    // 技術面能力値の変化
    for (final ability in oldPlayer.technicalAbilities.keys) {
      final oldValue = oldPlayer.technicalAbilities[ability] ?? 0;
      final newValue = newPlayer.technicalAbilities[ability] ?? 0;
      if (newValue > oldValue) {
        print('${ability.name}: $oldValue → $newValue (+${newValue - oldValue})');
      }
    }
    
    // メンタル面能力値の変化
    for (final ability in oldPlayer.mentalAbilities.keys) {
      final oldValue = oldPlayer.mentalAbilities[ability] ?? 0;
      final newValue = newPlayer.mentalAbilities[ability] ?? 0;
      if (newValue > oldValue) {
        print('${ability.name}: $oldValue → $newValue (+${newValue - oldValue})');
      }
    }
    
    // フィジカル面能力値の変化
    for (final ability in oldPlayer.physicalAbilities.keys) {
      final oldValue = oldPlayer.physicalAbilities[ability] ?? 0;
      final newValue = newPlayer.physicalAbilities[ability] ?? 0;
      if (newValue > oldValue) {
        print('${ability.name}: $oldValue → $newValue (+${newValue - oldValue})');
      }
    }
  }



  // 年齢による能力値減退を適用
  Player _applyAgeBasedDecline(Player player) {
    if (player.isDefaultPlayer) return player;
    
    final age = player.age;
    final growthType = player.growthType;
    
    // 年間の減退ポイントを計算（年間4回の成長期があるため、1回あたりの減退を制限）
    double yearlyDeclinePoints;
    
    // 37歳以降は全選手共通の大幅減退
    if (age >= 37) {
      yearlyDeclinePoints = 5.0; // 年間5ポイント減退
    }
    // 年齢段階による減退
    else if (age >= 33 && age <= 36) {
      switch (growthType) {
        case 'early':
          yearlyDeclinePoints = 4.0; // 年間4ポイント減退
        case 'normal':
          yearlyDeclinePoints = 3.0; // 年間3ポイント減退
        case 'late':
          yearlyDeclinePoints = 2.0; // 年間2ポイント減退
        default:
          yearlyDeclinePoints = 3.0; // 年間3ポイント減退
      }
    }
    else if (age >= 28 && age <= 32) {
      switch (growthType) {
        case 'early':
          yearlyDeclinePoints = 2.0; // 年間2ポイント減退
        case 'normal':
          yearlyDeclinePoints = 0.0; // 成長停止
        case 'late':
          yearlyDeclinePoints = 0.0; // 成長継続
        default:
          yearlyDeclinePoints = 0.0;
      }
    }
    else {
      return player; // 若手は減退なし
    }
    
    // 1回の成長期あたりの減退ポイントを計算（年間4回の成長期）
    final declinePerGrowthPeriod = yearlyDeclinePoints / 4.0;
    
    // 1回の成長期あたり最大2ポイントまで制限
    final limitedDeclinePerGrowthPeriod = declinePerGrowthPeriod.clamp(0.0, 2.0);
    
    return _applyDeclineToPlayer(player, limitedDeclinePerGrowthPeriod);
  }

  // 選手に減退を適用（ポイントベースの減退）
  Player _applyDeclineToPlayer(Player player, double declinePoints) {
    if (declinePoints <= 0) return player;
    
    final updatedTechnicalAbilities = <TechnicalAbility, int>{};
    final updatedMentalAbilities = <MentalAbility, int>{};
    final updatedPhysicalAbilities = <PhysicalAbility, int>{};
    
    // 技術面能力値に減退を適用（ポイントベース）
    for (final entry in player.technicalAbilities.entries) {
      final newValue = (entry.value - declinePoints).round().clamp(25, 150);
      updatedTechnicalAbilities[entry.key] = newValue;
    }
    
    // メンタル面能力値に減退を適用（ポイントベース）
    for (final entry in player.mentalAbilities.entries) {
      final newValue = (entry.value - declinePoints).round().clamp(25, 150);
      updatedMentalAbilities[entry.key] = newValue;
    }
    
    // フィジカル面能力値に減退を適用（ポイントベース）
    for (final entry in player.physicalAbilities.entries) {
      final newValue = (entry.value - declinePoints).round().clamp(25, 150);
      updatedPhysicalAbilities[entry.key] = newValue;
    }
    
    return player.copyWith(
      technicalAbilities: updatedTechnicalAbilities,
      mentalAbilities: updatedMentalAbilities,
      physicalAbilities: updatedPhysicalAbilities,
    );
  }

  // 全選手（高校生・プロ選手）の成長データをデータベースに保存
  Future<void> _saveAllGrownPlayersToDatabase(DataService dataService) async {
    print('GameManager._saveAllGrownPlayersToDatabase: 開始');
    try {
      final db = await dataService.database;
      
      // バッチ更新用のデータを準備
      final batch = db.batch();
      int updateCount = 0;
      
      // 高校生選手の成長データを保存
      print('GameManager._saveAllGrownPlayersToDatabase: 高校生選手の処理開始');
      int highSchoolPlayerCount = 0;
      int highSchoolPlayerWithIdCount = 0;
      int highSchoolPlayerUpdatesCount = 0;
      
      for (final school in _currentGame!.schools) {
        for (final player in school.players) {
          highSchoolPlayerCount++;
          
          // 最初の3件のみ詳細ログを出力
          if (highSchoolPlayerCount <= 3) {
            print('GameManager._saveAllGrownPlayersToDatabase: 高校生選手チェック - 名前: ${player.name}, ID: ${player.id}, isRetired: ${player.isRetired}, isDefaultPlayer: ${player.isDefaultPlayer}');
          }
          
          if (!player.isRetired && !player.isDefaultPlayer && player.id != null) {
            highSchoolPlayerWithIdCount++;
            
            // 最初の選手のみ詳細ログを出力
            if (highSchoolPlayerWithIdCount == 1) {
              print('GameManager._saveAllGrownPlayersToDatabase: 高校生選手処理対象 - 名前: ${player.name}, ID: ${player.id}');
            }
            
            final updates = _collectPlayerAbilityUpdates(player);
            
            // 最初の選手のみ詳細ログを出力
            if (highSchoolPlayerWithIdCount == 1) {
              print('GameManager._saveAllGrownPlayersToDatabase: 高校生選手更新データ - 名前: ${player.name}, 更新内容: $updates');
            }
            
            if (updates.isNotEmpty) {
              highSchoolPlayerUpdatesCount++;
              try {
                batch.update(
                  'Player',
                  updates,
                  where: 'id = ?',
                  whereArgs: [player.id],
                );
                updateCount++;
                
                // 最初の選手のみ詳細ログを出力
                if (highSchoolPlayerWithIdCount == 1) {
                  print('GameManager._saveAllGrownPlayersToDatabase: 高校生選手バッチ更新追加 - 名前: ${player.name}, ID: ${player.id}');
                }
              } catch (e) {
                print('GameManager._saveAllGrownPlayersToDatabase: 高校生選手ID ${player.id} の更新でエラー: $e');
                print('更新データ: $updates');
              }
            } else if (highSchoolPlayerWithIdCount == 1) {
              print('GameManager._saveAllGrownPlayersToDatabase: 高校生選手更新データなし - 名前: ${player.name}, ID: ${player.id}');
            }
          }
        }
      }
      
      print('GameManager._saveAllGrownPlayersToDatabase: 高校生選手処理完了 - 総数: $highSchoolPlayerCount, IDあり: $highSchoolPlayerWithIdCount, 更新対象: $highSchoolPlayerUpdatesCount');
      
      // プロ野球選手の成長データを保存
      print('GameManager._saveAllGrownPlayersToDatabase: プロ野球選手の処理開始');
      int proPlayerCount = 0;
      int proPlayerWithIdCount = 0;
      int proPlayerUpdatesCount = 0;
      
      for (final team in _currentGame!.professionalTeams.teams) {
        for (final proPlayer in team.professionalPlayers ?? []) {
          proPlayerCount++;
          final player = proPlayer.player;
          
          if (player == null) {
            if (proPlayerCount <= 3) {
              print('GameManager._saveAllGrownPlayersToDatabase: プロ選手チェック - playerがnull');
            }
            continue;
          }
          
          // 最初の3件のみ詳細ログを出力
          if (proPlayerCount <= 3) {
            print('GameManager._saveAllGrownPlayersToDatabase: プロ選手チェック - 名前: ${player.name}, ID: ${player.id}, isRetired: ${player.isRetired}, isDefaultPlayer: ${player.isDefaultPlayer}');
          }
          
          if (player.isRetired || player.isDefaultPlayer || player.id == null) {
            if (proPlayerCount <= 3) {
              print('GameManager._saveAllGrownPlayersToDatabase: プロ選手除外 - 名前: ${player.name}, ID: ${player.id}, isRetired: ${player.isRetired}, isDefaultPlayer: ${player.isDefaultPlayer}');
            }
            continue;
          }
          
          proPlayerWithIdCount++;
          
          // 最初の選手のみ詳細ログを出力
          if (proPlayerWithIdCount == 1) {
            print('GameManager._saveAllGrownPlayersToDatabase: プロ選手処理対象 - 名前: ${player.name}, ID: ${player.id}');
          }
          
          final updates = _collectPlayerAbilityUpdates(player);
          
          // 最初の選手のみ詳細ログを出力
          if (proPlayerWithIdCount == 1) {
            print('GameManager._saveAllGrownPlayersToDatabase: プロ選手更新データ - 名前: ${player.name}, 更新内容: $updates');
          }
          
          if (updates.isNotEmpty) {
            proPlayerUpdatesCount++;
            try {
              batch.update(
                'Player',
                updates,
                where: 'id = ?',
                whereArgs: [player.id],
              );
              updateCount++;
              
              // 最初の選手のみ詳細ログを出力
              if (proPlayerWithIdCount == 1) {
                print('GameManager._saveAllGrownPlayersToDatabase: プロ選手バッチ更新追加 - 名前: ${player.name}, ID: ${player.id}');
              }
            } catch (e) {
              print('GameManager._saveAllGrownPlayersToDatabase: プロ選手ID ${player.id} の更新でエラー: $e');
              print('更新データ: $updates');
            }
          } else if (proPlayerWithIdCount == 1) {
            print('GameManager._saveAllGrownPlayersToDatabase: プロ選手更新データなし - 名前: ${player.name}, ID: ${player.id}');
          }
          
          // プロ野球選手の引退処理は年次処理で行うため、ここでは能力値の更新のみ
        }
      }
      
      print('GameManager._saveAllGrownPlayersToDatabase: プロ野球選手処理完了 - 総数: $proPlayerCount, IDあり: $proPlayerWithIdCount, 更新対象: $proPlayerUpdatesCount');
      
      // バッチ更新を実行
      print('GameManager._saveAllGrownPlayersToDatabase: バッチ更新実行前 - updateCount: $updateCount');
      
      if (updateCount > 0) {
        print('GameManager._saveAllGrownPlayersToDatabase: $updateCount件の選手データをバッチ更新で保存中...');
        try {
          await batch.commit(noResult: true);
          print('GameManager._saveAllGrownPlayersToDatabase: 選手データのバッチ更新完了');
        } catch (e) {
          print('GameManager._saveAllGrownPlayersToDatabase: バッチ更新でエラー: $e');
          rethrow;
        }
      } else {
        print('GameManager._saveAllGrownPlayersToDatabase: 更新対象の選手データがありません');
        print('GameManager._saveAllGrownPlayersToDatabase: 詳細 - 高校生選手: $highSchoolPlayerCount件中$highSchoolPlayerWithIdCount件にIDあり、$highSchoolPlayerUpdatesCount件が更新対象');
        print('GameManager._saveAllGrownPlayersToDatabase: 詳細 - プロ野球選手: $proPlayerCount件中$proPlayerWithIdCount件にIDあり、$proPlayerUpdatesCount件が更新対象');
      }
      
      // デバッグ用：更新後のデータを確認（最初の選手のみ）
      await _logFirstPlayerDatabaseCheck(dataService);
      
      print('GameManager._saveAllGrownPlayersToDatabase: 完了');
      
    } catch (e) {
      print('GameManager._saveAllGrownPlayersToDatabase: 選手データ保存中にエラーが発生しました: $e');
      rethrow;
    }
  }

  // 選手の能力値更新データを収集
  Map<String, dynamic> _collectPlayerAbilityUpdates(Player player) {
    final updates = <String, dynamic>{};
    
    // データベースから現在の選手データを取得して比較
    // 注意: この実装では、元の選手データとの比較が必要
    // 現在は簡易実装として、常に更新データを作成
    
    // 技術面能力値を収集
    for (final entry in player.technicalAbilities.entries) {
      final columnName = _getDatabaseColumnName(entry.key.name);
      if (columnName.isNotEmpty && entry.value != null) {
        updates[columnName] = entry.value;
      }
    }
    
    // メンタル面能力値を収集
    for (final entry in player.mentalAbilities.entries) {
      final columnName = _getDatabaseColumnName(entry.key.name);
      if (columnName.isNotEmpty && entry.value != null) {
        updates[columnName] = entry.value;
      }
    }
    
    // フィジカル面能力値を収集
    for (final entry in player.physicalAbilities.entries) {
      final columnName = _getDatabaseColumnName(entry.key.name);
      if (columnName.isNotEmpty && entry.value != null) {
        updates[columnName] = entry.value;
      }
    }
    
    // null値と空文字のカラム名を除外
    final cleanUpdates = <String, dynamic>{};
    for (final entry in updates.entries) {
      if (entry.value != null && entry.key.isNotEmpty && entry.key != '') {
        cleanUpdates[entry.key] = entry.value;
      }
    }
    
    // デバッグ用：更新データの内容をログ出力（最初の選手のみ）
    if (cleanUpdates.isNotEmpty) {
      // ログは呼び出し元で制御
    } else {
      print('GameManager._collectPlayerAbilityUpdates: 警告 - 選手ID ${player.id} の更新データが空です');
    }
    
    return cleanUpdates;
  }

  // 最初の選手のデータベース確認ログを出力
  Future<void> _logFirstPlayerDatabaseCheck(DataService dataService) async {
    try {
      final db = await dataService.database;
      
      // 高校生選手から最初の選手を取得
      Player? firstPlayer;
      for (final school in _currentGame!.schools) {
        for (final player in school.players) {
          if (!player.isRetired && !player.isDefaultPlayer && player.id != null) {
            firstPlayer = player;
            break;
          }
        }
        if (firstPlayer != null) break;
      }
      
      if (firstPlayer != null) {
        final result = await db.query(
          'Player',
          columns: ['bunt', 'contact', 'power'],
          where: 'id = ?',
          whereArgs: [firstPlayer.id],
        );
        if (result.isNotEmpty) {
          final dbData = result.first;
          print('GameManager._saveAllGrownPlayersToDatabase: データベース確認 - ID: ${firstPlayer.id}, bunt: ${dbData['bunt']}, contact: ${dbData['contact']}, power: ${dbData['power']}');
          
          // メモリ上のデータと比較
          final memoryBunt = firstPlayer.technicalAbilities[TechnicalAbility.bunt];
          final memoryContact = firstPlayer.technicalAbilities[TechnicalAbility.contact];
          final memoryPower = firstPlayer.technicalAbilities[TechnicalAbility.power];
          print('GameManager._saveAllGrownPlayersToDatabase: メモリ上のデータ - bunt: $memoryBunt, contact: $memoryContact, power: $memoryPower');
          
          if (dbData['bunt'] != memoryBunt || dbData['contact'] != memoryContact || dbData['power'] != memoryPower) {
            print('GameManager._saveAllGrownPlayersToDatabase: 警告 - データベースとメモリ上のデータが一致しません');
          }
        }
      }
    } catch (e) {
      print('GameManager._logFirstPlayerDatabaseCheck: データベース確認でエラー: $e');
    }
  }



  // 能力値名をデータベースカラム名に変換
  String _getDatabaseColumnName(String abilityName) {
    // 存在しないカラムを除外
    final excludedColumns = ['motivation', 'adaptability', 'consistency'];
    if (excludedColumns.contains(abilityName)) {
      return ''; // 空文字を返して、後で除外されるようにする
    }
    
    // 特殊なマッピング
    final mapping = {
      'plateDiscipline': 'plate_discipline',
      'oppositeFieldHitting': 'opposite_field_hitting',
      'pullHitting': 'pull_hitting',
      'batControl': 'bat_control',
      'swingSpeed': 'swing_speed',
      'catcherAbility': 'catcher_ability',
      'breakingBall': 'breaking_ball',
      'pitchMovement': 'pitch_movement',
      'workRate': 'work_rate',
      'selfDiscipline': 'self_discipline',
      'pressureHandling': 'pressure_handling',
      'clutchAbility': 'clutch_ability',
      'jumpingReach': 'jumping_reach',
      'naturalFitness': 'natural_fitness',
      'injuryProneness': 'injury_proneness',
    };
    
    // マッピングに存在する場合はそれを使用
    if (mapping.containsKey(abilityName)) {
      return mapping[abilityName]!;
    }
    
    // それ以外は通常のcamelCase → snake_case変換
    final result = abilityName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}'
    );
    
    return result;
  }

  // スカウトスキル成長メソッド
  void addScoutExperience(int amount) {
    if (_currentScout == null) return;
    
    final oldLevel = _currentScout!.level;
    _currentScout = _currentScout!.addExperience(amount);
    final newLevel = _currentScout!.level;
    
    // レベルアップ時の処理
    if (newLevel > oldLevel) {
      // レベルアップ時にスキルポイントを獲得（仮の実装）
      print('スカウトがレベルアップしました！ Lv.$oldLevel → Lv.$newLevel');
    }
    
    // Gameインスタンスも更新
    if (_currentGame != null) {
      _currentGame = _currentGame!.copyWith(
        experience: _currentScout!.experience,
        level: _currentScout!.level,
        reputation: _currentScout!.reputation,
      );
    }
  }

  // スカウトスキルを増加
  void increaseScoutSkill(ScoutSkill skill, int amount) {
    if (_currentScout == null) return;
    
    _currentScout = _currentScout!.increaseSkill(skill, amount);
    
    // Gameインスタンスのスカウトスキルも更新
    if (_currentGame != null) {
      final newScoutSkills = Map<ScoutSkill, int>.from(_currentGame!.scoutSkills);
      newScoutSkills[skill] = _currentScout!.getSkill(skill);
      
      _currentGame = _currentGame!.copyWith(
        scoutSkills: newScoutSkills,
      );
    }
  }

  // スカウトのAPを消費
  void consumeScoutActionPoints(int amount) {
    if (_currentScout == null) return;
    
    _currentScout = _currentScout!.consumeActionPoints(amount);
    
    // GameインスタンスのAPも更新
    if (_currentGame != null) {
      _currentGame = _currentGame!.copyWith(
        ap: _currentScout!.actionPoints,
      );
    }
  }

  // スカウトのAPを回復
  void restoreScoutActionPoints(int amount) {
    if (_currentScout == null) return;
    
    _currentScout = _currentScout!.restoreActionPoints(amount);
    
    // GameインスタンスのAPも更新
    if (_currentGame != null) {
      _currentGame = _currentGame!.copyWith(
        ap: _currentScout!.actionPoints,
      );
    }
  }

  // スカウトのお金を消費
  void spendScoutMoney(int amount) {
    if (_currentScout == null) return;
    
    _currentScout = _currentScout!.spendMoney(amount);
    
    // Gameインスタンスの予算も更新
    if (_currentGame != null) {
      _currentGame = _currentGame!.copyWith(
        budget: _currentScout!.money,
      );
    }
  }

  // スカウトのお金を獲得
  void earnScoutMoney(int amount) {
    if (_currentScout == null) return;
    
    _currentScout = _currentScout!.earnMoney(amount);
    
    // Gameインスタンスの予算も更新
    if (_currentGame != null) {
      _currentGame = _currentGame!.copyWith(
        budget: _currentScout!.money,
      );
    }
  }

  // スカウトの信頼度を変更
  void changeScoutTrustLevel(int amount) {
    if (_currentScout == null) return;
    
    _currentScout = _currentScout!.changeTrustLevel(amount);
  }

  // スカウトの評判を変更
  void changeScoutReputation(int amount) {
    if (_currentScout == null) return;
    
    _currentScout = _currentScout!.changeReputation(amount);
    
    // Gameインスタンスの評判も更新
    if (_currentGame != null) {
      _currentGame = _currentGame!.copyWith(
        reputation: _currentScout!.reputation,
      );
    }
  }

  // 選手の注目選手状態を更新
  Future<void> toggleScoutFavorite(Player player, DataService dataService) async {
    final newFavoriteState = !player.isScoutFavorite;
    
    // discoveredPlayersリスト内の選手を更新
    final index = _currentGame!.discoveredPlayers.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      final updatedPlayer = player.copyWith(isScoutFavorite: newFavoriteState);
      _currentGame!.discoveredPlayers[index] = updatedPlayer;
    }
    
    // 学校の選手リストも更新
    for (final school in _currentGame!.schools) {
      final playerIndex = school.players.indexWhere((p) => p.id == player.id);
      if (playerIndex != -1) {
        final updatedPlayer = player.copyWith(isScoutFavorite: newFavoriteState);
        school.players[playerIndex] = updatedPlayer;
      }
    }
    
    // データベースにも保存
    try {
      final db = await dataService.database;
      await db.update(
        'Player',
        {'is_scout_favorite': newFavoriteState ? 1 : 0},
        where: 'id = ?',
        whereArgs: [player.id],
      );
    } catch (e) {
      print('注目選手状態のデータベース保存エラー: $e');
    }
  }

  // 選手のお気に入り状態を更新
  Future<void> togglePlayerFavorite(Player player, DataService dataService) async {
    final newFavoriteState = !player.isPubliclyKnown;
    
    // discoveredPlayersリスト内の選手を更新
    final index = _currentGame!.discoveredPlayers.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      final updatedPlayer = player.copyWith(isPubliclyKnown: newFavoriteState);
      _currentGame!.discoveredPlayers[index] = updatedPlayer;
    }
    
    // 学校の選手リストも更新
    for (final school in _currentGame!.schools) {
      final playerIndex = school.players.indexWhere((p) => p.id == player.id);
      if (playerIndex != -1) {
        final updatedPlayer = player.copyWith(isPubliclyKnown: newFavoriteState);
        school.players[playerIndex] = updatedPlayer;
      }
    }
    
    // データベースにも保存
    try {
      final db = await dataService.database;
      await db.update(
        'Player',
        {'is_publicly_known': newFavoriteState ? 1 : 0},
        where: 'id = ?',
        whereArgs: [player.id],
      );
    } catch (e) {
      print('お気に入り状態のデータベース保存エラー: $e');
    }
  }

  // スカウト情報をJSONで保存
  Map<String, dynamic> saveScoutToJson() {
    if (_currentScout == null) return {};
    return _currentScout!.toJson();
  }

  // スカウト情報をJSONから復元
  void loadScoutFromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return;
    _currentScout = Scout.fromJson(json);
  }


  Map<String, int> _generatePositionFit(String mainPosition) {
    final random = Random();
    const positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final fit = <String, int>{};
    for (final pos in positions) {
      if (pos == mainPosition) {
        fit[pos] = 70 + random.nextInt(21); // 70-90
      } else {
        fit[pos] = 40 + random.nextInt(31); // 40-70
      }
    }
    return fit;
  }


  

  


  Future<void> _refreshPlayersFromDb(DataService dataService, {bool isRetry = false}) async {
    try {
      print('_refreshPlayersFromDb: 開始, _currentGame = ${_currentGame != null ? "loaded" : "null"}, isRetry: $isRetry');
      if (isRetry) {
        print('_refreshPlayersFromDb: 再試行モードです');
      }
      print('_refreshPlayersFromDb: 呼び出し元のスタックトレース: ${StackTrace.current}');
      if (_currentGame == null) {
        print('_refreshPlayersFromDb: _currentGameがnullのため終了');
        return;
      }
          final db = await dataService.database;
      print('_refreshPlayersFromDb: データベース接続完了');
      final playerMaps = await db.query('Player');
      
      // デバッグ用：最初のプレイヤーのデータ型を確認
      if (playerMaps.isNotEmpty) {
        final firstPlayer = playerMaps.first;
        print('_refreshPlayersFromDb: 最初のプレイヤーのデータ型確認:');
        print('  id: ${firstPlayer['id']} (${firstPlayer['id'].runtimeType})');
        print('  contact: ${firstPlayer['contact']} (${firstPlayer['contact'].runtimeType})');
        print('  power: ${firstPlayer['power']} (${firstPlayer['power'].runtimeType})');
        print('  grade: ${firstPlayer['grade']} (${firstPlayer['grade'].runtimeType})');
        print('  fame: ${firstPlayer['fame']} (${firstPlayer['fame'].runtimeType})');
        print('  talent: ${firstPlayer['talent']} (${firstPlayer['talent'].runtimeType})');
      }
      
    // school_idの分布を確認
    final schoolIdCounts = <int, int>{};
    for (final p in playerMaps) {
      final schoolId = p['school_id'] as int? ?? 0;
      schoolIdCounts[schoolId] = (schoolIdCounts[schoolId] ?? 0) + 1;
    }
    
    
    final personIds = playerMaps.map((p) => p['id'] as int).toList();
    final persons = <int, Map<String, dynamic>>{};
    if (personIds.isNotEmpty) {
      final personMaps = await db.query('Person', where: 'id IN (${List.filled(personIds.length, '?').join(',')})', whereArgs: personIds);
      for (final p in personMaps) {
        persons[p['id'] as int] = p;
      }
    }
    
    // 個別ポテンシャルを取得
    final potentialMaps = await db.query('PlayerPotentials');
    final potentials = <int, Map<String, int>>{};
    for (final p in potentialMaps) {
      final playerId = p['player_id'] as int;
      final playerPotentials = <String, int>{};
      
      // ポテンシャルデータを変換
      for (final key in p.keys) {
        if (key.endsWith('_potential') && p[key] != null) {
          final abilityName = key.replaceAll('_potential', '');
          playerPotentials[abilityName] = p[key] as int;
        }
      }
      
      potentials[playerId] = playerPotentials;
    }
    
    // スカウト分析データを取得（scout_idを指定して最新のデータを取得）
    final scoutAnalysisMaps = await db.query('ScoutAnalysis');
    final scoutAnalyses = <int, Map<String, int>>{};
    
    for (final sa in scoutAnalysisMaps) {
      final playerId = _safeIntCast(sa['player_id']);
      final scoutId = sa['scout_id'] as String? ?? 'default_scout';
      final scoutAnalysis = <String, int>{};
      
      // スカウト分析データを変換
      for (final key in sa.keys) {
        if (key.endsWith('_scouted') && sa[key] != null) {
          final abilityName = _getAbilityNameFromScoutColumn(key);
          if (abilityName != null) {
            scoutAnalysis[abilityName] = _safeIntCast(sa[key]);
          }
        }
      }
      
      // 最新の分析データのみを保持（同じプレイヤーIDとスカウトIDの場合）
      final currentAnalysisDate = _safeIntCast(sa['analysis_date']);
      final existingAnalysisDate = _safeIntCast(scoutAnalyses[playerId]?['_analysis_date'] ?? 0);
      if (!scoutAnalyses.containsKey(playerId) || currentAnalysisDate > existingAnalysisDate) {
        scoutAnalysis['_analysis_date'] = currentAnalysisDate;
        scoutAnalysis['_scout_id'] = scoutId.hashCode; // スカウトIDも保存
        scoutAnalyses[playerId] = scoutAnalysis;
      }
    }
    
    
    
    // 学校ごとにplayersを再構築
    final updatedSchools = _currentGame!.schools.map((school) {
      final schoolPlayers = playerMaps.where((p) => p['school_id'] == school.id).map((p) {
        final playerId = _safeIntCast(p['id']);
        final person = persons[playerId] ?? {};
        final individualPotentials = potentials[playerId];
        
        // 能力値システムの復元（データベースから直接読み込み）
        final technicalAbilities = <TechnicalAbility, int>{};
        final mentalAbilities = <MentalAbility, int>{};
        final physicalAbilities = <PhysicalAbility, int>{};
        
        // Technical abilities復元
        try {
          // デバッグ用：データベースの値を確認
          _debugDatabaseValue('contact', p['contact'], playerId);
          _debugDatabaseValue('power', p['power'], playerId);
          
          technicalAbilities[TechnicalAbility.contact] = _safeIntCast(p['contact']);
          technicalAbilities[TechnicalAbility.power] = _safeIntCast(p['power']);
          technicalAbilities[TechnicalAbility.plateDiscipline] = _safeIntCast(p['plate_discipline']);
          technicalAbilities[TechnicalAbility.bunt] = _safeIntCast(p['bunt']);
          technicalAbilities[TechnicalAbility.oppositeFieldHitting] = _safeIntCast(p['opposite_field_hitting']);
          technicalAbilities[TechnicalAbility.pullHitting] = _safeIntCast(p['pull_hitting']);
          technicalAbilities[TechnicalAbility.batControl] = _safeIntCast(p['bat_control']);
          technicalAbilities[TechnicalAbility.swingSpeed] = _safeIntCast(p['swing_speed']);
          technicalAbilities[TechnicalAbility.fielding] = _safeIntCast(p['fielding']);
          technicalAbilities[TechnicalAbility.throwing] = _safeIntCast(p['throwing']);
          technicalAbilities[TechnicalAbility.catcherAbility] = _safeIntCast(p['catcher_ability']);
          technicalAbilities[TechnicalAbility.control] = _safeIntCast(p['control']);
          technicalAbilities[TechnicalAbility.fastball] = _safeIntCast(p['fastball']);
          technicalAbilities[TechnicalAbility.breakingBall] = _safeIntCast(p['breaking_ball']);
          technicalAbilities[TechnicalAbility.pitchMovement] = _safeIntCast(p['pitch_movement']);
        } catch (e) {
          print('_refreshPlayersFromDb: Technical abilities復元でエラー: $e');
          print('_refreshPlayersFromDb: 問題のプレイヤーID: $playerId');
          print('_refreshPlayersFromDb: contact: ${p['contact']} (${p['contact'].runtimeType})');
          print('_refreshPlayersFromDb: power: ${p['power']} (${p['power'].runtimeType})');
          rethrow;
        }
        
        // Mental abilities復元
        try {
          mentalAbilities[MentalAbility.concentration] = _safeIntCast(p['concentration']);
          mentalAbilities[MentalAbility.anticipation] = _safeIntCast(p['anticipation']);
          mentalAbilities[MentalAbility.vision] = _safeIntCast(p['vision']);
          mentalAbilities[MentalAbility.composure] = _safeIntCast(p['composure']);
          mentalAbilities[MentalAbility.aggression] = _safeIntCast(p['aggression']);
          mentalAbilities[MentalAbility.bravery] = _safeIntCast(p['bravery']);
          mentalAbilities[MentalAbility.leadership] = _safeIntCast(p['leadership']);
          mentalAbilities[MentalAbility.workRate] = _safeIntCast(p['work_rate']);
          mentalAbilities[MentalAbility.selfDiscipline] = _safeIntCast(p['self_discipline']);
          mentalAbilities[MentalAbility.ambition] = _safeIntCast(p['ambition']);
          mentalAbilities[MentalAbility.teamwork] = _safeIntCast(p['teamwork']);
          mentalAbilities[MentalAbility.positioning] = _safeIntCast(p['positioning']);
          mentalAbilities[MentalAbility.pressureHandling] = _safeIntCast(p['pressure_handling']);
          mentalAbilities[MentalAbility.clutchAbility] = _safeIntCast(p['clutch_ability']);
        } catch (e) {
          print('_refreshPlayersFromDb: Mental abilities復元でエラー: $e');
          print('_refreshPlayersFromDb: 問題のプレイヤーID: $playerId');
          rethrow;
        }
        
        // Physical abilities復元
        try {
          physicalAbilities[PhysicalAbility.acceleration] = _safeIntCast(p['acceleration']);
          physicalAbilities[PhysicalAbility.agility] = _safeIntCast(p['agility']);
          physicalAbilities[PhysicalAbility.balance] = _safeIntCast(p['balance']);
          physicalAbilities[PhysicalAbility.jumpingReach] = _safeIntCast(p['jumping_reach']);
          physicalAbilities[PhysicalAbility.flexibility] = _safeIntCast(p['flexibility']);
          physicalAbilities[PhysicalAbility.naturalFitness] = _safeIntCast(p['natural_fitness']);
          physicalAbilities[PhysicalAbility.injuryProneness] = _safeIntCast(p['injury_proneness']);
          physicalAbilities[PhysicalAbility.stamina] = _safeIntCast(p['stamina']);
          physicalAbilities[PhysicalAbility.strength] = _safeIntCast(p['strength']);
          physicalAbilities[PhysicalAbility.pace] = _safeIntCast(p['pace']);
        } catch (e) {
          print('_refreshPlayersFromDb: Physical abilities復元でエラー: $e');
          print('_refreshPlayersFromDb: 問題のプレイヤーID: $playerId');
          rethrow;
        }
        

        
        final scoutAnalysisData = scoutAnalyses[playerId];
        
        // 現在のゲーム状態から発掘情報を復元（学校の選手リストから検索）
        final existingPlayer = school.players.firstWhere(
          (p) => p.name == (person['name'] as String? ?? '名無し'),
          orElse: () => Player(
            name: person['name'] as String? ?? '名無し',
            school: school.name,
            grade: _safeIntCast(p['grade']),
            position: p['position'] as String? ?? '',
            personality: person['personality'] as String? ?? '',
            fame: _safeIntCast(p['fame']),
            isDiscovered: false,
            isPubliclyKnown: (p['is_publicly_known'] as int?) == 1, // データベースから読み込み
            isScoutFavorite: false,
            isGraduated: (p['is_graduated'] as int?) == 1, // 卒業フラグを読み込み
            graduatedAt: p['graduated_at'] != null ? DateTime.tryParse(p['graduated_at'] as String) : null, // 卒業日を読み込み
                      discoveredBy: null,
          scoutedDates: [],
            abilityKnowledge: <String, int>{},
            type: PlayerType.highSchool,
            yearsAfterGraduation: 0,
            pitches: [],
            technicalAbilities: technicalAbilities,
            mentalAbilities: mentalAbilities,
            physicalAbilities: physicalAbilities,
            mentalGrit: (p['mental_grit'] as num?)?.toDouble() ?? 0.0,
            growthRate: p['growth_rate'] as double? ?? 1.0,
            peakAbility: _safeIntCast(p['peak_ability']),
            positionFit: _generatePositionFit(p['position'] as String? ?? '投手'),
            talent: _safeIntCast(p['talent']),
            growthType: (p['growthType'] is String) ? p['growthType'] as String : (p['growthType']?.toString() ?? 'normal'),
            individualPotentials: individualPotentials,
            scoutAnalysisData: scoutAnalysisData,
          ),
        );

        final isPubliclyKnownFromDb = (p['is_publicly_known'] as int?) == 1;
        final isScoutFavoriteFromDb = (p['is_scout_favorite'] as int?) == 1;
        final isGraduatedFromDb = (p['is_graduated'] as int?) == 1;
        final graduatedAtFromDb = p['graduated_at'] as String?;
        final isDefaultPlayerFromDb = (p['is_default_player'] as int?) == 1; // デフォルト選手フラグを読み込み

        final player;
        try {
          player = Player(
            id: playerId,
            name: person['name'] as String? ?? '名無し',
            school: school.name,
            grade: _safeIntCast(p['grade']),
            position: p['position'] as String? ?? '',
            personality: person['personality'] as String? ?? '',
            fame: _safeIntCast(p['fame']), // fameフィールドを追加
            isWatched: existingPlayer.isWatched,
            isDiscovered: existingPlayer.isDiscovered,
            isPubliclyKnown: isPubliclyKnownFromDb, // データベースから読み込み
            isScoutFavorite: isScoutFavoriteFromDb, // データベースから読み込み
            isGraduated: isGraduatedFromDb, // 卒業フラグを読み込み
            graduatedAt: graduatedAtFromDb != null ? DateTime.tryParse(graduatedAtFromDb) : null, // 卒業日を読み込み
            discoveredBy: existingPlayer.discoveredBy,
            scoutedDates: existingPlayer.scoutedDates,
            abilityKnowledge: existingPlayer.abilityKnowledge,
            pitches: [],
            technicalAbilities: technicalAbilities,
            mentalAbilities: mentalAbilities,
            physicalAbilities: physicalAbilities,
            mentalGrit: (p['mental_grit'] as num?)?.toDouble() ?? 0.0,
            growthRate: p['growth_rate'] as double? ?? 1.0,
            peakAbility: _safeIntCast(p['peak_ability']),
            positionFit: _generatePositionFit(p['position'] as String? ?? '投手'),
            talent: _safeIntCast(p['talent']),
            growthType: (p['growthType'] is String) ? p['growthType'] as String : (p['growthType']?.toString() ?? 'normal'),
            individualPotentials: individualPotentials,
            scoutAnalysisData: scoutAnalysisData, // スカウト分析データを設定
            isDefaultPlayer: isDefaultPlayerFromDb, // デフォルト選手フラグを設定
          );
        } catch (e) {
          print('_refreshPlayersFromDb: Player作成でエラー: $e');
          print('_refreshPlayersFromDb: 問題のプレイヤーID: $playerId');
          print('_refreshPlayersFromDb: grade: ${p['grade']} (${p['grade'].runtimeType})');
          print('_refreshPlayersFromDb: fame: ${p['fame']} (${p['fame'].runtimeType})');
          print('_refreshPlayersFromDb: peak_ability: ${p['peak_ability']} (${p['peak_ability'].runtimeType})');
          print('_refreshPlayersFromDb: talent: ${p['talent']} (${p['talent'].runtimeType})');
          rethrow;
        }
        

        
        return player;
      }).toList();
      return school.copyWith(players: schoolPlayers.cast<Player>());
    }).toList();
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
    

    
    } catch (e) {
      print('_refreshPlayersFromDb: エラーが発生しました: $e');
      
      // データ型エラーの場合は修復を試行（再試行でない場合のみ）
      if (!isRetry && e.toString().contains('type \'String\' is not a subtype of type \'int?\'')) {
        print('_refreshPlayersFromDb: データ型エラーを検出。データベース修復を試行します...');
        try {
          await dataService.repairNumericData();
          print('_refreshPlayersFromDb: データベース修復が完了しました。再度読み込みを試行します...');
          // 修復後に再度実行（再試行フラグを設定）
          return await _refreshPlayersFromDb(dataService, isRetry: true);
        } catch (repairError) {
          print('_refreshPlayersFromDb: データベース修復でエラーが発生しました: $repairError');
        }
      }
      
      rethrow;
    }
  }

  /// 週送り時にアクションを実行し、リザルトを返す
  Future<List<String>> advanceWeekWithResults(NewsService newsService, DataService dataService) async {
    // 既に処理中の場合は早期リターン
    if (_isAdvancingWeek || _isProcessingGrowth) {
      print('GameManager.advanceWeekWithResults: 既に処理中のため、処理をスキップします');
      return [];
    }
    
    final results = <String>[];
    if (_currentGame == null) return results;
    
    // 週進行処理開始
    _updateAdvancingWeekStatus(true);
    
    print('GameManager.advanceWeekWithResults: 週送り処理開始');
    print('GameManager.advanceWeekWithResults: 現在の状態 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}, 年: ${_currentGame!.currentYear}');
    
    try {
      // スカウトアクションを実行
      print('GameManager.advanceWeekWithResults: スカウトアクション実行開始');
      final scoutResults = await executeScoutActions(dataService);
      results.addAll(scoutResults);
      print('GameManager.advanceWeekWithResults: スカウトアクション実行完了 - 結果数: ${scoutResults.length}');
      
      // 週送り（週進行、AP/予算リセット、アクションリセット）
      print('GameManager.advanceWeekWithResults: 週送り処理開始');
      print('GameManager.advanceWeekWithResults: 週送り前 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}');
      
      _currentGame = _currentGame!
        .advanceWeek()
        .resetWeeklyResources(newAp: 15, newBudget: _currentGame!.budget)
        .resetActions();
      
      print('GameManager.advanceWeekWithResults: 週送り後 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}');
      print('GameManager.advanceWeekWithResults: 週送り処理完了');

      // ペナントレースの進行
      if (isPennantRaceActive) {
        print('GameManager.advanceWeekWithResults: ペナントレース進行開始');
        _advancePennantRace();
        print('GameManager.advanceWeekWithResults: ペナントレース進行完了');
      }
      
      // 高校野球大会の初期化と進行
      print('GameManager.advanceWeekWithResults: 高校野球大会処理開始');
      _initializeHighSchoolTournaments();
      _advanceHighSchoolTournaments();
      print('GameManager.advanceWeekWithResults: 高校野球大会処理完了');
      
      // 8月4週終了後（9月1週開始前）に3年生の野球部引退処理
      // 8月4週（週20）の終了時に実行
      final isGraduation = _currentGame!.currentMonth == 8 && _currentGame!.currentWeekOfMonth == 4;
      final graduationWeek = _calculateCurrentWeek(_currentGame!.currentMonth, _currentGame!.currentWeekOfMonth);
      print('GameManager.advanceWeekWithResults: 3年生引退処理判定 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}, 引退処理: $isGraduation, 総週数: $graduationWeek');
      
      if (isGraduation) {
        // 卒業処理が既に実行済みかチェック（重複実行を防ぐ）
        final hasGraduationProcessed = _currentGame!.schools.any((school) => 
          school.players.any((player) => player.isGraduated)
        );
        
        if (hasGraduationProcessed) {
          print('GameManager.advanceWeekWithResults: 3年生引退処理は既に実行済みです。スキップします。');
          results.add('3年生引退処理は既に完了しています。');
        } else {
          print('GameManager.advanceWeekWithResults: 3年生引退処理開始');
          _updateGrowthStatus(true, '3年生の野球部引退処理を実行中...');
          
          try {
            await graduateThirdYearStudents(dataService);
            await _refreshPlayersFromDb(dataService);
            
            // 卒業生数を計算
            int totalGraduated = 0;
            for (final school in _currentGame!.schools) {
              totalGraduated += school.players.where((p) => p.isGraduated).length;
            }
            
            // 引退ニュースを生成
            newsService.generateGraduationNews(
              year: _currentGame!.currentYear,
              month: _currentGame!.currentMonth,
              weekOfMonth: _currentGame!.currentWeekOfMonth,
              totalGraduated: totalGraduated,
            );
            
            results.add('3年生${totalGraduated}名が野球部を引退しました。引退した選手は引退フラグが設定され、今後の成長を追跡できます。');
            print('GameManager.advanceWeekWithResults: 3年生引退処理完了');
          } catch (e) {
            print('GameManager.advanceWeekWithResults: 3年生引退処理でエラーが発生しました: $e');
            _updateGrowthStatus(false, '3年生引退処理でエラーが発生しました');
            // 週進行処理状態をリセット
            _updateAdvancingWeekStatus(false);
            rethrow;
          }
        }
      }
      
      // 12月4週（週36）の終了時にプロ野球選手引退処理、3月4週（週48）の終了時に学年アップ処理、4月1週（週1）の開始時に新入生生成
      final isProfessionalRetirement = _currentGame!.currentMonth == 12 && _currentGame!.currentWeekOfMonth == 4;
      final isGradeUp = _currentGame!.currentMonth == 3 && _currentGame!.currentWeekOfMonth == 4;
      final isNewYear = _currentGame!.currentMonth == 4 && _currentGame!.currentWeekOfMonth == 1;
      print('GameManager.advanceWeekWithResults: 処理判定 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}, プロ野球引退処理: $isProfessionalRetirement, 学年アップ処理: $isGradeUp, 新年度処理: $isNewYear');
      
              if (isProfessionalRetirement) {
        // プロ野球選手引退処理が既に実行済みかチェック（重複実行を防ぐ）
        final hasRetirementProcessed = _currentGame!.professionalTeams.teams.any((team) => 
          team.professionalPlayers?.any((pp) => pp.player?.isRetired == true) == true
        );
        
        if (hasRetirementProcessed) {
          print('GameManager.advanceWeekWithResults: プロ野球選手引退処理は既に実行済みです。スキップします。');
          results.add('プロ野球選手引退処理は既に完了しています。');
        } else {
          print('GameManager.advanceWeekWithResults: プロ野球選手引退処理開始');
          _updateGrowthStatus(true, 'プロ野球選手の引退処理を実行中...');
          
          try {
            await _processProfessionalPlayerRetirements(dataService);
            await _refreshPlayersFromDb(dataService);
            
            _updateGrowthStatus(false, 'プロ野球選手引退処理完了');
            print('GameManager.advanceWeekWithResults: プロ野球選手引退処理完了');
            
            // 引退処理のニュース生成
            results.add('プロ野球選手の引退処理が完了しました。');
            
          } catch (e) {
            print('GameManager.advanceWeekWithResults: プロ野球選手引退処理でエラーが発生しました: $e');
            _updateGrowthStatus(false, 'プロ野球選手引退処理でエラーが発生しました');
            results.add('プロ野球選手引退処理中にエラーが発生しましたが、処理を継続します。');
          }
        }
      }
      
      // 3月4週（週48）の終了時に学年アップ処理
      if (isGradeUp) {
        // 学年アップ処理が既に実行済みかチェック（重複実行を防ぐ）
        // 現在の年で学年アップ処理が既に実行済みかチェック
        // 学年アップ処理が実行済みかどうかは、現在の年で学年アップ処理が実行されたかどうかで判定
        final hasGradeUpProcessed = _currentGame!.hasGradeUpProcessedThisYear ?? false;
        
        if (hasGradeUpProcessed) {
          print('GameManager.advanceWeekWithResults: 学年アップ処理は既に実行済みです。スキップします。');
          results.add('学年アップ処理は既に完了しています。');
        } else {
          print('GameManager.advanceWeekWithResults: 学年アップ処理開始');
          _updateGrowthStatus(true, '学年アップ処理を実行中...');
          
          try {
            await promoteAllStudents(dataService);
            await _refreshPlayersFromDb(dataService);
            
            // 学年アップ処理完了フラグを設定
            _currentGame = _currentGame!.copyWith(hasGradeUpProcessedThisYear: true);
            
            _updateGrowthStatus(false, '学年アップ処理完了');
            print('GameManager.advanceWeekWithResults: 学年アップ処理完了');
            
            // 学年アップのニュース生成
            results.add('学年が1つ上がりました。');
            
          } catch (e) {
            print('GameManager.advanceWeekWithResults: 学年アップ処理でエラーが発生しました: $e');
            _updateGrowthStatus(false, '学年アップ処理でエラーが発生しました');
            results.add('学年アップ処理中にエラーが発生しましたが、処理を継続します。');
          }
        }
      }
      
      // 4月1週（週1）の開始時に新入生生成
      if (isNewYear) {
        // 新年度処理が既に実行済みかチェック（重複実行を防ぐ）
        // 現在の年で新年度処理が既に実行済みかチェック
        final hasNewYearProcessed = _currentGame!.hasNewYearProcessedThisYear ?? false;
        
        if (hasNewYearProcessed) {
          print('GameManager.advanceWeekWithResults: 新年度処理は既に実行済みです。スキップします。');
          results.add('新年度処理は既に完了しています。');
        } else {
          print('GameManager.advanceWeekWithResults: 新年度処理開始');
          _updateGrowthStatus(true, '新年度処理を実行中...');
        
        try {
          // 新入生生成処理
          await generateNewStudentsForAllSchoolsDb(dataService);
      
          // 新年度処理完了フラグを設定
          _currentGame = _currentGame!.copyWith(hasNewYearProcessedThisYear: true);
          
          _updateGrowthStatus(false, '新年度処理完了');
          print('GameManager.advanceWeekWithResults: 新年度処理完了');
          
          // 新年度のニュース生成
          results.add('新年度が始まりました。新入生が各学校に入学しました。');
          
        } catch (e) {
          print('GameManager.advanceWeekWithResults: 新年度処理でエラーが発生しました: $e');
          _updateGrowthStatus(false, '新年度処理でエラーが発生しました');
          // エラーが発生しても処理を継続（ゲームが止まらないように）
          results.add('新年度処理中にエラーが発生しましたが、処理を継続します。');
        }
      }
    }
    
    // 週送り後の新しい週で成長判定
    print('GameManager.advanceWeekWithResults: 成長判定開始');
    final currentWeek = _calculateCurrentWeek(_currentGame!.currentMonth, _currentGame!.currentWeekOfMonth);
    final isGrowthWeek = GrowthService.shouldGrow(currentWeek);
    
    // 成長処理の実行条件を修正
    // 4週固定の場合、月の第1週（週1）で成長処理を実行
    final isFirstWeekOfMonth = _currentGame!.currentWeekOfMonth == 1;
    final shouldExecuteGrowth = isGrowthWeek && isFirstWeekOfMonth;
    
    print('GameManager.advanceWeekWithResults: 成長判定詳細 - 現在週: $currentWeek, 成長週か: $isGrowthWeek, 月第1週か: $isFirstWeekOfMonth, 成長実行するか: $shouldExecuteGrowth');
    print('GameManager.advanceWeekWithResults: 現在の状態 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}, 年: ${_currentGame!.currentYear}');
    
    if (shouldExecuteGrowth) {
      print('GameManager.advanceWeek: 成長週を検出（月第1週） - 全選手の成長処理を開始');
      _updateGrowthStatus(true, '選手の成長期が訪れました。成長処理を実行中...');
      
      try {
        // 成長処理の詳細を表示
        final currentMonth = _currentGame!.currentMonth;
        String growthPeriodName;
        switch (currentMonth) {
          case 5:
            growthPeriodName = '春の成長期（週5）';
            break;
          case 8:
            growthPeriodName = '夏の成長期（週17）';
            break;
          case 11:
            growthPeriodName = '秋の成長期（週29）';
            break;
          case 2:
            growthPeriodName = '冬の成長期（週41）';
            break;
          default:
            growthPeriodName = '成長期';
        }
        
        _updateGrowthStatus(true, '$growthPeriodNameが始まりました。選手たちの能力値が向上しています...');
        
        await growAllPlayers(dataService);
        
        // 成長後に新たに注目選手になった選手をチェック
        _updateGrowthStatus(true, '注目選手の更新を確認中...');
        _updatePubliclyKnownPlayersAfterGrowth();
        
        results.add('$growthPeriodNameが終了しました。選手たちが大きく成長しました！');
        
              // 成長後のニュース生成（ログ出力停止）
      _updateGrowthStatus(true, '成長ニュースを生成中...');
      // newsService.generateAllPlayerNews(
      //   _currentGame!.schools,
      //   year: _currentGame!.currentYear,
      //   month: _currentGame!.currentMonth,
      //   weekOfMonth: _currentGame!.currentWeekOfMonth,
      // );
        
        _updateGrowthStatus(false, '成長処理完了');
        print('GameManager.advanceWeek: 成長処理完了');
      } catch (e) {
        _updateGrowthStatus(false, '成長処理でエラーが発生しました');
        print('GameManager.advanceWeek: 成長処理でエラーが発生しました: $e');
        
        // データ型エラーの場合は修復を試行
        if (e.toString().contains('type \'String\' is not a subtype of type \'int?\'')) {
          print('GameManager.advanceWeek: データ型エラーを検出。データベース修復を試行します...');
          try {
            await dataService.repairNumericData();
            print('GameManager.advanceWeek: データベース修復が完了しました。再度成長処理を試行します...');
            // 修復後に再度実行
            await growAllPlayers(dataService);
            // 修復が成功した場合は処理を続行
          } catch (repairError) {
            print('GameManager.advanceWeek: データベース修復でエラーが発生しました: $repairError');
          }
        }
        
        // 週進行処理状態をリセット
        _updateAdvancingWeekStatus(false);
        rethrow;
      }
    } else {
      print('GameManager.advanceWeek: 成長週ではありません - 成長処理をスキップします');
      print('GameManager.advanceWeek: 理由: isGrowthWeek=$isGrowthWeek, isFirstWeekOfMonth=$isFirstWeekOfMonth');
    }
      
    } catch (e) {
      print('GameManager.advanceWeekWithResults: 週進行処理でエラーが発生しました: $e');
      
      // データ型エラーの場合は修復を試行
      if (e.toString().contains('type \'String\' is not a subtype of type \'int?\'')) {
        print('GameManager.advanceWeekWithResults: データ型エラーを検出。データベース修復を試行します...');
        try {
          await dataService.repairNumericData();
          print('GameManager.advanceWeekWithResults: データベース修復が完了しました。再度週進行を試行します...');
          // 修復後に再度実行
          return await advanceWeekWithResults(newsService, dataService);
        } catch (repairError) {
          print('GameManager.advanceWeekWithResults: データベース修復でエラーが発生しました: $repairError');
        }
      }
      
      // 週進行処理状態をリセット
      _updateAdvancingWeekStatus(false);
      rethrow;
    }
    
    // 週送り時のニュース生成（毎週）（ログ出力停止）
    // print('GameManager.advanceWeekWithResults: ニュース生成開始');
    _generateWeeklyNews(newsService);
    // print('GameManager.advanceWeekWithResults: ニュース生成完了');
    
    // スカウトのAPを最大値まで回復
    if (_currentScout != null) {
      print('GameManager.advanceWeekWithResults: スカウトAP回復処理開始');
      _currentScout = _currentScout!.restoreActionPoints(_currentScout!.maxActionPoints);
      // GameインスタンスのAPも更新
      _currentGame = _currentGame!.copyWith(
        ap: _currentScout!.actionPoints,
      );
      print('GameManager.advanceWeekWithResults: スカウトAP回復処理完了 - 現在AP: ${_currentScout!.actionPoints}');
    }
    
    // ニュースをゲームデータに保存（ログ出力停止）
    // print('GameManager.advanceWeekWithResults: ニュース保存開始');
    saveNewsToGame(newsService);
    // print('GameManager.advanceWeekWithResults: ニュース保存完了');
    
    // オートセーブ（週送り完了後）
    print('GameManager.advanceWeekWithResults: オートセーブ開始');
    await saveGame();
    await _gameDataManager.saveAutoGameData(_currentGame!);
    print('GameManager.advanceWeekWithResults: オートセーブ完了');
    
    print('GameManager.advanceWeekWithResults: 週送り処理完了');
    
    // 週進行処理完了
    _updateAdvancingWeekStatus(false);
    
    return results;
  }

  /// 週送り時のニュース生成
  void _generateWeeklyNews(NewsService newsService) {
    if (_currentGame == null) return;
    
    // 週送り時のニュース生成
    newsService.generateWeeklyNews(
      _currentGame!.schools,
      year: _currentGame!.currentYear,
      month: _currentGame!.currentMonth,
      weekOfMonth: _currentGame!.currentWeekOfMonth,
    );
    
    // 月別ニュース生成（月の第1週に生成）
    if (_currentGame!.currentWeekOfMonth == 1) {
      newsService.generateMonthlyNews(
        _currentGame!.schools,
        _currentGame!.currentMonth,
        year: _currentGame!.currentYear,
        month: _currentGame!.currentMonth,
        weekOfMonth: _currentGame!.currentWeekOfMonth,
      );
    }
  }

  // 安全なint型変換ヘルパーメソッド
  int _safeIntCast(dynamic value) {
    try {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        print('_safeIntCast: 文字列をintに変換できませんでした: "$value"');
        return 0;
      }
      if (value is double) {
        return value.toInt();
      }
      print('_safeIntCast: 予期しない型です: ${value.runtimeType}, 値: $value');
      return 0;
    } catch (e) {
      print('_safeIntCast: エラーが発生しました: $e, 値: $value, 型: ${value.runtimeType}');
      return 0;
    }
  }
  
  // デバッグ用：データベースの値の詳細情報を出力
  void _debugDatabaseValue(String columnName, dynamic value, int? playerId) {
    if (value == null) {
      print('_debugDatabaseValue: $columnName = null (プレイヤーID: $playerId)');
      return;
    }
    
    final type = value.runtimeType;
    final stringValue = value.toString();
    
    if (type == String && stringValue.length > 50) {
      print('_debugDatabaseValue: $columnName = "${stringValue.substring(0, 50)}..." (${type}, プレイヤーID: $playerId)');
    } else {
      print('_debugDatabaseValue: $columnName = "$stringValue" (${type}, プレイヤーID: $playerId)');
    }
  }

  // 月の週数を取得（1年間48週、4週固定）
  int _getWeeksInMonth(int month) {
    // 全月4週固定（シンプルで分かりやすい）
    return 4;
  }

  // 現在の週番号を計算（4月1週を1週目として計算）
  int _calculateCurrentWeek(int month, int weekOfMonth) {
    // 4週固定なので計算が簡単
    // 4月1週：週1、5月1週：週5、8月1週：週17、11月1週：週29、2月1週：週41
    int totalWeeks;
    
    if (month >= 4) {
      // 4月以降は通常の計算
      totalWeeks = (month - 4) * 4 + weekOfMonth;
    } else {
      // 1月、2月、3月は翌年の週として計算
      totalWeeks = (month + 8) * 4 + weekOfMonth; // (1+8)*4=36, (2+8)*4=40, (3+8)*4=44
    }
    
    print('GameManager._calculateCurrentWeek: 4週固定計算 - 月=$month, 月内週=$weekOfMonth → 総週数=$totalWeeks');
    
    return totalWeeks;
  }



  void advanceWeek(NewsService newsService, DataService dataService) async {
    if (_currentGame != null) {
      _currentGame = _currentGame!.advanceWeek();
      // 必要に応じて週遷移時のイベントをここに追加
      triggerRandomEvent(newsService);
      
      // スカウトアクションを実行
      final scoutResults = await executeScoutActions(dataService);
      if (scoutResults.isNotEmpty) {
        print('スカウトアクション実行結果: ${scoutResults.join(', ')}');
      }
      
      // オートセーブ
      await saveGame();
      await _gameDataManager.saveAutoGameData(_currentGame!);
    }
  }

  void addActionToGame(GameAction action) {
    if (_currentGame != null) {
      _currentGame = _currentGame!.addAction(action);
    }
  }

  // スカウト分析カラム名から能力値名を取得
  String? _getAbilityNameFromScoutColumn(String columnName) {
    // _scoutedを除去
    final withoutSuffix = columnName.replaceAll('_scouted', '');
    
    // 逆マッピング
    final reverseMapping = {
      'plate_discipline': 'plateDiscipline',
      'opposite_field_hitting': 'oppositeFieldHitting',
      'pull_hitting': 'pullHitting',
      'bat_control': 'batControl',
      'swing_speed': 'swingSpeed',
      'catcher_ability': 'catcherAbility',
      'breaking_ball': 'breakingBall',
      'pitch_movement': 'pitchMovement',
      'work_rate': 'workRate',
      'self_discipline': 'selfDiscipline',
      'pressure_handling': 'pressureHandling',
      'clutch_ability': 'clutchAbility',
      'jumping_reach': 'jumpingReach',
      'natural_fitness': 'naturalFitness',
      'injury_proneness': 'injuryProneness',
    };
    
    // マッピングに存在する場合はそれを使用
    if (reverseMapping.containsKey(withoutSuffix)) {
      return reverseMapping[withoutSuffix]!;
    }
    
    // それ以外は通常のsnake_case → camelCase変換
    return withoutSuffix.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase()
    );
  }

  // セーブ
  Future<void> saveGame() async {
    if (_currentGame != null) {
      await _gameDataManager.saveGameData(_currentGame!, 1);
    }
  }

  // ロード
  Future<bool> loadGame(dynamic slot, DataService dataService) async {
    try {
      print('GameManager: loadGame開始 - スロット: $slot');
      final game = await _gameDataManager.loadGameData(slot);
      if (game != null) {
        _currentGame = game;
        print('GameManager: ゲームデータ読み込み完了');
        
        // ゲームデータから選手データが正しく復元されているかチェック
        final totalPlayers = game.schools.fold<int>(0, (sum, school) => sum + school.players.length);
        print('GameManager: 復元された選手数: $totalPlayers');
        
        // 選手データのIDが正しく設定されているかチェック
        bool hasValidPlayerIds = true;
        for (final school in game.schools) {
          for (final player in school.players) {
            if (player.id == null) {
              hasValidPlayerIds = false;
              print('GameManager: 選手IDがnull: ${player.name}');
              break;
            }
          }
          if (!hasValidPlayerIds) break;
        }
        
        // 選手データが不足している場合、またはIDが正しく設定されていない場合は_refreshPlayersFromDbを呼び出し
        if (totalPlayers == 0 || !hasValidPlayerIds) {
          print('GameManager: 選手データの修正が必要なため、データベースから再読み込み');
          await _refreshPlayersFromDb(dataService);
          print('GameManager: _refreshPlayersFromDb完了');
        }
        
        // プロ野球選手をデータベースから読み込み
        await _loadProfessionalPlayersFromDb(dataService);
        
        return true;
      }
      print('GameManager: ゲームデータが見つかりませんでした');
      return false;
    } catch (e, stackTrace) {
      print('GameManager: loadGame エラーが発生しました: $e');
      print('GameManager: loadGame スタックトレース: $stackTrace');
      return false;
    }
  }

  // プロ野球選手をデータベースから読み込み
  Future<void> _loadProfessionalPlayersFromDb(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager._loadProfessionalPlayersFromDb: プロ野球選手の読み込み開始');
    
    try {
      final db = await dataService.database;
      
      // ProfessionalPlayerテーブルからプロ選手情報を取得
      final proPlayerMaps = await db.query('ProfessionalPlayer');
      if (proPlayerMaps.isEmpty) {
        print('GameManager._loadProfessionalPlayersFromDb: ProfessionalPlayerテーブルにデータがありません');
        return;
      }
      
      print('GameManager._loadProfessionalPlayersFromDb: ${proPlayerMaps.length}件のプロ選手データを読み込み中...');
      
      // 各チームのプロ選手リストを更新
      final updatedTeams = <ProfessionalTeam>[];
      
      for (final team in _currentGame!.professionalTeams.teams) {
        final teamProPlayers = proPlayerMaps
            .where((proMap) => proMap['team_id'] == team.id)
            .toList();
        
        final validProPlayers = <ProfessionalPlayer>[];
        
        for (final proMap in teamProPlayers) {
          final playerId = proMap['player_id'] as int;
          
          print('GameManager._loadProfessionalPlayersFromDb: プロ選手データ - proMap: $proMap');
          print('GameManager._loadProfessionalPlayersFromDb: playerId: $playerId');
          
          // Playerテーブルから選手データを取得
          final playerMaps = await db.query('Player', where: 'id = ?', whereArgs: [playerId]);
          if (playerMaps.isEmpty) {
            print('GameManager._loadProfessionalPlayersFromDb: PlayerテーブルにplayerId=$playerIdのデータが見つかりません');
            continue;
          }
          
          final playerMap = playerMaps.first;
          print('GameManager._loadProfessionalPlayersFromDb: Playerデータ: $playerMap');
          
          final personId = playerMap['person_id'];
          print('GameManager._loadProfessionalPlayersFromDb: personId: $personId');
          
          final personMaps = await db.query('Person', where: 'id = ?', whereArgs: [personId]);
          if (personMaps.isEmpty) {
            print('GameManager._loadProfessionalPlayersFromDb: PersonテーブルにpersonId=$personIdのデータが見つかりません');
            continue;
          }
          
          final personMap = personMaps.first;
          print('GameManager._loadProfessionalPlayersFromDb: Personデータ: $personMap');
          
          // 能力値システムの復元
          final technicalAbilities = <TechnicalAbility, int>{};
          final mentalAbilities = <MentalAbility, int>{};
          final physicalAbilities = <PhysicalAbility, int>{};
          
          // Technical abilities復元
          technicalAbilities[TechnicalAbility.contact] = _safeIntCast(playerMap['contact']);
          technicalAbilities[TechnicalAbility.power] = _safeIntCast(playerMap['power']);
          technicalAbilities[TechnicalAbility.plateDiscipline] = _safeIntCast(playerMap['plate_discipline']);
          technicalAbilities[TechnicalAbility.bunt] = _safeIntCast(playerMap['bunt']);
          technicalAbilities[TechnicalAbility.oppositeFieldHitting] = _safeIntCast(playerMap['opposite_field_hitting']);
          technicalAbilities[TechnicalAbility.pullHitting] = _safeIntCast(playerMap['pull_hitting']);
          technicalAbilities[TechnicalAbility.batControl] = _safeIntCast(playerMap['bat_control']);
          technicalAbilities[TechnicalAbility.swingSpeed] = _safeIntCast(playerMap['swing_speed']);
          technicalAbilities[TechnicalAbility.fielding] = _safeIntCast(playerMap['fielding']);
          technicalAbilities[TechnicalAbility.throwing] = _safeIntCast(playerMap['throwing']);
          technicalAbilities[TechnicalAbility.catcherAbility] = _safeIntCast(playerMap['catcher_ability']);
          technicalAbilities[TechnicalAbility.control] = _safeIntCast(playerMap['control']);
          technicalAbilities[TechnicalAbility.fastball] = _safeIntCast(playerMap['fastball']);
          technicalAbilities[TechnicalAbility.breakingBall] = _safeIntCast(playerMap['breaking_ball']);
          technicalAbilities[TechnicalAbility.pitchMovement] = _safeIntCast(playerMap['pitch_movement']);
          
          // Mental abilities復元
          mentalAbilities[MentalAbility.concentration] = _safeIntCast(playerMap['concentration']);
          mentalAbilities[MentalAbility.anticipation] = _safeIntCast(playerMap['anticipation']);
          mentalAbilities[MentalAbility.vision] = _safeIntCast(playerMap['vision']);
          mentalAbilities[MentalAbility.composure] = _safeIntCast(playerMap['composure']);
          mentalAbilities[MentalAbility.aggression] = _safeIntCast(playerMap['aggression']);
          mentalAbilities[MentalAbility.bravery] = _safeIntCast(playerMap['bravery']);
          mentalAbilities[MentalAbility.leadership] = _safeIntCast(playerMap['leadership']);
          mentalAbilities[MentalAbility.workRate] = _safeIntCast(playerMap['work_rate']);
          mentalAbilities[MentalAbility.selfDiscipline] = _safeIntCast(playerMap['self_discipline']);
          mentalAbilities[MentalAbility.ambition] = _safeIntCast(playerMap['ambition']);
          mentalAbilities[MentalAbility.teamwork] = _safeIntCast(playerMap['teamwork']);
          mentalAbilities[MentalAbility.positioning] = _safeIntCast(playerMap['positioning']);
          mentalAbilities[MentalAbility.pressureHandling] = _safeIntCast(playerMap['pressure_handling']);
          mentalAbilities[MentalAbility.clutchAbility] = _safeIntCast(playerMap['clutch_ability']);
          
          // Physical abilities復元
          physicalAbilities[PhysicalAbility.acceleration] = _safeIntCast(playerMap['acceleration']);
          physicalAbilities[PhysicalAbility.agility] = _safeIntCast(playerMap['agility']);
          physicalAbilities[PhysicalAbility.balance] = _safeIntCast(playerMap['balance']);
          physicalAbilities[PhysicalAbility.jumpingReach] = _safeIntCast(playerMap['jumping_reach']);
          physicalAbilities[PhysicalAbility.flexibility] = _safeIntCast(playerMap['flexibility']);
          physicalAbilities[PhysicalAbility.naturalFitness] = _safeIntCast(playerMap['natural_fitness']);
          physicalAbilities[PhysicalAbility.injuryProneness] = _safeIntCast(playerMap['injury_proneness']);
          physicalAbilities[PhysicalAbility.stamina] = _safeIntCast(playerMap['stamina']);
          physicalAbilities[PhysicalAbility.strength] = _safeIntCast(playerMap['strength']);
          physicalAbilities[PhysicalAbility.pace] = _safeIntCast(playerMap['pace']);
          
          // Playerオブジェクトを作成
          final player = Player(
            id: playerId,
            name: personMap['name'] as String? ?? '名無し',
            school: 'プロ野球団',
            grade: 0,
            position: playerMap['position'] as String? ?? '',
            personality: personMap['personality'] as String? ?? '',
            fame: _safeIntCast(playerMap['fame']),
            isWatched: false,
            isDiscovered: true,
            isPubliclyKnown: (playerMap['is_publicly_known'] as int?) == 1,
            isScoutFavorite: false,
            isGraduated: (playerMap['is_graduated'] as int?) == 1,
            graduatedAt: playerMap['graduated_at'] != null ? DateTime.tryParse(playerMap['graduated_at'] as String) : null,
            discoveredBy: null,
            scoutedDates: [],
            abilityKnowledge: <String, int>{},
            type: PlayerType.social,
            yearsAfterGraduation: _safeIntCast(playerMap['years_after_graduation']),
            pitches: [],
            technicalAbilities: technicalAbilities,
            mentalAbilities: mentalAbilities,
            physicalAbilities: physicalAbilities,
            mentalGrit: (playerMap['mental_grit'] as num?)?.toDouble() ?? 0.0,
            growthRate: playerMap['growth_rate'] as double? ?? 1.0,
            peakAbility: _safeIntCast(playerMap['peak_ability']),
            positionFit: _generatePositionFit(playerMap['position'] as String? ?? '投手'),
            talent: _safeIntCast(playerMap['talent']),
            growthType: (playerMap['growthType'] is String) ? playerMap['growthType'] as String : (playerMap['growthType']?.toString() ?? 'normal'),
            individualPotentials: null,
            scoutAnalysisData: null,
            isDefaultPlayer: false,
            achievements: [],
            retiredAt: playerMap['retired_at'] != null ? DateTime.tryParse(playerMap['retired_at'] as String) : null,
            isRetired: (playerMap['is_retired'] as int?) == 1,
            isDrafted: (personMap['is_drafted'] as int?) == 1,
            professionalTeamId: null,
          );
          
          print('GameManager._loadProfessionalPlayersFromDb: 作成されたPlayerオブジェクト - id: ${player.id}, name: ${player.name}');
          
          // ProfessionalPlayerオブジェクトを作成
          final proPlayer = ProfessionalPlayer(
            id: proMap['id'] as int?,
            playerId: playerId,
            teamId: proMap['team_id'] as String,
            contractYear: proMap['contract_year'] as int,
            salary: proMap['salary'] as int,
            contractType: ContractType.values[proMap['contract_type'] as int? ?? 0],
            draftYear: proMap['draft_year'] as int,
            draftRound: proMap['draft_round'] as int,
            draftPosition: proMap['draft_position'] as int,
            isActive: (proMap['is_active'] as int?) == 1,
            joinedAt: DateTime.parse(proMap['joined_at'] as String),
            leftAt: proMap['left_at'] != null ? DateTime.parse(proMap['left_at'] as String) : null,
            createdAt: DateTime.parse(proMap['created_at'] as String),
            updatedAt: DateTime.parse(proMap['updated_at'] as String),
            player: player,
            teamName: team.name,
            teamShortName: team.shortName,
          );
          
          print('GameManager._loadProfessionalPlayersFromDb: 作成されたProfessionalPlayerオブジェクト - id: ${proPlayer.id ?? 'null'}, playerId: ${proPlayer.playerId}, player.id: ${proPlayer.player?.id ?? 'null'}, player.name: ${proPlayer.player?.name ?? 'null'}');
          
          validProPlayers.add(proPlayer);
        }
        
        print('GameManager._loadProfessionalPlayersFromDb: ${team.shortName}のプロ選手${validProPlayers.length}名を読み込み完了');
        
        updatedTeams.add(team.copyWith(professionalPlayers: validProPlayers));
      }
      
      // チームリストを更新
      _currentGame = _currentGame!.copyWith(
        professionalTeams: ProfessionalTeamManager(teams: updatedTeams),
      );
      
      // デバッグ: 更新後のプロ選手の状態を確認
      print('GameManager._loadProfessionalPlayersFromDb: 更新後のプロ選手状態確認');
      for (final team in _currentGame!.professionalTeams.teams) {
        print('GameManager._loadProfessionalPlayersFromDb: チーム ${team.shortName} - プロ選手数: ${team.professionalPlayers?.length ?? 0}');
        if (team.professionalPlayers != null) {
          for (int i = 0; i < team.professionalPlayers!.length && i < 3; i++) {
            final proPlayer = team.professionalPlayers![i];
            final player = proPlayer.player;
            print('GameManager._loadProfessionalPlayersFromDb: プロ選手${i + 1} - playerId: ${proPlayer.playerId}, player.id: ${player?.id ?? 'null'}, player.name: ${player?.name ?? 'null'}');
          }
        }
      }
      
      print('GameManager._loadProfessionalPlayersFromDb: プロ野球選手の読み込み完了');
      
    } catch (e) {
      print('GameManager._loadProfessionalPlayersFromDb: エラーが発生しました: $e');
      rethrow;
    }
  }

  // 指定スロットにセーブデータが存在するかチェック
  Future<bool> hasGameData(dynamic slot) async {
    return await _gameDataManager.hasGameData(slot);
  }
  
  // データベース修復を手動で実行
  Future<void> repairDatabase(DataService dataService) async {
    print('GameManager: 手動データベース修復を開始...');
    try {
      await dataService.repairNumericData();
      print('GameManager: 手動データベース修復が完了しました');
    } catch (e) {
      print('GameManager: 手動データベース修復でエラーが発生しました: $e');
      rethrow;
    }
  }

  void loadGameFromJson(Map<String, dynamic> json) {
    _currentGame = Game.fromJson(json);
    // 選手データのIDを正しく設定する必要がある
    print('GameManager: loadGameFromJson完了 - 選手データのID設定が必要');
  }

  // 選手を発掘済みとして登録
  void discoverPlayer(Player player) {
    if (_currentGame != null) {
      _currentGame = GameStateManager.discoverPlayer(_currentGame!, player);
    }
  }

  // 選手の能力値把握度を更新
  void updatePlayerKnowledge(Player player) {
    if (_currentGame != null) {
      _currentGame = GameStateManager.updatePlayerKnowledge(_currentGame!, player);
    }
  }

  // 週送り時にスカウトアクションを実行
  Future<List<String>> executeScoutActions(DataService dataService) async {
    final results = <String>[];
    
    if (_currentGame == null || _currentGame!.weeklyActions.isEmpty) {
      print('週送り時のスカウトアクション: アクションなし');
      return results;
    }
    
    print('週送り時のスカウトアクション実行開始: ${_currentGame!.weeklyActions.length}件');
    
    for (final action in _currentGame!.weeklyActions) {
      print('アクション実行: ${action.type}');
      
      if (action.type == 'SCOUT_SCHOOL') {
        // 学校視察アクションの実行をActionServiceに委譲
        final schoolIndex = action.schoolId;
        if (schoolIndex < _currentGame!.schools.length) {
          final school = _currentGame!.schools[schoolIndex];
          
          // ActionServiceを使用して学校視察を実行
          final scoutResult = await scouting.ActionService.scoutSchool(
            school: school,
            currentWeek: _currentGame!.currentWeekOfMonth,
          );
          
          // 結果をゲーム状態に反映
          if (scoutResult.discoveredPlayer != null) {
            print('選手発掘: ${scoutResult.discoveredPlayer!.name}');
            discoverPlayer(scoutResult.discoveredPlayer!);
          }
          
          if (scoutResult.improvedPlayer != null) {
            updatePlayerKnowledge(scoutResult.improvedPlayer!);
          }
          
          results.add(scoutResult.message);
        }
      } else if (action.type == 'PRAC_WATCH') {
        // 練習視察アクション（複数選手発掘版）
        final schoolIndex = action.schoolId;
        
        if (schoolIndex < _currentGame!.schools.length) {
          final school = _currentGame!.schools[schoolIndex];
          
          final result = scouting.ActionService.practiceWatchMultiple(
            school: school,
            currentWeek: _currentGame!.currentWeekOfMonth,
          );
          
          // 結果をゲーム状態に反映
          if (result.discoveredPlayers.isNotEmpty) {
            for (final player in result.discoveredPlayers) {
              discoverPlayer(player);
              // 新たに発掘した選手のフィジカル面分析データを生成
              await scouting.ActionService.generateScoutAnalysisForPhysicalAbilities(player, 1);
            }
          }
          
          if (result.improvedPlayer != null) {
            updatePlayerKnowledge(result.improvedPlayer!);
          }
          
          // 既に発掘済みの場合もフィジカル面の分析を行う
          if (result.discoveredPlayers.isEmpty && result.improvedPlayer == null) {
            // 発掘済み選手からランダムで1人選んでフィジカル面分析
            final discoveredPlayers = school.players.where((p) => p.isDiscovered).toList();
            if (discoveredPlayers.isNotEmpty) {
              final random = Random();
              final targetPlayer = discoveredPlayers[random.nextInt(discoveredPlayers.length)];
              await scouting.ActionService.generateScoutAnalysisForPhysicalAbilities(targetPlayer, 1);
              results.add('🏃 ${school.name}の練習視察: 「${targetPlayer.name}」のフィジカル面を詳しく観察できました');
            } else {
              results.add(result.message);
            }
          } else {
            results.add(result.message);
          }
        }
      } else if (action.type == 'interview') {
        // インタビューアクション
        final schoolIndex = action.schoolId;
        final playerId = action.playerId;
        
        if (schoolIndex < _currentGame!.schools.length) {
          final school = _currentGame!.schools[schoolIndex];
          
          // 指定された選手を探す
          Player? targetPlayer;
          if (playerId != null) {
            targetPlayer = school.players.firstWhere(
              (p) => p.id == playerId,
              orElse: () => school.players.first,
            );
          } else {
            // playerIdがnullの場合は、名前で検索
            final playerName = action.playerName;
            if (playerName != null) {
              targetPlayer = school.players.firstWhere(
                (p) => p.name == playerName,
                orElse: () => school.players.first,
              );
            }
          }
          
          if (targetPlayer != null) {
            print('インタビュー実行: ${targetPlayer.name}');
            
            // ActionServiceを使用してインタビューを実行
            await scouting.ActionService.generateScoutAnalysisForMentalAbilities(targetPlayer, 1);
            
            // 選手を発掘済み状態にする
            discoverPlayer(targetPlayer);
            
            results.add('💬 ${targetPlayer.name}へのインタビューが完了しました');
          } else {
            results.add('インタビュー対象の選手が見つかりませんでした');
          }
        }
      } else if (action.type == 'videoAnalyze') {
        // ビデオ分析アクション
        final schoolIndex = action.schoolId;
        final playerId = action.playerId;
        
        if (schoolIndex < _currentGame!.schools.length) {
          final school = _currentGame!.schools[schoolIndex];
          
          // 指定された選手を探す
          Player? targetPlayer;
          if (playerId != null) {
            targetPlayer = school.players.firstWhere(
              (p) => p.id == playerId,
              orElse: () => school.players.first,
            );
          } else {
            // playerIdがnullの場合は、名前で検索
            final playerName = action.playerName;
            if (playerName != null) {
              targetPlayer = school.players.firstWhere(
                (p) => p.name == playerName,
                orElse: () => school.players.first,
              );
            }
          }
          
          if (targetPlayer != null) {
            print('ビデオ分析実行: ${targetPlayer.name}');
            
            // ActionServiceを使用してビデオ分析を実行
            await scouting.ActionService.generateVideoAnalysisScoutData(targetPlayer, 1);
            
            // 選手を発掘済み状態にする
            discoverPlayer(targetPlayer);
            
            results.add('📹 ${targetPlayer.name}のビデオ分析が完了しました');
          } else {
            results.add('ビデオ分析対象の選手が見つかりませんでした');
          }
        }
      } else if (action.type == 'PRACTICE_WATCH') {
        // 練習視察アクション（単一選手版）
        final schoolIndex = action.schoolId;
        final playerId = action.playerId;
        
        if (schoolIndex < _currentGame!.schools.length) {
          final school = _currentGame!.schools[schoolIndex];
          Player? targetPlayer;
          
          if (playerId != null) {
            targetPlayer = school.players.firstWhere(
              (p) => p.id == playerId,
              orElse: () => school.players.first,
            );
          }
          
          final result = await scouting.ActionService.practiceWatch(
            school: school,
            targetPlayer: targetPlayer,
            scoutSkills: _currentGame!.scoutSkills,
            currentWeek: _currentGame!.currentWeekOfMonth,
          );
          
          // 結果をゲーム状態に反映
          if (result.discoveredPlayer != null) {
            discoverPlayer(result.discoveredPlayer!);
          }
          
          if (result.improvedPlayer != null) {
            updatePlayerKnowledge(result.improvedPlayer!);
          }
          
          results.add(result.message);
        }
      } else if (action.type == 'GAME_WATCH') {
        // 試合観戦アクション
        final schoolIndex = action.schoolId;
        final playerId = action.playerId;
        
        if (schoolIndex < _currentGame!.schools.length) {
          final school = _currentGame!.schools[schoolIndex];
          Player? targetPlayer;
          
          if (playerId != null) {
            targetPlayer = school.players.firstWhere(
              (p) => p.id == playerId,
              orElse: () => school.players.first,
            );
          }
          
          final result = await scouting.ActionService.gameWatch(
            school: school,
            targetPlayer: targetPlayer,
            scoutSkills: _currentGame!.scoutSkills,
            currentWeek: _currentGame!.currentWeekOfMonth,
          );
          
          // 結果をゲーム状態に反映
          if (result.discoveredPlayer != null) {
            discoverPlayer(result.discoveredPlayer!);
          }
          
          if (result.improvedPlayer != null) {
            updatePlayerKnowledge(result.improvedPlayer!);
          }
          
          results.add(result.message);
        }

      } else if (action.type == 'scrimmage') {
        // 練習試合観戦アクション
        final schoolIndex = action.schoolId;
        final playerId = action.playerId;
        
        if (schoolIndex < _currentGame!.schools.length) {
          final school = _currentGame!.schools[schoolIndex];
          Player? targetPlayer;
          
          if (playerId != null) {
            targetPlayer = school.players.firstWhere(
              (p) => p.id == playerId,
              orElse: () => school.players.first,
            );
          }
          
          final result = await scouting.ActionService.scrimmage(
            school: school,
            targetPlayer: targetPlayer,
            scoutSkills: _currentGame!.scoutSkills,
            currentWeek: _currentGame!.currentWeekOfMonth,
          );
          
          // 結果をゲーム状態に反映
          if (result.discoveredPlayer != null) {
            discoverPlayer(result.discoveredPlayer!);
          }
          
          if (result.improvedPlayer != null) {
            updatePlayerKnowledge(result.improvedPlayer!);
          }
          
          results.add(result.message);
        }
      } else if (action.type == 'interview') {
        // インタビューアクション
        final schoolIndex = action.schoolId;
        final playerId = action.playerId;
        
        if (schoolIndex < _currentGame!.schools.length && playerId != null) {
          final school = _currentGame!.schools[schoolIndex];
          final targetPlayer = school.players.firstWhere(
            (p) => p.id == playerId,
            orElse: () => school.players.first,
          );
          
          final result = await scouting.ActionService.interview(
            targetPlayer: targetPlayer,
            scout: _currentScout ?? Scout.createDefault('デフォルトスカウト'),
            scoutSkills: _currentGame!.scoutSkills,
            currentWeek: _currentGame!.currentWeekOfMonth,
          );
          
          // 結果をゲーム状態に反映
          if (result.improvedPlayer != null) {
            updatePlayerKnowledge(result.improvedPlayer!);
          }
          
          results.add(result.message);
        }
      } else if (action.type == 'videoAnalyze') {
        // ビデオ分析アクション
        final playerId = action.playerId;
        if (playerId != null) {
          // 全学校から対象選手を検索
          Player? targetPlayer;
          for (final school in _currentGame!.schools) {
            try {
              targetPlayer = school.players.firstWhere((p) => p.id == playerId);
              break;
            } catch (e) {
              continue;
            }
          }
          
          if (targetPlayer != null) {
            final result = await scouting.ActionService.videoAnalyze(
              targetPlayer: targetPlayer,
              scoutSkills: _currentGame!.scoutSkills,
              currentWeek: _currentGame!.currentWeekOfMonth,
            );
            
            if (result.improvedPlayer != null) {
              updatePlayerKnowledge(result.improvedPlayer!);
            }
            
            results.add(result.message);
          }
        }
      } else if (action.type == 'reportWrite') {
        // レポート作成アクション
        final requestId = action.params?['requestId'] as String?;
        final playerId = action.playerId;
        
        if (requestId != null && playerId != null) {
          final teamRequest = _currentGame!.teamRequests.getRequest(requestId);
          final player = _currentGame!.discoveredPlayers.firstWhere(
            (p) => p.id == playerId,
            orElse: () => _currentGame!.discoveredPlayers.first,
          );
          
          if (teamRequest != null) {
            final result = scouting.ActionService.reportWrite(
              teamRequest: teamRequest,
              selectedPlayer: player,
              scoutSkills: _currentGame!.scoutSkills,
              currentWeek: _currentGame!.currentWeekOfMonth,
            );
            
            // 要望を完了としてマーク
            _currentGame!.teamRequests.completeRequest(requestId, playerId.toString());
            
            // 報酬を追加
            _currentGame = _currentGame!.copyWith(
              budget: _currentGame!.budget + teamRequest.reward,
            );
            
            results.add(result.message);
          }
        }
      }
    }
    
    return results;
  }

  /// 成長後に新たに注目選手になった選手を更新
  void _updatePubliclyKnownPlayersAfterGrowth() {
    if (_currentGame == null) return;
    
    final updatedSchools = _currentGame!.schools.map((school) {
      final updatedPlayers = school.players.map((player) {
        // 既に注目選手の場合は変更なし（削除されない）
        if (player.isPubliclyKnown) {
          return player;
        }
        
        // 成長により新たに注目選手の条件を満たした場合
        final shouldBeKnown = _shouldBecomePubliclyKnownAfterGrowth(player);
        if (shouldBeKnown) {
          return player.copyWith(isPubliclyKnown: true);
        }
        
        return player;
      }).toList();
      
      return school.copyWith(players: updatedPlayers);
    }).toList();
    
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  /// 成長後に注目選手になるかどうかを判定
  bool _shouldBecomePubliclyKnownAfterGrowth(Player player) {
    // 成長により総合能力が大幅に向上した場合
    final totalAbility = player.trueTotalAbility;
    
    // 才能6以上または総合能力80以上で注目選手
    if (player.talent >= 6 || totalAbility >= 80) {
      return true;
    }
    
    // 3年生で才能5以上または総合能力75以上（進路注目）
    if (player.grade == 3 && (player.talent >= 5 || totalAbility >= 75)) {
      return true;
    }
    
    return false;
  }

  /// ニュースをゲームデータに保存
  void saveNewsToGame(NewsService newsService) {
    if (_currentGame != null) {
      final newsList = newsService.newsList;
      _currentGame = _currentGame!.copyWith(newsList: newsList);
    }
  }

  /// ゲームデータからニュースを読み込み
  void loadNewsFromGame(NewsService newsService) {
    if (_currentGame != null) {
      // 既存のニュースをクリア
      newsService.clearAllNews();
      
      // ゲームデータからニュースを復元
      for (final news in _currentGame!.newsList) {
        newsService.addNews(news);
      }
    }
  }

  /// ゲーム保存時にニュースも保存
  Future<void> saveGameWithNews(NewsService newsService) async {
    if (_currentGame != null) {
      // ニュースをゲームデータに保存
      saveNewsToGame(newsService);
      
      // ゲームデータを保存
      await _gameDataManager.saveGameData(_currentGame!, _currentGame!.scoutName);
    }
  }

  /// ゲーム読み込み時にニュースも復元
  Future<void> loadGameWithNews(NewsService newsService, dynamic slot) async {
    final game = await _gameDataManager.loadGameData(slot);
    if (game != null) {
      _currentGame = game;
      
      // ゲームデータからニュースを復元
      loadNewsFromGame(newsService);
    }
  }

  /// 全学校の全選手を取得
  List<Player> getAllPlayers() {
    if (_currentGame == null) return [];
    
    final allPlayers = <Player>[];
    for (final school in _currentGame!.schools) {
      allPlayers.addAll(school.players);
    }
    

    
    return allPlayers;
  }

  // 学校の強さを計算してデータベースを更新
  Future<void> updateSchoolStrengths(DataService dataService) async {
    if (_currentGame == null) return;
    
    try {
      final db = await dataService.database;
      final updatedSchools = <School>[];
      
      for (final school in _currentGame!.schools) {
        // 在籍選手（卒業していない選手）のみを対象
        final activePlayers = school.players.where((p) => !p.isGraduated).toList();
        
        if (activePlayers.isEmpty) {
          // 在籍選手がいない場合はデフォルト値
          final updatedSchool = school.copyWith(coachTrust: 70);
          updatedSchools.add(updatedSchool);
          continue;
        }
        
        // 全能力値の平均を計算
        int totalAbility = 0;
        int abilityCount = 0;
        
        for (final player in activePlayers) {
          // 技術能力
          for (final ability in player.technicalAbilities.values) {
            totalAbility += ability;
            abilityCount++;
          }
          // 精神能力
          for (final ability in player.mentalAbilities.values) {
            totalAbility += ability;
            abilityCount++;
          }
          // 身体能力
          for (final ability in player.physicalAbilities.values) {
            totalAbility += ability;
            abilityCount++;
          }
        }
        
        final averageStrength = abilityCount > 0 ? totalAbility / abilityCount : 70;
        final schoolStrength = averageStrength.round();
        
        // 学校の強さを更新
        try {
          await db.update(
            'School',
            {'school_strength': schoolStrength},
            where: 'id = ?',
            whereArgs: [school.id]
          );
        } catch (e) {
          // エラーが発生しても処理を継続
        }
        
        final updatedSchool = school.copyWith(coachTrust: schoolStrength);
        updatedSchools.add(updatedSchool);
      }
      
      _currentGame = _currentGame!.copyWith(schools: updatedSchools);
      
    } catch (e) {
      print('GameManager.updateSchoolStrengths: エラーが発生しました: $e');
      rethrow;
    }
  }

  /// 進行が遅れている大会を自動調整（必要に応じて）
  high_school_tournament.HighSchoolTournament _autoAdjustSlowTournamentIfNeeded(
    high_school_tournament.HighSchoolTournament tournament,
    int month,
    int week,
  ) {
    // 進行状況の予測を取得
    final prediction = HighSchoolTournamentService.predictTournamentProgress(tournament, month, week);
    
    // スケジュール通りに進行している場合は調整不要
    if (prediction.isOnSchedule) {
      return tournament;
    }
    
    print('GameManager._autoAdjustSlowTournamentIfNeeded: 進行遅延を検出 - 大会: ${tournament.id}, 完了予定: ${prediction.estimatedCompletionDate}');
    print('GameManager._autoAdjustSlowTournamentIfNeeded: 推奨アクション: ${prediction.recommendationsText}');
    
    // 自動調整を実行
    final adjustedTournament = HighSchoolTournamentService.autoAdjustSlowTournament(
      tournament,
      month,
      week,
    );
    
    // 調整後の進行状況をログ出力
    final adjustedPrediction = HighSchoolTournamentService.predictTournamentProgress(
      adjustedTournament,
      month,
      week,
    );
    
    print('GameManager._autoAdjustSlowTournamentIfNeeded: 自動調整完了 - 調整後完了予定: ${adjustedPrediction.estimatedCompletionDate}');
    
    return adjustedTournament;
  }

  /// 全大会の効率性を評価してレポートを生成
  Map<String, dynamic> generateTournamentEfficiencyReport() {
    if (_currentGame == null) return {};
    
    final report = <String, dynamic>{};
    final currentMonth = _currentGame!.currentMonth;
    final currentWeek = _currentGame!.currentWeekOfMonth;
    
    for (final tournament in _currentGame!.highSchoolTournaments) {
      final efficiency = HighSchoolTournamentService.evaluateTournamentEfficiency(
        tournament,
        currentMonth,
        currentWeek,
      );
      
      report[tournament.id] = {
        'tournamentName': '${tournament.year}年${_getTournamentTypeNameString(tournament.type)}${_getTournamentStageNameString(tournament.stage)}',
        'efficiencyScore': efficiency.efficiencyScore,
        'efficiencyLevel': efficiency.efficiencyLevel,
        'overallProgressRate': efficiency.overallProgressRate,
        'isOnSchedule': efficiency.isOnSchedule,
        'estimatedRemainingWeeks': efficiency.estimatedRemainingWeeks,
        'recommendations': efficiency.recommendations,
        'detailedAnalysis': efficiency.detailedAnalysis,
      };
    }
    
    return report;
  }

  /// 大会種別名を文字列で取得
  String _getTournamentTypeNameString(high_school_tournament.TournamentType type) {
    switch (type) {
      case high_school_tournament.TournamentType.spring:
        return '春の大会';
      case high_school_tournament.TournamentType.summer:
        return '夏の大会';
      case high_school_tournament.TournamentType.autumn:
        return '秋の大会';
      case high_school_tournament.TournamentType.springNational:
        return '春の全国大会';
    }
  }

  /// 大会段階名を文字列で取得
  String _getTournamentStageNameString(high_school_tournament.TournamentStage stage) {
    switch (stage) {
      case high_school_tournament.TournamentStage.prefectural:
        return '県大会';
      case high_school_tournament.TournamentStage.national:
        return '全国大会';
    }
  }

  /// プロ選手をデータベースから読み込んでメモリに設定
  Future<void> _loadProfessionalPlayersFromDatabase(DataService dataService) async {
    try {
      print('GameManager._loadProfessionalPlayersFromDatabase: 開始');
      
      final db = await dataService.database;
      
      // ProfessionalTeamテーブルから全チームを取得
      final teamMaps = await db.query('ProfessionalTeam');
      if (teamMaps.isEmpty) {
        print('GameManager._loadProfessionalPlayersFromDatabase: プロ野球団が見つかりません');
        return;
      }
      
      // 各チームのプロ選手を取得
      for (final teamMap in teamMaps) {
        final teamId = teamMap['id'] as String;
        final teamName = teamMap['name'] as String;
        final teamShortName = teamMap['short_name'] as String;
        
        // チームのプロ選手を取得
        final playerMaps = await db.query(
          'ProfessionalPlayer',
          where: 'team_id = ? AND is_active = 1',
          whereArgs: [teamId],
        );
        
        final professionalPlayers = <ProfessionalPlayer>[];
        
        for (final playerMap in playerMaps) {
          final playerId = playerMap['player_id'] as int;
          
          // Playerテーブルから選手の詳細情報を取得
          final playerDetailMaps = await db.query(
            'Player',
            where: 'id = ?',
            whereArgs: [playerId],
          );
          
          if (playerDetailMaps.isNotEmpty) {
            final playerDetail = playerDetailMaps.first;
            
            // Personテーブルから個人情報を取得
            final personId = playerDetail['person_id'] as int;
            final personMaps = await db.query(
              'Person',
              where: 'id = ?',
              whereArgs: [personId],
            );
            
            if (personMaps.isNotEmpty) {
              final personDetail = personMaps.first;
              
              // Playerオブジェクトを作成
              final player = Player(
                id: playerId,
                name: personDetail['name'] as String,
                school: 'プロ野球団',
                grade: 0,
                age: playerDetail['age'] as int? ?? 25,
                position: playerDetail['position'] as String,
                positionFit: _generateProfessionalPositionFit(playerDetail['position'] as String? ?? '投手'),
                fame: playerDetail['fame'] as int? ?? 60,
                isPubliclyKnown: (playerDetail['is_publicly_known'] as int? ?? 1) == 1,
                isScoutFavorite: (playerDetail['is_scout_favorite'] as int? ?? 0) == 1,
                isDiscovered: true,
                isGraduated: true,
                isRetired: (playerDetail['is_retired'] as int? ?? 0) == 1,
                isDefaultPlayer: false,
                growthRate: (playerDetail['growth_rate'] as double? ?? 1.0),
                talent: playerDetail['talent'] as int? ?? 3,
                growthType: playerDetail['growth_type'] as String? ?? 'normal',
                mentalGrit: playerDetail['mental_grit'] as double? ?? 0.5,
                peakAbility: playerDetail['peak_ability'] as int? ?? 100,
                personality: personDetail['personality'] as String? ?? '普通',
                technicalAbilities: {
                  TechnicalAbility.contact: playerDetail['contact'] as int? ?? 50,
                  TechnicalAbility.power: playerDetail['power'] as int? ?? 50,
                  TechnicalAbility.plateDiscipline: playerDetail['plate_discipline'] as int? ?? 50,
                  TechnicalAbility.bunt: playerDetail['bunt'] as int? ?? 50,
                  TechnicalAbility.oppositeFieldHitting: playerDetail['opposite_field_hitting'] as int? ?? 50,
                  TechnicalAbility.pullHitting: playerDetail['pull_hitting'] as int? ?? 50,
                  TechnicalAbility.batControl: playerDetail['bat_control'] as int? ?? 50,
                  TechnicalAbility.swingSpeed: playerDetail['swing_speed'] as int? ?? 50,
                  TechnicalAbility.fielding: playerDetail['fielding'] as int? ?? 50,
                  TechnicalAbility.throwing: playerDetail['throwing'] as int? ?? 50,
                  TechnicalAbility.catcherAbility: playerDetail['catcher_ability'] as int? ?? 50,
                  TechnicalAbility.control: playerDetail['control'] as int? ?? 50,
                  TechnicalAbility.fastball: playerDetail['fastball'] as int? ?? 50,
                  TechnicalAbility.breakingBall: playerDetail['breaking_ball'] as int? ?? 50,
                  TechnicalAbility.pitchMovement: playerDetail['pitch_movement'] as int? ?? 50,
                },
                mentalAbilities: {
                  MentalAbility.concentration: playerDetail['concentration'] as int? ?? 50,
                  MentalAbility.anticipation: playerDetail['anticipation'] as int? ?? 50,
                  MentalAbility.vision: playerDetail['vision'] as int? ?? 50,
                  MentalAbility.composure: playerDetail['composure'] as int? ?? 50,
                  MentalAbility.aggression: playerDetail['aggression'] as int? ?? 50,
                  MentalAbility.bravery: playerDetail['bravery'] as int? ?? 50,
                  MentalAbility.leadership: playerDetail['leadership'] as int? ?? 50,
                  MentalAbility.workRate: playerDetail['work_rate'] as int? ?? 50,
                  MentalAbility.selfDiscipline: playerDetail['self_discipline'] as int? ?? 50,
                  MentalAbility.ambition: playerDetail['ambition'] as int? ?? 50,
                  MentalAbility.teamwork: playerDetail['teamwork'] as int? ?? 50,
                  MentalAbility.positioning: playerDetail['positioning'] as int? ?? 50,
                  MentalAbility.pressureHandling: playerDetail['pressure_handling'] as int? ?? 50,
                  MentalAbility.clutchAbility: playerDetail['clutch_ability'] as int? ?? 50,
                },
                physicalAbilities: {
                  PhysicalAbility.acceleration: playerDetail['acceleration'] as int? ?? 50,
                  PhysicalAbility.agility: playerDetail['agility'] as int? ?? 50,
                  PhysicalAbility.balance: playerDetail['balance'] as int? ?? 50,
                  PhysicalAbility.pace: playerDetail['pace'] as int? ?? 50,
                  PhysicalAbility.stamina: playerDetail['stamina'] as int? ?? 50,
                  PhysicalAbility.strength: playerDetail['strength'] as int? ?? 50,
                  PhysicalAbility.flexibility: playerDetail['flexibility'] as int? ?? 50,
                  PhysicalAbility.jumpingReach: playerDetail['jumping_reach'] as int? ?? 50,
                  PhysicalAbility.naturalFitness: playerDetail['natural_fitness'] as int? ?? 50,
                  PhysicalAbility.injuryProneness: playerDetail['injury_proneness'] as int? ?? 50,
                },
              );
              
              // ProfessionalPlayerオブジェクトを作成
              final professionalPlayer = ProfessionalPlayer(
                playerId: playerId,
                teamId: teamId,
                contractYear: playerMap['contract_year'] as int? ?? 1,
                salary: playerMap['salary'] as int? ?? 1000,
                contractType: ContractType.values.firstWhere(
                  (e) => e.toString().split('.').last == (playerMap['contract_type'] as String? ?? 'regular'),
                  orElse: () => ContractType.regular,
                ),
                draftYear: playerMap['draft_year'] as int? ?? DateTime.now().year - 1,
                draftRound: playerMap['draft_round'] as int? ?? 1,
                draftPosition: playerMap['draft_position'] as int? ?? 1,
                isActive: (playerMap['is_active'] as int? ?? 1) == 1,
                joinedAt: DateTime.parse(playerMap['joined_at'] as String? ?? DateTime.now().toIso8601String()),
                leftAt: playerMap['left_at'] != null ? DateTime.parse(playerMap['left_at'] as String) : null,
                createdAt: DateTime.parse(playerMap['created_at'] as String? ?? DateTime.now().toIso8601String()),
                updatedAt: DateTime.parse(playerMap['updated_at'] as String? ?? DateTime.now().toIso8601String()),
                player: player,
                teamName: teamName,
                teamShortName: teamShortName,
              );
              
              professionalPlayers.add(professionalPlayer);
            }
          }
        }
        
        // チームにプロ選手を設定
        final teamIndex = _currentGame!.professionalTeams.teams.indexWhere((t) => t.id == teamId);
        if (teamIndex != -1) {
          _currentGame!.professionalTeams.teams[teamIndex] = _currentGame!.professionalTeams.teams[teamIndex].copyWith(
            professionalPlayers: professionalPlayers,
          );
        }
      }
      
      print('GameManager._loadProfessionalPlayersFromDatabase: 完了 - 全チームのプロ選手を読み込みました');
      
    } catch (e) {
      print('GameManager._loadProfessionalPlayersFromDatabase: エラーが発生しました: $e');
      rethrow;
    }
  }

  /// プロ選手用のポジション適性を生成
  Map<String, int> _generateProfessionalPositionFit(String position) {
    final fit = <String, int>{};
    
    // メインポジションは90-100
    fit[position] = 90 + (DateTime.now().millisecondsSinceEpoch % 11);
    
    // 他のポジションは適度に低く
    final otherPositions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    for (final otherPosition in otherPositions) {
      if (otherPosition != position) {
        fit[otherPosition] = 20 + (DateTime.now().millisecondsSinceEpoch % 41); // 20-60
      }
    }
    
    return fit;
  }
} 