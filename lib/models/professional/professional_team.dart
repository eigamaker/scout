import 'dart:math';
import '../player/player.dart';
import '../../services/player_generator.dart';

// プロ野球団のリーグ
enum League {
  central,    // セ・リーグ
  pacific,   // パ・リーグ
}

// プロ野球団の地区
enum Division {
  east,       // 東地区
  west,       // 西地区
  central,    // 中地区
}

// プロ野球団クラス
class ProfessionalTeam {
  final String id;
  final String name;
  final String shortName; // 略称（例：巨人、阪神）
  final League league;
  final Division division;
  final String homeStadium; // 本拠地
  final String city; // 所在都市
  final int budget; // 球団予算（単位：万円）
  final List<String> needs; // 球団ニーズ
  final Map<String, int> scoutRelations; // スカウトとの関係性（0-100）
  
  // ドラフト指名順位（1位が最優先）
  final int draftOrder;
  
  // 球団の戦力状況（各ポジションの戦力レベル：1-100）
  final Map<String, int> teamStrength;
  
  // 球団の特徴・戦略
  final String strategy; // 戦略（例：投手重視、打撃重視）
  final List<String> strengths; // 強み
  final List<String> weaknesses; // 弱み
  
  // 球団の評判・人気度
  final int popularity; // 人気度（0-100）
  final int success; // 成功度（0-100）
  
  // 選手リスト
  final List<Player> players; // 所属選手

  ProfessionalTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.league,
    required this.division,
    required this.homeStadium,
    required this.city,
    required this.budget,
    required this.needs,
    required this.scoutRelations,
    required this.draftOrder,
    required this.teamStrength,
    required this.strategy,
    required this.strengths,
    required this.weaknesses,
    required this.popularity,
    required this.success,
    List<Player>? players,
  }) : players = players ?? [];

  // 球団の総合戦力を計算
  int get totalStrength {
    if (teamStrength.isEmpty) return 0;
    return teamStrength.values.reduce((a, b) => a + b) ~/ teamStrength.length;
  }

  // 特定ポジションの戦力レベルを取得
  int getPositionStrength(String position) {
    return teamStrength[position] ?? 50; // デフォルトは50
  }

  // スカウトとの関係性レベルを取得
  int getScoutRelationLevel(String scoutId) {
    return scoutRelations[scoutId] ?? 30; // デフォルトは30
  }

  // 球団の予算レベルを取得
  String get budgetLevel {
    if (budget >= 100000) return '高予算';
    if (budget >= 50000) return '中予算';
    return '低予算';
  }

  // 球団の戦力レベルを取得
  String get strengthLevel {
    final strength = totalStrength;
    if (strength >= 80) return '強豪';
    if (strength >= 60) return '中堅';
    if (strength >= 40) return '弱小';
    return '最下位';
  }

  // 球団の特徴を文字列で取得
  String get characteristics {
    final chars = <String>[];
    chars.add('${league.name == 'central' ? 'セ・リーグ' : 'パ・リーグ'}');
    chars.add('${division.name == 'east' ? '東地区' : division.name == 'west' ? '西地区' : '中地区'}');
    chars.add(strategy);
    chars.add(budgetLevel);
    chars.add(strengthLevel);
    return chars.join(' / ');
  }

  // 球団の詳細情報を取得
  Map<String, String> get detailedInfo {
    return {
      '本拠地': homeStadium,
      '所在都市': city,
      '球団予算': '${budget}万円',
      '戦略': strategy,
      '強み': strengths.join(', '),
      '弱み': weaknesses.join(', '),
      '人気度': '$popularity%',
      '成功度': '$success%',
    };
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'league': league.index,
    'division': division.index,
    'homeStadium': homeStadium,
    'city': city,
    'budget': budget,
    'needs': needs,
    'scoutRelations': scoutRelations,
    'draftOrder': draftOrder,
    'teamStrength': teamStrength,
    'strategy': strategy,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'popularity': popularity,
    'success': success,
    'players': players.map((p) => p.toJson()).toList(),
  };

  factory ProfessionalTeam.fromJson(Map<String, dynamic> json) {
    return ProfessionalTeam(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      league: League.values[json['league'] as int],
      division: Division.values[json['division'] as int],
      homeStadium: json['homeStadium'] as String,
      city: json['city'] as String,
      budget: json['budget'] as int,
      needs: List<String>.from(json['needs']),
      scoutRelations: Map<String, int>.from(json['scoutRelations']),
      draftOrder: json['draftOrder'] as int,
      teamStrength: Map<String, int>.from(json['teamStrength']),
      strategy: json['strategy'] as String,
      strengths: List<String>.from(json['strengths']),
      weaknesses: List<String>.from(json['weaknesses']),
      popularity: json['popularity'] as int,
      success: json['success'] as int,
      players: json['players'] != null
        ? (json['players'] as List).map((p) => Player.fromJson(p)).toList()
        : [],
    );
  }

  // コピーメソッド
  ProfessionalTeam copyWith({
    String? id,
    String? name,
    String? shortName,
    League? league,
    Division? division,
    String? homeStadium,
    String? city,
    int? budget,
    List<String>? needs,
    Map<String, int>? scoutRelations,
    int? draftOrder,
    Map<String, int>? teamStrength,
    String? strategy,
    List<String>? strengths,
    List<String>? weaknesses,
    int? popularity,
    int? success,
    List<Player>? players,
  }) {
    return ProfessionalTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      league: league ?? this.league,
      division: division ?? this.division,
      homeStadium: homeStadium ?? this.homeStadium,
      city: city ?? this.city,
      budget: budget ?? this.budget,
      needs: needs ?? this.needs,
      scoutRelations: scoutRelations ?? this.scoutRelations,
      draftOrder: draftOrder ?? this.draftOrder,
      teamStrength: teamStrength ?? this.teamStrength,
      strategy: strategy ?? this.strategy,
      strengths: strengths ?? this.strengths,
      weaknesses: weaknesses ?? this.weaknesses,
      popularity: popularity ?? this.popularity,
      success: success ?? this.success,
      players: players ?? this.players,
    );
  }

  // スカウトとの関係性を更新
  ProfessionalTeam updateScoutRelation(String scoutId, int newLevel) {
    final newRelations = Map<String, int>.from(scoutRelations);
    newRelations[scoutId] = newLevel.clamp(0, 100);
    return copyWith(scoutRelations: newRelations);
  }

  // 球団戦力を更新
  ProfessionalTeam updateTeamStrength(String position, int newStrength) {
    final newTeamStrength = Map<String, int>.from(teamStrength);
    newTeamStrength[position] = newStrength.clamp(1, 100);
    return copyWith(teamStrength: newTeamStrength);
  }

  // 球団予算を更新
  ProfessionalTeam updateBudget(int newBudget) {
    return copyWith(budget: newBudget.clamp(1000, 1000000));
  }

  // 球団の成功度を更新
  ProfessionalTeam updateSuccess(int newSuccess) {
    return copyWith(success: newSuccess.clamp(0, 100));
  }
}

