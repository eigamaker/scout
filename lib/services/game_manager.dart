import 'dart:math';

import '../models/game/game.dart';
import '../models/player/player.dart';

import '../models/player/player_abilities.dart';
import '../models/school/school.dart';

import 'news_service.dart';
import 'data_service.dart';

import 'scouting/action_service.dart' as scouting;
import 'game_data_manager.dart';
import 'player_data_generator.dart';
import 'game_state_manager.dart';
import '../models/scouting/scout.dart';
import '../models/scouting/team_request.dart';
import 'growth_service.dart';



class GameManager {
  Game? _currentGame;
  late final GameDataManager _gameDataManager;
  late final PlayerDataGenerator _playerDataGenerator;
  Scout? _currentScout;
  
  // 成長処理状態の管理
  bool _isProcessingGrowth = false;
  String _growthStatusMessage = '';

  Game? get currentGame => _currentGame;
  Scout? get currentScout => _currentScout;
  
  // 成長処理状態のゲッター
  bool get isProcessingGrowth => _isProcessingGrowth;
  String get growthStatusMessage => _growthStatusMessage;
  
  // 成長処理中は進行できないかチェック
  bool get canAdvanceWeek => !_isProcessingGrowth;

  // 成長処理状態を更新するプライベートメソッド
  void _updateGrowthStatus(bool isProcessing, String message) {
    _isProcessingGrowth = isProcessing;
    _growthStatusMessage = message;
    print('GameManager: 成長処理状態更新 - $isProcessing: $message');
  }

  GameManager(DataService dataService) {
    _gameDataManager = GameDataManager(dataService);
    _playerDataGenerator = PlayerDataGenerator(dataService);
  }

  // ニューゲーム時に全学校に1〜3年生を生成・配属（DBにもinsert）
  Future<void> generateInitialStudentsForAllSchoolsDb(DataService dataService) async {
    final updatedSchools = <School>[];
    
    for (final school in _currentGame!.schools) {
      final newPlayers = <Player>[];
      
      // 各学校に1〜3年生を生成（各学年10人）
      for (int grade = 1; grade <= 3; grade++) {
        final playerCount = 10; // 各学年10人
        
        // 新しいPlayerDataGeneratorを使用して選手を生成
        final players = await _playerDataGenerator.generatePlayersForSchool(school, playerCount);
        newPlayers.addAll(players);
      }
      
      updatedSchools.add(school.copyWith(players: newPlayers));
    }
    
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  Future<void> startNewGameWithDb(String scoutName, DataService dataService) async {
    try {
      print('startNewGameWithDb: 開始');
      // 初期データ投入（初回のみ）
      await dataService.insertInitialData();
      print('startNewGameWithDb: 初期データ投入完了');
      final db = await dataService.database;
      print('startNewGameWithDb: DB接続完了');
    // 学校リスト取得
    final schoolMaps = await db.query('Organization', where: 'type = ?', whereArgs: ['高校']);
    final schools = schoolMaps.map((m) => School(
      id: m['id'] as int,
      name: m['name'] as String,
      location: m['location'] as String,
      players: [], // 後で選手を割り当て
      coachTrust: m['school_strength'] as int? ?? 70,
      coachName: '未設定',
    )).toList();
    // 初期選手リストは空で開始（generateInitialStudentsForAllSchoolsDbで生成される）
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
    );
    // 全学校に1〜3年生を生成
    await generateInitialStudentsForAllSchoolsDb(dataService);
    
    // generateInitialStudentsForAllSchoolsDbで更新された学校リストを取得
    final updatedSchools = _currentGame!.schools;
    
    // 全選手をdiscoveredPlayersにも追加
    final allPlayers = <Player>[];
    for (final school in updatedSchools) {
      allPlayers.addAll(school.players);
    }
    _currentGame = _currentGame!.copyWith(discoveredPlayers: allPlayers);
    print('startNewGameWithDb: 完了 - 学校数: ${updatedSchools.length}, 選手数: ${allPlayers.length}');
    for (final s in _currentGame!.schools) {
      print('final schools: name=${s.name}, players=${s.players.length}');
    }
  } catch (e, stackTrace) {
    print('startNewGameWithDb: エラー発生 - $e');
    print('startNewGameWithDb: スタックトレース - $stackTrace');
    rethrow;
  }
  }

