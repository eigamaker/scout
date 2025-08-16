import 'package:flutter/foundation.dart';
import '../player/player.dart';

// プロ野球選手の契約タイプ
enum ContractType {
  regular,    // 支配下選手
  minor,      // 育成選手
  freeAgent,  // フリーエージェント
}

// プロ野球選手クラス
class ProfessionalPlayer {
  final int? id;
  final int playerId; // PlayerテーブルのID
  final String teamId; // ProfessionalTeamテーブルのID
  final int contractYear; // 契約年数
  final int salary; // 年俸（万円）
  final ContractType contractType;
  final int draftYear; // ドラフト年
  final int draftRound; // ドラフト回数
  final int draftPosition; // ドラフト順位
  final bool isActive; // 現役かどうか
  final DateTime joinedAt; // 入団日
  final DateTime? leftAt; // 退団日
  final DateTime createdAt;
  final DateTime updatedAt;

  // 関連データ
  final Player? player;
  final String? teamName;
  final String? teamShortName;

  ProfessionalPlayer({
    this.id,
    required this.playerId,
    required this.teamId,
    required this.contractYear,
    required this.salary,
    required this.contractType,
    required this.draftYear,
    required this.draftRound,
    required this.draftPosition,
    this.isActive = true,
    required this.joinedAt,
    this.leftAt,
    required this.createdAt,
    required this.updatedAt,
    this.player,
    this.teamName,
    this.teamShortName,
  });

  // 契約タイプの文字列表現
  String get contractTypeText {
    switch (contractType) {
      case ContractType.regular:
        return '支配下';
      case ContractType.minor:
        return '育成';
      case ContractType.freeAgent:
        return 'FA';
    }
  }

  // ドラフト情報の文字列表現
  String get draftInfo {
    return '${draftYear}年 ${draftRound}回目 ${draftPosition}位';
  }

  // 在籍年数
  int get yearsInTeam {
    final now = DateTime.now();
    final endDate = leftAt ?? now;
    return endDate.difference(joinedAt).inDays ~/ 365;
  }

  // 年俸レベルの文字列表現
  String get salaryLevel {
    if (salary >= 10000) return '億円級';
    if (salary >= 5000) return '高額';
    if (salary >= 2000) return '中額';
    if (salary >= 1000) return '標準';
    return '低額';
  }

