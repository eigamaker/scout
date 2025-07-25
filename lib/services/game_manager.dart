import '../models/game/game.dart';
import '../models/player/player.dart';
import '../models/school/school.dart';
import '../models/news/news_item.dart';
import 'news_service.dart';
import 'data_service.dart';

class GameManager {
  Game? _currentGame;

  Game? get currentGame => _currentGame;

  // ニューゲーム時に全学校に1〜3年生を生成・配属（DBにもinsert）
  Future<void> generateInitialStudentsForAllSchoolsDb(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    for (final school in _currentGame!.schools) {
      final newPlayers = <Player>[];
      for (int grade = 1; grade <= 3; grade++) {
        final numNew = 10 + (DateTime.now().millisecondsSinceEpoch % 6); // 10〜15人
        for (int i = 0; i < numNew; i++) {
          final isFamous = i == 0 && (DateTime.now().millisecondsSinceEpoch % 3 == 0);
          final name = _generateRandomName();
          final position = _randomPosition();
          final personality = _randomPersonality();
          final fastballVelo = 110 + (DateTime.now().millisecondsSinceEpoch % 60);
          final control = 30 + (DateTime.now().millisecondsSinceEpoch % 40);
          final stamina = 30 + (DateTime.now().millisecondsSinceEpoch % 40);
          final breakAvg = 20 + (DateTime.now().millisecondsSinceEpoch % 60);
          final mentalGrit = 0.5 + ((DateTime.now().millisecondsSinceEpoch % 50) / 100);
          final growthRate = 0.9 + ((DateTime.now().millisecondsSinceEpoch % 30) / 100);
          final peakAbility = 80 + (isFamous ? 15 : (DateTime.now().millisecondsSinceEpoch % 20));
          // Personテーブルinsert
          final personId = await db.insert('Person', {
            'name': name,
            'birth_date': '20${6 + DateTime.now().millisecondsSinceEpoch % 10}-04-01',
            'gender': '男',
            'hometown': school.location,
            'personality': personality,
          });
          // Playerテーブルinsert
          await db.insert('Player', {
            'id': personId,
            'school_id': updatedSchools.length + 1, // 仮: schoolIdは1始まりで順次
            'grade': grade,
            'position': position,
            'fastball_velo': fastballVelo,
            'max_fastball_velo': fastballVelo + 10,
            'control': control,
            'max_control': control + 10,
            'stamina': stamina,
            'max_stamina': stamina + 10,
            'batting_power': 0,
            'max_batting_power': 0,
            'running_speed': 0,
            'max_running_speed': 0,
            'defense': 0,
            'max_defense': 0,
            'mental': 0,
            'max_mental': 0,
            'growth_rate': growthRate,
          });
          // Playerインスタンス生成
          final player = Player(
            name: name,
            school: school.name,
            grade: grade,
            position: position,
            personality: personality,
            fastballVelo: fastballVelo,
            control: control,
            stamina: stamina,
            breakAvg: breakAvg,
            pitches: [],
            mentalGrit: mentalGrit,
            growthRate: growthRate,
            peakAbility: peakAbility,
            positionFit: {},
            talent: 3,
            growthType: 'normal',
          );
          newPlayers.add(player);
          if (isFamous) {
            _currentGame = _currentGame!.discoverPlayer(player);
          }
        }
      }
      updatedSchools.add(school.copyWith(players: newPlayers));
    }
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  Future<void> startNewGameWithDb(String scoutName, DataService dataService) async {
    // 初期データ投入（初回のみ）
    await dataService.insertInitialData();
    final db = await dataService.database;
    // 学校リスト取得
    final schoolMaps = await db.query('Organization', where: 'type = ?', whereArgs: ['高校']);
    final schools = schoolMaps.map((m) => School(
      name: m['name'] as String,
      location: m['location'] as String,
      players: [], // 後で選手を割り当て
      coachTrust: m['school_strength'] as int? ?? 70,
      coachName: '未設定',
    )).toList();
    // 選手リスト取得
    final playerMaps = await db.query('Player');
    final personIds = playerMaps.map((p) => p['id'] as int).toList();
    final persons = <int, Map<String, dynamic>>{};
    if (personIds.isNotEmpty) {
      final personMaps = await db.query('Person', where: 'id IN (${List.filled(personIds.length, '?').join(',')})', whereArgs: personIds);
      for (final p in personMaps) {
        persons[p['id'] as int] = p;
      }
    }
    final players = playerMaps.map((p) {
      final person = persons[p['id'] as int] ?? {};
      return Player(
        name: person['name'] as String? ?? '名無し',
        school: schools.firstWhere((s) => s.name == '横浜工業高校').name,
        grade: p['grade'] as int? ?? 1,
        position: p['position'] as String? ?? '',
        personality: person['personality'] as String? ?? '',
        fastballVelo: p['fastball_velo'] as int? ?? 0,
        control: p['control'] as int? ?? 0,
        stamina: p['stamina'] as int? ?? 0,
        breakAvg: 0,
        pitches: [],
        mentalGrit: 0.0,
        growthRate: p['growth_rate'] as double? ?? 1.0,
        peakAbility: p['max_fastball_velo'] as int? ?? 0,
        positionFit: {},
        talent: p['talent'] is int ? p['talent'] as int : int.tryParse(p['talent']?.toString() ?? '') ?? 3,
        growthType: p['growthType'] is String ? p['growthType'] as String : (p['growthType']?.toString() ?? 'normal'),
      );
    }).toList();
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
      ap: 6,
      budget: 1000000,
      scoutSkills: {
        'exploration': 50,
        'observation': 50,
        'analysis': 50,
        'insight': 50,
        'communication': 50,
        'negotiation': 50,
        'stamina': 50,
      },
      reputation: 50,
      experience: 0,
      level: 1,
      weeklyActions: [],
    );
    // 全学校に1〜3年生を生成
    await generateInitialStudentsForAllSchoolsDb(dataService);
  }

