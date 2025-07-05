import 'dart:math';
import 'game_models.dart';
import 'models/player.dart';

// 試合結果クラス
class GameResult {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final DateTime gameDate;
  final List<PlayerPerformance> performances;
  final String gameType; // '練習試合', '大会', '公式戦'
  
  GameResult({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.gameDate,
    required this.performances,
    required this.gameType,
  });
  
  bool get isHomeWin => homeScore > awayScore;
  String get winner => isHomeWin ? homeTeam : awayTeam;
  
  Map<String, dynamic> toJson() => {
    'homeTeam': homeTeam,
    'awayTeam': awayTeam,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'gameDate': gameDate.toIso8601String(),
    'performances': performances.map((p) => p.toJson()).toList(),
    'gameType': gameType,
  };
  
  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
    homeTeam: json['homeTeam'],
    awayTeam: json['awayTeam'],
    homeScore: json['homeScore'],
    awayScore: json['awayScore'],
    gameDate: DateTime.parse(json['gameDate']),
    performances: (json['performances'] as List).map((p) => PlayerPerformance.fromJson(p)).toList(),
    gameType: json['gameType'],
  );
}

// 選手成績クラス
class PlayerPerformance {
  final String playerName;
  final String school;
  final String position;
  
  // 投手成績
  final int? inningsPitched; // 投球回数
  final int? hitsAllowed; // 被安打
  final int? runsAllowed; // 失点
  final int? earnedRuns; // 自責点
  final int? walks; // 与四球
  final int? strikeouts; // 奪三振
  final double? era; // 防御率
  
  // 野手成績
  final int? atBats; // 打数
  final int? hits; // 安打
  final int? doubles; // 二塁打
  final int? triples; // 三塁打
  final int? homeRuns; // 本塁打
  final int? rbis; // 打点
  final int? runs; // 得点
  final int? stolenBases; // 盗塁
  final double? battingAverage; // 打率
  final double? onBasePercentage; // 出塁率
  final double? sluggingPercentage; // 長打率
  
  // 守備成績
  final int? putouts; // 刺殺
  final int? assists; // 補殺
  final int? errors; // 失策
  final double? fieldingPercentage; // 守備率
  
  PlayerPerformance({
    required this.playerName,
    required this.school,
    required this.position,
    this.inningsPitched,
    this.hitsAllowed,
    this.runsAllowed,
    this.earnedRuns,
    this.walks,
    this.strikeouts,
    this.era,
    this.atBats,
    this.hits,
    this.doubles,
    this.triples,
    this.homeRuns,
    this.rbis,
    this.runs,
    this.stolenBases,
    this.battingAverage,
    this.onBasePercentage,
    this.sluggingPercentage,
    this.putouts,
    this.assists,
    this.errors,
    this.fieldingPercentage,
  });
  
  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'school': school,
    'position': position,
    'inningsPitched': inningsPitched,
    'hitsAllowed': hitsAllowed,
    'runsAllowed': runsAllowed,
    'earnedRuns': earnedRuns,
    'walks': walks,
    'strikeouts': strikeouts,
    'era': era,
    'atBats': atBats,
    'hits': hits,
    'doubles': doubles,
    'triples': triples,
    'homeRuns': homeRuns,
    'rbis': rbis,
    'runs': runs,
    'stolenBases': stolenBases,
    'battingAverage': battingAverage,
    'onBasePercentage': onBasePercentage,
    'sluggingPercentage': sluggingPercentage,
    'putouts': putouts,
    'assists': assists,
    'errors': errors,
    'fieldingPercentage': fieldingPercentage,
  };
  
  factory PlayerPerformance.fromJson(Map<String, dynamic> json) => PlayerPerformance(
    playerName: json['playerName'],
    school: json['school'],
    position: json['position'],
    inningsPitched: json['inningsPitched'],
    hitsAllowed: json['hitsAllowed'],
    runsAllowed: json['runsAllowed'],
    earnedRuns: json['earnedRuns'],
    walks: json['walks'],
    strikeouts: json['strikeouts'],
    era: json['era']?.toDouble(),
    atBats: json['atBats'],
    hits: json['hits'],
    doubles: json['doubles'],
    triples: json['triples'],
    homeRuns: json['homeRuns'],
    rbis: json['rbis'],
    runs: json['runs'],
    stolenBases: json['stolenBases'],
    battingAverage: json['battingAverage']?.toDouble(),
    onBasePercentage: json['onBasePercentage']?.toDouble(),
    sluggingPercentage: json['sluggingPercentage']?.toDouble(),
    putouts: json['putouts'],
    assists: json['assists'],
    errors: json['errors'],
    fieldingPercentage: json['fieldingPercentage']?.toDouble(),
  );
}