  // スカウト実行
  Future<Player?> scoutNewPlayer(NewsService newsService) async {
    if (_currentGame == null || _currentGame!.schools.isEmpty) return null;
    // ランダムな学校を選択
    final school = (_currentGame!.schools..shuffle()).first;
    
    // PlayerDataGeneratorを使用して選手を生成
    final newPlayer = await _playerDataGenerator.generatePlayer(school);
    
    // 発掘リストに追加
    _currentGame = _currentGame!.discoverPlayer(newPlayer);

    // 選手に基づくニュース生成
    newsService.generatePlayerNews(
      newPlayer, 
      school,
      year: _currentGame!.currentYear,
      month: _currentGame!.currentMonth,
      weekOfMonth: _currentGame!.currentWeekOfMonth,
    );
    
    return newPlayer;
  }

  // 日付進行・イベント
  void triggerRandomEvent(NewsService newsService) {
    if (_currentGame == null) return;
    _currentGame = GameStateManager.triggerRandomEvent(_currentGame!, newsService);
  }

  // 新年度（4月1週）開始時に全学校へ新1年生を生成・配属（DBにもinsert）
  Future<void> generateNewStudentsForAllSchoolsDb(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager.generateNewStudentsForAllSchoolsDb: 新入生生成処理開始');
    
    try {
      final db = await dataService.database;
      final updatedSchools = <School>[];
      
      for (final school in _currentGame!.schools) {
        print('GameManager.generateNewStudentsForAllSchoolsDb: ${school.name}の新入生生成開始');
        
        try {
          // 新1年生を5人生成
          final newFirstYears = await _playerDataGenerator.generatePlayersForSchool(school, 5);
          print('GameManager.generateNewStudentsForAllSchoolsDb: ${school.name}に新入生${newFirstYears.length}人を生成');
          
          // 既存の選手と新入生を統合
          final allPlayers = [...school.players, ...newFirstYears];
          final updatedSchool = school.copyWith(players: allPlayers);
          updatedSchools.add(updatedSchool);
          
          print('GameManager.generateNewStudentsForAllSchoolsDb: ${school.name}の新入生生成完了 - 総選手数: ${allPlayers.length}');
          
        } catch (e) {
          print('GameManager.generateNewStudentsForAllSchoolsDb: ${school.name}の新入生生成エラー: $e');
          // エラーが発生しても既存の学校をそのまま追加
          updatedSchools.add(school);
        }
      }
      
      _currentGame = _currentGame!.copyWith(schools: updatedSchools);
      print('GameManager.generateNewStudentsForAllSchoolsDb: 全学校の新入生生成完了');
      
    } catch (e) {
      print('GameManager.generateNewStudentsForAllSchoolsDb: エラーが発生しました: $e');
      rethrow;
    }
  }

