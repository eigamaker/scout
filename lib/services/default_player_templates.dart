import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../models/player/pitch.dart';
import '../models/school/school.dart';

/// 学校ランクごとのデフォルト選手テンプレート
/// 各ランク1人ずつ、全学校で共有して使用
class DefaultPlayerTemplate {
  
  /// 弱小校用デフォルト選手（全能力45）
  static final Player weakTemplate = Player(
    name: 'デフォルト選手',
    school: '', // 学校名は動的に設定
    grade: 1,
    position: '投手', // ポジションは何でもOK
    personality: '真面目',
    fame: 0,
    isPubliclyKnown: false,
    isScoutFavorite: false,
    isGraduated: false,
    discoveredAt: null,
    discoveredBy: null,
    discoveredCount: 0,
    scoutedDates: [],
    abilityKnowledge: <String, int>{},
    type: PlayerType.highSchool,
    yearsAfterGraduation: 0,
    pitches: [
      Pitch(type: 'ストレート', breakAmount: 0, breakPot: 30, unlocked: true),
    ],
    technicalAbilities: _createAllAbilities(45),
    mentalAbilities: _createAllMentalAbilities(45),
    physicalAbilities: _createAllPhysicalAbilities(45),
    mentalGrit: 0.5,
    growthRate: 1.0,
    peakAbility: 55,
    positionFit: _createDefaultPositionFit('投手'),
    talent: 1, // デフォルト選手は才能ランク1
    growthType: 'normal',
    individualPotentials: _createDefaultPotentials(45),
    scoutAnalysisData: null,
  );

  /// 中堅校用デフォルト選手（全能力50）
  static final Player averageTemplate = weakTemplate.copyWith(
    technicalAbilities: _createAllAbilities(50),
    mentalAbilities: _createAllMentalAbilities(50),
    physicalAbilities: _createAllPhysicalAbilities(50),
    peakAbility: 60,
    individualPotentials: _createDefaultPotentials(50),
  );

  /// 強豪校用デフォルト選手（全能力55）
  static final Player strongTemplate = weakTemplate.copyWith(
    technicalAbilities: _createAllAbilities(55),
    mentalAbilities: _createAllMentalAbilities(55),
    physicalAbilities: _createAllPhysicalAbilities(55),
    peakAbility: 65,
    individualPotentials: _createDefaultPotentials(55),
  );

  /// 名門校用デフォルト選手（全能力60）
  static final Player eliteTemplate = weakTemplate.copyWith(
    technicalAbilities: _createAllAbilities(60),
    mentalAbilities: _createAllMentalAbilities(60),
    physicalAbilities: _createAllPhysicalAbilities(60),
    peakAbility: 70,
    individualPotentials: _createDefaultPotentials(60),
  );

  /// 学校ランクに応じたデフォルト選手テンプレートを取得
  static Player getTemplateByRank(SchoolRank rank) {
    switch (rank) {
      case SchoolRank.elite:
        return eliteTemplate;
      case SchoolRank.strong:
        return strongTemplate;
      case SchoolRank.average:
        return averageTemplate;
      case SchoolRank.weak:
        return weakTemplate;
    }
  }

  /// 全技術面能力値を指定値で作成
  static Map<TechnicalAbility, int> _createAllAbilities(int value) {
    return {
      for (final ability in TechnicalAbility.values) ability: value
    };
  }

  /// 全メンタル面能力値を指定値で作成
  static Map<MentalAbility, int> _createAllMentalAbilities(int value) {
    return {
      for (final ability in MentalAbility.values) ability: value
    };
  }

  /// 全フィジカル面能力値を指定値で作成
  static Map<PhysicalAbility, int> _createAllPhysicalAbilities(int value) {
    return {
      for (final ability in PhysicalAbility.values) ability: value
    };
  }

  /// デフォルトポジション適性を作成
  static Map<String, int> _createDefaultPositionFit(String mainPosition) {
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final fit = <String, int>{};
    
    for (final pos in positions) {
      if (pos == mainPosition) {
        fit[pos] = 60; // メインポジションは60
      } else {
        fit[pos] = 30; // その他は30
      }
    }
    
    return fit;
  }

  /// デフォルトポテンシャルを作成
  static Map<String, int> _createDefaultPotentials(int baseValue) {
    final potentials = <String, int>{};
    
    // 技術面ポテンシャル
    for (final ability in TechnicalAbility.values) {
      potentials[ability.name] = baseValue;
    }
    
    // メンタル面ポテンシャル
    for (final ability in MentalAbility.values) {
      potentials[ability.name] = baseValue;
    }
    
    // フィジカル面ポテンシャル
    for (final ability in PhysicalAbility.values) {
      potentials[ability.name] = baseValue;
    }
    
    return potentials;
  }
}
