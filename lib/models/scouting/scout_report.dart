import '../player/player.dart';

// スカウトレポートの更新タイプ
enum ScoutReportUpdateType {
  ability, // 能力値更新
  discovery, // 発掘
  evaluation, // 評価更新
  note, // メモ追加
  watch, // 注目設定
  favorite, // お気に入り設定
}

// スカウトレポートの更新履歴
class ScoutReportUpdate {
  final ScoutReportUpdateType type;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic>? data; // 更新データ
  
  ScoutReportUpdate({
    required this.type,
    required this.timestamp,
    required this.description,
    this.data,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type.index,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
    'data': data,
  };
  
  factory ScoutReportUpdate.fromJson(Map<String, dynamic> json) => ScoutReportUpdate(
    type: ScoutReportUpdateType.values[json['type']],
    timestamp: DateTime.parse(json['timestamp']),
    description: json['description'],
    data: json['data'],
  );
}

// スカウトレポート管理クラス
class ScoutReportManager {
  final Map<String, List<ScoutReportUpdate>> playerReports; // 選手ID -> レポート履歴
  final Map<String, DateTime> lastScoutDate; // 選手ID -> 最終スカウト日
  
  ScoutReportManager({
    Map<String, List<ScoutReportUpdate>>? playerReports,
    Map<String, DateTime>? lastScoutDate,
  }) : 
    playerReports = playerReports ?? {},
    lastScoutDate = lastScoutDate ?? {};
  
  // レポートを追加
  void addReport(String playerId, ScoutReportUpdate update) {
    if (!playerReports.containsKey(playerId)) {
      playerReports[playerId] = [];
    }
    playerReports[playerId]!.add(update);
    lastScoutDate[playerId] = update.timestamp;
  }
  
  // 選手の発掘レポートを追加
  void addDiscoveryReport(Player player, String scoutName) {
    final update = ScoutReportUpdate(
      type: ScoutReportUpdateType.discovery,
      timestamp: DateTime.now(),
      description: '${player.name}選手を発掘しました',
      data: {
        'playerName': player.name,
        'school': player.school,
        'position': player.position,
        'scoutName': scoutName,
      },
    );
    
    addReport(player.name, update);
  }
  
  // 能力値更新レポートを追加
  void addAbilityUpdateReport(Player player, String abilityName, int oldValue, int newValue) {
    final update = ScoutReportUpdate(
      type: ScoutReportUpdateType.ability,
      timestamp: DateTime.now(),
      description: '${player.name}選手の${abilityName}が${oldValue}から${newValue}に更新されました',
      data: {
        'abilityName': abilityName,
        'oldValue': oldValue,
        'newValue': newValue,
      },
    );
    
    addReport(player.name, update);
  }
  
  // 評価更新レポートを追加
  void addEvaluationReport(Player player, String evaluation, String notes) {
    final update = ScoutReportUpdate(
      type: ScoutReportUpdateType.evaluation,
      timestamp: DateTime.now(),
      description: '${player.name}選手の評価を更新しました',
      data: {
        'evaluation': evaluation,
        'notes': notes,
      },
    );
    
    addReport(player.name, update);
  }
  
  // メモ追加レポートを追加
  void addNoteReport(Player player, String note) {
    final update = ScoutReportUpdate(
      type: ScoutReportUpdateType.note,
      timestamp: DateTime.now(),
      description: '${player.name}選手にメモを追加しました',
      data: {
        'note': note,
      },
    );
    
    addReport(player.name, update);
  }
  
  // 注目設定レポートを追加
  void addWatchReport(Player player, bool isWatched) {
    final update = ScoutReportUpdate(
      type: ScoutReportUpdateType.watch,
      timestamp: DateTime.now(),
      description: isWatched 
        ? '${player.name}選手を注目選手に設定しました'
        : '${player.name}選手の注目設定を解除しました',
      data: {
        'isWatched': isWatched,
      },
    );
    
    addReport(player.name, update);
  }
  
  // お気に入り設定レポートを追加
  void addFavoriteReport(Player player, bool isFavorite) {
    final update = ScoutReportUpdate(
      type: ScoutReportUpdateType.favorite,
      timestamp: DateTime.now(),
      description: isFavorite 
        ? '${player.name}選手をお気に入りに設定しました'
        : '${player.name}選手のお気に入り設定を解除しました',
      data: {
        'isFavorite': isFavorite,
      },
    );
    
    addReport(player.name, update);
  }
  
  // 選手のレポート履歴を取得
  List<ScoutReportUpdate> getPlayerReports(String playerId) {
    return playerReports[playerId] ?? [];
  }
  
  // 選手の最終スカウト日を取得
  DateTime? getLastScoutDate(String playerId) {
    return lastScoutDate[playerId];
  }
  
  // 選手がスカウト済みかどうか
  bool isPlayerScouted(String playerId) {
    return lastScoutDate.containsKey(playerId);
  }
  
  // 最近のレポートを取得（指定日数以内）
  List<ScoutReportUpdate> getRecentReports(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentUpdates = <ScoutReportUpdate>[];
    
    for (final reports in playerReports.values) {
      for (final report in reports) {
        if (report.timestamp.isAfter(cutoffDate)) {
          recentUpdates.add(report);
        }
      }
    }
    
    // 日時順にソート
    recentUpdates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return recentUpdates;
  }
  
  // 発掘レポートのみを取得
  List<ScoutReportUpdate> getDiscoveryReports() {
    final discoveryUpdates = <ScoutReportUpdate>[];
    
    for (final reports in playerReports.values) {
      for (final report in reports) {
        if (report.type == ScoutReportUpdateType.discovery) {
          discoveryUpdates.add(report);
        }
      }
    }
    
    // 日時順にソート
    discoveryUpdates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return discoveryUpdates;
  }

  Map<String, dynamic> toJson() => {
    'playerReports': playerReports.map(
      (key, value) => MapEntry(key, value.map((r) => r.toJson()).toList())
    ),
    'lastScoutDate': lastScoutDate.map(
      (key, value) => MapEntry(key, value.toIso8601String())
    ),
  };

  factory ScoutReportManager.fromJson(Map<String, dynamic> json) {
    final playerReports = <String, List<ScoutReportUpdate>>{};
    final lastScoutDate = <String, DateTime>{};
    
    // playerReportsの復元
    final reportsMap = json['playerReports'] as Map<String, dynamic>;
    for (final entry in reportsMap.entries) {
      final reports = (entry.value as List)
        .map((r) => ScoutReportUpdate.fromJson(r))
        .toList();
      playerReports[entry.key] = reports;
    }
    
    // lastScoutDateの復元
    final dateMap = json['lastScoutDate'] as Map<String, dynamic>;
    for (final entry in dateMap.entries) {
      lastScoutDate[entry.key] = DateTime.parse(entry.value);
    }
    
    return ScoutReportManager(
      playerReports: playerReports,
      lastScoutDate: lastScoutDate,
    );
  }
} 