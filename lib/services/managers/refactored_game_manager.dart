import '../../models/game/game.dart';
import '../../models/player/player.dart';
import '../../models/school/school.dart';
import '../../models/scouting/scout.dart';
import '../../models/scouting/team_request.dart';
import '../../models/professional/professional_team.dart';
import '../../models/professional/professional_player.dart';
import '../../models/game/pennant_race.dart';
import '../../models/game/high_school_tournament.dart' as high_school_tournament;

import '../news_service.dart';
import '../data_service.dart';
import '../database/refactored_data_service.dart';
import '../scouting/action_service.dart' as scouting;
import '../game_data_manager.dart';
import '../game_state_manager.dart';
import '../growth_service.dart';
import '../pennant_race_service.dart';
import '../high_school_tournament_service.dart';
import '../default_school_data.dart';
import '../school_data_service.dart';
import '../talented_player_generator.dart';
import '../player_assignment_service.dart';

import 'player_management_service.dart';
import 'game_progression_service.dart';
import 'school_management_service.dart';

/// リファクタリングされたゲームマネージャー
/// 機能を分離してより管理しやすくした
class RefactoredGameManager {
  Game? _currentGame;
  late final GameDataManager _gameDataManager;
  late final PlayerManagementService _playerManagementService;
  late final GameProgressionService _gameProgressionService;
  late final SchoolManagementService _schoolManagementService;

  Scout? _currentScout;
  
  // 週進行処理状態の管理
  bool _isAdvancingWeek = false;
  bool _isProcessingGrowth = false;
  String _growthStatusMessage = '';

  Game? get currentGame => _currentGame;
  Scout? get currentScout => _currentScout;
  
  // 週進行処理状態のゲッター
  bool get isAdvancingWeek => _isAdvancingWeek;
  bool get isProcessingGrowth => _isProcessingGrowth;
  String get growthStatusMessage => _growthStatusMessage;
  
  // 週進行処理中または成長処理中は進行できないかチェック
  bool get canAdvanceWeek => !_isAdvancingWeek && !_isProcessingGrowth;

  RefactoredGameManager() {
    _gameDataManager = GameDataManager();
  }

  /// サービスを初期化
  void _initializeServices(DataService dataService, NewsService newsService, GrowthService growthService) {
    _playerManagementService = PlayerManagementService(dataService);
    _gameProgressionService = GameProgressionService(dataService, newsService, growthService);
    _schoolManagementService = SchoolManagementService(dataService, SchoolDataService());
  }

  /// 週進行処理状態を更新するプライベートメソッド
  void _updateAdvancingWeekStatus(bool isAdvancing) {
    _isAdvancingWeek = isAdvancing;
    print('RefactoredGameManager: 週進行処理状態更新 - $isAdvancing');
  }

  /// 成長処理状態を更新するプライベートメソッド
  void _updateGrowthStatus(bool isProcessing, String message) {
    _isProcessingGrowth = isProcessing;
    _growthStatusMessage = message;
    print('RefactoredGameManager: 成長処理状態更新 - $isProcessing: $message');
  }