  // スカウト実行
  Player? scoutNewPlayer(NewsService newsService) {
    if (_currentGame == null || _currentGame!.schools.isEmpty) return null;
    // ランダムな学校を選択
    final school = (_currentGame!.schools..shuffle()).first;
    // ランダムな学年
    final grade = 1 + (DateTime.now().millisecondsSinceEpoch % 3);
    // 新しい選手を生成
    final newPlayer = school.generateNewPlayer(grade);
    // 発掘リストに追加
    _currentGame = _currentGame!.discoverPlayer(newPlayer);

    // ニュースも追加
    newsService.addNews(
      NewsItem(
        title: '${newPlayer.name}選手を発掘！',
        content: '${school.name}の${newPlayer.position}、${newPlayer.name}選手を発掘しました。',
        date: DateTime.now(),
        importance: NewsImportance.high,
        category: NewsCategory.player,
        relatedPlayerId: newPlayer.name,
        relatedSchoolId: school.name,
      ),
    );
    return newPlayer;
  }

  // 日付進行・イベント
  void triggerRandomEvent(NewsService newsService) {
    if (_currentGame == null) return;
    final rand = DateTime.now().millisecondsSinceEpoch % 100;
    if (rand < 5) {
      newsService.addNews(
        NewsItem(
          title: '選手が怪我！',
          content: '注目選手の一人が練習中に怪我をしました。',
          date: DateTime.now(),
          importance: NewsImportance.critical,
          category: NewsCategory.player,
        ),
      );
    } else if (rand < 10) {
      newsService.addNews(
        NewsItem(
          title: 'スポンサー獲得！',
          content: '新たなスポンサーがチームを支援してくれることになりました。',
          date: DateTime.now(),
          importance: NewsImportance.high,
          category: NewsCategory.general,
        ),
      );
      _currentGame = _currentGame!.changeBudget(50000);
    } else if (rand < 15) {
      newsService.addNews(
        NewsItem(
          title: 'ファン感謝デー開催',
          content: 'ファン感謝デーが開催され、評判が上がりました。',
          date: DateTime.now(),
          importance: NewsImportance.medium,
          category: NewsCategory.general,
        ),
      );
      _currentGame = _currentGame!.changeReputation(5);
    }
  }

