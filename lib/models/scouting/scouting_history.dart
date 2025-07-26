import 'action.dart';

class ScoutingHistory {
  final String scoutId;
  final String targetId;  // 選手IDまたは学校ID
  final String targetType;  // "player" または "school"
  
  // 視察履歴
  final List<ScoutingRecord> records;
  
  // 統計情報
  final int totalVisits;
  final DateTime? lastVisit;
  final double currentAccuracy;

  ScoutingHistory({
    required this.scoutId,
    required this.targetId,
    required this.targetType,
    required this.records,
    required this.totalVisits,
    this.lastVisit,
    required this.currentAccuracy,
  });

  // 新しい視察記録を追加
  ScoutingHistory addRecord(ScoutingRecord record) {
    final newRecords = List<ScoutingRecord>.from(records)..add(record);
    return copyWith(
      records: newRecords,
      totalVisits: totalVisits + 1,
      lastVisit: record.visitDate,
    );
  }

  // 指定した週の視察記録を取得
  List<ScoutingRecord> getRecordsForWeek(int weekNumber) {
    return records.where((record) => record.weekNumber == weekNumber).toList();
  }

  // 最後の視察から経過した週数を計算
  int getWeeksSinceLastVisit(int currentWeek) {
    if (lastVisit == null) return 0;
    // lastVisitはDateTimeなので、週数を計算する必要がある
    // 簡易的に、日付の差を7で割って週数を計算
    final daysSinceLastVisit = DateTime.now().difference(lastVisit!).inDays;
    final weeksSinceLastVisit = daysSinceLastVisit ~/ 7;
    return currentWeek - weeksSinceLastVisit;
  }

  // 指定したアクションタイプの視察回数を取得
  int getVisitCountForAction(ActionType actionType) {
    return records.where((record) => record.actionId == actionType.name).length;
  }

  // デフォルト履歴を作成
  factory ScoutingHistory.create({
    required String scoutId,
    required String targetId,
    required String targetType,
  }) {
    return ScoutingHistory(
      scoutId: scoutId,
      targetId: targetId,
      targetType: targetType,
      records: [],
      totalVisits: 0,
      lastVisit: null,
      currentAccuracy: 0.0,
    );
  }

  // コピーメソッド
  ScoutingHistory copyWith({
    String? scoutId,
    String? targetId,
    String? targetType,
    List<ScoutingRecord>? records,
    int? totalVisits,
    DateTime? lastVisit,
    double? currentAccuracy,
  }) {
    return ScoutingHistory(
      scoutId: scoutId ?? this.scoutId,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      records: records ?? this.records,
      totalVisits: totalVisits ?? this.totalVisits,
      lastVisit: lastVisit ?? this.lastVisit,
      currentAccuracy: currentAccuracy ?? this.currentAccuracy,
    );
  }

  @override
  String toString() {
    return 'ScoutingHistory(scoutId: $scoutId, targetId: $targetId, totalVisits: $totalVisits)';
  }
}

class ScoutingRecord {
  final String actionId;
  final DateTime visitDate;
  final int weekNumber;
  final double accuracy;
  final Map<String, dynamic> obtainedInfo;
  final bool wasSuccessful;

  ScoutingRecord({
    required this.actionId,
    required this.visitDate,
    required this.weekNumber,
    required this.accuracy,
    required this.obtainedInfo,
    required this.wasSuccessful,
  });

  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'actionId': actionId,
      'visitDate': visitDate.toIso8601String(),
      'weekNumber': weekNumber,
      'accuracy': accuracy,
      'obtainedInfo': obtainedInfo,
      'wasSuccessful': wasSuccessful,
    };
  }

  // JSONから作成
  factory ScoutingRecord.fromJson(Map<String, dynamic> json) {
    return ScoutingRecord(
      actionId: json['actionId'],
      visitDate: DateTime.parse(json['visitDate']),
      weekNumber: json['weekNumber'],
      accuracy: json['accuracy'].toDouble(),
      obtainedInfo: Map<String, dynamic>.from(json['obtainedInfo']),
      wasSuccessful: json['wasSuccessful'],
    );
  }

  @override
  String toString() {
    return 'ScoutingRecord(actionId: $actionId, weekNumber: $weekNumber, accuracy: $accuracy)';
  }
} 