// 試合シミュレーター
class GameSimulator {
  static GameResult simulateGame(School homeTeam, School awayTeam, String gameType) {
    final random = Random();
    final performances = <PlayerPerformance>[];
    
    // 投手の成績をシミュレート
    final homePitchers = homeTeam.players.where((p) => p.isPitcher).toList();
    final awayPitchers = awayTeam.players.where((p) => p.isPitcher).toList();
    
    if (homePitchers.isNotEmpty && awayPitchers.isNotEmpty) {
      final homePitcher = homePitchers[random.nextInt(homePitchers.length)];
      final awayPitcher = awayPitchers[random.nextInt(awayPitchers.length)];
      
      // 投手成績を能力値から計算
      performances.add(_simulatePitcherPerformance(homePitcher, homeTeam.name));
      performances.add(_simulatePitcherPerformance(awayPitcher, awayTeam.name));
    }
    
    // 野手の成績をシミュレート
    final homeBatters = homeTeam.players.where((p) => !p.isPitcher).take(9).toList();
    final awayBatters = awayTeam.players.where((p) => !p.isPitcher).take(9).toList();
    
    for (final batter in homeBatters) {
      performances.add(_simulateBatterPerformance(batter, homeTeam.name));
    }
    for (final batter in awayBatters) {
      performances.add(_simulateBatterPerformance(batter, awayTeam.name));
    }
    
    // チームスコアを計算
    final homeScore = _calculateTeamScore(homeBatters, awayPitchers.isNotEmpty ? awayPitchers.first : null);
    final awayScore = _calculateTeamScore(awayBatters, homePitchers.isNotEmpty ? homePitchers.first : null);
    
    return GameResult(
      homeTeam: homeTeam.name,
      awayTeam: awayTeam.name,
      homeScore: homeScore,
      awayScore: awayScore,
      gameDate: DateTime.now(),
      performances: performances,
      gameType: gameType,
    );
  }
  
  // 投手成績を能力値から計算
  static PlayerPerformance _simulatePitcherPerformance(Player pitcher, String school) {
    final random = Random();
    
    // 能力値から成績を計算
    final control = pitcher.control ?? 50;
    final stamina = pitcher.stamina ?? 50;
    final veloScore = pitcher.veloScore;
    final breakScore = pitcher.breakAvg ?? 50;
    
    // 投球回数（スタミナに基づく）
    final inningsPitched = (stamina / 20).round().clamp(1, 9);
    
    // 奪三振（球速と変化に基づく）
    final strikeoutRate = (veloScore + breakScore) / 200.0;
    final strikeouts = (random.nextDouble() * 15 * strikeoutRate).round();
    
    // 与四球（制球に基づく）
    final walkRate = (100 - control) / 100.0;
    final walks = (random.nextDouble() * 8 * walkRate).round();
    
    // 被安打（制球と球速に基づく）
    final hitRate = (100 - control) / 100.0 * 0.8 + (100 - veloScore) / 100.0 * 0.2;
    final hits = (random.nextDouble() * 12 * hitRate).round();
    
    // 失点
    final runs = (hits * 0.3 + walks * 0.4).round();
    final earnedRuns = (runs * 0.8).round();
    
    // ERA計算
    final era = inningsPitched > 0 ? (earnedRuns * 9.0) / inningsPitched : 0.0;
    
    return PlayerPerformance(
      playerName: pitcher.name,
      school: school,
      position: pitcher.position,
      inningsPitched: inningsPitched,
      hitsAllowed: hits,
      runsAllowed: runs,
      earnedRuns: earnedRuns,
      walks: walks,
      strikeouts: strikeouts,
      era: era,
    );
  }
  