  // 新年度（4月1週）開始時に全学校へ新1年生を生成・配属（DBにもinsert）
  Future<void> generateNewStudentsForAllSchoolsDb(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final updatedSchools = <School>[];
    for (final school in _currentGame!.schools) {
      final newPlayers = List<Player>.from(school.players);
      final numNew = 10 + (DateTime.now().millisecondsSinceEpoch % 6); // 10〜15人
      for (int i = 0; i < numNew; i++) {
        final isFamous = i == 0 && (DateTime.now().millisecondsSinceEpoch % 3 == 0);
        final name = _generateRandomName();
        final position = _randomPosition();
        final personality = _randomPersonality();
        final fastballVelo = 110 + (DateTime.now().millisecondsSinceEpoch % 60);
        final control = 30 + (DateTime.now().millisecondsSinceEpoch % 40);
        final stamina = 30 + (DateTime.now().millisecondsSinceEpoch % 40);
        final breakAvg = 20 + (DateTime.now().millisecondsSinceEpoch % 60);
        final mentalGrit = 0.5 + ((DateTime.now().millisecondsSinceEpoch % 50) / 100);
        final growthRate = 0.9 + ((DateTime.now().millisecondsSinceEpoch % 30) / 100);
        final peakAbility = 80 + (isFamous ? 15 : (DateTime.now().millisecondsSinceEpoch % 20));
        // Personテーブルinsert
        final personId = await db.insert('Person', {
          'name': name,
          'birth_date': '20${6 + DateTime.now().millisecondsSinceEpoch % 10}-04-01',
          'gender': '男',
          'hometown': school.location,
          'personality': personality,
        });
        // Playerテーブルinsert
        await db.insert('Player', {
          'id': personId,
          'school_id': updatedSchools.length + 1, // 仮: schoolIdは1始まりで順次
          'grade': 1,
          'position': position,
          'fastball_velo': fastballVelo,
          'max_fastball_velo': fastballVelo + 10,
          'control': control,
          'max_control': control + 10,
          'stamina': stamina,
          'max_stamina': stamina + 10,
          'batting_power': 0,
          'max_batting_power': 0,
          'running_speed': 0,
          'max_running_speed': 0,
          'defense': 0,
          'max_defense': 0,
          'mental': 0,
          'max_mental': 0,
          'growth_rate': growthRate,
        });
        // Playerインスタンス生成
        final player = Player(
          name: name,
          school: school.name,
          grade: 1,
          position: position,
          personality: personality,
          fastballVelo: fastballVelo,
          control: control,
          stamina: stamina,
          breakAvg: breakAvg,
          pitches: [],
          mentalGrit: mentalGrit,
          growthRate: growthRate,
          peakAbility: peakAbility,
          positionFit: {},
          talent: 3,
          growthType: 'normal',
        );
        newPlayers.add(player);
        if (isFamous) {
          _currentGame = _currentGame!.discoverPlayer(player);
        }
      }
      updatedSchools.add(school.copyWith(players: newPlayers));
    }
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
    final updatedSchools = _currentGame!.schools.map((school) {
      final grownPlayers = school.players.map((p) {
        final player = p.copyWith();
        player.grow();
        return player;
      }).toList();
      return school.copyWith(players: grownPlayers);
    }).toList();
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  // ランダムな名前生成（簡易）
  String _generateRandomName() {
    const familyNames = ['田中', '佐藤', '鈴木', '高橋', '伊藤', '渡辺', '山本', '中村', '小林', '加藤'];
    const givenNames = ['太郎', '次郎', '大輔', '翔太', '健太', '悠斗', '陸', '蓮', '颯太', '陽斗'];
    final f = familyNames[DateTime.now().millisecondsSinceEpoch % familyNames.length];
    final g = givenNames[DateTime.now().microsecondsSinceEpoch % givenNames.length];
    return '$f$g';
  }
  String _randomPosition() {
    const positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '外野手'];
    return positions[DateTime.now().millisecondsSinceEpoch % positions.length];
  }
  String _randomPersonality() {
    const personalities = ['真面目', '負けず嫌い', 'ムードメーカー', '冷静', '情熱的', '努力家', '天才肌'];
    return personalities[DateTime.now().millisecondsSinceEpoch % personalities.length];
  }

