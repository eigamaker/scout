import 'dart:math';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import 'data_service.dart';

// 年齢段階の定義
enum AgeStage { young, prime, mature, decline, retirement }

class GrowthService {
  // 年齢段階を取得
  static AgeStage _getAgeStage(int age) {
    if (age <= 20) return AgeStage.young;      // 15-20歳
    if (age <= 27) return AgeStage.prime;      // 21-27歳
    if (age <= 32) return AgeStage.mature;     // 28-32歳
    if (age <= 36) return AgeStage.decline;    // 33-36歳
    return AgeStage.retirement;                 // 37歳以上
  }

  // 年齢と成長型に基づく成長係数を取得
  static double _getAgeBasedGrowthFactor(int age, String growthType) {
    // 37歳以降は全選手共通の大幅減退
    if (age >= 37) return -0.4;
    
    final ageStage = _getAgeStage(age);
    
    // 高校時代（15-20歳）は成長タイプに関係なく一律の成長
    if (ageStage == AgeStage.young) {
      return 1.0; // 高校時代は標準成長
    }
    
    // プロ時代（21歳以降）から成長タイプによる差が出る
    switch (growthType) {
      case 'early':
        switch (ageStage) {
          case AgeStage.prime: return 1.0;    // 21-27歳：標準成長
          case AgeStage.mature: return -0.2;  // 28-32歳：減退開始
          case AgeStage.decline: return -0.3; // 33-36歳：減退加速
          case AgeStage.retirement: return -0.4; // 37歳以上：大幅減退
          default: return 1.0;
        }
      case 'normal':
        switch (ageStage) {
          case AgeStage.prime: return 1.2;    // 21-27歳：成長率高め
          case AgeStage.mature: return 0.0;   // 28-32歳：成長停止
          case AgeStage.decline: return -0.2; // 33-36歳：能力値減退
          case AgeStage.retirement: return -0.4; // 37歳以上：大幅減退
          default: return 1.0;
        }
      case 'late':
        switch (ageStage) {
          case AgeStage.prime: return 1.0;    // 21-27歳：標準成長
          case AgeStage.mature: return 0.8;   // 28-32歳：成長継続
          case AgeStage.decline: return -0.1; // 33-36歳：軽微な減退
          case AgeStage.retirement: return -0.4; // 37歳以上：大幅減退
          default: return 1.0;
        }
      case 'spurt':
        switch (ageStage) {
          case AgeStage.prime: return 1.1;    // 21-27歳：やや高め
          case AgeStage.mature: return 0.0;   // 28-32歳：成長停止
          case AgeStage.decline: return -0.2; // 33-36歳：能力値減退
          case AgeStage.retirement: return -0.4; // 37歳以上：大幅減退
          default: return 1.0;
        }
      default:
        return 1.0;
    }
  }

  // 成長タイミングの判定（3ヶ月に1回）
  static bool shouldGrow(int currentWeek) {
    // 5月1週、8月1週、11月1週、2月1週で成長
    final isGrowthWeek = _isGrowthWeek(currentWeek);
    
    return isGrowthWeek;
  }

  // 成長週かどうかを判定
  static bool _isGrowthWeek(int week) {
    // 4週固定の場合の成長週
    // 5月1週：週5、8月1週：週17、11月1週：週29、2月1週：週41
    return week == 5 || week == 17 || week == 29 || week == 41;
  }

  // 選手の成長処理
  static Player growPlayer(Player player) {
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
    final ageBasedFactor = _getAgeBasedGrowthFactor(player.age, player.growthType);
    final growthRate = player.growthRate;
    final mentalGritBonus = 0.8 + player.mentalGrit * 0.4; // 0.8-1.2
    final talentBonus = _getTalentBonus(player.talent);
    final randomFactor = _getRandomFactor();
    final potentialPenalty = _getPotentialPenalty(currentValue, potential);

    final growthAmount = ageBasedFactor * growthRate * mentalGritBonus * talentBonus * randomFactor * potentialPenalty;
    final finalGrowthAmount = growthAmount.round().clamp(-5, 10); // マイナス成長も許可（-5から10）
    
    return finalGrowthAmount;
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