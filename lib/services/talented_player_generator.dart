import 'dart:math';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../models/player/pitch.dart';
import '../models/school/school.dart';
import 'data_service.dart';

/// 才能のある選手（ランク3以上）を生成するクラス
class TalentedPlayerGenerator {
  final DataService _dataService;
  final Random _random = Random();

  TalentedPlayerGenerator(this._dataService);

  /// 才能のある選手を1000人生成
  Future<List<Player>> generateTalentedPlayers() async {
    final players = <Player>[];
    
    // 都道府県別の選手数を決定（1都道府県あたり最大25人）
    final prefecturePlayerCounts = _determinePrefecturePlayerCounts();
    
    // 各都道府県で選手を生成
    for (final entry in prefecturePlayerCounts.entries) {
      final prefecture = entry.key;
      final count = entry.value;
      
      for (int i = 0; i < count; i++) {
        final player = await _generateTalentedPlayer(prefecture);
        players.add(player);
      }
    }
    
    print('才能のある選手を${players.length}人生成しました');
    return players;
  }

  /// 都道府県別の選手数を決定
  Map<String, int> _determinePrefecturePlayerCounts() {
    final prefectures = [
      '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
      '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
      '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
      '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
      '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
      '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
      '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
    ];
    
    final prefecturePlayerCounts = <String, int>{};
    
    for (final prefecture in prefectures) {
      // 1都道府県あたり最大25人
      final count = _random.nextInt(21) + 5; // 5-25人
      prefecturePlayerCounts[prefecture] = count;
    }
    
    return prefecturePlayerCounts;
  }

  /// 個別の才能のある選手を生成
  Future<Player> _generateTalentedPlayer(String prefecture) async {
    // 才能ランクを決定（指定された割合）
    final talentRank = _determineTalentRank();
    
    // ポジションを決定
    final position = _determinePositionByTalent(talentRank);
    
    // 学年を決定（1-3年生）
    final grade = _random.nextInt(3) + 1;
    final age = 13 + grade; // 1年生15歳、2年生16歳、3年生17歳
    
    // 個別ポテンシャルを生成
    final individualPotentials = _generateIndividualPotentials();
    
    // 能力値を生成
    final technicalAbilities = _generateTechnicalAbilities(talentRank, grade);
    final mentalAbilities = _generateMentalAbilities(talentRank, grade);
    final physicalAbilities = _generatePhysicalAbilities(talentRank, grade);
    
    // その他の属性を生成
    final pitches = _generatePitches(position);
    final growthType = _generateGrowthType();
    final mentalGrit = _generateMentalGrit();
    final growthRate = _generateGrowthRate();
    final positionFit = _generatePositionFit(position);
    
    // 選手名と基本情報を生成
    final name = _generatePlayerName();
    final birthDate = _generateBirthDate(age);
    final hometown = prefecture;
    final personality = _generatePersonality();
    final fame = _generateFame(talentRank);
    final isPubliclyKnown = _shouldBePubliclyKnown(talentRank);
    
    // 選手を作成
    final player = Player(
      name: name,
      school: '', // 学校は後で配属
      grade: grade,
      position: position,
      personality: personality,
      fame: fame,
      isPubliclyKnown: isPubliclyKnown,
      isScoutFavorite: false,
      isDiscovered: isPubliclyKnown, // 注目選手は自動的に発掘済み
      isGraduated: false,
      discoveredAt: isPubliclyKnown ? DateTime.now() : null, // 注目選手は自動的に発掘済み
      discoveredBy: isPubliclyKnown ? '自動生成' : null,
      discoveredCount: isPubliclyKnown ? 1 : 0, // 注目選手は発掘回数1
      scoutedDates: isPubliclyKnown ? [DateTime.now()] : [], // 注目選手は視察済み
      abilityKnowledge: <String, int>{},
      type: PlayerType.highSchool,
      yearsAfterGraduation: 0,
      pitches: pitches.map((p) => Pitch(type: p, breakAmount: 0, breakPot: 50, unlocked: true)).toList(),
      technicalAbilities: technicalAbilities,
      mentalAbilities: mentalAbilities,
      physicalAbilities: physicalAbilities,
      mentalGrit: mentalGrit,
      growthRate: growthRate,
      peakAbility: _getMaxPotentialByTalent(talentRank),
      positionFit: positionFit,
      talent: talentRank,
      growthType: growthType,
      individualPotentials: individualPotentials,
      scoutAnalysisData: null,
    );
    
    // 総合能力値を更新
    _updatePlayerOverallAbilities(player);
    
    return player;
  }

  /// 才能ランクを決定（指定された割合）
  int _determineTalentRank() {
    final rand = _random.nextDouble();
    
    if (rand < 0.80) return 3;      // 80% - ランク3
    if (rand < 0.99) return 4;      // 19% - ランク4
    if (rand < 0.9999) return 5;   // 1% - ランク5
    return 6;                       // 0.01% - ランク6
  }

