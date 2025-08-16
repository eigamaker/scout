import 'dart:math';
import 'package:flutter/foundation.dart';
import 'professional_player.dart';

// ポジション別のdepth chart
class PositionDepthChart {
  final String position;
  final List<String> playerIds; // 選手IDのリスト（1番目がスタメル、2番目が控え1番目...）
  final Map<String, double> playingTimePercentages; // 各選手の出場時間割合

  PositionDepthChart({
    required this.position,
    required this.playerIds,
    required this.playingTimePercentages,
  });

  // スタメル選手のIDを取得
  String? get starterPlayerId => playerIds.isNotEmpty ? playerIds.first : null;

  // 控え選手のIDリストを取得
  List<String> get backupPlayerIds => playerIds.skip(1).toList();

  // 特定の選手の出場時間割合を取得
  double getPlayingTimePercentage(String playerId) {
    return playingTimePercentages[playerId] ?? 0.0;
  }

  // 出場選手を決定（能力値とランダム性を考慮）
  String determinePlayingPlayer(List<ProfessionalPlayer> players, Random random) {
    if (playerIds.isEmpty) return '';

    // 各選手の出場確率を計算
    final probabilities = <String, double>{};
    double totalProbability = 0.0;

    for (final playerId in playerIds) {
      final player = players.firstWhere((p) => p.id.toString() == playerId);
      final basePercentage = playingTimePercentages[playerId] ?? 0.0;
      
      // 能力値による調整（能力値が高いほど出場確率が上がる）
      final abilityBonus = (player.player?.trueTotalAbility ?? 0) / 100.0;
      final adjustedPercentage = basePercentage + abilityBonus;
      
      probabilities[playerId] = adjustedPercentage;
      totalProbability += adjustedPercentage;
    }

    // 確率に基づいて選手を選択
    final randomValue = random.nextDouble() * totalProbability;
    double currentSum = 0.0;

    for (final entry in probabilities.entries) {
      currentSum += entry.value;
      if (randomValue <= currentSum) {
        return entry.key;
      }
    }

    // フォールバック：最初の選手
    return playerIds.first;
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'position': position,
    'playerIds': playerIds,
    'playingTimePercentages': playingTimePercentages,
  };

  factory PositionDepthChart.fromJson(Map<String, dynamic> json) {
    return PositionDepthChart(
      position: json['position'] as String,
      playerIds: List<String>.from(json['playerIds']),
      playingTimePercentages: Map<String, double>.from(json['playingTimePercentages']),
    );
  }

  // コピーメソッド
  PositionDepthChart copyWith({
    String? position,
    List<String>? playerIds,
    Map<String, double>? playingTimePercentages,
  }) {
    return PositionDepthChart(
      position: position ?? this.position,
      playerIds: playerIds ?? this.playerIds,
      playingTimePercentages: playingTimePercentages ?? this.playingTimePercentages,
    );
  }
}

// 投手ローテーション
class PitcherRotation {
  final List<String> startingPitcherIds; // 先発投手のIDリスト
  final List<String> reliefPitcherIds; // リリーフ投手のIDリスト
  final List<String> closerPitcherIds; // クローザーのIDリスト
  final int currentRotationIndex; // 現在のローテーション位置
  final Map<String, int> pitcherUsage; // 投手の使用回数

  PitcherRotation({
    required this.startingPitcherIds,
    required this.reliefPitcherIds,
    required this.closerPitcherIds,
    this.currentRotationIndex = 0,
    required this.pitcherUsage,
  });

  // 次の先発投手を取得
  String getNextStartingPitcher() {
    if (startingPitcherIds.isEmpty) return '';
    return startingPitcherIds[currentRotationIndex % startingPitcherIds.length];
  }

  // ローテーションを進める
  PitcherRotation advanceRotation() {
    return copyWith(
      currentRotationIndex: (currentRotationIndex + 1) % startingPitcherIds.length,
    );
  }

  // 投手の使用回数を増やす
  PitcherRotation incrementUsage(String pitcherId) {
    final newUsage = Map<String, int>.from(pitcherUsage);
    newUsage[pitcherId] = (newUsage[pitcherId] ?? 0) + 1;
    return copyWith(pitcherUsage: newUsage);
  }

  // リリーフ投手を選択（疲労度と能力値を考慮）
  String selectReliefPitcher(List<ProfessionalPlayer> players, Random random) {
    if (reliefPitcherIds.isEmpty) return '';

    // 疲労度が低く、能力値が高い投手を優先
    final availablePitchers = reliefPitcherIds.where((id) {
      final usage = pitcherUsage[id] ?? 0;
      return usage < 3; // 週3回まで使用可能
    }).toList();

    if (availablePitchers.isEmpty) return '';

    // 能力値と疲労度でスコアリング
    final scores = <String, double>{};
    for (final id in availablePitchers) {
      final player = players.firstWhere((p) => p.id.toString() == id);
      final ability = player.player?.trueTotalAbility ?? 0;
      final fatigue = (pitcherUsage[id] ?? 0) * 10.0; // 疲労度
      scores[id] = ability - fatigue;
    }

    // スコアが高い順にソート
    final sortedPitchers = availablePitchers.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    // 上位3名からランダム選択（能力値の高い投手が選ばれやすい）
    final topPitchers = sortedPitchers.take(3).toList();
    return topPitchers[random.nextInt(topPitchers.length)];
  }

