import 'dart:math';

// 簡易版の位置決定ロジックをテスト
void main() {
  final random = Random();
  int pitcherCount = 0;
  int fielderCount = 0;
  
  // 1000人の選手を生成して位置分布をテスト
  for (int i = 0; i < 1000; i++) {
    final talent = _generateTalent(random);
    final position = _determinePositionByPitchingAbility(talent, random);
    
    if (position == '投手') {
      pitcherCount++;
    } else {
      fielderCount++;
    }
  }
  
  print('投手: $pitcherCount (${(pitcherCount / 1000 * 100).toStringAsFixed(1)}%)');
  print('野手: $fielderCount (${(fielderCount / 1000 * 100).toStringAsFixed(1)}%)');
  print('投手:野手比率 = ${(pitcherCount / fielderCount).toStringAsFixed(2)}:1');
}

int _generateTalent(Random random) {
  final r = random.nextInt(1000000);
  if (r < 700000) return 1;      // 70%
  if (r < 930000) return 2;      // 23%
  if (r < 980000) return 3;      // 5%
  if (r < 999800) return 4;      // 2%
  if (r < 999990) return 5;      // 0.01%
  return 6;                       // 0.0004%
}

String _determinePositionByPitchingAbility(int talent, Random random) {
  final baseAbility = _getBaseAbilityByTalent(talent);
  final baseVelocity = _getBaseVelocityByTalent(talent);
  
  final pitcherScore = _calculatePitcherScore(baseAbility, baseVelocity, random);
  final fielderScore = _calculateFielderScore(baseAbility, random);
  
  double pitcherProbability = _calculatePitcherProbability(pitcherScore, fielderScore);
  
  // 才能ランクに基づく調整
  if (talent >= 4) {
    pitcherProbability *= 0.8;
  } else if (talent <= 2) {
    pitcherProbability *= 1.2;
  }
  
  final isPitcher = random.nextDouble() < pitcherProbability;
  
  if (isPitcher) {
    return '投手';
  } else {
    return '野手';
  }
}

int _getBaseAbilityByTalent(int talent) {
  switch (talent) {
    case 1: return 35;
    case 2: return 45;
    case 3: return 55;
    case 4: return 65;
    case 5: return 75;
    case 6: return 85;
    default: return 45;
  }
}

int _getBaseVelocityByTalent(int talent) {
  switch (talent) {
    case 1: return 130;
    case 2: return 135;
    case 3: return 140;
    case 4: return 145;
    case 5: return 150;
    case 6: return 155;
    default: return 135;
  }
}

int _calculatePitcherScore(int baseAbility, int baseVelocity, Random random) {
  final control = baseAbility + random.nextInt(20);
  final stamina = baseAbility + random.nextInt(20);
  final breakAvg = baseAbility + random.nextInt(20);
  final velocity = baseVelocity + random.nextInt(20);
  
  // 球速を能力値システムに合わせて正規化（130-155km/h → 25-100の能力値）
  final normalizedVelocity = 25 + ((velocity - 130) * 75 / 25).clamp(0, 75);
  
  return ((normalizedVelocity * 0.4) + (control * 0.25) + (stamina * 0.2) + (breakAvg * 0.15)).round();
}

int _calculateFielderScore(int baseAbility, Random random) {
  final batPower = baseAbility + random.nextInt(20);
  final batControl = baseAbility + random.nextInt(20);
  final run = baseAbility + random.nextInt(20);
  final field = baseAbility + random.nextInt(20);
  final arm = baseAbility + random.nextInt(20);
  
  final battingScore = (batPower + batControl) / 2;
  final fieldingScore = (run + field + arm) / 3;
  return ((battingScore * 0.5) + (fieldingScore * 0.5)).round();
}

double _calculatePitcherProbability(int pitcherScore, int fielderScore) {
  final scoreDifference = pitcherScore - fielderScore;
  
  if (scoreDifference >= 30) return 0.70;
  if (scoreDifference >= 20) return 0.55;
  if (scoreDifference >= 10) return 0.40;
  if (scoreDifference >= 0) return 0.25;
  if (scoreDifference >= -10) return 0.15;
  if (scoreDifference >= -20) return 0.08;
  return 0.03;
} 