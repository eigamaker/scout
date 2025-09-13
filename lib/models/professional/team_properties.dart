import 'enums.dart';

/// プロ野球団の基本プロパティ
class TeamProperties {
  final String id;
  final String name;
  final String shortName; // 略称（例：巨人、阪神）
  final League league;
  final Division division;
  final List<String> needs; // 球団ニーズ
  final Map<String, int> scoutRelations; // スカウトとの関係性（0-100）
  
  // ドラフト指名順位（1位が最優先）
  final int draftOrder;
  
  // 球団の戦力状況（各ポジションの戦力レベル：1-100）
  final Map<String, int> teamStrength;
  
  // 球団の特徴・戦略
  final String strategy; // 戦略（例：投手重視、打撃重視）

  TeamProperties({
    required this.id,
    required this.name,
    required this.shortName,
    required this.league,
    required this.division,
    required this.needs,
    required this.scoutRelations,
    required this.draftOrder,
    required this.teamStrength,
    required this.strategy,
  });

  // 球団の総合戦力を計算（従来のポジション別戦力の平均）
  int get totalStrength {
    if (teamStrength.isEmpty) return 0;
    return teamStrength.values.reduce((a, b) => a + b) ~/ teamStrength.length;
  }

  // プロ選手のoverall数値の平均を基にした戦力計算
  // このメソッドは外部から呼び出されて、プロ選手のoverall平均値を設定する
  int _proPlayerOverallAverage = 0;
  
  int get proPlayerOverallAverage => _proPlayerOverallAverage;
  
  void setProPlayerOverallAverage(int average) {
    _proPlayerOverallAverage = average;
  }

  // 特定ポジションの戦力レベルを取得
  int getPositionStrength(String position) {
    return teamStrength[position] ?? 50; // デフォルトは50
  }

  // スカウトとの関係性レベルを取得
  int getScoutRelationLevel(String scoutId) {
    return scoutRelations[scoutId] ?? 30; // デフォルトは30
  }


  // 球団の戦力レベルを取得（従来の数値ベース）
  String get strengthLevel {
    final strength = totalStrength;
    if (strength >= 80) return '強豪';
    if (strength >= 60) return '中堅';
    if (strength >= 40) return '弱小';
    return '最下位';
  }

  // 球団の戦力グレードを取得（overall数値ベース）
  String get strengthGrade {
    // プロ選手のoverall平均値が設定されている場合はそれを使用、そうでなければ従来の計算
    final strength = _proPlayerOverallAverage > 0 ? _proPlayerOverallAverage : totalStrength;
    if (strength >= 120) return 'S';
    if (strength >= 115) return 'A';
    if (strength >= 110) return 'B';
    if (strength >= 105) return 'C';
    return 'D';
  }

  // 球団の特徴を文字列で取得
  String get characteristics {
    final chars = <String>[];
    chars.add('${league.name == 'central' ? 'セ・リーグ' : 'パ・リーグ'}');
    chars.add('${division.name == 'east' ? '東地区' : division.name == 'west' ? '西地区' : '中地区'}');
    chars.add(strategy);
    chars.add(strengthLevel);
    return chars.join(' / ');
  }

  // 球団の詳細情報を取得
  Map<String, String> get detailedInfo {
    return {
      '戦略': strategy,
      '戦力レベル': strengthLevel,
      '戦力グレード': strengthGrade,
    };
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'league': league.index,
    'division': division.index,
    'needs': needs,
    'scoutRelations': scoutRelations,
    'draftOrder': draftOrder,
    'teamStrength': teamStrength,
    'strategy': strategy,
  };

  factory TeamProperties.fromJson(Map<String, dynamic> json) {
    return TeamProperties(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      league: League.values[json['league'] as int],
      division: Division.values[json['division'] as int],
      needs: List<String>.from(json['needs']),
      scoutRelations: Map<String, int>.from(json['scoutRelations']),
      draftOrder: json['draftOrder'] as int,
      teamStrength: Map<String, int>.from(json['teamStrength']),
      strategy: json['strategy'] as String,
    );
  }

  // コピーメソッド
  TeamProperties copyWith({
    String? id,
    String? name,
    String? shortName,
    League? league,
    Division? division,
    List<String>? needs,
    Map<String, int>? scoutRelations,
    int? draftOrder,
    Map<String, int>? teamStrength,
    String? strategy,
  }) {
    return TeamProperties(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      league: league ?? this.league,
      division: division ?? this.division,
      needs: needs ?? this.needs,
      scoutRelations: scoutRelations ?? this.scoutRelations,
      draftOrder: draftOrder ?? this.draftOrder,
      teamStrength: teamStrength ?? this.teamStrength,
      strategy: strategy ?? this.strategy,
    );
  }
}
