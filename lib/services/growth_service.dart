import 'dart:math';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import 'data_service.dart';

class GrowthService {
  static const int _springGrowthStartWeek = 8; // 2月4週
  static const int _springGrowthEndWeek = 9;    // 3月1週
  static const int _summerGrowthStartWeek = 34; // 8月5週
  static const int _summerGrowthEndWeek = 35;   // 9月1週

  // 成長タイミングの判定
  static bool shouldGrow(int currentWeek) {
    return _isSpringGrowthPeriod(currentWeek) || _isSummerGrowthPeriod(currentWeek);
  }

  static bool _isSpringGrowthPeriod(int week) {
    return week >= _springGrowthStartWeek && week <= _springGrowthEndWeek;
  }

  static bool _isSummerGrowthPeriod(int week) {
    return week >= _summerGrowthStartWeek && week <= _summerGrowthEndWeek;
  }

  // 選手の成長処理
  static Player growPlayer(Player player) {
    print('GrowthService.growPlayer: 選手ID ${player.id} (${player.name}) の成長処理開始');
    print('GrowthService.growPlayer: 選手情報 - 学年: ${player.grade}, 成長タイプ: ${player.growthType}, 成長率: ${player.growthRate}');
    final random = Random();
    
    // 各能力値を成長させる
    final updatedTechnicalAbilities = _growAbilities<TechnicalAbility>(
      player.technicalAbilities,
      player.individualPotentials,
      player,
      random,
    );

    final updatedMentalAbilities = _growAbilities<MentalAbility>(
      player.mentalAbilities,
      player.individualPotentials,
      player,
      random,
    );

    final updatedPhysicalAbilities = _growAbilities<PhysicalAbility>(
      player.physicalAbilities,
      player.individualPotentials,
      player,
      random,
    );

    final grownPlayer = player.copyWith(
      technicalAbilities: updatedTechnicalAbilities,
      mentalAbilities: updatedMentalAbilities,
      physicalAbilities: updatedPhysicalAbilities,
    );
    print('GrowthService.growPlayer: 選手ID ${player.id} (${player.name}) の成長処理完了');
    return grownPlayer;
  }

  // 能力値の成長計算
  static Map<T, int> _growAbilities<T>(
    Map<T, int> currentAbilities,
    Map<String, int>? potentials,
    Player player,
    Random random,
  ) {
    final updatedAbilities = <T, int>{};
    
    for (final ability in currentAbilities.keys) {
      final currentValue = currentAbilities[ability] ?? 25;
      final potential = _getPotentialForAbility(player, ability);
      
      if (currentValue < potential) {
        final growthAmount = _calculateGrowthAmount(player, currentValue, potential);
        final newValue = (currentValue + growthAmount).clamp(25, potential);
        updatedAbilities[ability] = newValue;
      } else {
        updatedAbilities[ability] = currentValue;
      }
    }
    
    return updatedAbilities;
  }

  // 能力値に対応するポテンシャルを取得
  static int _getPotentialForAbility(Player player, dynamic ability) {
    final abilityName = _getAbilityName(ability);
    return player.individualPotentials?[abilityName] ?? 100;
  }

  // 能力値の名前を取得
  static String _getAbilityName(dynamic ability) {
    if (ability is TechnicalAbility) {
      return ability.name;
    } else if (ability is MentalAbility) {
      return ability.name;
    } else if (ability is PhysicalAbility) {
      return ability.name;
    }
    return ability.toString();
  }