  // JSON変換
  Map<String, dynamic> toJson() => {
    'id': id,
    'player_id': playerId,
    'team_id': teamId,
    'contract_year': contractYear,
    'salary': salary,
    'contract_type': contractType.index,
    'draft_year': draftYear,
    'draft_round': draftRound,
    'draft_position': draftPosition,
    'is_active': isActive ? 1 : 0,
    'joined_at': joinedAt.toIso8601String(),
    'left_at': leftAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ProfessionalPlayer.fromJson(Map<String, dynamic> json) {
    return ProfessionalPlayer(
      id: json['id'] as int?,
      playerId: json['player_id'] as int,
      teamId: json['team_id'] as String,
      contractYear: json['contract_year'] as int,
      salary: json['salary'] as int,
      contractType: ContractType.values[json['contract_type'] as int],
      draftYear: json['draft_year'] as int,
      draftRound: json['draft_round'] as int,
      draftPosition: json['draft_position'] as int,
      isActive: (json['is_active'] as int) == 1,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // コピーメソッド
  ProfessionalPlayer copyWith({
    int? id,
    int? playerId,
    String? teamId,
    int? contractYear,
    int? salary,
    ContractType? contractType,
    int? draftYear,
    int? draftRound,
    int? draftPosition,
    bool? isActive,
    DateTime? joinedAt,
    DateTime? leftAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Player? player,
    String? teamName,
    String? teamShortName,
  }) {
    return ProfessionalPlayer(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      contractYear: contractYear ?? this.contractYear,
      salary: salary ?? this.salary,
      contractType: contractType ?? this.contractType,
      draftYear: draftYear ?? this.draftYear,
      draftRound: draftRound ?? this.draftRound,
      draftPosition: draftPosition ?? this.draftPosition,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      player: player ?? this.player,
      teamName: teamName ?? this.teamName,
      teamShortName: teamShortName ?? this.teamShortName,
    );
  }

  // 契約更新
  ProfessionalPlayer renewContract({
    required int newContractYear,
    required int newSalary,
    ContractType? newContractType,
  }) {
    return copyWith(
      contractYear: newContractYear,
      salary: newSalary,
      contractType: newContractType ?? contractType,
      updatedAt: DateTime.now(),
    );
  }

  // 退団処理
  ProfessionalPlayer leaveTeam() {
    return copyWith(
      isActive: false,
      leftAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // 移籍処理
  ProfessionalPlayer transferToTeam({
    required String newTeamId,
    required int newContractYear,
    required int newSalary,
    ContractType? newContractType,
  }) {
    return copyWith(
      teamId: newTeamId,
      contractYear: newContractYear,
      salary: newSalary,
      contractType: newContractType ?? contractType,
      joinedAt: DateTime.now(),
      leftAt: null,
      isActive: true,
      updatedAt: DateTime.now(),
    );
  }
}

// プロ野球選手管理クラス
class ProfessionalPlayerManager {
  final List<ProfessionalPlayer> players;
  
  ProfessionalPlayerManager({List<ProfessionalPlayer>? players}) : players = players ?? [];

  // 全プロ選手を取得
  List<ProfessionalPlayer> getAllPlayers() => players;

  // 特定の球団の選手を取得
  List<ProfessionalPlayer> getPlayersByTeam(String teamId) {
    return players.where((player) => player.teamId == teamId && player.isActive).toList();
  }

  // 特定の選手を取得
  ProfessionalPlayer? getPlayer(int playerId) {
    try {
      return players.firstWhere((player) => player.playerId == playerId);
    } catch (e) {
      return null;
    }
    return null;
  }

  // ドラフト年別の選手を取得
  List<ProfessionalPlayer> getPlayersByDraftYear(int year) {
    return players.where((player) => player.draftYear == year).toList();
  }

  // 年俸順にソート
  List<ProfessionalPlayer> getPlayersBySalary() {
    final sortedPlayers = List<ProfessionalPlayer>.from(players);
    sortedPlayers.sort((a, b) => b.salary.compareTo(a.salary));
    return sortedPlayers;
  }

  // 在籍年数順にソート
  List<ProfessionalPlayer> getPlayersByYearsInTeam() {
    final sortedPlayers = List<ProfessionalPlayer>.from(players);
    sortedPlayers.sort((a, b) => b.yearsInTeam.compareTo(a.yearsInTeam));
    return sortedPlayers;
  }

  // 選手を追加
  void addPlayer(ProfessionalPlayer player) {
    if (!players.any((p) => p.playerId == player.playerId)) {
      players.add(player);
    }
  }

  // 選手を更新
  void updatePlayer(ProfessionalPlayer updatedPlayer) {
    final index = players.indexWhere((player) => player.id == updatedPlayer.id);
    if (index != -1) {
      players[index] = updatedPlayer;
    }
  }

  // 選手を削除
  void removePlayer(int playerId) {
    players.removeWhere((player) => player.playerId == playerId);
  }

  // 球団の総年俸を計算
  int getTeamTotalSalary(String teamId) {
    return players
        .where((player) => player.teamId == teamId && player.isActive)
        .fold(0, (sum, player) => sum + player.salary);
  }

  // 球団の選手数を取得
  int getTeamPlayerCount(String teamId) {
    return players.where((player) => player.teamId == teamId && player.isActive).length;
  }

  // 契約タイプ別の選手数を取得
  Map<ContractType, int> getContractTypeCounts(String teamId) {
    final teamPlayers = players.where((player) => player.teamId == teamId && player.isActive);
    final counts = <ContractType, int>{};
    
    for (final type in ContractType.values) {
      counts[type] = teamPlayers.where((player) => player.contractType == type).length;
    }
    
    return counts;
  }
}