  /// ポジションを才能ランクに基づいて決定
  String _determinePositionByTalent(int talentRank) {
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    
    // 才能ランクが高いほど投手や遊撃手などの重要ポジションの確率が上がる
    if (talentRank >= 5) {
      final importantPositions = ['投手', '遊撃手', '中堅手', '捕手'];
      return importantPositions[_random.nextInt(importantPositions.length)];
    } else if (talentRank >= 4) {
      final mediumPositions = ['投手', '遊撃手', '中堅手', '捕手', '二塁手', '三塁手'];
      return mediumPositions[_random.nextInt(mediumPositions.length)];
    } else {
      return positions[_random.nextInt(positions.length)];
    }
  }

  /// 個別ポテンシャルを生成
  Map<String, int> _generateIndividualPotentials() {
    final potentials = <String, int>{};
    
    // 技術面ポテンシャル
    for (final ability in TechnicalAbility.values) {
      final basePotential = 50 + _random.nextInt(31); // 50-80
      potentials[ability.name] = basePotential;
    }
    
    // メンタル面ポテンシャル
    for (final ability in MentalAbility.values) {
      final basePotential = 50 + _random.nextInt(31); // 50-80
      potentials[ability.name] = basePotential;
    }
    
    // フィジカル面ポテンシャル
    for (final ability in PhysicalAbility.values) {
      final basePotential = 50 + _random.nextInt(31); // 50-80
      potentials[ability.name] = basePotential;
    }
    
    return potentials;
  }