  // 3月1週→2週の週送り時に卒業処理（3年生を卒業フラグ設定）
  Future<void> graduateThirdYearStudents(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager.graduateThirdYearStudents: 卒業処理開始');
    _updateGrowthStatus(true, '3年生の卒業処理を実行中...');
    
    try {
      final db = await dataService.database;
      final updatedSchools = <School>[];
      int totalGraduated = 0;
      
      for (final school in _currentGame!.schools) {
        print('GameManager.graduateThirdYearStudents: 学校 ${school.name} の卒業処理開始');
        print('GameManager.graduateThirdYearStudents: ${school.name} - 全選手数: ${school.players.length}名');
        
        final remaining = school.players.where((p) => p.grade < 3).toList();
        final graduating = school.players.where((p) => p.grade == 3).toList();
        
        print('GameManager.graduateThirdYearStudents: ${school.name} - 残る選手: ${remaining.length}名, 卒業: ${graduating.length}名');
        
        // 卒業する選手の詳細情報をログ出力
        for (final p in graduating) {
          print('GameManager.graduateThirdYearStudents: 卒業予定選手 - ID: ${p.id}, 名前: ${p.name}, 学年: ${p.grade}年生, 学校: ${p.school}');
        }
        
        // DBで3年生を卒業フラグ設定（関連テーブルも含めて更新）
        for (final p in graduating) {
          print('GameManager.graduateThirdYearStudents: 選手 ${p.name} (${p.grade}年生) を卒業処理中...');
          
          // Playerテーブルの卒業フラグを更新
          final playerUpdateResult = await db.update(
            'Player',
            {
              'is_graduated': 1,
              'graduated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [p.id]
          );
          print('GameManager.graduateThirdYearStudents: Playerテーブル更新完了 - 結果: $playerUpdateResult');
          
          // PlayerPotentialsテーブルの卒業フラグを更新
          try {
            final potentialsUpdateResult = await db.update(
              'PlayerPotentials',
              {'is_graduated': 1},
              where: 'player_id = ?',
              whereArgs: [p.id]
            );
            print('GameManager.graduateThirdYearStudents: PlayerPotentialsテーブル更新完了 - 結果: $potentialsUpdateResult');
          } catch (e) {
            print('GameManager.graduateThirdYearStudents: PlayerPotentialsテーブル更新エラー: $e');
          }
          
          // ScoutAnalysisテーブルの卒業フラグを更新
          try {
            final analysisUpdateResult = await db.update(
              'ScoutAnalysis',
              {'is_graduated': 1},
              where: 'player_id = ?',
              whereArgs: [p.id]
            );
            print('GameManager.graduateThirdYearStudents: ScoutAnalysisテーブル更新完了 - 結果: $analysisUpdateResult');
          } catch (e) {
            print('GameManager.graduateThirdYearStudents: ScoutAnalysisテーブル更新エラー: $e');
          }
          
          // ScoutBasicInfoAnalysisテーブルの卒業フラグを更新
          try {
            final basicAnalysisUpdateResult = await db.update(
              'ScoutBasicInfoAnalysis',
              {'is_graduated': 1},
              where: 'player_id = ?',
              whereArgs: [p.id]
            );
            print('GameManager.graduateThirdYearStudents: ScoutBasicInfoAnalysisテーブル更新完了 - 結果: $basicAnalysisUpdateResult');
          } catch (e) {
            print('GameManager.graduateThirdYearStudents: ScoutBasicInfoAnalysisテーブル更新エラー: $e');
          }
          
          print('GameManager.graduateThirdYearStudents: 選手 ${p.name} の卒業処理完了');
        }
        
        // 卒業した選手も含めて学校に保持（ただし卒業フラグ付き）
        final allPlayers = [...remaining, ...graduating.map((p) => p.copyWith(
          isGraduated: true,
          graduatedAt: DateTime.now(),
        ))];
        
        updatedSchools.add(school.copyWith(players: allPlayers));
        totalGraduated += graduating.length;
        print('GameManager.graduateThirdYearStudents: 学校 ${school.name} の卒業処理完了 - 在籍選手数: ${allPlayers.length}名（卒業生含む）');
      }
      
      _currentGame = _currentGame!.copyWith(schools: updatedSchools);
      _updateGrowthStatus(false, '卒業処理完了');
      print('GameManager.graduateThirdYearStudents: 全学校の卒業処理完了 - 総卒業生数: ${totalGraduated}名');
      
      // 卒業処理後に学校の強さを更新
      print('GameManager.graduateThirdYearStudents: 学校の強さ更新開始');
      await updateSchoolStrengths(dataService);
      print('GameManager.graduateThirdYearStudents: 学校の強さ更新完了');
      
    } catch (e) {
      _updateGrowthStatus(false, '卒業処理でエラーが発生しました');
      print('GameManager.graduateThirdYearStudents: エラーが発生しました: $e');
      rethrow;
    }
  }

  // 3月5週→4月1週の週送り時に全選手のgradeを+1
  Future<void> promoteAllStudents(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager.promoteAllStudents: 学年アップ処理開始');
    
    try {
      final db = await dataService.database;
      final updatedSchools = <School>[];
      
      for (final school in _currentGame!.schools) {
        print('GameManager.promoteAllStudents: ${school.name}の学年アップ処理開始');
        final promoted = <Player>[];
        
        for (final p in school.players) {
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
          print('GameManager.promoteAllStudents: 選手 ${p.name} (ID: ${p.id}) の学年を ${p.grade} → ${newGrade} に更新、年齢を ${p.age} → ${newAge} に更新');
          
          // 引退判定
          if (newAge > 17) { // 高校卒業後
            final shouldRetire = _shouldPlayerRetire(p, newAge);
            if (shouldRetire) {
              print('GameManager.promoteAllStudents: 選手 ${p.name} (ID: ${p.id}) が引退しました（年齢: ${newAge}歳）');
              
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
                print('GameManager.promoteAllStudents: 引退フラグ設定エラー: $e');
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
            final updateResult = await db.update(
              'Player', 
              {'grade': newGrade, 'age': newAge}, // 年齢も更新
              where: 'id = ?', 
              whereArgs: [p.id]
            );
            print('GameManager.promoteAllStudents: 選手 ${p.name} のDB更新完了 - 結果: $updateResult');
          } catch (e) {
            print('GameManager.promoteAllStudents: 選手 ${p.name} のDB更新エラー: $e');
            // エラーが発生しても処理を継続
          }
          
          promoted.add(p.copyWith(grade: newGrade, age: newAge)); // 年齢も更新
        }
        
        updatedSchools.add(school.copyWith(players: promoted));
        print('GameManager.promoteAllStudents: ${school.name}の学年アップ処理完了 - 選手数: ${promoted.length}');
      }
      
      _currentGame = _currentGame!.copyWith(schools: updatedSchools);
      print('GameManager.promoteAllStudents: 全学校の学年アップ処理完了');
      
    } catch (e) {
      print('GameManager.promoteAllStudents: エラーが発生しました: $e');
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

  // 全選手の成長処理（半年ごと）
  Future<void> growAllPlayers(DataService dataService) async {
    if (_currentGame == null) return;
    
    print('GameManager.growAllPlayers: 全選手の成長処理開始');
    _updateGrowthStatus(true, '選手の成長処理を実行中...');
    
    try {
      _currentGame = GameStateManager.growAllPlayers(_currentGame!);
      
      // 成長後の選手データをデータベースに保存
      _updateGrowthStatus(true, '成長データをデータベースに保存中...');
      await _saveGrownPlayersToDatabase(dataService);
      
      // 成長処理後に学校の強さを更新
      _updateGrowthStatus(true, '学校の強さを更新中...');
      await updateSchoolStrengths(dataService);
      
      _updateGrowthStatus(false, '成長処理完了');
      print('GameManager.growAllPlayers: 全選手の成長処理完了（データベース保存済み）');
    } catch (e) {
      _updateGrowthStatus(false, '成長処理でエラーが発生しました');
      print('GameManager.growAllPlayers: エラーが発生しました: $e');
      rethrow;
    }
  }

  // 成長後の選手データをデータベースに保存
  Future<void> _saveGrownPlayersToDatabase(DataService dataService) async {
    try {
      final db = await dataService.database;
      
      // バッチ更新用のデータを準備
      final batch = db.batch();
      int updateCount = 0;
      
      for (final school in _currentGame!.schools) {
        for (final player in school.players) {
          // 引退選手は成長処理をスキップ
          if (player.isRetired) {
            continue;
          }
          
          final updates = <String, dynamic>{};
          
          // 技術面能力値を収集
          for (final entry in player.technicalAbilities.entries) {
            final columnName = _getDatabaseColumnName(entry.key.name);
            updates[columnName] = entry.value;
          }
          
          // メンタル面能力値を収集
          for (final entry in player.mentalAbilities.entries) {
            final columnName = _getDatabaseColumnName(entry.key.name);
            updates[columnName] = entry.value;
          }
          
          // フィジカル面能力値を収集
          for (final entry in player.physicalAbilities.entries) {
            final columnName = _getDatabaseColumnName(entry.key.name);
            updates[columnName] = entry.value;
          }
          
          // バッチに更新を追加
          if (updates.isNotEmpty) {
            batch.update(
              'Player',
              updates,
              where: 'id = ?',
              whereArgs: [player.id],
            );
            updateCount++;
          }
        }
      }
      
      // バッチ更新を実行
      print('GameManager: $updateCount件の選手データをバッチ更新で保存中...');
      await batch.commit(noResult: true);
      print('GameManager: 選手データのバッチ更新完了');
      
    } catch (e) {
      print('GameManager: 選手データ保存中にエラーが発生しました: $e');
    }
  }

  // 能力値名をデータベースカラム名に変換
  String _getDatabaseColumnName(String abilityName) {
    // camelCase → snake_case 変換
    return abilityName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}'
    );
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

  // 選手のお気に入り状態を更新
  Future<void> togglePlayerFavorite(Player player, DataService dataService) async {
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


  

  


  Future<void> _refreshPlayersFromDb(DataService dataService) async {
    try {
      print('_refreshPlayersFromDb: 開始, _currentGame = ${_currentGame != null ? "loaded" : "null"}');
      print('_refreshPlayersFromDb: 呼び出し元のスタックトレース: ${StackTrace.current}');
      if (_currentGame == null) {
        print('_refreshPlayersFromDb: _currentGameがnullのため終了');
        return;
      }
          final db = await dataService.database;
      print('_refreshPlayersFromDb: データベース接続完了');
      final playerMaps = await db.query('Player');
      
    
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
        
        // Mental abilities復元
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
        
        // Physical abilities復元
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
            discoveredAt: null,
            discoveredBy: null,
            discoveredCount: 0,
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

        final player = Player(
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
          discoveredAt: existingPlayer.discoveredAt,
          discoveredBy: existingPlayer.discoveredBy,
          discoveredCount: existingPlayer.discoveredCount,
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
        );
        

        
        return player;
      }).toList();
      return school.copyWith(players: schoolPlayers.cast<Player>());
    }).toList();
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
    

    
    } catch (e) {
      print('_refreshPlayersFromDb: エラーが発生しました: $e');
      rethrow;
    }
  }

