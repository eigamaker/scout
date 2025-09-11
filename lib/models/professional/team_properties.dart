import 'enums.dart';

/// プロ野球団の基本プロパティ
class TeamProperties {
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

  const TeamProperties({
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
  });

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
  };

  factory TeamProperties.fromJson(Map<String, dynamic> json) {
    return TeamProperties(
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
    );
  }

  // コピーメソッド
  TeamProperties copyWith({
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
  }) {
    return TeamProperties(
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
    );
  }
}
