// 球団からの要望タイプ
enum TeamRequestType {
  immediateImpact,    // 即戦力
  futureCleanup,      // 5年後のチームの4番
  futureSecond,       // 5年後のセカンド
  futureAce,          // 5年後のエース
  futureCloser,       // 5年後のクローザー
  futureLeadoff,      // 5年後の1番
  futureThird,        // 5年後の3番
  futureShortstop,    // 5年後のショート
}

// 球団からの要望
class TeamRequest {
  final String id;
  final TeamRequestType type;
  final String title;
  final String description;
  final DateTime deadline;
  final int reward; // 報酬
  final bool isCompleted;
  final String? completedPlayerId; // 完了時に推薦した選手ID
  
  TeamRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.deadline,
    required this.reward,
    this.isCompleted = false,
    this.completedPlayerId,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'title': title,
    'description': description,
    'deadline': deadline.toIso8601String(),
    'reward': reward,
    'isCompleted': isCompleted,
    'completedPlayerId': completedPlayerId,
  };
  
  factory TeamRequest.fromJson(Map<String, dynamic> json) => TeamRequest(
    id: json['id'] as String,
    type: TeamRequestType.values[json['type'] as int],
    title: json['title'] as String,
    description: json['description'] as String,
    deadline: DateTime.parse(json['deadline'] as String),
    reward: json['reward'] as int,
    isCompleted: json['isCompleted'] as bool? ?? false,
    completedPlayerId: json['completedPlayerId'] as String?,
  );
  
  // 期限が切れているかチェック
  bool get isExpired => DateTime.now().isAfter(deadline);
  
  // 残り日数を取得
  int get remainingDays => deadline.difference(DateTime.now()).inDays;
  
  // 完了済みのコピーを作成
  TeamRequest markAsCompleted(String playerId) {
    return TeamRequest(
      id: id,
      type: type,
      title: title,
      description: description,
      deadline: deadline,
      reward: reward,
      isCompleted: true,
      completedPlayerId: playerId,
    );
  }
}

// 球団要望管理クラス
class TeamRequestManager {
  final List<TeamRequest> requests;
  
  TeamRequestManager({List<TeamRequest>? requests}) : requests = requests ?? [];
  
  // 新しい要望を追加
  void addRequest(TeamRequest request) {
    requests.add(request);
  }
  
  // 期限が切れていない要望を取得
  List<TeamRequest> getActiveRequests() {
    return requests.where((request) => !request.isExpired && !request.isCompleted).toList();
  }
  
  // 完了済みの要望を取得
  List<TeamRequest> getCompletedRequests() {
    return requests.where((request) => request.isCompleted).toList();
  }
  
  // 期限切れの要望を取得
  List<TeamRequest> getExpiredRequests() {
    return requests.where((request) => request.isExpired && !request.isCompleted).toList();
  }
  
  // 要望を完了としてマーク
  void completeRequest(String requestId, String playerId) {
    final index = requests.indexWhere((request) => request.id == requestId);
    if (index != -1) {
      requests[index] = requests[index].markAsCompleted(playerId);
    }
  }
  
  // 要望を取得
  TeamRequest? getRequest(String requestId) {
    try {
      return requests.firstWhere((request) => request.id == requestId);
    } catch (e) {
      return null;
    }
  }
  
  // デフォルトの要望リストを生成
  static List<TeamRequest> generateDefaultRequests() {
    return [
      TeamRequest(
        id: 'req_001',
        type: TeamRequestType.immediateImpact,
        title: '即戦力選手の推薦',
        description: '今年のドラフトで即座に戦力として使える選手を推薦してください。',
        deadline: DateTime.now().add(Duration(days: 30)),
        reward: 50000,
      ),
      TeamRequest(
        id: 'req_002',
        type: TeamRequestType.futureCleanup,
        title: '5年後のチームの4番候補',
        description: '5年後にチームの4番打者として期待できる選手を推薦してください。',
        deadline: DateTime.now().add(Duration(days: 45)),
        reward: 80000,
      ),
      TeamRequest(
        id: 'req_003',
        type: TeamRequestType.futureSecond,
        title: '5年後のセカンド候補',
        description: '5年後にセカンドベースとして期待できる選手を推薦してください。',
        deadline: DateTime.now().add(Duration(days: 40)),
        reward: 60000,
      ),
      TeamRequest(
        id: 'req_004',
        type: TeamRequestType.futureAce,
        title: '5年後のエース候補',
        description: '5年後にチームのエースとして期待できる投手を推薦してください。',
        deadline: DateTime.now().add(Duration(days: 50)),
        reward: 100000,
      ),
    ];
  }
} 