// プロ野球団管理クラス
class ProfessionalTeamManager {
  final List<ProfessionalTeam> teams;
  
  ProfessionalTeamManager({List<ProfessionalTeam>? teams}) : teams = teams ?? [];

  // 全チームを取得
  List<ProfessionalTeam> getAllTeams() => teams;

  // リーグ別のチームを取得
  List<ProfessionalTeam> getTeamsByLeague(League league) {
    return teams.where((team) => team.league == league).toList();
  }

  // 地区別のチームを取得
  List<ProfessionalTeam> getTeamsByDivision(Division division) {
    return teams.where((team) => team.division == division).toList();
  }

  // 特定のチームを取得
  ProfessionalTeam? getTeam(String teamId) {
    try {
      return teams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }

  // チーム名で検索
  ProfessionalTeam? getTeamByName(String teamName) {
    try {
      return teams.firstWhere((team) => team.name == teamName || team.shortName == teamName);
    } catch (e) {
      return null;
    }
  }

  // ドラフト順位順にソート
  List<ProfessionalTeam> getTeamsByDraftOrder() {
    final sortedTeams = List<ProfessionalTeam>.from(teams);
    sortedTeams.sort((a, b) => a.draftOrder.compareTo(b.draftOrder));
    return sortedTeams;
  }

  // 戦力順にソート
  List<ProfessionalTeam> getTeamsByStrength() {
    final sortedTeams = List<ProfessionalTeam>.from(teams);
    sortedTeams.sort((a, b) => b.totalStrength.compareTo(a.totalStrength));
    return sortedTeams;
  }

  // 予算順にソート
  List<ProfessionalTeam> getTeamsByBudget() {
    final sortedTeams = List<ProfessionalTeam>.from(teams);
    sortedTeams.sort((a, b) => b.budget.compareTo(a.budget));
    return sortedTeams;
  }

  // チームを追加
  void addTeam(ProfessionalTeam team) {
    if (!teams.any((t) => t.id == team.id)) {
      teams.add(team);
    }
  }

  // チームを更新
  void updateTeam(ProfessionalTeam updatedTeam) {
    final index = teams.indexWhere((team) => team.id == updatedTeam.id);
    if (index != -1) {
      teams[index] = updatedTeam;
    }
  }
  
  // 全チームに選手を生成
  void generatePlayersForAllTeams() {
    for (int i = 0; i < teams.length; i++) {
      final team = teams[i];
      final players = PlayerGenerator.generateProfessionalPlayers(team);
      teams[i] = team.copyWith(players: players);
    }
  }
  
  // 特定のチームに選手を生成
  void generatePlayersForTeam(String teamId) {
    final index = teams.indexWhere((t) => t.id == teamId);
    if (index != -1) {
      final team = teams[index];
      final players = PlayerGenerator.generateProfessionalPlayers(team);
      teams[index] = team.copyWith(players: players);
    }
  }
  
  // チームの選手数を取得
  int getTeamPlayerCount(String teamId) {
    final team = getTeam(teamId);
    return team?.players.length ?? 0;
  }
  
  // チームの特定ポジションの選手数を取得
  int getTeamPositionPlayerCount(String teamId, String position) {
    final team = getTeam(teamId);
    if (team == null) return 0;
    return team.players.where((p) => p.position == position).length;
  }

  // チームを削除
  void removeTeam(String teamId) {
    teams.removeWhere((team) => team.id == teamId);
  }

  // デフォルトのプロ野球団リストを生成
  static List<ProfessionalTeam> generateDefaultTeams() {
    return [
      // セ・リーグ
      ProfessionalTeam(
        id: 'giants',
        name: '読売ジャイアンツ',
        shortName: '巨人',
        league: League.central,
        division: Division.east,
        homeStadium: '東京ドーム',
        city: '東京都',
        budget: 80000,
        needs: ['投手', '外野手'],
        scoutRelations: {},
        draftOrder: 1,
        teamStrength: {
          '投手': 75,
          '捕手': 80,
          '一塁手': 85,
          '二塁手': 70,
          '三塁手': 75,
          '遊撃手': 80,
          '外野手': 70,
        },
        strategy: '打撃重視',
        strengths: ['打撃力', '知名度', '資金力'],
        weaknesses: ['投手力', '若手育成'],
        popularity: 90,
        success: 85,
      ),
      ProfessionalTeam(
        id: 'tigers',
        name: '阪神タイガース',
        shortName: '阪神',
        league: League.central,
        division: Division.west,
        homeStadium: '阪神甲子園球場',
        city: '兵庫県',
        budget: 70000,
        needs: ['投手', '内野手'],
        scoutRelations: {},
        draftOrder: 2,
        teamStrength: {
          '投手': 70,
          '捕手': 75,
          '一塁手': 80,
          '二塁手': 75,
          '三塁手': 70,
          '遊撃手': 75,
          '外野手': 80,
        },
        strategy: 'バランス型',
        strengths: ['投手力', '守備力'],
        weaknesses: ['打撃力', '長打力'],
        popularity: 85,
        success: 80,
      ),
      ProfessionalTeam(
        id: 'carp',
        name: '広島東洋カープ',
        shortName: '広島',
        league: League.central,
        division: Division.central,
        homeStadium: 'MAZDA Zoom-Zoom スタジアム広島',
        city: '広島県',
        budget: 60000,
        needs: ['投手', '捕手'],
        scoutRelations: {},
        draftOrder: 3,
        teamStrength: {
          '投手': 65,
          '捕手': 60,
          '一塁手': 75,
          '二塁手': 80,
          '三塁手': 75,
          '遊撃手': 70,
          '外野手': 75,
        },
        strategy: '若手育成重視',
        strengths: ['若手育成', '打撃力'],
        weaknesses: ['投手力', '資金力'],
        popularity: 75,
        success: 70,
      ),
      // パ・リーグ
      ProfessionalTeam(
        id: 'hawks',
        name: '福岡ソフトバンクホークス',
        shortName: 'ソフトバンク',
        league: League.pacific,
        division: Division.west,
        homeStadium: '福岡PayPayドーム',
        city: '福岡県',
        budget: 90000,
        needs: ['投手', '内野手'],
        scoutRelations: {},
        draftOrder: 4,
        teamStrength: {
          '投手': 85,
          '捕手': 80,
          '一塁手': 90,
          '二塁手': 75,
          '三塁手': 80,
          '遊撃手': 75,
          '外野手': 85,
        },
        strategy: '投手重視',
        strengths: ['投手力', '資金力', '戦略性'],
        weaknesses: ['内野守備'],
        popularity: 80,
        success: 90,
      ),
      ProfessionalTeam(
        id: 'marines',
        name: '千葉ロッテマリーンズ',
        shortName: 'ロッテ',
        league: League.pacific,
        division: Division.east,
        homeStadium: 'ZOZOマリンスタジアム',
        city: '千葉県',
        budget: 50000,
        needs: ['投手', '外野手'],
        scoutRelations: {},
        draftOrder: 5,
        teamStrength: {
          '投手': 60,
          '捕手': 70,
          '一塁手': 70,
          '二塁手': 65,
          '三塁手': 70,
          '遊撃手': 65,
          '外野手': 60,
        },
        strategy: '若手育成重視',
        strengths: ['若手育成', '守備力'],
        weaknesses: ['投手力', '打撃力', '資金力'],
        popularity: 60,
        success: 55,
      ),
      ProfessionalTeam(
        id: 'eagles',
        name: '東北楽天ゴールデンイーグルス',
        shortName: '楽天',
        league: League.pacific,
        division: Division.east,
        homeStadium: '楽天生命パーク宮城',
        city: '宮城県',
        budget: 65000,
        needs: ['投手', '捕手'],
        scoutRelations: {},
        draftOrder: 6,
        teamStrength: {
          '投手': 70,
          '捕手': 65,
          '一塁手': 75,
          '二塁手': 70,
          '三塁手': 75,
          '遊撃手': 70,
          '外野手': 75,
        },
        strategy: 'バランス型',
        strengths: ['打撃力', '若手育成'],
        weaknesses: ['投手力', '守備力'],
        popularity: 70,
        success: 65,
      ),
    ];
  }
}
