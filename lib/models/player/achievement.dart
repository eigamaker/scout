enum AchievementType {
  // 代表選出
  u15NationalTeam,      // U-15日本代表
  u18NationalTeam,      // U-18日本代表
  highSchoolNational,   // 高校日本代表
  
  // 全国大会
  nationalChampionship, // 全国大会優勝
  nationalRunnerUp,     // 全国大会準優勝
  nationalSemifinal,    // 全国大会ベスト4
  
  // 地方大会
  regionalChampionship, // 地方大会優勝
  regionalRunnerUp,     // 地方大会準優勝
  
  // リーグ戦
  leagueChampionship,   // リーグ優勝
  leagueRunnerUp,       // リーグ準優勝
  
  // 個人賞
  mvp,                  // MVP
  bestPitcher,          // 最優秀投手
  bestBatter,           // 最優秀打者
  goldenGlove,          // ゴールデングラブ
  homeRunKing,          // ホームラン王
  strikeoutKing,        // 奪三振王
  
  // 記録
  noHitter,             // ノーヒットノーラン
  perfectGame,          // 完全試合
  cycleHit,             // サイクルヒット
  grandSlam,            // 満塁ホームラン
  
  // その他
  allStar,              // オールスター選出
  rookieOfTheYear,      // 新人王
  comebackPlayer,       // カムバック賞
}

class Achievement {
  final AchievementType type;
  final String name;
  final String description;
  final int year;
  final int month;
  final int famePoints;  // 知名度ポイント
  final String? team;    // 所属チーム
  final String? category; // カテゴリ（投手/野手/全体）

  const Achievement({
    required this.type,
    required this.name,
    required this.description,
    required this.year,
    required this.month,
    required this.famePoints,
    this.team,
    this.category,
  });

  // 実績定義
  static const Map<AchievementType, Map<String, dynamic>> _achievementData = {
    AchievementType.u15NationalTeam: {
      'name': 'U-15日本代表',
      'description': 'U-15日本代表に選出',
      'famePoints': 50,
      'category': '全体',
    },
    AchievementType.u18NationalTeam: {
      'name': 'U-18日本代表',
      'description': 'U-18日本代表に選出',
      'famePoints': 80,
      'category': '全体',
    },
    AchievementType.highSchoolNational: {
      'name': '高校日本代表',
      'description': '高校日本代表に選出',
      'famePoints': 100,
      'category': '全体',
    },
    AchievementType.nationalChampionship: {
      'name': '全国大会優勝',
      'description': '全国大会で優勝',
      'famePoints': 60,
      'category': '全体',
    },
    AchievementType.nationalRunnerUp: {
      'name': '全国大会準優勝',
      'description': '全国大会で準優勝',
      'famePoints': 40,
      'category': '全体',
    },
    AchievementType.nationalSemifinal: {
      'name': '全国大会ベスト4',
      'description': '全国大会でベスト4',
      'famePoints': 30,
      'category': '全体',
    },
    AchievementType.regionalChampionship: {
      'name': '地方大会優勝',
      'description': '地方大会で優勝',
      'famePoints': 25,
      'category': '全体',
    },
    AchievementType.regionalRunnerUp: {
      'name': '地方大会準優勝',
      'description': '地方大会で準優勝',
      'famePoints': 15,
      'category': '全体',
    },
    AchievementType.leagueChampionship: {
      'name': 'リーグ優勝',
      'description': 'リーグ戦で優勝',
      'famePoints': 20,
      'category': '全体',
    },
    AchievementType.leagueRunnerUp: {
      'name': 'リーグ準優勝',
      'description': 'リーグ戦で準優勝',
      'famePoints': 10,
      'category': '全体',
    },
    AchievementType.mvp: {
      'name': 'MVP',
      'description': '最優秀選手賞',
      'famePoints': 40,
      'category': '全体',
    },
    AchievementType.bestPitcher: {
      'name': '最優秀投手',
      'description': '最優秀投手賞',
      'famePoints': 30,
      'category': '投手',
    },
    AchievementType.bestBatter: {
      'name': '最優秀打者',
      'description': '最優秀打者賞',
      'famePoints': 30,
      'category': '野手',
    },
    AchievementType.goldenGlove: {
      'name': 'ゴールデングラブ',
      'description': '守備部門で優秀な成績',
      'famePoints': 20,
      'category': '野手',
    },
    AchievementType.homeRunKing: {
      'name': 'ホームラン王',
      'description': 'ホームラン数でリーグ1位',
      'famePoints': 25,
      'category': '野手',
    },
    AchievementType.strikeoutKing: {
      'name': '奪三振王',
      'description': '奪三振数でリーグ1位',
      'famePoints': 25,
      'category': '投手',
    },
    AchievementType.noHitter: {
      'name': 'ノーヒットノーラン',
      'description': 'ノーヒットノーランを達成',
      'famePoints': 35,
      'category': '投手',
    },
    AchievementType.perfectGame: {
      'name': '完全試合',
      'description': '完全試合を達成',
      'famePoints': 50,
      'category': '投手',
    },
    AchievementType.cycleHit: {
      'name': 'サイクルヒット',
      'description': 'サイクルヒットを達成',
      'famePoints': 30,
      'category': '野手',
    },
    AchievementType.grandSlam: {
      'name': '満塁ホームラン',
      'description': '満塁ホームランを記録',
      'famePoints': 15,
      'category': '野手',
    },
    AchievementType.allStar: {
      'name': 'オールスター選出',
      'description': 'オールスターゲームに選出',
      'famePoints': 20,
      'category': '全体',
    },
    AchievementType.rookieOfTheYear: {
      'name': '新人王',
      'description': '新人王に選出',
      'famePoints': 35,
      'category': '全体',
    },
    AchievementType.comebackPlayer: {
      'name': 'カムバック賞',
      'description': 'カムバック賞を受賞',
      'famePoints': 25,
      'category': '全体',
    },
  };

  // 実績を作成
  factory Achievement.create({
    required AchievementType type,
    required int year,
    required int month,
    String? team,
  }) {
    final data = _achievementData[type]!;
    return Achievement(
      type: type,
      name: data['name'],
      description: data['description'],
      year: year,
      month: month,
      famePoints: data['famePoints'],
      team: team,
      category: data['category'],
    );
  }

  // 知名度レベルを取得
  int get fameLevel {
    if (famePoints >= 100) return 5; // 超有名
    if (famePoints >= 80) return 4;  // 有名
    if (famePoints >= 50) return 3;  // 知られている
    if (famePoints >= 20) return 2;  // 少し知られている
    return 1; // 無名
  }

  // 知名度レベルの表示名
  String get fameLevelName {
    switch (fameLevel) {
      case 5: return '超有名';
      case 4: return '有名';
      case 3: return '知られている';
      case 2: return '少し知られている';
      case 1: return '無名';
      default: return '無名';
    }
  }

  @override
  String toString() {
    return '$name ($year年$month月)';
  }
} 