  // 成長量の計算
  static int _calculateGrowthAmount(Player player, int currentValue, int potential) {
    final baseGrowth = _getBaseGrowth(player.grade, player.growthType);
    final growthRate = player.growthRate;
    final mentalGritBonus = 0.8 + player.mentalGrit * 0.4; // 0.8-1.2
    final talentBonus = _getTalentBonus(player.talent);
    final randomFactor = _getRandomFactor();
    final potentialPenalty = _getPotentialPenalty(currentValue, potential);

    final growthAmount = baseGrowth * growthRate * mentalGritBonus * talentBonus * randomFactor * potentialPenalty;
    final finalGrowthAmount = growthAmount.round().clamp(0, 10); // 最大成長量を10に制限
    
    // 詳細な成長計算ログ（デバッグ用）
    if (finalGrowthAmount > 0) {
      print('GrowthService._calculateGrowthAmount: 選手ID ${player.id} - 現在値: $currentValue, ポテンシャル: $potential, 成長量: $finalGrowthAmount');
      print('GrowthService._calculateGrowthAmount: 計算要素 - baseGrowth: ${baseGrowth.toStringAsFixed(2)}, growthRate: ${growthRate.toStringAsFixed(2)}, mentalGritBonus: ${mentalGritBonus.toStringAsFixed(2)}, talentBonus: ${talentBonus.toStringAsFixed(2)}, randomFactor: ${randomFactor.toStringAsFixed(2)}, potentialPenalty: ${potentialPenalty.toStringAsFixed(2)}');
    }
    
    return finalGrowthAmount;
  }

  // 基本成長係数の計算
  static double _getBaseGrowth(int grade, String growthType) {
    double gradeFactor;
    switch (grade) {
      case 1:
        gradeFactor = 1.0;
        break;
      case 2:
        gradeFactor = 1.2;
        break;
      case 3:
        gradeFactor = 1.5;
        break;
      default:
        gradeFactor = 1.0;
    }

    double typeFactor;
    switch (growthType) {
      case 'early':
        typeFactor = 1.3;
        break;
      case 'normal':
        typeFactor = 1.0;
        break;
      case 'late':
        typeFactor = 0.8;
        break;
      default:
        typeFactor = 1.0;
    }

    return gradeFactor * typeFactor;
  }

  // 才能ランク補正
  static double _getTalentBonus(int talent) {
    return 0.8 + (talent - 1) * 0.1; // 0.8-1.3
  }

  // ランダム係数
  static double _getRandomFactor() {
    final random = Random();
    final rand = random.nextDouble();
    
    if (rand < 0.1) return 0.7;      // 10%: 成長不振
    if (rand < 0.25) return 0.8;     // 15%: 成長鈍化
    if (rand < 0.5) return 0.9;      // 25%: 成長普通
    if (rand < 0.75) return 1.0;     // 25%: 成長良好
    if (rand < 0.9) return 1.1;      // 15%: 成長優秀
    return 1.2;                       // 10%: 成長卓越
  }

  // ポテンシャル補正
  static double _getPotentialPenalty(int currentValue, int potential) {
    final progress = currentValue / potential;
    if (progress < 0.8) {
      return 1.0; // 80%未満は通常成長
    } else if (progress < 0.9) {
      return 0.5; // 80-90%は成長減速
    } else {
      return 0.2; // 90%以上は成長困難
    }
  }

  // 成長ログの生成
  static String generateGrowthLog(Player player, Map<String, int> oldAbilities, Map<String, int> newAbilities) {
    final growthAmounts = <String, int>{};
    int totalGrowth = 0;
    
    for (final ability in oldAbilities.keys) {
      final oldValue = oldAbilities[ability] ?? 0;
      final newValue = newAbilities[ability] ?? 0;
      final growth = newValue - oldValue;
      if (growth > 0) {
        growthAmounts[ability] = growth;
        totalGrowth += growth;
      }
    }
    
    if (totalGrowth == 0) {
      return '${player.name}の成長はありませんでした。';
    }
    
    final log = StringBuffer();
    log.writeln('${player.name}の成長ログ:');
    log.writeln('総成長量: $totalGrowth');
    
    for (final entry in growthAmounts.entries) {
      log.writeln('${entry.key}: +${entry.value}');
    }
    
    return log.toString();
  }

  // 成長タイプの説明
  static String getGrowthTypeDescription(String growthType) {
    switch (growthType) {
      case 'early':
        return '早期成長型: 若いうちから高いレベルに達するが、ポテンシャル到達は困難';
      case 'normal':
        return '標準成長型: 安定した成長パターン';
      case 'late':
        return '遅咲き型: 長期的な成長が見込める';
      default:
        return '不明な成長タイプ';
    }
  }
} 