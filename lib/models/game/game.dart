import '../player/player.dart';
import '../school/school.dart';
import '../scouting/scout.dart';
import '../scouting/team_request.dart';
import '../news/news_item.dart';
import '../professional/professional_team.dart';
import '../game/pennant_race.dart';
import '../game/high_school_tournament.dart';

// ゲーム状態
enum GameState {
  mainMenu, // メインメニュー
  scouting, // スカウト中
  gameSimulation, // 試合シミュレーション
  draft, // ドラフト
  endOfSeason, // シーズン終了
}

// ゲームクラス
class GameAction {
  final String id; // アクションID
  final String type; // アクション種別（例: PRAC_WATCH, GAME_WATCH など）
  final int schoolId; // 対象学校ID
  final int? playerId; // 対象選手ID（任意）
  final String? playerName; // 対象選手名（playerIdがnullの場合に使用）
  final int apCost; // AP消費
  final int budgetCost; // 予算消費
  final Map<String, dynamic>? params; // その他パラメータ

  GameAction({
    required this.id,
    required this.type,
    required this.schoolId,
    this.playerId,
    this.playerName,
    required this.apCost,
    required this.budgetCost,
    this.params,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'schoolId': schoolId,
    'playerId': playerId,
    'playerName': playerName,
    'apCost': apCost,
    'budgetCost': budgetCost,
    'params': params,
  };

  factory GameAction.fromJson(Map<String, dynamic> json) => GameAction(
    id: json['id'] as String,
    type: json['type'] as String,
    schoolId: json['schoolId'] as int,
    playerId: json['playerId'] as int?,
    playerName: json['playerName'] as String?,
    apCost: json['apCost'] as int,
    budgetCost: json['budgetCost'] as int,
    params: json['params'] as Map<String, dynamic>?,
  );
}

class Game {
  final String scoutName; // スカウト名
  final int scoutSkill; // スカウトスキル 0-100
  final int currentYear; // 現在の年
  final int currentMonth; // 現在の月（1-12）
  final int currentWeekOfMonth; // 現在の月内の週（1-5）
  final GameState state; // ゲーム状態
  final List<School> schools; // 学校リスト
  final List<Player> discoveredPlayers; // 発掘した選手リスト
  final List<Player> watchedPlayers; // 注目選手リスト
  final List<Player> favoritePlayers; // お気に入り選手リスト
  final int ap; // 今週のアクションポイント
  final int budget; // 予算
  final Map<ScoutSkill, int> scoutSkills; // スカウトスキル
  final int reputation; // 評判 0-100
  final int experience; // 経験値
  final int level; // レベル
  final List<GameAction> weeklyActions; // 今週の行動計画
  final TeamRequestManager teamRequests; // 球団からの要望
  final List<NewsItem> newsList; // ニュースリスト
  final ProfessionalTeamManager professionalTeams; // プロ野球団管理
  final PennantRace? pennantRace; // ペナントレース
  final List<HighSchoolTournament> highSchoolTournaments; // 高校野球大会
  
  Game({
    required this.scoutName,
    required this.scoutSkill,
    required this.currentYear,
    required this.currentMonth,
    required this.currentWeekOfMonth,
    required this.state,
    required this.schools,
    required this.discoveredPlayers,
    required this.watchedPlayers,
    required this.favoritePlayers,
    required this.ap,
    required this.budget,
    required this.scoutSkills,
    required this.reputation,
    required this.experience,
    required this.level,
    required this.weeklyActions,
    required this.teamRequests,
    required this.newsList,
    required this.professionalTeams,
    this.pennantRace,
    this.highSchoolTournaments = const [],
  });

