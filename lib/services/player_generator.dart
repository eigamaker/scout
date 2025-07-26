import 'dart:math';
import '../models/player/player.dart';
import '../models/player/achievement.dart';

class PlayerGenerator {
  static final Random _random = Random();

  // テスト用の選手データを生成
  static List<Player> generateTestPlayers() {
    return [
      // 超有名選手（U-15日本代表 + 全国大会優勝）
      Player(
        name: '田中 翔太',
        school: '甲子園高校',
        grade: 1,
        position: '投手',
        personality: '真面目',
        trustLevel: 80,
        fame: 100,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: true,
        fastballVelo: 155,
        control: 85,
        stamina: 90,
        breakAvg: 80,
        mentalGrit: 0.1,
        growthRate: 1.1,
        peakAbility: 140,
        positionFit: {'投手': 95, '野手': 30},
        talent: 5,
        growthType: '早期型',
        achievements: [
          Achievement.create(
            type: AchievementType.u15NationalTeam,
            year: 2024,
            month: 8,
            team: 'U-15日本代表',
          ),
          Achievement.create(
            type: AchievementType.nationalChampionship,
            year: 2024,
            month: 7,
            team: '甲子園高校',
          ),
          Achievement.create(
            type: AchievementType.perfectGame,
            year: 2024,
            month: 6,
            team: '甲子園高校',
          ),
        ],
      ),

      // 有名選手（U-18日本代表）
      Player(
        name: '佐藤 健一',
        school: '野球名門高校',
        grade: 2,
        position: '外野手',
        personality: '積極的',
        trustLevel: 60,
        fame: 85,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: true,
        batPower: 90,
        batControl: 85,
        run: 95,
        field: 80,
        arm: 85,
        mentalGrit: 0.05,
        growthRate: 1.05,
        peakAbility: 130,
        positionFit: {'外野手': 90, '内野手': 70, '投手': 20},
        talent: 4,
        growthType: '標準型',
        achievements: [
          Achievement.create(
            type: AchievementType.u18NationalTeam,
            year: 2024,
            month: 9,
            team: 'U-18日本代表',
          ),
          Achievement.create(
            type: AchievementType.homeRunKing,
            year: 2024,
            month: 7,
            team: '野球名門高校',
          ),
        ],
      ),

      // 知られている選手（地方大会優勝）
      Player(
        name: '鈴木 大輔',
        school: '地方強豪高校',
        grade: 3,
        position: '投手',
        personality: '冷静',
        trustLevel: 40,
        fame: 55,
        isWatched: false,
        isDiscovered: true,
        isPubliclyKnown: false,
        fastballVelo: 145,
        control: 75,
        stamina: 80,
        breakAvg: 70,
        mentalGrit: 0.0,
        growthRate: 1.0,
        peakAbility: 120,
        positionFit: {'投手': 85, '野手': 25},
        talent: 3,
        growthType: '晩成型',
        achievements: [
          Achievement.create(
            type: AchievementType.regionalChampionship,
            year: 2024,
            month: 6,
            team: '地方強豪高校',
          ),
          Achievement.create(
            type: AchievementType.bestPitcher,
            year: 2024,
            month: 7,
            team: '地方強豪高校',
          ),
        ],
      ),

      // 少し知られている選手（リーグ優勝）
      Player(
        name: '高橋 優',
        school: '普通の高校',
        grade: 2,
        position: '内野手',
        personality: '明るい',
        trustLevel: 20,
        fame: 25,
        isWatched: false,
        isDiscovered: false,
        isPubliclyKnown: false,
        batPower: 70,
        batControl: 75,
        run: 80,
        field: 85,
        arm: 70,
        mentalGrit: -0.05,
        growthRate: 0.95,
        peakAbility: 110,
        positionFit: {'内野手': 80, '外野手': 60, '投手': 15},
        talent: 2,
        growthType: '標準型',
        achievements: [
          Achievement.create(
            type: AchievementType.leagueChampionship,
            year: 2024,
            month: 5,
            team: '普通の高校',
          ),
        ],
      ),

      // 無名選手（実績なし）
      Player(
        name: '伊藤 誠',
        school: '小さな高校',
        grade: 1,
        position: '投手',
        personality: '控えめ',
        trustLevel: 0,
        fame: 0,
        isWatched: false,
        isDiscovered: false,
        isPubliclyKnown: false,
        fastballVelo: 135,
        control: 60,
        stamina: 65,
        breakAvg: 55,
        mentalGrit: -0.1,
        growthRate: 0.9,
        peakAbility: 100,
        positionFit: {'投手': 70, '野手': 20},
        talent: 1,
        growthType: '晩成型',
        achievements: [],
      ),

      // 隠れた才能選手（実績なしだが高ポテンシャル）
      Player(
        name: '渡辺 隼人',
        school: '田舎の高校',
        grade: 1,
        position: '外野手',
        personality: '負けん気',
        trustLevel: 0,
        fame: 0,
        isWatched: false,
        isDiscovered: false,
        isPubliclyKnown: false,
        batPower: 60,
        batControl: 65,
        run: 95,
        field: 70,
        arm: 75,
        mentalGrit: 0.15,
        growthRate: 1.15,
        peakAbility: 145,
        positionFit: {'外野手': 90, '内野手': 60, '投手': 30},
        talent: 4,
        growthType: '晩成型',
        achievements: [],
      ),

      // 発掘済みの無名選手（視察で発見）
      Player(
        name: '山田 太郎',
        school: '小さな高校',
        grade: 2,
        position: '投手',
        personality: '真面目',
        trustLevel: 30,
        fame: 0,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: false,
        fastballVelo: 140,
        control: 70,
        stamina: 75,
        breakAvg: 65,
        mentalGrit: 0.05,
        growthRate: 1.0,
        peakAbility: 115,
        positionFit: {'投手': 80, '野手': 25},
        talent: 2,
        growthType: '標準型',
        achievements: [],
      ),

      // 発掘済みの隠れた才能選手
      Player(
        name: '中村 花子',
        school: '普通の高校',
        grade: 1,
        position: '内野手',
        personality: '積極的',
        trustLevel: 50,
        fame: 0,
        isWatched: true,
        isDiscovered: true,
        isPubliclyKnown: false,
        batPower: 75,
        batControl: 80,
        run: 85,
        field: 90,
        arm: 70,
        mentalGrit: 0.1,
        growthRate: 1.1,
        peakAbility: 135,
        positionFit: {'内野手': 85, '外野手': 65, '投手': 20},
        talent: 3,
        growthType: '早期型',
        achievements: [],
      ),
    ];
  }

  // ランダムな実績を生成
  static List<Achievement> generateRandomAchievements(int count) {
    final achievementTypes = AchievementType.values;
    final achievements = <Achievement>[];
    
    for (int i = 0; i < count; i++) {
      final type = achievementTypes[_random.nextInt(achievementTypes.length)];
      final year = 2024 - _random.nextInt(3); // 2022-2024年
      final month = _random.nextInt(12) + 1; // 1-12月
      
      achievements.add(Achievement.create(
        type: type,
        year: year,
        month: month,
      ));
    }
    
    return achievements;
  }

  // 知名度に応じた実績数を決定
  static int getAchievementCountByFame(int fameLevel) {
    switch (fameLevel) {
      case 5: return _random.nextInt(3) + 3; // 3-5個
      case 4: return _random.nextInt(2) + 2; // 2-3個
      case 3: return _random.nextInt(2) + 1; // 1-2個
      case 2: return _random.nextInt(1) + 1; // 1個
      case 1: return 0; // 実績なし
      default: return 0;
    }
  }
} 