  /// ペナントレースを初期化
  void _initializePennantRace() {
    if (_currentGame != null && _currentGame!.pennantRace == null) {
      final stopwatch = Stopwatch()..start();
      final pennantRace = PennantRaceService.createInitialPennantRace(
        _currentGame!.currentYear,
        _currentGame!.professionalTeams.teams,
      );
      
      _currentGame = _currentGame!.copyWith(pennantRace: pennantRace);
      stopwatch.stop();
      print('RefactoredGameManager: ペナントレースを初期化しました - ${stopwatch.elapsedMilliseconds}ms');
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

  /// ドラフト週かどうかをチェック
  bool get isDraftWeek {
    if (_currentGame == null) return false;
    return _currentGame!.currentMonth == 10 && _currentGame!.currentWeekOfMonth == 4;
  }

  /// 高校野球大会が進行中かチェック
  bool get isHighSchoolTournamentActive {
    if (_currentGame?.highSchoolTournament == null) return false;
    final month = _currentGame!.currentMonth;
    return month >= 7 && month <= 8;
  }

  /// 新しいゲームを開始（データベース使用）
  Future<void> startNewGameWithDb(String scoutName, DataService dataService, NewsService newsService, GrowthService growthService) async {
    print('RefactoredGameManager: 新しいゲーム開始（データベース使用）');
    final stopwatch = Stopwatch()..start();
    
    try {
      // サービスを初期化
      _initializeServices(dataService, newsService, growthService);
      
      // スカウトを作成
      _currentScout = Scout(
        name: scoutName,
        reputation: 50,
        experience: 0,
        level: 1,
        skills: {
          ScoutSkill.exploration: 50,
          ScoutSkill.observation: 50,
          ScoutSkill.analysis: 50,
          ScoutSkill.insight: 50,
          ScoutSkill.communication: 50,
          ScoutSkill.negotiation: 50,
          ScoutSkill.stamina: 50,
        },
      );
      
      // 初期学校データを生成
      await _schoolManagementService.generateInitialSchools();
      
      // 初期生徒を生成
      await _playerManagementService.generateInitialStudentsForAllSchools();
      
      // プロ野球選手を読み込み
      await _playerManagementService.loadProfessionalPlayersFromDatabase();
      
      // 学校データを取得
      final schoolsData = await _schoolManagementService.getAllSchoolsWithPlayers();
      final schools = schoolsData.map((data) => School.fromJson(data)).toList();
      
      // 選手データを取得
      final players = <Player>[];
      for (final school in schools) {
        players.addAll(school.players);
      }
      
      // Gameインスタンス生成
      _currentGame = Game(
        scoutName: scoutName,
        scoutSkill: 50,
        currentYear: DateTime.now().year,
        currentMonth: 4,
        currentWeekOfMonth: 1,
        state: GameState.scouting,
        schools: schools,
        discoveredPlayerIds: players.map((p) => p.id!).toList(),
        watchedPlayerIds: [],
        favoritePlayerIds: [],
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
        newsList: [],
        professionalTeams: ProfessionalTeamManager(teams: ProfessionalTeamManager.generateDefaultTeams()),
      );
      
      // ペナントレースを初期化
      _initializePennantRace();
      
      // ゲームデータを保存
      await _gameDataManager.saveGameData(_currentGame!);
      
      stopwatch.stop();
      print('RefactoredGameManager: 新しいゲーム開始完了 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('RefactoredGameManager: 新しいゲーム開始エラー: $e');
      rethrow;
    }
  }

  /// 週送り時にアクションを実行し、リザルトを返す
  Future<List<String>> advanceWeekWithResults(NewsService newsService, DataService dataService) async {
    // 既に処理中の場合は早期リターン
    if (_isAdvancingWeek || _isProcessingGrowth) {
      print('RefactoredGameManager: 既に処理中のため、処理をスキップします');
      return [];
    }
    
    if (_currentGame == null) return [];
    
    // サービスを初期化（必要に応じて）
    if (_gameProgressionService == null) {
      _initializeServices(dataService, newsService, GrowthService());
    }
    
    // 週進行処理開始
    _updateAdvancingWeekStatus(true);
    
    try {
      // ゲーム進行サービスに委譲
      final results = await _gameProgressionService.advanceWeekWithResults(_currentGame!);
      
      // ゲーム状態を更新
      _currentGame = _currentGame!.advanceWeek();
      
      // ゲームデータを保存
      await _gameDataManager.saveGameData(_currentGame!);
      
      return results;
      
    } catch (e) {
      print('RefactoredGameManager: 週送り処理エラー: $e');
      return ['週送り処理中にエラーが発生しました'];
    } finally {
      _updateAdvancingWeekStatus(false);
    }
  }

  /// ゲームを保存
  Future<void> saveGame() async {
    if (_currentGame != null) {
      await _gameDataManager.saveGameData(_currentGame!);
      print('RefactoredGameManager: ゲームを保存しました');
    }
  }

  /// ゲームをロード
  Future<bool> loadGame(DataService dataService) async {
    try {
      print('RefactoredGameManager: ゲームロード開始');
      final game = await _gameDataManager.loadGameData();
      if (game != null) {
        _currentGame = game;
        print('RefactoredGameManager: ゲームデータ読み込み完了');
        
        // 選手データを再読み込み
        await _playerManagementService.refreshPlayersFromDatabase();
        
        return true;
      }
      print('RefactoredGameManager: ゲームデータが見つかりませんでした');
      return false;
    } catch (e, stackTrace) {
      print('RefactoredGameManager: ゲームロードエラー: $e');
      print('RefactoredGameManager: スタックトレース: $stackTrace');
      return false;
    }
  }

  /// セーブデータが存在するかチェック
  Future<bool> hasGameData() async {
    return await _gameDataManager.hasGameData();
  }
  
  /// データベース修復を手動で実行
  Future<void> repairDatabase(DataService dataService) async {
    print('RefactoredGameManager: 手動データベース修復を開始...');
    try {
      await dataService.repairNumericData();
      print('RefactoredGameManager: 手動データベース修復が完了しました');
    } catch (e) {
      print('RefactoredGameManager: 手動データベース修復でエラーが発生しました: $e');
      rethrow;
    }
  }

  /// 選手を発掘済みとして登録
  void discoverPlayer(Player player) {
    if (_currentGame != null) {
      _currentGame = GameStateManager.discoverPlayer(_currentGame!, player);
    }
  }

  /// 選手の能力値把握度を更新
  void updatePlayerKnowledge(Player player) {
    if (_currentGame != null) {
      _currentGame = GameStateManager.updatePlayerKnowledge(_currentGame!, player);
    }
  }

  /// 週送り時にスカウトアクションを実行
  Future<List<String>> executeScoutActions(DataService dataService) async {
    if (_currentGame == null) return [];
    
    final results = <String>[];
    
    try {
      // 週次アクションを実行
      for (final action in _currentGame!.weeklyActions) {
        final actionResult = await scouting.ActionService.executeAction(action, _currentGame!, dataService);
        if (actionResult.isNotEmpty) {
          results.add(actionResult);
        }
      }
      
      return results;
    } catch (e) {
      print('RefactoredGameManager: スカウトアクション実行エラー: $e');
      return results;
    }
  }

  /// ゲーム状態を取得
  String get gameState {
    if (_currentGame == null) return 'ゲーム未開始';
    
    switch (_currentGame!.state) {
      case GameState.scouting:
        return 'スカウト中';
      case GameState.draft:
        return 'ドラフト中';
      case GameState.playing:
        return 'プレイ中';
      case GameState.finished:
        return '終了';
      default:
        return '不明';
    }
  }

  /// 現在の年を取得
  int get currentYear => _currentGame?.currentYear ?? 0;

  /// 現在の月を取得
  int get currentMonth => _currentGame?.currentMonth ?? 0;

  /// 現在の週を取得
  int get currentWeek => _currentGame?.currentWeekOfMonth ?? 0;

  /// 現在のAPを取得
  int get currentAp => _currentGame?.ap ?? 0;

  /// 現在の予算を取得
  int get currentBudget => _currentGame?.budget ?? 0;

  /// スカウトのレベルを取得
  int get scoutLevel => _currentScout?.level ?? 1;

  /// スカウトの経験値を取得
  int get scoutExperience => _currentScout?.experience ?? 0;

  /// スカウトの評判を取得
  int get scoutReputation => _currentScout?.reputation ?? 0;

  /// 学校の数を取得
  int get schoolCount => _currentGame?.schools.length ?? 0;

  /// 発掘済み選手の数を取得
  int get discoveredPlayerCount => _currentGame?.discoveredPlayerIds.length ?? 0;

  /// 注目選手の数を取得
  int get watchedPlayerCount => _currentGame?.watchedPlayerIds.length ?? 0;

  /// お気に入り選手の数を取得
  int get favoritePlayerCount => _currentGame?.favoritePlayerIds.length ?? 0;

  /// プロ野球団の数を取得
  int get professionalTeamCount => _currentGame?.professionalTeams.teams.length ?? 0;

  /// ニュースの数を取得
  int get newsCount => _currentGame?.newsList.length ?? 0;

  /// チームリクエストの数を取得
  int get teamRequestCount => _currentGame?.teamRequests.requests.length ?? 0;
}
