import '../models/game/game.dart';
import '../models/player/player.dart';
import '../models/school/school.dart';
import '../models/news/news_item.dart';
import 'news_service.dart';
import 'data_service.dart';

class GameManager {
  Game? _currentGame;

  Game? get currentGame => _currentGame;

  void startNewGame(String scoutName) {
    // ダミー学校・選手を生成
    final school = School(
      name: '甲子園高校',
      location: '兵庫県',
      players: [
        Player(
          name: '田中太郎',
          school: '甲子園高校',
          grade: 3,
          position: '投手',
          personality: '真面目',
          fastballVelo: 145,
          control: 70,
          stamina: 80,
          breakAvg: 75,
          pitches: [],
          mentalGrit: 0.1,
          growthRate: 1.0,
          peakAbility: 120,
          positionFit: {'投手': 90},
        ),
      ],
      coachTrust: 80,
      coachName: '山田監督',
    );

    _currentGame = Game(
      scoutName: scoutName,
      scoutSkill: 50,
      currentDate: DateTime.now(),
      currentYear: DateTime.now().year,
      currentMonth: DateTime.now().month,
      currentDay: DateTime.now().day,
      state: GameState.scouting,
      schools: [school],
      discoveredPlayers: school.players,
      watchedPlayers: [],
      favoritePlayers: [],
      budget: 1000000,
      reputation: 50,
      experience: 0,
      level: 1,
    );
  }

  void loadGame(Map<String, dynamic> json) {
    _currentGame = Game.fromJson(json);
  }

  Map<String, dynamic>? saveGame() {
    return _currentGame?.toJson();
  }

  // セーブ
  Future<void> saveGame(DataService dataService) async {
    if (_currentGame != null) {
      await dataService.saveGameData(_currentGame!.toJson());
    }
  }

  // ロード
  Future<bool> loadGame(DataService dataService) async {
    final json = await dataService.loadGameData();
    if (json != null) {
      _currentGame = Game.fromJson(json);
      return true;
    }
    return false;
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

  void triggerRandomEvent(NewsService newsService) {
    if (_currentGame == null) return;
    final rand = DateTime.now().millisecondsSinceEpoch % 100;
    if (rand < 10) {
      // 10%の確率でイベント発生
      newsService.addNews(
        NewsItem(
          title: '特別イベント発生！',
          content: '今日は特別な出来事がありました。',
          date: DateTime.now(),
          importance: NewsImportance.critical,
          category: NewsCategory.general,
        ),
      );
    }
  }

  void advanceDay(NewsService newsService) {
    if (_currentGame != null) {
      _currentGame = _currentGame!.advanceDate();
      triggerRandomEvent(newsService);
    }
  }

  // TODO: ゲーム進行・ターン処理など
} 