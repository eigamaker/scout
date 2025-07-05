import 'package:flutter/material.dart';

// レポート更新の種類
enum ReportUpdateType {
  playerDiscovered,    // 選手発見
  playerEvaluated,     // 選手評価更新
  schoolVisited,       // 学校視察
  gameWatched,         // 試合観戦
  interviewConducted,  // インタビュー実施
  videoAnalyzed,       // ビデオ分析
  teamVisited,         // 球団訪問
  infoExchanged,       // 情報交換
}

// レポート更新情報
class ScoutReportUpdate {
  final String id;
  final ReportUpdateType type;
  final String title;
  final String description;
  final String? schoolName;
  final String? playerName;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? additionalData;

  ScoutReportUpdate({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.schoolName,
    this.playerName,
    required this.timestamp,
    this.isRead = false,
    this.additionalData,
  });

  // JSON変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'title': title,
    'description': description,
    'schoolName': schoolName,
    'playerName': playerName,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'additionalData': additionalData,
  };

  factory ScoutReportUpdate.fromJson(Map<String, dynamic> json) => ScoutReportUpdate(
    id: json['id'],
    type: ReportUpdateType.values.firstWhere(
      (e) => e.toString() == json['type'],
    ),
    title: json['title'],
    description: json['description'],
    schoolName: json['schoolName'],
    playerName: json['playerName'],
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] ?? false,
    additionalData: json['additionalData'],
  );

  // アイコンを取得
  IconData getIcon() {
    switch (type) {
      case ReportUpdateType.playerDiscovered:
        return Icons.person_add;
      case ReportUpdateType.playerEvaluated:
        return Icons.assessment;
      case ReportUpdateType.schoolVisited:
        return Icons.school;
      case ReportUpdateType.gameWatched:
        return Icons.sports_baseball;
      case ReportUpdateType.interviewConducted:
        return Icons.chat;
      case ReportUpdateType.videoAnalyzed:
        return Icons.video_library;
      case ReportUpdateType.teamVisited:
        return Icons.business;
      case ReportUpdateType.infoExchanged:
        return Icons.info;
    }
  }

  // 色を取得
  Color getColor() {
    switch (type) {
      case ReportUpdateType.playerDiscovered:
        return Colors.green;
      case ReportUpdateType.playerEvaluated:
        return Colors.blue;
      case ReportUpdateType.schoolVisited:
        return Colors.orange;
      case ReportUpdateType.gameWatched:
        return Colors.purple;
      case ReportUpdateType.interviewConducted:
        return Colors.teal;
      case ReportUpdateType.videoAnalyzed:
        return Colors.indigo;
      case ReportUpdateType.teamVisited:
        return Colors.red;
      case ReportUpdateType.infoExchanged:
        return Colors.amber;
    }
  }
}

// スカウトレポート管理クラス
class ScoutReportManager {
  List<ScoutReportUpdate> _reports = [];
  Map<String, bool> _updatedSchools = {};
  Map<String, bool> _updatedPlayers = {};

  ScoutReportManager();

  // レポートを追加
  void addReport(ScoutReportUpdate report) {
    _reports.add(report);
    
    // 学校と選手の更新フラグを設定
    if (report.schoolName != null) {
      _updatedSchools[report.schoolName!] = true;
    }
    if (report.playerName != null) {
      _updatedPlayers[report.playerName!] = true;
    }
  }

  // 未読レポートを取得
  List<ScoutReportUpdate> getUnreadReports() {
    return _reports.where((report) => !report.isRead).toList();
  }

  // 全レポートを取得
  List<ScoutReportUpdate> getAllReports() {
    return List.from(_reports);
  }

  // 学校の更新フラグを確認
  bool isSchoolUpdated(String schoolName) {
    return _updatedSchools[schoolName] ?? false;
  }

  // 選手の更新フラグを確認
  bool isPlayerUpdated(String playerName) {
    return _updatedPlayers[playerName] ?? false;
  }

  // レポートを既読にする
  void markAsRead(String reportId) {
    final report = _reports.firstWhere((r) => r.id == reportId);
    final index = _reports.indexOf(report);
    _reports[index] = ScoutReportUpdate(
      id: report.id,
      type: report.type,
      title: report.title,
      description: report.description,
      schoolName: report.schoolName,
      playerName: report.playerName,
      timestamp: report.timestamp,
      isRead: true,
      additionalData: report.additionalData,
    );
  }

  // 学校の更新フラグをクリア
  void clearSchoolUpdate(String schoolName) {
    _updatedSchools[schoolName] = false;
  }

  // 選手の更新フラグをクリア
  void clearPlayerUpdate(String playerName) {
    _updatedPlayers[playerName] = false;
  }

  // 全更新フラグをクリア
  void clearAllUpdates() {
    _updatedSchools.clear();
    _updatedPlayers.clear();
  }

  // 未読レポート数を取得
  int getUnreadCount() {
    return _reports.where((report) => !report.isRead).length;
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'reports': _reports.map((r) => r.toJson()).toList(),
    'updatedSchools': _updatedSchools,
    'updatedPlayers': _updatedPlayers,
  };

  factory ScoutReportManager.fromJson(Map<String, dynamic> json) {
    final manager = ScoutReportManager();
    manager._reports = (json['reports'] as List?)
        ?.map((r) => ScoutReportUpdate.fromJson(r))
        .toList() ?? [];
    manager._updatedSchools = Map<String, bool>.from(json['updatedSchools'] ?? {});
    manager._updatedPlayers = Map<String, bool>.from(json['updatedPlayers'] ?? {});
    return manager;
  }
} 