  // 月ごとの最大週数を返す
  int getMaxWeeksOfMonth(int month) {
    // より現実的な週の配分
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

  // 週を進める
  Game advanceWeek() {
    int newWeek = currentWeekOfMonth + 1;
    int newMonth = currentMonth;
    int newYear = currentYear;
    int maxWeeks = getMaxWeeksOfMonth(currentMonth);
    if (newWeek > maxWeeks) {
      newWeek = 1;
      newMonth += 1;
      if (newMonth > 12) {
        newMonth = 1;
      }
      // 年度切り替え（3月5週→4月1週）
      if (currentMonth == 3 && currentWeekOfMonth == 5) {
        newYear += 1;
        newMonth = 4;
        newWeek = 1;
      }
    }
    return copyWith(
      currentYear: newYear,
      currentMonth: newMonth,
      currentWeekOfMonth: newWeek,
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
    return '${currentMonth}月${currentWeekOfMonth}週';
  }

  // 新年度開始判定
  bool get isNewFiscalYearStart => currentMonth == 4 && currentWeekOfMonth == 1;
  
  // シーズンかどうか（4月〜8月）
  bool get isSeason {
    return currentWeekOfMonth >= 1 && currentWeekOfMonth <= 20; // 4月〜8月の週数を想定
  }
  
  // オフシーズンかどうか
  bool get isOffSeason {
    return !isSeason;
  }
  
  // ドラフトシーズンかどうか（10月〜11月）
  bool get isDraftSeason {
    return currentWeekOfMonth >= 40 && currentWeekOfMonth <= 50; // 10月〜11月の週数を想定
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

  // 週初にAP/予算をリセット
  Game resetWeeklyResources({int? newAp, int? newBudget}) {
    return copyWith(
      ap: newAp ?? ap,
      budget: newBudget ?? budget,
    );
  }

  // アクション追加
  Game addAction(GameAction action) {
    if (ap < action.apCost || budget < action.budgetCost) {
      // AP/予算不足
      return this;
    }
    return copyWith(
      weeklyActions: [...weeklyActions, action],
      ap: ap - action.apCost,
      budget: budget - action.budgetCost,
    );
  }
  // アクションリセット（週送り時）
  Game resetActions() {
    return copyWith(weeklyActions: []);
  }

  Map<String, dynamic> toJson() => {
    'scoutName': scoutName,
    'scoutSkill': scoutSkill,
    'currentYear': currentYear,
    'currentMonth': currentMonth,
    'currentWeekOfMonth': currentWeekOfMonth,
    'state': state.index,
    'schools': schools.map((s) => s.toJson()).toList(),
    'discoveredPlayers': discoveredPlayers.map((p) => p.toJson()).toList(),
    'watchedPlayers': watchedPlayers.map((p) => p.toJson()).toList(),
    'favoritePlayers': favoritePlayers.map((p) => p.toJson()).toList(),
    'budget': budget,
    'reputation': reputation,
    'experience': experience,
    'level': level,
    'weeklyActions': weeklyActions.map((a) => a.toJson()).toList(),
    'scoutSkills': scoutSkills.map((k, v) => MapEntry(k.name, v)),
    'newsList': newsList.map((n) => n.toJson()).toList(),
    'pennantRace': pennantRace?.toJson(),
    'highSchoolTournaments': highSchoolTournaments.map((t) => t.toJson()).toList(),
  };

  factory Game.fromJson(Map<String, dynamic> json) {
    // scoutSkillsの変換
    final scoutSkillsJson = json['scoutSkills'] as Map<String, dynamic>? ?? {
      'exploration': 50,
      'observation': 50,
      'analysis': 50,
      'insight': 50,
      'communication': 50,
      'negotiation': 50,
      'stamina': 50,
    };
    
    final scoutSkills = <ScoutSkill, int>{};
    for (final entry in scoutSkillsJson.entries) {
      final skill = ScoutSkill.values.firstWhere(
        (s) => s.name == entry.key,
        orElse: () => ScoutSkill.exploration,
      );
      scoutSkills[skill] = entry.value as int;
    }

    final newsList = (json['newsList'] as List?)?.map((n) => NewsItem.fromJson(n)).toList() ?? [];
    
    return Game(
      scoutName: json['scoutName'] ?? '',
      scoutSkill: json['scoutSkill'] ?? 50,
      currentYear: json['currentYear'] ?? DateTime.now().year,
      currentMonth: json['currentMonth'] ?? 4,
      currentWeekOfMonth: json['currentWeekOfMonth'] ?? 1,
      state: GameState.values[(json['state'] ?? 0)],
      schools: (json['schools'] as List?)?.map((s) => School.fromJson(s)).toList() ?? [],
      discoveredPlayers: (json['discoveredPlayers'] as List?)?.map((p) => Player.fromJson(p)).toList() ?? [],
      watchedPlayers: (json['watchedPlayers'] as List?)?.map((p) => Player.fromJson(p)).toList() ?? [],
      favoritePlayers: (json['favoritePlayers'] as List?)?.map((p) => Player.fromJson(p)).toList() ?? [],
      ap: json['ap'] ?? 6,
      budget: json['budget'] ?? 1000000,
      scoutSkills: scoutSkills,
      reputation: json['reputation'] ?? 50,
      experience: json['experience'] ?? 0,
      level: json['level'] ?? 1,
      weeklyActions: (json['weeklyActions'] as List?)?.map((a) => GameAction.fromJson(a)).toList() ?? [],
      teamRequests: TeamRequestManager(),
      newsList: newsList,
      professionalTeams: ProfessionalTeamManager(teams: ProfessionalTeamManager.generateDefaultTeams()),
      highSchoolTournaments: (json['highSchoolTournaments'] as List?)?.map((t) => HighSchoolTournament.fromJson(t)).toList() ?? [],
    );
  }
  
  // コピーメソッド
  Game copyWith({
    String? scoutName,
    int? scoutSkill,
    int? currentYear,
    int? currentMonth,
    int? currentWeekOfMonth,
    GameState? state,
    List<School>? schools,
    List<Player>? discoveredPlayers,
    List<Player>? watchedPlayers,
    List<Player>? favoritePlayers,
    int? budget,
    int? reputation,
    int? experience,
    int? level,
    List<GameAction>? weeklyActions,
    int? ap,
    Map<ScoutSkill, int>? scoutSkills,
    TeamRequestManager? teamRequests,
    List<NewsItem>? newsList,
    ProfessionalTeamManager? professionalTeams,
    PennantRace? pennantRace,
    List<HighSchoolTournament>? highSchoolTournaments,
  }) {
    return Game(
      scoutName: scoutName ?? this.scoutName,
      scoutSkill: scoutSkill ?? this.scoutSkill,
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
      currentWeekOfMonth: currentWeekOfMonth ?? this.currentWeekOfMonth,
      state: state ?? this.state,
      schools: schools ?? this.schools,
      discoveredPlayers: discoveredPlayers ?? this.discoveredPlayers,
      watchedPlayers: watchedPlayers ?? this.watchedPlayers,
      favoritePlayers: favoritePlayers ?? this.favoritePlayers,
      budget: budget ?? this.budget,
      reputation: reputation ?? this.reputation,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      weeklyActions: weeklyActions ?? this.weeklyActions,
      ap: ap ?? this.ap,
      scoutSkills: scoutSkills ?? this.scoutSkills,
      teamRequests: teamRequests ?? this.teamRequests,
      newsList: newsList ?? this.newsList,
      professionalTeams: professionalTeams ?? this.professionalTeams,
      pennantRace: pennantRace ?? this.pennantRace,
      highSchoolTournaments: highSchoolTournaments ?? this.highSchoolTournaments,
    );
  }
} 