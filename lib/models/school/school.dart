import '../player/player.dart';

// 学校ランクの定義
enum SchoolRank {
  weak,      // 弱小
  average,   // 中堅
  strong,    // 強豪
  elite;     // 名門
  
  String get name {
    switch (this) {
      case SchoolRank.weak:
        return '弱小';
      case SchoolRank.average:
        return '中堅';
      case SchoolRank.strong:
        return '強豪';
      case SchoolRank.elite:
        return '名門';
    }
  }

  int get value {
    switch (this) {
      case SchoolRank.weak:
        return 1;
      case SchoolRank.average:
        return 2;
      case SchoolRank.strong:
        return 3;
      case SchoolRank.elite:
        return 4;
    }
  }

  int compareTo(SchoolRank other) {
    return value.compareTo(other.value);
  }
}

// 高校クラス
class School {
  final String id; // データベースのID
  final String name;
  final String shortName; // 略称
  final String location;
  final String prefecture; // 都道府県
  final SchoolRank rank; // 学校ランク
  final List<Player> players;
  final int coachTrust; // 監督の信頼度 0-100
  final String coachName;
  
  School({
    required this.id,
    required this.name,
    required this.shortName,
    required this.location,
    required this.prefecture,
    required this.rank,
    required this.players,
    required this.coachTrust,
    required this.coachName,
  });
  
  School copyWith({
    String? id,
    String? name,
    String? shortName,
    String? location,
    String? prefecture,
    SchoolRank? rank,
    List<Player>? players,
    int? coachTrust,
    String? coachName,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      location: location ?? this.location,
      prefecture: prefecture ?? this.prefecture,
      rank: rank ?? this.rank,
      players: players ?? this.players,
      coachTrust: coachTrust ?? this.coachTrust,
      coachName: coachName ?? this.coachName,
    );
  }

  // 学校ランクに応じたデフォルト選手の能力値を取得
  int getDefaultAbilityValue() {
    switch (rank) {
      case SchoolRank.weak:
        return 45;
      case SchoolRank.average:
        return 50;
      case SchoolRank.strong:
        return 55;
      case SchoolRank.elite:
        return 60;
    }
  }

  // 学校ランクに応じた生成選手の最大所属数を取得
  int getMaxGeneratedPlayers() {
    switch (rank) {
      case SchoolRank.weak:
        return 3; // 弱小：最大3人
      case SchoolRank.average:
        return 8; // 中堅：最大8人
      case SchoolRank.strong:
        return 15; // 強豪：最大15人
      case SchoolRank.elite:
        return 25; // 名門：最大25人
    }
  }

  // 学校ランクに応じた生成選手の所属確率を取得
  double getGeneratedPlayerProbability() {
    switch (rank) {
      case SchoolRank.weak:
        return 0.3; // 弱小：30%の確率で生成選手が所属
      case SchoolRank.average:
        return 0.6; // 中堅：60%の確率で生成選手が所属
      case SchoolRank.strong:
        return 0.8; // 強豪：80%の確率で生成選手が所属
      case SchoolRank.elite:
        return 1.0; // 名門：100%の確率で生成選手が所属
    }
  }


  

    

  

  


  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'prefecture': prefecture,
    'rank': rank.name,
    'players': players.map((p) => p.toJson()).toList(),
    'coachTrust': coachTrust,
    'coachName': coachName,
  };

  factory School.fromJson(Map<String, dynamic> json) => School(
    id: json['id'] ?? '',
    name: json['name'],
    shortName: json['shortName'] ?? json['name'],
    location: json['location'],
    prefecture: json['prefecture'],
    rank: SchoolRank.values.firstWhere((r) => r.name == json['rank']),
    players: (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
    coachTrust: json['coachTrust'],
    coachName: json['coachName'],
  );
} 