  // クローザーを選択
  String selectCloser(List<ProfessionalPlayer> players) {
    if (closerPitcherIds.isEmpty) return '';
    
    // 疲労度が最も低いクローザーを選択
    String selectedCloser = closerPitcherIds.first;
    int minUsage = pitcherUsage[selectedCloser] ?? 0;

    for (final id in closerPitcherIds) {
      final usage = pitcherUsage[id] ?? 0;
      if (usage < minUsage) {
        selectedCloser = id;
        minUsage = usage;
      }
    }

    return selectedCloser;
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'startingPitcherIds': startingPitcherIds,
    'reliefPitcherIds': reliefPitcherIds,
    'closerPitcherIds': closerPitcherIds,
    'currentRotationIndex': currentRotationIndex,
    'pitcherUsage': pitcherUsage,
  };

  factory PitcherRotation.fromJson(Map<String, dynamic> json) {
    return PitcherRotation(
      startingPitcherIds: List<String>.from(json['startingPitcherIds']),
      reliefPitcherIds: List<String>.from(json['reliefPitcherIds']),
      closerPitcherIds: List<String>.from(json['closerPitcherIds']),
      currentRotationIndex: json['currentRotationIndex'] as int,
      pitcherUsage: Map<String, int>.from(json['pitcherUsage']),
    );
  }

  // コピーメソッド
  PitcherRotation copyWith({
    List<String>? startingPitcherIds,
    List<String>? reliefPitcherIds,
    List<String>? closerPitcherIds,
    int? currentRotationIndex,
    Map<String, int>? pitcherUsage,
  }) {
    return PitcherRotation(
      startingPitcherIds: startingPitcherIds ?? this.startingPitcherIds,
      reliefPitcherIds: reliefPitcherIds ?? this.reliefPitcherIds,
      closerPitcherIds: closerPitcherIds ?? this.closerPitcherIds,
      currentRotationIndex: currentRotationIndex ?? this.currentRotationIndex,
      pitcherUsage: pitcherUsage ?? this.pitcherUsage,
    );
  }
}

// チーム全体のdepth chart
class TeamDepthChart {
  final String teamId;
  final Map<String, PositionDepthChart> positionCharts; // ポジション別depth chart
  final PitcherRotation pitcherRotation; // 投手ローテーション
  final DateTime lastUpdated; // 最終更新日時

  TeamDepthChart({
    required this.teamId,
    required this.positionCharts,
    required this.pitcherRotation,
    required this.lastUpdated,
  });

  // 特定ポジションのdepth chartを取得
  PositionDepthChart? getPositionChart(String position) {
    return positionCharts[position];
  }

  // スタメル選手を取得
  Map<String, String> getStartingLineup() {
    final lineup = <String, String>{};
    for (final entry in positionCharts.entries) {
      final starterId = entry.value.starterPlayerId;
      if (starterId != null) {
        lineup[entry.key] = starterId;
      }
    }
    return lineup;
  }

  // 投手ローテーションを進める
  TeamDepthChart advancePitcherRotation() {
    return copyWith(
      pitcherRotation: pitcherRotation.advanceRotation(),
      lastUpdated: DateTime.now(),
    );
  }

  // 投手の使用回数を更新
  TeamDepthChart updatePitcherUsage(String pitcherId) {
    return copyWith(
      pitcherRotation: pitcherRotation.incrementUsage(pitcherId),
      lastUpdated: DateTime.now(),
    );
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'positionCharts': positionCharts.map((key, value) => MapEntry(key, value.toJson())),
    'pitcherRotation': pitcherRotation.toJson(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory TeamDepthChart.fromJson(Map<String, dynamic> json) {
    return TeamDepthChart(
      teamId: json['teamId'] as String,
      positionCharts: (json['positionCharts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PositionDepthChart.fromJson(value)),
      ),
      pitcherRotation: PitcherRotation.fromJson(json['pitcherRotation']),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  // コピーメソッド
  TeamDepthChart copyWith({
    String? teamId,
    Map<String, PositionDepthChart>? positionCharts,
    PitcherRotation? pitcherRotation,
    DateTime? lastUpdated,
  }) {
    return TeamDepthChart(
      teamId: teamId ?? this.teamId,
      positionCharts: positionCharts ?? this.positionCharts,
      pitcherRotation: pitcherRotation ?? this.pitcherRotation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
