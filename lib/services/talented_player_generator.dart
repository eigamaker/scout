import 'dart:math';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../models/player/pitch.dart';
import '../models/school/school.dart';
import 'data_service.dart';
import '../utils/name_generator.dart';

/// 才能のある選手（ランク3以上）を生成するクラス
class TalentedPlayerGenerator {
  final DataService _dataService;
  final Random _random = Random();
  
  // 高校生の能力値生成設定（調整可能）
  static const double _minAbilityPercentage = 0.60; // ポテンシャルの60%
  static const double _maxAbilityPercentage = 0.70; // ポテンシャルの70%

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
    
    // 個別ポテンシャルを生成（プロ野球選手のロジックを参考）
    final individualPotentials = _generateIndividualPotentials(talentRank, position);
    
    // 能力値を生成（ポテンシャルの60-70%で生成）
    final technicalAbilities = _generateTechnicalAbilities(talentRank, position, grade);
    final mentalAbilities = _generateMentalAbilities(talentRank, grade);
    final physicalAbilities = _generatePhysicalAbilities(talentRank, position, grade);
    
    // 追加された能力値を生成
    final additionalAbilities = _generateAdditionalAbilities(talentRank, grade);
    
    // その他の属性を生成
    final pitches = _generatePitches(position);
    final growthType = _generateGrowthType();
    final mentalGrit = _generateMentalGrit();
    final growthRate = _generateGrowthRate();
    final positionFit = _generatePositionFit(position);
    
    // 選手名と基本情報を生成
    final name = NameGenerator.generatePlayerName();
    final birthDate = _generateBirthDate(age);
    final hometown = prefecture;
    final personality = _generatePersonality();
    final fame = _generateFame(talentRank);
    final isPubliclyKnown = _shouldBePubliclyKnown(talentRank);
    