  /// 週送り時にアクションを実行し、リザルトを返す
  Future<List<String>> advanceWeekWithResults(NewsService newsService, DataService dataService) async {
    final results = <String>[];
    if (_currentGame == null) return results;
    
    print('GameManager.advanceWeekWithResults: 週送り処理開始');
    print('GameManager.advanceWeekWithResults: 現在の状態 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}, 年: ${_currentGame!.currentYear}');
    
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
    
    // 3月1週の開始時に卒業処理（2月4週の終了後）
    final isGraduation = _currentGame!.currentMonth == 3 && _currentGame!.currentWeekOfMonth == 1;
    print('GameManager.advanceWeekWithResults: 卒業処理判定 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}, 卒業処理: $isGraduation');
    
    if (isGraduation) {
      print('GameManager.advanceWeekWithResults: 卒業処理開始');
      _updateGrowthStatus(true, '3年生の卒業処理を実行中...');
      
      try {
        await graduateThirdYearStudents(dataService);
        print('GameManager.advanceWeekWithResults: 卒業処理完了、データベース更新開始');
        await _refreshPlayersFromDb(dataService);
        print('GameManager.advanceWeekWithResults: データベース更新完了');
        
        // 卒業生数を計算
        int totalGraduated = 0;
        for (final school in _currentGame!.schools) {
          totalGraduated += school.players.where((p) => p.isGraduated).length;
        }
        
        // 卒業ニュースを生成
        newsService.generateGraduationNews(
          year: _currentGame!.currentYear,
          month: _currentGame!.currentMonth,
          weekOfMonth: _currentGame!.currentWeekOfMonth,
          totalGraduated: totalGraduated,
        );
        
        results.add('3年生${totalGraduated}名が卒業しました。卒業生は卒業フラグが設定され、今後の成長を追跡できます。');
        print('GameManager.advanceWeekWithResults: 卒業処理完了');
      } catch (e) {
        print('GameManager.advanceWeekWithResults: 卒業処理でエラーが発生しました: $e');
        _updateGrowthStatus(false, '卒業処理でエラーが発生しました');
        rethrow;
      }
    }
    
    // 4月1週の開始時に学年アップ＋新入生生成
    final isNewYear = _currentGame!.currentMonth == 4 && _currentGame!.currentWeekOfMonth == 1;
    print('GameManager.advanceWeekWithResults: 新年度処理判定 - 月: ${_currentGame!.currentMonth}, 週: ${_currentGame!.currentWeekOfMonth}, 新年度処理: $isNewYear');
    
    if (isNewYear) {
      print('GameManager.advanceWeekWithResults: 新年度処理開始');
      _updateGrowthStatus(true, '新年度処理を実行中...');
      
      try {
        print('GameManager.advanceWeekWithResults: 学年アップ処理開始');
        await promoteAllStudents(dataService);
        print('GameManager.advanceWeekWithResults: 学年アップ処理完了');
        
        print('GameManager.advanceWeekWithResults: 新入生生成開始');
        await generateNewStudentsForAllSchoolsDb(dataService);
        print('GameManager.advanceWeekWithResults: 新入生生成完了');
        
        print('GameManager.advanceWeekWithResults: データベース更新開始');
        await _refreshPlayersFromDb(dataService);
        print('GameManager.advanceWeekWithResults: データベース更新完了');
        
        results.add('新年度が始まり、全学校で学年が1つ上がり新1年生が入学しました！');
        
        // 新年度開始時のニュース生成
        print('GameManager.advanceWeekWithResults: 新年度ニュース生成開始');
        _updateGrowthStatus(true, '新年度ニュースを生成中...');
        newsService.generateAllPlayerNews(
          _currentGame!.schools,
          year: _currentGame!.currentYear,
          month: _currentGame!.currentMonth,
          weekOfMonth: _currentGame!.currentWeekOfMonth,
        );
        newsService.generateDraftNews(
          year: _currentGame!.currentYear,
          month: _currentGame!.currentMonth,
          weekOfMonth: _currentGame!.currentWeekOfMonth,
        );
        print('GameManager.advanceWeekWithResults: 新年度ニュース生成完了');
        
        _updateGrowthStatus(false, '新年度処理完了');
        print('GameManager.advanceWeekWithResults: 新年度処理完了');
        
      } catch (e) {
        print('GameManager.advanceWeekWithResults: 新年度処理でエラーが発生しました: $e');
        _updateGrowthStatus(false, '新年度処理でエラーが発生しました');
        // エラーが発生しても処理を継続（ゲームが止まらないように）
        results.add('新年度処理中にエラーが発生しましたが、処理を継続します。');
      }
    }
    
    // 週送り後の新しい週で成長判定
    print('GameManager.advanceWeekWithResults: 成長判定開始');
    final currentWeek = _calculateCurrentWeek(_currentGame!.currentMonth, _currentGame!.currentWeekOfMonth);
    final isGrowthWeek = GrowthService.shouldGrow(currentWeek);
    print('GameManager.advanceWeek: 現在週: $currentWeek, 成長週か: $isGrowthWeek');
    
    // 成長処理は月の第1週にのみ実行（重複実行を防ぐ）
    final isFirstWeekOfMonth = _currentGame!.currentWeekOfMonth == 1;
    final shouldExecuteGrowth = isGrowthWeek && isFirstWeekOfMonth;
    
    if (shouldExecuteGrowth) {
      print('GameManager.advanceWeek: 成長週を検出（月第1週） - 全選手の成長処理を開始');
      _updateGrowthStatus(true, '選手の成長期が訪れました。成長処理を実行中...');
      
      try {
        // 成長処理の詳細を表示
        final currentMonth = _currentGame!.currentMonth;
        String growthPeriodName;
        switch (currentMonth) {
          case 5:
            growthPeriodName = '春の成長期';
            break;
          case 8:
            growthPeriodName = '夏の成長期';
            break;
          case 11:
            growthPeriodName = '秋の成長期';
            break;
          case 2:
            growthPeriodName = '冬の成長期';
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
        
        // 成長後のニュース生成
        _updateGrowthStatus(true, '成長ニュースを生成中...');
        newsService.generateAllPlayerNews(
          _currentGame!.schools,
          year: _currentGame!.currentYear,
          month: _currentGame!.currentMonth,
          weekOfMonth: _currentGame!.currentWeekOfMonth,
        );
        
        _updateGrowthStatus(false, '成長処理完了');
        print('GameManager.advanceWeek: 成長処理完了');
      } catch (e) {
        _updateGrowthStatus(false, '成長処理でエラーが発生しました');
        print('GameManager.advanceWeek: 成長処理でエラーが発生しました: $e');
        rethrow;
      }
    }
    
    // 週送り時のニュース生成（毎週）
    print('GameManager.advanceWeekWithResults: ニュース生成開始');
    _generateWeeklyNews(newsService);
    print('GameManager.advanceWeekWithResults: ニュース生成完了');
    
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
    
    // ニュースをゲームデータに保存
    print('GameManager.advanceWeekWithResults: ニュース保存開始');
    saveNewsToGame(newsService);
    print('GameManager.advanceWeekWithResults: ニュース保存完了');
    
    // オートセーブ（週送り完了後）
    print('GameManager.advanceWeekWithResults: オートセーブ開始');
    await saveGame();
    await _gameDataManager.saveAutoGameData(_currentGame!);
    print('GameManager.advanceWeekWithResults: オートセーブ完了');
    
    print('GameManager.advanceWeekWithResults: 週送り処理完了');
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
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // 現在の週番号を計算（4月1週を1週目として計算）
  int _calculateCurrentWeek(int month, int weekOfMonth) {
    int totalWeeks = 0;
    
    // 4月から指定月までの週数を計算
    for (int m = 4; m < month; m++) {
      totalWeeks += _getWeeksInMonth(m);
    }
    
    // 指定月の週数を追加
    totalWeeks += weekOfMonth;
    
    print('GameManager._calculateCurrentWeek: 月=$month, 月内週=$weekOfMonth → 総週数=$totalWeeks');
    
    return totalWeeks;
  }

  // 月の週数を取得（1年間52週になるように調整）
  int _getWeeksInMonth(int month) {
    // より現実的な週の配分
    // 2月は4週、その他の月は4週または5週
    switch (month) {
      case 2:  // 2月は4週
        return 4;
      case 3:  // 3月は5週（年度末）
        return 5;
      case 4:  // 4月は4週
        return 4;
      case 5:  // 5月は5週
        return 5;
      case 6:  // 6月は4週
        return 4;
      case 7:  // 7月は4週
        return 4;
      case 8:  // 8月は5週（夏休み期間）
        return 5;
      case 9:  // 9月は4週
        return 4;
      case 10: // 10月は4週
        return 4;
      case 11: // 11月は4週
        return 4;
      case 12: // 12月は5週（年末）
        return 5;
      case 1:  // 1月は4週
        return 4;
      default:
        return 4;
    }
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
        
        // 選手データが不足している場合のみ_refreshPlayersFromDbを呼び出し
        if (totalPlayers == 0) {
          print('GameManager: 選手データが不足しているため、データベースから再読み込み');
          await _refreshPlayersFromDb(dataService);
          print('GameManager: _refreshPlayersFromDb完了');
        }
        
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

  // 指定スロットにセーブデータが存在するかチェック
  Future<bool> hasGameData(dynamic slot) async {
    return await _gameDataManager.hasGameData(slot);
  }

  void loadGameFromJson(Map<String, dynamic> json) {
    _currentGame = Game.fromJson(json);
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
          final scoutResult = scouting.ActionService.scoutSchool(
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
    
    print('GameManager.updateSchoolStrengths: 学校の強さ計算開始');
    
    try {
      final db = await dataService.database;
      
      for (final school in _currentGame!.schools) {
        // 在籍選手（卒業していない選手）の総合能力を計算
        final activePlayers = school.players.where((p) => !p.isGraduated).toList();
        
        if (activePlayers.isEmpty) {
          print('GameManager.updateSchoolStrengths: ${school.name} - 在籍選手なし');
          continue;
        }
        
        double totalStrength = 0;
        int playerCount = 0;
        
        for (final player in activePlayers) {
          // 選手の総合能力を計算（技術面、メンタル面、フィジカル面の平均）
          final technicalAvg = player.technicalAbilities.values.isNotEmpty 
              ? player.technicalAbilities.values.reduce((a, b) => a + b) / player.technicalAbilities.values.length 
              : 0;
          
          final mentalAvg = player.mentalAbilities.values.isNotEmpty 
              ? player.mentalAbilities.values.reduce((a, b) => a + b) / player.mentalAbilities.values.length 
              : 0;
          
          final physicalAvg = player.physicalAbilities.values.isNotEmpty 
              ? player.physicalAbilities.values.reduce((a, b) => a + b) / player.physicalAbilities.values.length 
              : 0;
          
          final playerStrength = (technicalAvg + mentalAvg + physicalAvg) / 3;
          totalStrength += playerStrength;
          playerCount++;
        }
        
        final averageStrength = playerCount > 0 ? totalStrength / playerCount : 0;
        final schoolStrength = averageStrength.round();
        
        print('GameManager.updateSchoolStrengths: ${school.name} - 平均強さ: ${averageStrength.toStringAsFixed(1)}, 計算された強さ: $schoolStrength');
        
        // データベースのOrganizationテーブルを更新
        try {
          final updateResult = await db.update(
            'Organization',
            {
              'school_strength': schoolStrength,
              'last_year_strength': schoolStrength, // 今年の強さを去年の強さとして記録
            },
            where: 'name = ?',
            whereArgs: [school.name]
          );
          print('GameManager.updateSchoolStrengths: ${school.name}の強さ更新完了 - 結果: $updateResult');
        } catch (e) {
          print('GameManager.updateSchoolStrengths: ${school.name}の強さ更新エラー: $e');
        }
      }
      
      print('GameManager.updateSchoolStrengths: 全学校の強さ計算完了');
      
    } catch (e) {
      print('GameManager.updateSchoolStrengths: エラーが発生しました: $e');
      rethrow;
    }
  }
} 