  // 野手成績を能力値から計算
  static PlayerPerformance _simulateBatterPerformance(Player batter, String school) {
    final random = Random();
    
    // 能力値から成績を計算
    final power = batter.batPower ?? 50;
    final control = batter.batControl ?? 50;
    final run = batter.run ?? 50;
    final field = batter.field ?? 50;
    final arm = batter.arm ?? 50;
    
    // 打数
    final atBats = 3 + random.nextInt(3); // 3-5打数
    
    // 打率（バットコントロールに基づく）
    final contactRate = control / 100.0;
    final hits = (random.nextDouble() * atBats * contactRate).round();
    
    // 長打率（パワーに基づく）
    final powerRate = power / 100.0;
    final homeRuns = (random.nextDouble() * hits * powerRate * 0.3).round();
    final doubles = (random.nextDouble() * hits * powerRate * 0.4).round();
    final triples = (random.nextDouble() * hits * powerRate * 0.1).round();
    
    // 打点
    final rbis = homeRuns + (doubles * 0.6 + triples * 0.8).round();
    
    // 得点
    final runs = homeRuns + (random.nextDouble() * (hits - homeRuns) * 0.4).round();
    
    // 盗塁（走力に基づく）
    final stealRate = run / 100.0;
    final stolenBases = (random.nextDouble() * 2 * stealRate).round();
    
    // 打率計算
    final battingAverage = atBats > 0 ? hits / atBats : 0.0;
    
    // 守備成績
    final fieldingChance = field / 100.0;
    final putouts = (random.nextDouble() * 3 * fieldingChance).round();
    final assists = (random.nextDouble() * 2 * fieldingChance).round();
    final errors = (random.nextDouble() * 2 * (1 - fieldingChance)).round();
    
    final fieldingPercentage = (putouts + assists + errors) > 0 
      ? (putouts + assists) / (putouts + assists + errors) 
      : 1.0;
    
    return PlayerPerformance(
      playerName: batter.name,
      school: school,
      position: batter.position,
      atBats: atBats,
      hits: hits,
      doubles: doubles,
      triples: triples,
      homeRuns: homeRuns,
      rbis: rbis,
      runs: runs,
      stolenBases: stolenBases,
      battingAverage: battingAverage,
      putouts: putouts,
      assists: assists,
      errors: errors,
      fieldingPercentage: fieldingPercentage,
    );
  }
  
  // チームスコアを計算
  static int _calculateTeamScore(List<Player> batters, Player? pitcher) {
    final random = Random();
    int totalRuns = 0;
    
    for (final batter in batters) {
      final power = batter.batPower ?? 50;
      final control = batter.batControl ?? 50;
      
      // 投手の能力を考慮
      final pitcherControl = pitcher?.control ?? 50;
      final pitcherVelo = pitcher?.veloScore ?? 50;
      
      // 打率を計算（投手の制球と球速を考慮）
      final contactRate = (control / 100.0) * (1 - (pitcherControl / 100.0) * 0.3);
      final powerRate = (power / 100.0) * (1 - (pitcherVelo / 100.0) * 0.2);
      
      // 得点確率
      final runChance = contactRate * powerRate;
      if (random.nextDouble() < runChance) {
        totalRuns += 1 + (powerRate * 2).round().toInt();
      }
    }
    
    return totalRuns;
  }
} 