    // ピーク能力をタレントランクに基づいて生成
    final peakAbility = _calculatePeakAbilityByTalent(talentRank);
    
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
      isDiscovered: false, // 注目選手でも初期状態では未発掘
      isGraduated: false,
      discoveredBy: null,
      scoutedDates: [], // 初期状態では視察履歴なし
      abilityKnowledge: <String, int>{},
      type: PlayerType.highSchool,
      yearsAfterGraduation: 0,
      pitches: pitches.map((p) => Pitch(type: p, breakAmount: 0, breakPot: 50, unlocked: true)).toList(),
      technicalAbilities: technicalAbilities,
      mentalAbilities: mentalAbilities,
      physicalAbilities: physicalAbilities,
      mentalGrit: mentalGrit,
      growthRate: growthRate,
      peakAbility: peakAbility,
      positionFit: positionFit,
      talent: talentRank,
      growthType: growthType,
      individualPotentials: individualPotentials,
      scoutAnalysisData: null,
      motivationAbility: additionalAbilities['motivation'] ?? 50,
      pressureAbility: additionalAbilities['pressure'] ?? 50,
      adaptabilityAbility: additionalAbilities['adaptability'] ?? 50,
      consistencyAbility: additionalAbilities['consistency'] ?? 50,
      clutchAbility: additionalAbilities['clutch'] ?? 50,
      workEthicAbility: additionalAbilities['work_ethic'] ?? 50,
    );
    
    // 総合能力値を更新
    _updatePlayerOverallAbilities(player);
    
    return player;
  }

  /// 才能ランクを決定（指定された割合）
  int _determineTalentRank() {
    final rand = _random.nextDouble();
    
    if (rand < 0.80) return 3;      // 80% - ランク3
    if (rand < 0.98) return 4;      // 18% - ランク4
    if (rand < 0.9999) return 5;    // 2% - ランク5
    return 6;                        // 0.01% - ランク6
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

  /// 才能ランクに基づく基本ポテンシャルを取得（プロ野球選手のロジックを参考）
  int _getBasePotentialByTalent(int talentRank) {
    switch (talentRank) {
      case 3: return 95;  // ランク3: 80-110
      case 4: return 105; // ランク4: 90-120
      case 5: return 115; // ランク5: 100-130
      case 6: return 140; // ランク6: 125-150（怪物級）
      default: return 95;
    }
  }

  /// ポジションによる調整を適用
  int _applyPositionAdjustment(int baseValue, TechnicalAbility ability, String position) {
    switch (position) {
      case '投手':
        if (ability == TechnicalAbility.control || 
            ability == TechnicalAbility.fastball || 
            ability == TechnicalAbility.breakingBall ||
            ability == TechnicalAbility.pitchMovement) {
          baseValue += _random.nextInt(21); // 投手能力+0-20
        }
        break;
      case '捕手':
        if (ability == TechnicalAbility.catcherAbility) {
          baseValue += _random.nextInt(21);
        }
        break;
      case '内野手':
      case '外野手':
        if (ability == TechnicalAbility.fielding || 
            ability == TechnicalAbility.throwing) {
          baseValue += _random.nextInt(16); // +0-15
        }
        break;
    }
    
    // 打撃技術の調整
    if (ability == TechnicalAbility.contact || 
        ability == TechnicalAbility.power ||
        ability == TechnicalAbility.plateDiscipline ||
        ability == TechnicalAbility.batControl ||
        ability == TechnicalAbility.swingSpeed) {
      if (position != '投手') {
        baseValue += _random.nextInt(16); // 野手は打撃能力+0-15
      }
    }
    
    return baseValue;
  }

  /// フィジカル面のポジション調整を適用
  int _applyPhysicalPositionAdjustment(int baseValue, PhysicalAbility ability, String position) {
    switch (position) {
      case '投手':
        if (ability == PhysicalAbility.stamina) {
          baseValue += _random.nextInt(16); // +0-15
        }
        break;
      case '外野手':
        if (ability == PhysicalAbility.pace || ability == PhysicalAbility.acceleration) {
          baseValue += _random.nextInt(16); // +0-15
        }
        break;
      case '内野手':
        if (ability == PhysicalAbility.agility || ability == PhysicalAbility.balance) {
          baseValue += _random.nextInt(16); // +0-15
        }
        break;
    }
    return baseValue;
  }

  /// 個別ポテンシャルを生成（プロ野球選手のロジックを参考）
  Map<String, int> _generateIndividualPotentials(int talentRank, String position) {
    final potentials = <String, int>{};
    
    // 才能ランクに基づく基本ポテンシャル範囲（プロ野球選手のロジックを参考）
    final basePotential = _getBasePotentialByTalent(talentRank);
    final variationRange = 15; // ±15の変動（プロ野球選手と同様）
    
    // 技術面ポテンシャル
    for (final ability in TechnicalAbility.values) {
      int baseValue = basePotential + _random.nextInt(variationRange * 2 + 1) - variationRange;
      
      // ポジションによる調整
      baseValue = _applyPositionAdjustment(baseValue, ability, position);
      
      final potential = baseValue.clamp(50, 150);
      potentials[ability.name] = potential;
    }
    
    // メンタル面ポテンシャル（データベースに存在するカラムのみ）
    for (final ability in MentalAbility.values) {
      // 存在しないカラムを除外
      if (ability.name == 'motivation' || ability.name == 'adaptability' || ability.name == 'consistency') {
        continue;
      }
      int baseValue = basePotential + _random.nextInt(variationRange * 2 + 1) - variationRange;
      
      // 才能ランクによる微調整
      baseValue += (talentRank - 1) * 3; // 才能ランク1つにつき+3
      
      final potential = baseValue.clamp(50, 150);
      potentials[ability.name] = potential;
    }
    
    // フィジカル面ポテンシャル
    for (final ability in PhysicalAbility.values) {
      int baseValue = basePotential + _random.nextInt(variationRange * 2 + 1) - variationRange;
      
      // 才能ランクによる微調整
      baseValue += (talentRank - 1) * 3; // 才能ランク1つにつき+3
      
      // ポジションによる調整
      baseValue = _applyPhysicalPositionAdjustment(baseValue, ability, position);
      
      final potential = baseValue.clamp(50, 150);
      potentials[ability.name] = potential;
    }
    
    return potentials;
  }

  /// 技術面ポテンシャルを生成（個別ポテンシャル生成用）
  Map<TechnicalAbility, int> _generateTechnicalPotentials(int talentRank, String position) {
    final potentials = <TechnicalAbility, int>{};
    
    // 才能ランクに基づく基本ポテンシャルを決定
    final basePotential = _getBasePotentialByTalent(talentRank);
    
    for (final ability in TechnicalAbility.values) {
      int baseValue = basePotential + _random.nextInt(31) - 15; // 基本値 + ランダム変動
      
      // ポジションによる調整
      baseValue = _applyPositionAdjustment(baseValue, ability, position);
      
      potentials[ability] = baseValue.clamp(50, 150);
    }
    
    return potentials;
  }

  /// メンタル面ポテンシャルを生成（個別ポテンシャル生成用）
  Map<MentalAbility, int> _generateMentalPotentials(int talentRank) {
    final potentials = <MentalAbility, int>{};
    
    // 才能ランクに基づく基本ポテンシャルを決定
    final basePotential = _getBasePotentialByTalent(talentRank);
    
    for (final ability in MentalAbility.values) {
      // 存在しないカラムを除外
      if (ability.name == 'motivation' || ability.name == 'adaptability' || ability.name == 'consistency') {
        continue;
      }
      
      int baseValue = basePotential + _random.nextInt(31) - 15; // 基本値 + ランダム変動
      
      // 才能ランクによる微調整
      baseValue += (talentRank - 1) * 3; // 才能ランク1つにつき+3
      
      potentials[ability] = baseValue.clamp(50, 150);
    }
    
    return potentials;
  }

  /// フィジカル面ポテンシャルを生成（個別ポテンシャル生成用）
  Map<PhysicalAbility, int> _generatePhysicalPotentials(int talentRank, String position) {
    final potentials = <PhysicalAbility, int>{};
    
    // 才能ランクに基づく基本ポテンシャルを決定
    final basePotential = _getBasePotentialByTalent(talentRank);
    
    for (final ability in PhysicalAbility.values) {
      int baseValue = basePotential + _random.nextInt(31) - 15; // 基本値 + ランダム変動
      
      // 才能ランクによる微調整
      baseValue += (talentRank - 1) * 3; // 才能ランク1つにつき+3
      
      // ポジションによる調整
      baseValue = _applyPhysicalPositionAdjustment(baseValue, ability, position);
      
      potentials[ability] = baseValue.clamp(50, 150);
    }
    
    return potentials;
  }

  /// 技術面能力値を生成（ポテンシャルの60-70%で生成）
  Map<TechnicalAbility, int> _generateTechnicalAbilities(int talentRank, String position, int grade) {
    // ポテンシャル値を先に生成
    final potentials = _generateTechnicalPotentials(talentRank, position);
    
    // ポテンシャルの60-70%の範囲で能力値を生成
    final abilities = <TechnicalAbility, int>{};
    for (final entry in potentials.entries) {
      final ability = entry.key;
      final potential = entry.value;
      
      // ポテンシャルの60-70%の範囲で能力値を設定
      final baseValue = (potential * (_minAbilityPercentage + _random.nextDouble() * (_maxAbilityPercentage - _minAbilityPercentage))).round();
      
      // 学年による微調整（絶対値での調整）
      int adjustedValue = baseValue;
      if (grade == 1) {
        adjustedValue += _random.nextInt(4) - 2; // -2から+1の絶対値調整
      } else if (grade == 2) {
        adjustedValue += _random.nextInt(3) - 1; // -1から+1の絶対値調整
      } else { // grade == 3
        adjustedValue += _random.nextInt(2) - 1; // -1から+0の絶対値調整
      }
      
      // 最終的な能力値を設定（ポテンシャル値を超えないように、最小値45）
      abilities[ability] = adjustedValue.clamp(45, potential);
    }
    
    return abilities;
  }

  /// メンタル面能力値を生成（ポテンシャルの60-70%で生成）
  Map<MentalAbility, int> _generateMentalAbilities(int talentRank, int grade) {
    // ポテンシャル値を先に生成
    final potentials = _generateMentalPotentials(talentRank);
    
    // ポテンシャルの60-70%の範囲で能力値を生成
    final abilities = <MentalAbility, int>{};
    for (final entry in potentials.entries) {
      final ability = entry.key;
      final potential = entry.value;
      
      // 存在しないカラムを除外
      if (ability.name == 'motivation' || ability.name == 'adaptability' || ability.name == 'consistency') {
        continue;
      }
      
      // ポテンシャルの60-70%の範囲で能力値を設定
      final baseValue = (potential * (_minAbilityPercentage + _random.nextDouble() * (_maxAbilityPercentage - _minAbilityPercentage))).round();
      
      // 学年による微調整（絶対値での調整）
      int adjustedValue = baseValue;
      if (grade == 1) {
        adjustedValue += _random.nextInt(4) - 2; // -2から+1の絶対値調整
      } else if (grade == 2) {
        adjustedValue += _random.nextInt(3) - 1; // -1から+1の絶対値調整
      } else { // grade == 3
        adjustedValue += _random.nextInt(2) - 1; // -1から+0の絶対値調整
      }
      
      // 最終的な能力値を設定（ポテンシャル値を超えないように、最小値45）
      abilities[ability] = adjustedValue.clamp(45, potential);
    }
    
    return abilities;
  }

  /// フィジカル面能力値を生成（ポテンシャルの60-70%で生成）
  Map<PhysicalAbility, int> _generatePhysicalAbilities(int talentRank, String position, int grade) {
    // ポテンシャル値を先に生成
    final potentials = _generatePhysicalPotentials(talentRank, position);
    
    // ポテンシャルの60-70%の範囲で能力値を生成
    final abilities = <PhysicalAbility, int>{};
    for (final entry in potentials.entries) {
      final ability = entry.key;
      final potential = entry.value;
      
      // ポテンシャルの60-70%の範囲で能力値を設定
      final baseValue = (potential * (_minAbilityPercentage + _random.nextDouble() * (_maxAbilityPercentage - _minAbilityPercentage))).round();
      
      // 学年による微調整（絶対値での調整）
      int adjustedValue = baseValue;
      if (grade == 1) {
        adjustedValue += _random.nextInt(4) - 2; // -2から+1の絶対値調整
      } else if (grade == 2) {
        adjustedValue += _random.nextInt(3) - 1; // -1から+1の絶対値調整
      } else { // grade == 3
        adjustedValue += _random.nextInt(2) - 1; // -1から+0の絶対値調整
      }
      
      // 最終的な能力値を設定（ポテンシャル値を超えないように、最小値45）
      abilities[ability] = adjustedValue.clamp(45, potential);
    }
    
    return abilities;
  }

  /// タレントランクに基づくピーク能力を計算
  int _calculatePeakAbilityByTalent(int talentRank) {
    switch (talentRank) {
      case 3: return 80 + _random.nextInt(21);  // 80-100
      case 4: return 90 + _random.nextInt(21);  // 90-110
      case 5: return 100 + _random.nextInt(21); // 100-120
      case 6: return 120 + _random.nextInt(31); // 120-150（怪物級）
      default: return 80 + _random.nextInt(21);
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

  /// 追加された能力値を生成
  Map<String, int> _generateAdditionalAbilities(int talentRank, int grade) {
    final abilities = <String, int>{};
    
    // 才能ランクに基づく基本能力値を決定
    final baseAbility = _getBasePotentialByTalent(talentRank);
    
    // 各能力値を生成
    abilities['motivation'] = baseAbility + _random.nextInt(31) - 15;
    abilities['pressure'] = baseAbility + _random.nextInt(31) - 15;
    abilities['adaptability'] = baseAbility + _random.nextInt(31) - 15;
    abilities['consistency'] = baseAbility + _random.nextInt(31) - 15;
    abilities['clutch'] = baseAbility + _random.nextInt(31) - 15;
    abilities['work_ethic'] = baseAbility + _random.nextInt(31) - 15;
    
    // 学年による微調整
    for (final entry in abilities.entries) {
      int adjustedValue = entry.value;
      if (grade == 1) {
        adjustedValue += _random.nextInt(4) - 2; // -2から+1の絶対値調整
      } else if (grade == 2) {
        adjustedValue += _random.nextInt(3) - 1; // -1から+1の絶対値調整
      } else { // grade == 3
        adjustedValue += _random.nextInt(2) - 1; // -1から+0の絶対値調整
      }
      
      abilities[entry.key] = adjustedValue.clamp(45, 150);
    }
    
    return abilities;
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
