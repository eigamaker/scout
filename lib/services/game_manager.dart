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

  Game? get currentGame => _currentGame;
  Scout? get currentScout => _currentScout;

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
  Future<void> startNewYear(NewsService newsService) async {
    if (_currentGame == null) return;
    
    try {
      print('startNewYear: 新年度開始処理を開始');
      
      // 全学校の選手を更新
      final updatedSchools = <School>[];
      
      for (final school in _currentGame!.schools) {
        print('startNewYear: ${school.name}の処理を開始');
        
        // 既存選手の学年を更新
        final updatedPlayers = school.players.map((player) {
          if (player.grade < 3) {
            return player.copyWith(grade: player.grade + 1);
          } else {
            // 3年生は卒業（削除）
            return null;
          }
        }).where((player) => player != null).cast<Player>().toList();
        
        // 新1年生を生成
        final newFirstYears = await _playerDataGenerator.generatePlayersForSchool(school, 5);
        
        // 全選手を統合
        final allPlayers = [...updatedPlayers, ...newFirstYears];
        
        // 学校を更新
        final updatedSchool = school.copyWith(players: allPlayers);
        updatedSchools.add(updatedSchool);
        
        print('startNewYear: ${school.name}の処理完了 - 選手数: ${allPlayers.length}');
      }
      
      // ゲーム状態を更新
      _currentGame = _currentGame!.copyWith(schools: updatedSchools);
      
      // 全選手のニュース生成
      newsService.generateAllPlayerNews(
        updatedSchools,
        year: _currentGame!.currentYear,
        month: _currentGame!.currentMonth,
        weekOfMonth: _currentGame!.currentWeekOfMonth,
      );
      
      // ドラフト関連ニュース生成
      newsService.generateDraftNews(
        year: _currentGame!.currentYear,
        month: _currentGame!.currentMonth,
        weekOfMonth: _currentGame!.currentWeekOfMonth,
      );
      
      print('startNewYear: 新年度開始処理完了');
    } catch (e, stackTrace) {
      print('startNewYear: エラー発生 - $e');
      print('startNewYear: スタックトレース - $stackTrace');
      rethrow;
    }
  }

  // 新年度（4月1週）開始時に全学校へ新1年生を生成・配属（DBにもinsert）
  Future<void> generateNewStudentsForAllSchoolsDb(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    
    // バッチ処理用のリスト
    final personBatch = <Map<String, dynamic>>[];
    final playerBatch = <Map<String, dynamic>>[];
    final potentialBatch = <Map<String, dynamic>>[];
    
    for (final school in _currentGame!.schools) {
      final newPlayers = List<Player>.from(school.players);
      final numNew = 10 + (Random().nextInt(6)); // 10〜15人
      for (int i = 0; i < numNew; i++) {
        final isFamous = i == 0 && (Random().nextInt(3) == 0);
        final name = _playerDataGenerator.generateRandomName();
        final personality = _playerDataGenerator.generateRandomPersonality();
        
        // PlayerDataGeneratorを使用して選手を生成
        final player = await _playerDataGenerator.generatePlayer(school);
        
        // バッチ用データを準備
        personBatch.add({
          'name': name,
          'birth_date': '20${6 + Random().nextInt(10)}-04-01',
          'gender': '男',
          'hometown': school.location,
          'personality': personality,
        });
        

                  playerBatch.add({
            'school_id': school.id, // 正しい学校IDを使用
          'grade': 1,
          'position': player.position,
          'growth_rate': player.growthRate,
          'talent': player.talent,
          'growth_type': player.growthType,
          'mental_grit': player.mentalGrit,
          'peak_ability': player.peakAbility,
          // Technical（技術面）能力値
          'contact': player.getTechnicalAbility(TechnicalAbility.contact),
          'power': player.getTechnicalAbility(TechnicalAbility.power),
          'plate_discipline': player.getTechnicalAbility(TechnicalAbility.plateDiscipline),
          'bunt': player.getTechnicalAbility(TechnicalAbility.bunt),
          'opposite_field_hitting': player.getTechnicalAbility(TechnicalAbility.oppositeFieldHitting),
          'pull_hitting': player.getTechnicalAbility(TechnicalAbility.pullHitting),
          'bat_control': player.getTechnicalAbility(TechnicalAbility.batControl),
          'swing_speed': player.getTechnicalAbility(TechnicalAbility.swingSpeed),
          'fielding': player.getTechnicalAbility(TechnicalAbility.fielding),
          'throwing': player.getTechnicalAbility(TechnicalAbility.throwing),
          'catcher_ability': player.getTechnicalAbility(TechnicalAbility.catcherAbility),
          'control': player.getTechnicalAbility(TechnicalAbility.control),
          'fastball': player.getTechnicalAbility(TechnicalAbility.fastball),
          'breaking_ball': player.getTechnicalAbility(TechnicalAbility.breakingBall),
          'pitch_movement': player.getTechnicalAbility(TechnicalAbility.pitchMovement),
          // Mental（メンタル面）能力値
          'concentration': player.getMentalAbility(MentalAbility.concentration),
          'anticipation': player.getMentalAbility(MentalAbility.anticipation),
          'vision': player.getMentalAbility(MentalAbility.vision),
          'composure': player.getMentalAbility(MentalAbility.composure),
          'aggression': player.getMentalAbility(MentalAbility.aggression),
          'bravery': player.getMentalAbility(MentalAbility.bravery),
          'leadership': player.getMentalAbility(MentalAbility.leadership),
          'work_rate': player.getMentalAbility(MentalAbility.workRate),
          'self_discipline': player.getMentalAbility(MentalAbility.selfDiscipline),
          'ambition': player.getMentalAbility(MentalAbility.ambition),
          'teamwork': player.getMentalAbility(MentalAbility.teamwork),
          'positioning': player.getMentalAbility(MentalAbility.positioning),
          'pressure_handling': player.getMentalAbility(MentalAbility.pressureHandling),
          'clutch_ability': player.getMentalAbility(MentalAbility.clutchAbility),
          // Physical（フィジカル面）能力値
          'acceleration': player.getPhysicalAbility(PhysicalAbility.acceleration),
          'agility': player.getPhysicalAbility(PhysicalAbility.agility),
          'balance': player.getPhysicalAbility(PhysicalAbility.balance),
          'jumping_reach': player.getPhysicalAbility(PhysicalAbility.jumpingReach),
          'flexibility': player.getPhysicalAbility(PhysicalAbility.flexibility),
          'natural_fitness': player.getPhysicalAbility(PhysicalAbility.naturalFitness),
          'injury_proneness': player.getPhysicalAbility(PhysicalAbility.injuryProneness),
          'stamina': player.getPhysicalAbility(PhysicalAbility.stamina),
          'strength': player.getPhysicalAbility(PhysicalAbility.strength),
          'pace': player.getPhysicalAbility(PhysicalAbility.pace),
        });
        
        // PlayerPotentialsテーブル用データを準備
        if (player.individualPotentials != null) {
          potentialBatch.add({
            // Technical（技術面）ポテンシャル
            'contact_potential': player.individualPotentials!['contact'] ?? 0,
            'power_potential': player.individualPotentials!['power'] ?? 0,
            'plate_discipline_potential': player.individualPotentials!['plateDiscipline'] ?? 0,
            'bunt_potential': player.individualPotentials!['bunt'] ?? 0,
            'opposite_field_hitting_potential': player.individualPotentials!['oppositeFieldHitting'] ?? 0,
            'pull_hitting_potential': player.individualPotentials!['pullHitting'] ?? 0,
            'bat_control_potential': player.individualPotentials!['batControl'] ?? 0,
            'swing_speed_potential': player.individualPotentials!['swingSpeed'] ?? 0,
            'fielding_potential': player.individualPotentials!['fielding'] ?? 0,
            'throwing_potential': player.individualPotentials!['throwing'] ?? 0,
            'catcher_ability_potential': player.individualPotentials!['catcherAbility'] ?? 0,
            'control_potential': player.individualPotentials!['control'] ?? 0,
            'fastball_potential': player.individualPotentials!['fastball'] ?? 0,
            'breaking_ball_potential': player.individualPotentials!['breakingBall'] ?? 0,
            'pitch_movement_potential': player.individualPotentials!['pitchMovement'] ?? 0,
            // Mental（メンタル面）ポテンシャル
            'concentration_potential': player.individualPotentials!['concentration'] ?? 0,
            'anticipation_potential': player.individualPotentials!['anticipation'] ?? 0,
            'vision_potential': player.individualPotentials!['vision'] ?? 0,
            'composure_potential': player.individualPotentials!['composure'] ?? 0,
            'aggression_potential': player.individualPotentials!['aggression'] ?? 0,
            'bravery_potential': player.individualPotentials!['bravery'] ?? 0,
            'leadership_potential': player.individualPotentials!['leadership'] ?? 0,
            'work_rate_potential': player.individualPotentials!['workRate'] ?? 0,
            'self_discipline_potential': player.individualPotentials!['selfDiscipline'] ?? 0,
            'ambition_potential': player.individualPotentials!['ambition'] ?? 0,
            'teamwork_potential': player.individualPotentials!['teamwork'] ?? 0,
            'positioning_potential': player.individualPotentials!['positioning'] ?? 0,
            'pressure_handling_potential': player.individualPotentials!['pressureHandling'] ?? 0,
            'clutch_ability_potential': player.individualPotentials!['clutchAbility'] ?? 0,
            // Physical（フィジカル面）ポテンシャル
            'acceleration_potential': player.individualPotentials!['acceleration'] ?? 0,
            'agility_potential': player.individualPotentials!['agility'] ?? 0,
            'balance_potential': player.individualPotentials!['balance'] ?? 0,
            'jumping_reach_potential': player.individualPotentials!['jumpingReach'] ?? 0,
            'natural_fitness_potential': player.individualPotentials!['naturalFitness'] ?? 0,
            'injury_proneness_potential': player.individualPotentials!['injuryProneness'] ?? 0,
            'stamina_potential': player.individualPotentials!['stamina'] ?? 0,
            'strength_potential': player.individualPotentials!['strength'] ?? 0,
            'pace_potential': player.individualPotentials!['pace'] ?? 0,
            'flexibility_potential': player.individualPotentials!['flexibility'] ?? 0,
          });
        }
        
        newPlayers.add(player);
        if (isFamous) {
          _currentGame = _currentGame!.discoverPlayer(player);
        }
      }
      updatedSchools.add(school.copyWith(players: newPlayers));
    }
    
    // バッチ挿入を実行
    await db.transaction((txn) async {
      // Personテーブルをバッチ挿入
      for (final personData in personBatch) {
        final personId = await txn.insert('Person', personData);
        
        // 対応するPlayerデータにpersonIdを設定
        final playerIndex = personBatch.indexOf(personData);
        if (playerIndex < playerBatch.length) {
          playerBatch[playerIndex]['id'] = personId;
          
          // 対応するPotentialデータにplayerIdを設定
          if (playerIndex < potentialBatch.length) {
            potentialBatch[playerIndex]['player_id'] = personId;
          }
        }
      }
      
      // Playerテーブルをバッチ挿入
      for (final playerData in playerBatch) {
        await txn.insert('Player', playerData);
      }
      
      // PlayerPotentialsテーブルをバッチ挿入
      for (final potentialData in potentialBatch) {
        await txn.insert('PlayerPotentials', potentialData);
      }
    });
    
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  // 3月1週→2週の週送り時に卒業処理（3年生を削除）
  Future<void> graduateThirdYearStudents(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    for (final school in _currentGame!.schools) {
      final remaining = school.players.where((p) => p.grade < 3).toList();
      // DBからも3年生を削除
      for (final p in school.players.where((p) => p.grade == 3)) {
        await db.delete('Player', where: 'name = ? AND school_id = ?', whereArgs: [p.name, school.name]);
      }
      updatedSchools.add(school.copyWith(players: remaining));
    }
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  // 3月5週→4月1週の週送り時に全選手のgradeを+1
  Future<void> promoteAllStudents(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    for (final school in _currentGame!.schools) {
      final promoted = <Player>[];
      for (final p in school.players) {
        final newGrade = p.grade + 1;
        // DBも更新
        await db.update('Player', {'grade': newGrade}, where: 'name = ? AND school_id = ?', whereArgs: [p.name, school.name]);
        promoted.add(p.copyWith(grade: newGrade));
      }
      updatedSchools.add(school.copyWith(players: promoted));
    }
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  // 全選手の成長処理（3か月ごと）
  void growAllPlayers() {
    if (_currentGame == null) return;
    _currentGame = GameStateManager.growAllPlayers(_currentGame!);
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
    

    
    // スカウトアクションを実行
    final scoutResults = await executeScoutActions(dataService);
    results.addAll(scoutResults);
    
    // 3月1週→2週の週送り時に卒業処理
    final isGraduation = _currentGame!.currentMonth == 3 && _currentGame!.currentWeekOfMonth == 1;
    if (isGraduation) {
      await graduateThirdYearStudents(dataService);
      await _refreshPlayersFromDb(dataService);
      results.add('3年生が卒業しました。学校には1・2年生のみが在籍しています。');
    }
    
    // 3月5週→4月1週の週送り時に学年アップ＋新入生生成
    final isNewYear = _currentGame!.currentMonth == 3 && _currentGame!.currentWeekOfMonth == 5;
    if (isNewYear) {
      await promoteAllStudents(dataService);
      await generateNewStudentsForAllSchoolsDb(dataService);
      await _refreshPlayersFromDb(dataService);
      results.add('新年度が始まり、全学校で学年が1つ上がり新1年生が入学しました！');
      
      // 新年度開始時のニュース生成
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
    }
    
    // 半年ごとの成長処理（3月1週と9月1週）
    final currentWeek = _calculateCurrentWeek(_currentGame!.currentMonth, _currentGame!.currentWeekOfMonth);
    final isGrowthWeek = GrowthService.shouldGrow(currentWeek);
    if (isGrowthWeek) {
      growAllPlayers();
      
      // 成長後に新たに注目選手になった選手をチェック
      _updatePubliclyKnownPlayersAfterGrowth();
      
      results.add('選手たちの成長期が訪れました。選手たちが成長しています。');
      
      // 成長後のニュース生成
      newsService.generateAllPlayerNews(
        _currentGame!.schools,
        year: _currentGame!.currentYear,
        month: _currentGame!.currentMonth,
        weekOfMonth: _currentGame!.currentWeekOfMonth,
      );
    }
    
    // 週送り時のニュース生成（毎週）
    _generateWeeklyNews(newsService);
    
    // 週送り（週進行、AP/予算リセット、アクションリセット）
    _currentGame = _currentGame!
      .advanceWeek()
      .resetWeeklyResources(newAp: 15, newBudget: _currentGame!.budget)
      .resetActions();
    
    // スカウトのAPを最大値まで回復
    if (_currentScout != null) {
      _currentScout = _currentScout!.restoreActionPoints(_currentScout!.maxActionPoints);
      // GameインスタンスのAPも更新
      _currentGame = _currentGame!.copyWith(
        ap: _currentScout!.actionPoints,
      );
    }
    
    // ニュースをゲームデータに保存
    saveNewsToGame(newsService);
    
    // オートセーブ（週送り完了後）
    await saveGame();
    await _gameDataManager.saveAutoGameData(_currentGame!);
    

    
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
    for (int m = 4; m < month; m++) {
      totalWeeks += _getWeeksInMonth(m);
    }
    totalWeeks += weekOfMonth;
    return totalWeeks;
  }

  // 月の週数を取得
  int _getWeeksInMonth(int month) {
    if (month == 3 || month == 5 || month == 8 || month == 12) {
      return 5;
    }
    return 4;
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
} 