  /// 平均ポテンシャルを才能ランクに基づいて取得
  int _getAveragePotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 3: return 55;
      case 4: return 65;
      case 5: return 75;
      case 6: return 85;
      default: return 50;
    }
  }

  /// 能力値ポテンシャルを生成
  int _generateAbilityPotential(int talentRank) {
    final averagePotential = _getAveragePotentialByTalent(talentRank);
    final variationRange = _getVariationRangeByTalent(talentRank);
    final minPotential = _getMinPotentialByTalent(talentRank);
    final maxPotential = _getMaxPotentialByTalent(talentRank);
    
    final variation = _random.nextInt(variationRange * 2 + 1) - variationRange;
    final potential = averagePotential + variation;
    
    return potential.clamp(minPotential, maxPotential);
  }

  /// 才能ランクに応じた変動幅を取得
  int _getVariationRangeByTalent(int talentRank) {
    switch (talentRank) {
      case 3: return 10;
      case 4: return 8;
      case 5: return 6;
      case 6: return 4;
      default: return 15;
    }
  }

  /// 才能ランクに応じた最小ポテンシャルを取得
  int _getMinPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 3: return 45;
      case 4: return 55;
      case 5: return 65;
      case 6: return 75;
      default: return 40;
    }
  }

  /// 才能ランクに応じた最大ポテンシャルを取得
  int _getMaxPotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 3: return 70;
      case 4: return 80;
      case 5: return 90;
      case 6: return 95;
      default: return 65;
    }
  }

  /// 技術面能力値を生成
  Map<TechnicalAbility, int> _generateTechnicalAbilities(int talentRank, int grade) {
    final abilities = <TechnicalAbility, int>{};
    final baseAbility = _getBaseAbilityByTalent(talentRank);
    final gradeMultiplier = _getGradeMultiplier(grade);
    
    for (final ability in TechnicalAbility.values) {
      final base = baseAbility + _random.nextInt(21) - 10; // ±10の変動
      final gradeBonus = (base * gradeMultiplier).round();
      abilities[ability] = gradeBonus.clamp(25, 85);
    }
    
    return abilities;
  }

  /// メンタル面能力値を生成
  Map<MentalAbility, int> _generateMentalAbilities(int talentRank, int grade) {
    final abilities = <MentalAbility, int>{};
    final baseAbility = _getBaseAbilityByTalent(talentRank);
    final gradeMultiplier = _getGradeMultiplier(grade);
    
    for (final ability in MentalAbility.values) {
      final base = baseAbility + _random.nextInt(21) - 10; // ±10の変動
      final gradeBonus = (base * gradeMultiplier).round();
      abilities[ability] = gradeBonus.clamp(25, 85);
    }
    
    return abilities;
  }

  /// フィジカル面能力値を生成
  Map<PhysicalAbility, int> _generatePhysicalAbilities(int talentRank, int grade) {
    final abilities = <PhysicalAbility, int>{};
    final baseAbility = _getBaseAbilityByTalent(talentRank);
    final gradeMultiplier = _getGradeMultiplier(grade);
    
    for (final ability in PhysicalAbility.values) {
      final base = baseAbility + _random.nextInt(21) - 10; // ±10の変動
      final gradeBonus = (base * gradeMultiplier).round();
      abilities[ability] = gradeBonus.clamp(25, 85);
    }
    
    return abilities;
  }

  /// 才能ランクに応じた基本能力値を取得
  int _getBaseAbilityByTalent(int talentRank) {
    switch (talentRank) {
      case 3: return 45;
      case 4: return 55;
      case 5: return 65;
      case 6: return 75;
      default: return 40;
    }
  }

  /// 学年に応じた能力値倍率を取得
  double _getGradeMultiplier(int grade) {
    switch (grade) {
      case 1: return 0.9;  // 1年生は90%
      case 2: return 1.0;  // 2年生は100%
      case 3: return 1.1;  // 3年生は110%
      default: return 1.0;
    }
  }

  /// 投球種を生成
  List<String> _generatePitches(String position) {
    if (position != '投手') return [];
    
    final allPitches = ['ストレート', 'カーブ', 'スライダー', 'フォーク', 'チェンジアップ', 'シュート'];
    final pitchCount = 2 + _random.nextInt(3); // 2-4種類
    
    final pitches = <String>[];
    final shuffledPitches = List<String>.from(allPitches)..shuffle(_random);
    
    for (int i = 0; i < pitchCount && i < shuffledPitches.length; i++) {
      pitches.add(shuffledPitches[i]);
    }
    
    return pitches;
  }

  /// 成長型を生成
  String _generateGrowthType() {
    final types = ['early', 'normal', 'late'];
    final weights = [20, 60, 20]; // early: 20%, normal: 60%, late: 20%
    
    final rand = _random.nextInt(100);
    int cumulativeWeight = 0;
    
    for (int i = 0; i < types.length; i++) {
      cumulativeWeight += weights[i];
      if (rand < cumulativeWeight) {
        return types[i];
      }
    }
    
    return 'normal';
  }

  /// メンタルグリットを生成
  double _generateMentalGrit() {
    return _random.nextDouble() * 2.0 - 1.0; // -1.0 から 1.0
  }

  /// 成長率を生成
  double _generateGrowthRate() {
    return 0.8 + _random.nextDouble() * 0.4; // 0.8 から 1.2
  }

  /// ポジション適性を生成
  Map<String, int> _generatePositionFit(String mainPosition) {
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final fit = <String, int>{};
    
    for (final pos in positions) {
      if (pos == mainPosition) {
        fit[pos] = 70 + _random.nextInt(21); // 70-90
      } else {
        fit[pos] = 40 + _random.nextInt(31); // 40-70
      }
    }
    
    return fit;
  }

  /// 選手名を生成
  String _generatePlayerName() {
    final surnames = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final givenNames = ['翔太', '健太', '大輔', '直樹', '裕太', '智也', '和也', '達也', '誠', '勇気'];
    
    final surname = surnames[_random.nextInt(surnames.length)];
    final givenName = givenNames[_random.nextInt(givenNames.length)];
    
    return '$surname$givenName';
  }

  /// 誕生日を生成
  DateTime _generateBirthDate(int age) {
    final currentYear = DateTime.now().year;
    final birthYear = currentYear - age;
    final month = _random.nextInt(12) + 1;
    final day = _random.nextInt(28) + 1; // 簡易的な日付生成
    
    return DateTime(birthYear, month, day);
  }

  /// 性格を生成
  String _generatePersonality() {
    final personalities = ['真面目', '明るい', '冷静', '情熱的', '慎重', '積極的', '協調的', '独立心旺盛'];
    return personalities[_random.nextInt(personalities.length)];
  }

  /// 知名度を生成
  int _generateFame(int talentRank) {
    final baseFame = talentRank * 10; // 才能ランクに応じた基本知名度
    final variation = _random.nextInt(21) - 10; // ±10の変動
    return (baseFame + variation).clamp(0, 100);
  }

  /// 注目選手になるかどうかを判定
  bool _shouldBePubliclyKnown(int talentRank) {
    // 才能ランクが高いほど注目選手になりやすい
    if (talentRank >= 5) return true;
    if (talentRank >= 4) return _random.nextDouble() < 0.7; // 70%
    if (talentRank >= 3) return _random.nextDouble() < 0.3; // 30%
    return false;
  }

  /// 選手の総合能力値を更新
  void _updatePlayerOverallAbilities(Player player) {
    // 技術面、メンタル面、フィジカル面の平均を計算
    final technicalAvg = player.technicalAbilities.values.reduce((a, b) => a + b) / player.technicalAbilities.length;
    final mentalAvg = player.mentalAbilities.values.reduce((a, b) => a + b) / player.mentalAbilities.length;
    final physicalAvg = player.physicalAbilities.values.reduce((a, b) => a + b) / player.physicalAbilities.length;
    
    // 総合能力値は3つの平均の平均
    final overallAvg = (technicalAvg + mentalAvg + physicalAvg) / 3;
    
    // 選手の総合能力値を更新（実際の実装ではPlayerクラスにsetterが必要）
    // print('選手 ${player.name} の総合能力値: ${overallAvg.toStringAsFixed(1)}');
  }
}