  // 才能ランク・成長タイプ・peakAbility・全ポジション適性を含めた選手生成
  Player generatePlayer({
    required String name,
    required String school,
    required int grade,
    required String position,
    required String personality,
  }) {
    // 才能ランク（1〜5）
    final talent = _randomTalent();
    // 成長タイプ
    final growthType = _randomGrowthType();
    // peakAbility（才能ランクでレンジを決定）
    final peakAbility = _randomPeakAbility(talent);
    // 全ポジション適性
    final positionFit = _randomPositionFit(position);
    // 投手能力
    final fastballVelo = 110 + (DateTime.now().millisecondsSinceEpoch % 60);
    final control = 30 + (DateTime.now().millisecondsSinceEpoch % 40);
    final stamina = 30 + (DateTime.now().millisecondsSinceEpoch % 40);
    final breakAvg = 20 + (DateTime.now().millisecondsSinceEpoch % 60);
    // 野手能力
    final batPower = 35 + (DateTime.now().millisecondsSinceEpoch % 41);
    final batControl = 40 + (DateTime.now().millisecondsSinceEpoch % 41);
    final run = 45 + (DateTime.now().millisecondsSinceEpoch % 41);
    final field = 40 + (DateTime.now().millisecondsSinceEpoch % 41);
    final arm = 35 + (DateTime.now().millisecondsSinceEpoch % 41);
    // メンタル・成長率
    final mentalGrit = 0.5 + ((DateTime.now().millisecondsSinceEpoch % 50) / 100);
    final growthRate = 0.9 + ((DateTime.now().millisecondsSinceEpoch % 30) / 100);
    return Player(
      name: name,
      school: school,
      grade: grade,
      position: position,
      personality: personality,
      fastballVelo: fastballVelo,
      control: control,
      stamina: stamina,
      breakAvg: breakAvg,
      pitches: [],
      batPower: batPower,
      batControl: batControl,
      run: run,
      field: field,
      arm: arm,
      mentalGrit: mentalGrit,
      growthRate: growthRate,
      peakAbility: peakAbility,
      positionFit: positionFit,
      talent: talent,
      growthType: growthType,
    );
  }

  int _randomTalent() {
    final r = DateTime.now().millisecondsSinceEpoch % 100;
    if (r < 20) return 1; // 20%
    if (r < 50) return 2; // 30%
    if (r < 85) return 3; // 35%
    if (r < 95) return 4; // 10%
    return 5; // 5%
  }
  String _randomGrowthType() {
    const types = ['early', 'normal', 'late', 'spurt'];
    return types[DateTime.now().millisecondsSinceEpoch % types.length];
  }
  int _randomPeakAbility(int talent) {
    switch (talent) {
      case 1:
        return 75 + (DateTime.now().millisecondsSinceEpoch % 6); // 75-80
      case 2:
        return 85 + (DateTime.now().millisecondsSinceEpoch % 8); // 85-92
      case 3:
        return 95 + (DateTime.now().millisecondsSinceEpoch % 8); // 95-102
      case 4:
        return 105 + (DateTime.now().millisecondsSinceEpoch % 10); // 105-115
      case 5:
        return 120 + (DateTime.now().millisecondsSinceEpoch % 31); // 120-150
      default:
        return 80;
    }
  }
  Map<String, int> _randomPositionFit(String mainPosition) {
    const positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final fit = <String, int>{};
    for (final pos in positions) {
      if (pos == mainPosition) {
        fit[pos] = 70 + (DateTime.now().millisecondsSinceEpoch % 21); // 70-90
      } else {
        fit[pos] = 40 + (DateTime.now().millisecondsSinceEpoch % 31); // 40-70
      }
    }
    return fit;
  }

