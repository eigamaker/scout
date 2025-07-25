import '../player/player.dart';
import '../school/school.dart';

// ゲーム状態
enum GameState {
  mainMenu, // メインメニュー
  scouting, // スカウト中
  gameSimulation, // 試合シミュレーション
  draft, // ドラフト
  endOfSeason, // シーズン終了
}

// ゲームクラス
class Game {
  final String scoutName; // スカウト名
  final int scoutSkill; // スカウトスキル 0-100
  final DateTime currentDate; // 現在の日付
  final int currentYear; // 現在の年
  final int currentMonth; // 現在の月
  final int currentDay; // 現在の日
  final GameState state; // ゲーム状態
  final List<School> schools; // 学校リスト
  final List<Player> discoveredPlayers; // 発掘した選手リスト
  final List<Player> watchedPlayers; // 注目選手リスト
  final List<Player> favoritePlayers; // お気に入り選手リスト
  final int budget; // 予算
  final int reputation; // 評判 0-100
  final int experience; // 経験値
  final int level; // レベル
  
  Game({
    required this.scoutName,
    required this.scoutSkill,
    required this.currentDate,
    required this.currentYear,
    required this.currentMonth,
    required this.currentDay,
    required this.state,
    required this.schools,
    required this.discoveredPlayers,
    required this.watchedPlayers,
    required this.favoritePlayers,
    required this.budget,
    required this.reputation,
    required this.experience,
    required this.level,
  });
  
  // 日付を進める
  Game advanceDate() {
    final newDate = currentDate.add(const Duration(days: 1));
    return copyWith(
      currentDate: newDate,
      currentYear: newDate.year,
      currentMonth: newDate.month,
      currentDay: newDate.day,
    );
  }
  
  // 月を進める
  Game advanceMonth() {
    final newDate = DateTime(currentYear, currentMonth + 1, 1);
    return copyWith(
      currentDate: newDate,
      currentYear: newDate.year,
      currentMonth: newDate.month,
      currentDay: newDate.day,
    );
  }
  
  // 年を進める
  Game advanceYear() {
    final newDate = DateTime(currentYear + 1, 1, 1);
    return copyWith(
      currentDate: newDate,
      currentYear: newDate.year,
      currentMonth: newDate.month,
      currentDay: newDate.day,
    );
  }
  
  // 選手を発掘
  Game discoverPlayer(Player player) {
    final newDiscoveredPlayers = List<Player>.from(discoveredPlayers);
    if (!newDiscoveredPlayers.any((p) => p.name == player.name)) {
      newDiscoveredPlayers.add(player);
    }
    
    return copyWith(
      discoveredPlayers: newDiscoveredPlayers,
      experience: experience + 10, // 発掘で経験値獲得
    );
  }
  
  // 選手を注目に追加
  Game addWatchedPlayer(Player player) {
    final newWatchedPlayers = List<Player>.from(watchedPlayers);
    if (!newWatchedPlayers.any((p) => p.name == player.name)) {
      newWatchedPlayers.add(player);
    }
    
    return copyWith(watchedPlayers: newWatchedPlayers);
  }
  
  // 選手を注目から削除
  Game removeWatchedPlayer(Player player) {
    final newWatchedPlayers = watchedPlayers.where((p) => p.name != player.name).toList();
    return copyWith(watchedPlayers: newWatchedPlayers);
  }
  
  // 選手をお気に入りに追加
  Game addFavoritePlayer(Player player) {
    final newFavoritePlayers = List<Player>.from(favoritePlayers);
    if (!newFavoritePlayers.any((p) => p.name == player.name)) {
      newFavoritePlayers.add(player);
    }
    
    return copyWith(favoritePlayers: newFavoritePlayers);
  }
  
  // 選手をお気に入りから削除
  Game removeFavoritePlayer(Player player) {
    final newFavoritePlayers = favoritePlayers.where((p) => p.name != player.name).toList();
    return copyWith(favoritePlayers: newFavoritePlayers);
  }
  
  // 予算を変更
  Game changeBudget(int amount) {
    return copyWith(budget: budget + amount);
  }
  
  // 評判を変更
  Game changeReputation(int amount) {
    return copyWith(reputation: (reputation + amount).clamp(0, 100));
  }
  
  // 経験値を追加
  Game addExperience(int amount) {
    final newExperience = experience + amount;
    final newLevel = (newExperience / 100).floor() + 1;
    
    return copyWith(
      experience: newExperience,
      level: newLevel,
    );
  }
  
  // スカウトスキルを変更
  Game changeScoutSkill(int amount) {
    return copyWith(scoutSkill: (scoutSkill + amount).clamp(0, 100));
  }
  
