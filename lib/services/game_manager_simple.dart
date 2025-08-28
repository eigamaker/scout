import 'package:sqflite/sqflite.dart';

import '../models/game/game.dart';
import 'news_service.dart';
import '../models/scouting/scout.dart';
import '../models/scouting/team_request.dart';
import '../models/professional/professional_team.dart';
import 'data_service.dart';

class GameManager {
  Game? _currentGame;
  Scout? _currentScout;
  final DataService _dataService = DataService();
  
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

  // 週進行処理状態を更新するプライベートメソッド
  void _updateAdvancingWeekStatus(bool isAdvancing) {
    _isAdvancingWeek = isAdvancing;
    print('GameManager: 週進行処理状態更新 - $isAdvancing');
  }



  /// データベースを初期化
  Future<void> _initDatabase() async {
    try {
      final db = await _dataService.database;
      
      // テーブルの存在確認
      final tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      print('存在するテーブル: ${tables.map((t) => t['name']).toList()}');
      
      // 必要なテーブルが存在しない場合は作成
      if (tables.isEmpty) {
        print('データベーステーブルを作成中...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS GameState (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scoutName TEXT,
            currentYear INTEGER,
            currentMonth INTEGER,
            currentWeekOfMonth INTEGER,
            state TEXT,
            ap INTEGER,
            budget INTEGER,
            scoutSkills TEXT,
            reputation INTEGER,
            experience INTEGER,
            level INTEGER,
            timestamp INTEGER
          )
        ''');
        
        print('データベーステーブルの作成が完了しました');
      }
    } catch (e) {
      print('データベース初期化でエラーが発生しました: $e');
    }
  }

  /// ゲーム状態を自動保存
  Future<void> _autoSaveGame() async {
    if (_currentGame == null) return;
    
    try {
      final db = await _dataService.database;
      
      // ゲーム状態をGameStateテーブルに保存
      final gameData = {
        'scoutName': _currentGame!.scoutName,
        'currentYear': _currentGame!.currentYear,
        'currentMonth': _currentGame!.currentMonth,
        'currentWeekOfMonth': _currentGame!.currentWeekOfMonth,
        'state': _currentGame!.state.index,
        'ap': _currentGame!.ap,
        'budget': _currentGame!.budget,
        'reputation': _currentGame!.reputation,
        'experience': _currentGame!.experience,
        'level': _currentGame!.level,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await db.insert('GameState', gameData, conflictAlgorithm: ConflictAlgorithm.replace);
      print('ゲーム状態を自動保存しました');
    } catch (e) {
      print('自動保存でエラーが発生しました: $e');
    }
  }

  /// ゲーム状態を自動復元
  Future<void> _autoLoadGame() async {
    try {
      final db = await _dataService.database;
      final gameStateData = await db.query('GameState', limit: 1);
      
      if (gameStateData.isNotEmpty) {
        final gameData = gameStateData.first;
        
        // 基本的なゲーム状態を復元
        _currentGame = Game(
          scoutName: (gameData['scoutName'] as String?) ?? 'あなた',
          scoutSkill: 50,
          currentYear: (gameData['currentYear'] as int?) ?? DateTime.now().year,
          currentMonth: (gameData['currentMonth'] as int?) ?? 4,
          currentWeekOfMonth: (gameData['currentWeekOfMonth'] as int?) ?? 1,
          state: GameState.values[(gameData['state'] as int?) ?? 0],
          schools: [], // 学校データは別途復元
          discoveredPlayerIds: [],
          watchedPlayerIds: [],
          favoritePlayerIds: [],
          ap: (gameData['ap'] as int?) ?? 15,
          budget: (gameData['budget'] as int?) ?? 1000000,
          scoutSkills: {
            ScoutSkill.exploration: 50,
            ScoutSkill.observation: 50,
            ScoutSkill.analysis: 50,
            ScoutSkill.insight: 50,
            ScoutSkill.communication: 50,
            ScoutSkill.negotiation: 50,
            ScoutSkill.stamina: 50,
          },
          reputation: (gameData['reputation'] as int?) ?? 50,
          experience: (gameData['experience'] as int?) ?? 0,
          level: (gameData['level'] as int?) ?? 1,
          weeklyActions: [],
          teamRequests: TeamRequestManager(),
          newsList: [],
          professionalTeams: ProfessionalTeamManager(teams: ProfessionalTeamManager.generateDefaultTeams()),
          highSchoolTournaments: [],
          hasGradeUpProcessedThisYear: false,
          hasNewYearProcessedThisYear: false,
        );
        
        print('ゲーム状態を自動復元しました');
      }
    } catch (e) {
      print('自動復元でエラーが発生しました: $e');
    }
  }

  /// 新しいゲームを開始
  Future<void> startNewGame(String scoutName) async {
    try {
      await _initDatabase();
      
      // スカウトインスタンス生成
      _currentScout = Scout.createDefault(scoutName);
      
      // 基本的なゲーム状態で開始
      _currentGame = Game(
        scoutName: scoutName,
        scoutSkill: 50,
        currentYear: DateTime.now().year,
        currentMonth: 4,
        currentWeekOfMonth: 1,
        state: GameState.scouting,
        schools: [],
        discoveredPlayerIds: [],
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
        reputation: 50,
        experience: 0,
        level: 1,
        weeklyActions: [],
        teamRequests: TeamRequestManager(),
        newsList: [],
        professionalTeams: ProfessionalTeamManager(teams: ProfessionalTeamManager.generateDefaultTeams()),
        highSchoolTournaments: [],
        hasGradeUpProcessedThisYear: false,
        hasNewYearProcessedThisYear: false,
      );
      
      // 自動保存
      await _autoSaveGame();
      
      print('新しいゲームを開始しました');
    } catch (e) {
      print('ゲーム開始でエラーが発生しました: $e');
      rethrow;
    }
  }

  /// ゲームを続行（自動復元）
  Future<void> continueGame() async {
    try {
      await _initDatabase();
      await _autoLoadGame();
      
      if (_currentGame != null) {
        print('ゲームを続行しました');
      } else {
        print('続行可能なゲームが見つかりませんでした');
      }
    } catch (e) {
      print('ゲーム続行でエラーが発生しました: $e');
    }
  }

  /// 週送り時にアクションを実行し、リザルトを返す
  Future<List<String>> advanceWeekWithResults(NewsService newsService) async {
    // 既に処理中の場合は早期リターン
    if (_isAdvancingWeek || _isProcessingGrowth) {
      print('GameManager.advanceWeekWithResults: 既に処理中のため、処理をスキップします');
      return [];
    }
    
    final results = <String>[];
    if (_currentGame == null) return results;
    
    // 週進行処理開始
    _updateAdvancingWeekStatus(true);
    
    try {
      // 週送り（週進行、AP/予算リセット、アクションリセット）
      _currentGame = _currentGame!
        .advanceWeek()
        .resetWeeklyResources(newAp: 15, newBudget: _currentGame!.budget)
        .resetActions();
      
      // 自動保存
      await _autoSaveGame();
      
      results.add('週が進みました。新しい週の開始です。');
      
    } catch (e) {
      print('週送り処理でエラーが発生しました: $e');
      rethrow;
    } finally {
      _updateAdvancingWeekStatus(false);
    }
    
    return results;
  }

  /// ゲーム状態を更新
  void updateGame(Game newGame) {
    _currentGame = newGame;
    _autoSaveGame(); // 自動保存
  }
}