  Future<void> _refreshPlayersFromDb(DataService dataService) async {
    if (_currentGame == null) return;
    final db = await dataService.database;
    final playerMaps = await db.query('Player');
    final personIds = playerMaps.map((p) => p['id'] as int).toList();
    final persons = <int, Map<String, dynamic>>{};
    if (personIds.isNotEmpty) {
      final personMaps = await db.query('Person', where: 'id IN (${List.filled(personIds.length, '?').join(',')})', whereArgs: personIds);
      for (final p in personMaps) {
        persons[p['id'] as int] = p;
      }
    }
    // 学校ごとにplayersを再構築
    final updatedSchools = _currentGame!.schools.map((school) {
      final schoolPlayers = playerMaps.where((p) => school.name == school.name).map((p) {
        final person = persons[p['id'] as int] ?? {};
        return Player(
          name: person['name'] as String? ?? '名無し',
          school: school.name,
          grade: p['grade'] as int? ?? 1,
          position: p['position'] as String? ?? '',
          personality: person['personality'] as String? ?? '',
          fastballVelo: p['fastball_velo'] as int? ?? 0,
          control: p['control'] as int? ?? 0,
          stamina: p['stamina'] as int? ?? 0,
          breakAvg: 0,
          pitches: [],
          mentalGrit: 0.0,
          growthRate: p['growth_rate'] as double? ?? 1.0,
          peakAbility: p['max_fastball_velo'] as int? ?? 0,
          positionFit: {},
          talent: (p['talent'] is int) ? p['talent'] as int : int.tryParse(p['talent']?.toString() ?? '') ?? 3,
          growthType: (p['growthType'] is String) ? p['growthType'] as String : (p['growthType']?.toString() ?? 'normal'),
        );
      }).toList();
      return school.copyWith(players: schoolPlayers);
    }).toList();
    _currentGame = _currentGame!.copyWith(schools: updatedSchools);
  }

  /// 週送り時にアクションを実行し、リザルトを返す
  Future<List<String>> advanceWeekWithResults(NewsService newsService, DataService dataService) async {
    final results = <String>[];
    if (_currentGame != null) {
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
      }
      // 3か月ごと（4,7,10,1月の最終週）に成長処理
      final isGrowthMonth = [4, 7, 10, 1].contains(_currentGame!.currentMonth);
      final isLastWeekOfMonth = _currentGame!.getMaxWeeksOfMonth(_currentGame!.currentMonth) == _currentGame!.currentWeekOfMonth;
      if (isGrowthMonth && isLastWeekOfMonth) {
        growAllPlayers();
        results.add('今シーズンの成長イベントが発生しました。選手たちが成長しています。');
      }
      for (final action in _currentGame!.weeklyActions) {
        // 簡易リザルト生成（今後詳細化）
        final schoolName = (action.schoolId < _currentGame!.schools.length)
            ? _currentGame!.schools[action.schoolId].name
            : '不明な学校';
        results.add('${schoolName}で${_actionTypeToText(action.type)}を実行しました');
      }
      // 週送り（週進行、AP/予算リセット、アクションリセット）
      _currentGame = _currentGame!
        .advanceWeek()
        .resetWeeklyResources(newAp: 6, newBudget: _currentGame!.budget)
        .resetActions();
      await saveGame(dataService);
      // オートセーブ
      await dataService.saveAutoGameData(_currentGame!.toJson());
    }
    return results;
  }

  String _actionTypeToText(String type) {
    switch (type) {
      case 'PRAC_WATCH':
        return '練習視察';
      case 'GAME_WATCH':
        return '試合観戦';
      default:
        return type;
    }
  }

  void advanceWeek(NewsService newsService, DataService dataService) async {
    if (_currentGame != null) {
      _currentGame = _currentGame!.advanceWeek();
      // 必要に応じて週遷移時のイベントをここに追加
      triggerRandomEvent(newsService);
      // オートセーブ
      await saveGame(dataService);
    }
  }

  void addActionToGame(GameAction action) {
    if (_currentGame != null) {
      _currentGame = _currentGame!.addAction(action);
    }
  }

  // セーブ
  Future<void> saveGame(DataService dataService) async {
    if (_currentGame != null) {
      await dataService.saveGameDataToSlot(_currentGame!.toJson(), 1);
    }
  }

  // ロード
  Future<bool> loadGame(DataService dataService) async {
    final json = await dataService.loadGameDataFromSlot(1);
    if (json != null) {
      _currentGame = Game.fromJson(json);
      return true;
    }
    return false;
  }

  void loadGameFromJson(Map<String, dynamic> json) {
    _currentGame = Game.fromJson(json);
  }
} 