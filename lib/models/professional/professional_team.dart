import '../player/player.dart';
import 'team_properties.dart';
import 'enums.dart';
import 'professional_player.dart';

/// プロ野球団クラス
class ProfessionalTeam {
  final TeamProperties properties;
  final List<Player> players; // 所属選手（高校選手）
  final List<ProfessionalPlayer>? professionalPlayers; // プロ野球選手

  ProfessionalTeam({
    required this.properties,
    List<Player>? players,
    this.professionalPlayers,
  }) : players = players ?? [];

  // プロパティへの委譲
  String get id => properties.id;
  String get name => properties.name;
  String get shortName => properties.shortName;
  League get league => properties.league;
  Division get division => properties.division;
  List<String> get needs => properties.needs;
  Map<String, int> get scoutRelations => properties.scoutRelations;
  int get draftOrder => properties.draftOrder;
  Map<String, int> get teamStrength => properties.teamStrength;
  String get strategy => properties.strategy;

  // 計算プロパティへの委譲
  int get totalStrength => properties.totalStrength;
  String get strengthLevel => properties.strengthLevel;
  String get strengthGrade => properties.strengthGrade;
  String get characteristics => properties.characteristics;
  Map<String, String> get detailedInfo => properties.detailedInfo;

  // メソッドへの委譲
  int getPositionStrength(String position) => properties.getPositionStrength(position);
  int getScoutRelationLevel(String scoutId) => properties.getScoutRelationLevel(scoutId);

  // JSON変換
  Map<String, dynamic> toJson() => {
    ...properties.toJson(),
    'players': players.map((p) => p.toJson()).toList(),
  };

  factory ProfessionalTeam.fromJson(Map<String, dynamic> json) {
    return ProfessionalTeam(
      properties: TeamProperties.fromJson(json),
      players: json['players'] != null
        ? (json['players'] as List).map((p) => Player.fromJson(p)).toList()
        : [],
    );
  }

  // コピーメソッド
  ProfessionalTeam copyWith({
    TeamProperties? properties,
    List<Player>? players,
    List<ProfessionalPlayer>? professionalPlayers,
  }) {
    return ProfessionalTeam(
      properties: properties ?? this.properties,
      players: players ?? this.players,
      professionalPlayers: professionalPlayers ?? this.professionalPlayers,
    );
  }

  // スカウトとの関係性を更新
  ProfessionalTeam updateScoutRelation(String scoutId, int newLevel) {
    final newProperties = properties.copyWith(
      scoutRelations: {
        ...properties.scoutRelations,
        scoutId: newLevel.clamp(0, 100),
      },
    );
    return copyWith(properties: newProperties);
  }

  // 球団戦力を更新
  ProfessionalTeam updateTeamStrength(String position, int newStrength) {
    final newTeamStrength = Map<String, int>.from(properties.teamStrength);
    newTeamStrength[position] = newStrength.clamp(1, 100);
    final newProperties = properties.copyWith(teamStrength: newTeamStrength);
    return copyWith(properties: newProperties);
  }


  // プロ選手のoverall平均値を設定
  ProfessionalTeam setProPlayerOverallAverage(int average) {
    final newProperties = properties.copyWith();
    newProperties.setProPlayerOverallAverage(average);
    return copyWith(properties: newProperties);
  }
}