  // ゲーム状態を変更
  Game changeState(GameState newState) {
    return copyWith(state: newState);
  }
  
  // 学校を追加
  Game addSchool(School school) {
    final newSchools = List<School>.from(schools);
    if (!newSchools.any((s) => s.name == school.name)) {
      newSchools.add(school);
    }
    return copyWith(schools: newSchools);
  }
  
  // 日付のフォーマット
  String getFormattedDate() {
    return '${currentYear}/${currentMonth.toString().padLeft(2, '0')}/${currentDay.toString().padLeft(2, '0')}';
  }
  
  // シーズンかどうか（4月〜8月）
  bool get isSeason {
    return currentMonth >= 4 && currentMonth <= 8;
  }
  
  // オフシーズンかどうか
  bool get isOffSeason {
    return !isSeason;
  }
  
  // ドラフトシーズンかどうか（10月〜11月）
  bool get isDraftSeason {
    return currentMonth >= 10 && currentMonth <= 11;
  }
  
  // 発掘可能な選手を取得
  List<Player> getAvailablePlayers() {
    final allPlayers = <Player>[];
    for (final school in schools) {
      allPlayers.addAll(school.players);
    }
    
    // 未発掘の選手のみを返す
    return allPlayers.where((player) => 
      !discoveredPlayers.any((p) => p.name == player.name)
    ).toList();
  }
  
  // 注目選手の更新
  List<Player> getUpdatedWatchedPlayers() {
    final updatedPlayers = <Player>[];
    
    for (final watchedPlayer in watchedPlayers) {
      // 学校から最新の選手情報を取得
      for (final school in schools) {
        final player = school.players.firstWhere(
          (p) => p.name == watchedPlayer.name,
          orElse: () => watchedPlayer,
        );
        
        if (player != watchedPlayer) {
          updatedPlayers.add(player);
        } else {
          updatedPlayers.add(watchedPlayer);
        }
      }
    }
    
    return updatedPlayers;
  }

  Map<String, dynamic> toJson() => {
    'scoutName': scoutName,
    'scoutSkill': scoutSkill,
    'currentDate': currentDate.toIso8601String(),
    'currentYear': currentYear,
    'currentMonth': currentMonth,
    'currentDay': currentDay,
    'state': state.index,
    'schools': schools.map((s) => s.toJson()).toList(),
    'discoveredPlayers': discoveredPlayers.map((p) => p.toJson()).toList(),
    'watchedPlayers': watchedPlayers.map((p) => p.toJson()).toList(),
    'favoritePlayers': favoritePlayers.map((p) => p.toJson()).toList(),
    'budget': budget,
    'reputation': reputation,
    'experience': experience,
    'level': level,
  };

  factory Game.fromJson(Map<String, dynamic> json) => Game(
    scoutName: json['scoutName'],
    scoutSkill: json['scoutSkill'],
    currentDate: DateTime.parse(json['currentDate']),
    currentYear: json['currentYear'],
    currentMonth: json['currentMonth'],
    currentDay: json['currentDay'],
    state: GameState.values[json['state']],
    schools: (json['schools'] as List).map((s) => School.fromJson(s)).toList(),
    discoveredPlayers: (json['discoveredPlayers'] as List).map((p) => Player.fromJson(p)).toList(),
    watchedPlayers: (json['watchedPlayers'] as List).map((p) => Player.fromJson(p)).toList(),
    favoritePlayers: (json['favoritePlayers'] as List).map((p) => Player.fromJson(p)).toList(),
    budget: json['budget'],
    reputation: json['reputation'],
    experience: json['experience'],
    level: json['level'],
  );
  
  // コピーメソッド
  Game copyWith({
    String? scoutName,
    int? scoutSkill,
    DateTime? currentDate,
    int? currentYear,
    int? currentMonth,
    int? currentDay,
    GameState? state,
    List<School>? schools,
    List<Player>? discoveredPlayers,
    List<Player>? watchedPlayers,
    List<Player>? favoritePlayers,
    int? budget,
    int? reputation,
    int? experience,
    int? level,
  }) {
    return Game(
      scoutName: scoutName ?? this.scoutName,
      scoutSkill: scoutSkill ?? this.scoutSkill,
      currentDate: currentDate ?? this.currentDate,
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
      currentDay: currentDay ?? this.currentDay,
      state: state ?? this.state,
      schools: schools ?? this.schools,
      discoveredPlayers: discoveredPlayers ?? this.discoveredPlayers,
      watchedPlayers: watchedPlayers ?? this.watchedPlayers,
      favoritePlayers: favoritePlayers ?? this.favoritePlayers,
      budget: budget ?? this.budget,
      reputation: reputation ?? this.reputation,
      experience: experience ?? this.experience,
      level: level ?? this.level,
    );
  }
} 