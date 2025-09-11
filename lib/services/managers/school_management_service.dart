import '../../models/school/school.dart';
import '../../models/player/player.dart';
import '../data_service.dart';
import '../school_data_service.dart';
import '../default_school_data.dart';

/// 学校管理に関する機能を担当するサービス
class SchoolManagementService {
  final DataService _dataService;
  final SchoolDataService _schoolDataService;

  SchoolManagementService(this._dataService, this._schoolDataService);

  /// 初期学校データを生成してデータベースに挿入
  Future<void> generateInitialSchools() async {
    print('SchoolManagementService: 初期学校データ生成開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      // デフォルト学校データを取得
      final defaultSchools = DefaultSchoolData.getDefaultSchools();
      print('SchoolManagementService: ${defaultSchools.length}校のデフォルト学校データを取得しました');
      
      // 各学校をデータベースに挿入
      for (final schoolData in defaultSchools) {
        await _dataService.insertSchool(schoolData);
        print('SchoolManagementService: 学校を挿入: ${schoolData['name']}');
      }
      
      stopwatch.stop();
      print('SchoolManagementService: 初期学校データ生成完了 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('SchoolManagementService: 初期学校データ生成エラー: $e');
      rethrow;
    }
  }

  /// 全学校のデータを取得
  Future<List<Map<String, dynamic>>> getAllSchools() async {
    try {
      return await _dataService.getAllSchools();
    } catch (e) {
      print('SchoolManagementService: 全学校データ取得エラー: $e');
      rethrow;
    }
  }

  /// 全学校のデータを選手情報と共に取得
  Future<List<Map<String, dynamic>>> getAllSchoolsWithPlayers() async {
    try {
      return await _dataService.getAllSchoolsWithPlayers();
    } catch (e) {
      print('SchoolManagementService: 全学校データ（選手含む）取得エラー: $e');
      rethrow;
    }
  }

  /// 指定された学校のデータを取得
  Future<Map<String, dynamic>?> getSchoolById(int schoolId) async {
    try {
      return await _dataService.getSchoolById(schoolId);
    } catch (e) {
      print('SchoolManagementService: 学校データ取得エラー: $e');
      rethrow;
    }
  }

  /// 指定された学校の選手データを取得
  Future<List<Map<String, dynamic>>> getSchoolPlayers(int schoolId) async {
    try {
      return await _dataService.getSchoolPlayers(schoolId);
    } catch (e) {
      print('SchoolManagementService: 学校選手データ取得エラー: $e');
      rethrow;
    }
  }

  /// 学校の情報を更新
  Future<void> updateSchoolInfo(int schoolId, Map<String, dynamic> updates) async {
    try {
      await _dataService.updateSchool(schoolId, updates);
      print('SchoolManagementService: 学校情報を更新: ID $schoolId');
    } catch (e) {
      print('SchoolManagementService: 学校情報更新エラー: $e');
      rethrow;
    }
  }

  /// 学校の強さを計算
  int calculateSchoolStrength(List<Player> players) {
    if (players.isEmpty) return 0;
    
    // 選手の総合能力値の平均を学校の強さとする
    final totalAbility = players.fold<int>(0, (sum, player) => sum + player.overall);
    return (totalAbility / players.length).round();
  }

  /// 学校のランキングを取得
  Future<List<Map<String, dynamic>>> getSchoolRankings() async {
    try {
      final schools = await getAllSchoolsWithPlayers();
      final rankings = <Map<String, dynamic>>[];
      
      for (final schoolData in schools) {
        final players = schoolData['players'] as List;
        final playerObjects = players.map((p) => Player.fromJson(Map<String, dynamic>.from(p))).toList();
        
        final strength = calculateSchoolStrength(playerObjects);
        
        rankings.add({
          'schoolId': schoolData['id'],
          'schoolName': schoolData['name'],
          'strength': strength,
          'playerCount': players.length,
        });
      }
      
      // 強さでソート
      rankings.sort((a, b) => (b['strength'] as int).compareTo(a['strength'] as int));
      
      return rankings;
    } catch (e) {
      print('SchoolManagementService: 学校ランキング取得エラー: $e');
      return [];
    }
  }

  /// 学校の統計情報を取得
  Future<Map<String, dynamic>> getSchoolStatistics(int schoolId) async {
    try {
      final schoolData = await getSchoolById(schoolId);
      if (schoolData == null) {
        throw Exception('学校が見つかりません: ID $schoolId');
      }
      
      final players = await getSchoolPlayers(schoolId);
      final playerObjects = players.map((p) => Player.fromJson(Map<String, dynamic>.from(p))).toList();
      
      // 基本統計
      final totalPlayers = playerObjects.length;
      final grade1Players = playerObjects.where((p) => p.grade == 1).length;
      final grade2Players = playerObjects.where((p) => p.grade == 2).length;
      final grade3Players = playerObjects.where((p) => p.grade == 3).length;
      
      // 能力値統計
      final overallAbilities = playerObjects.map((p) => p.overall).toList();
      final averageOverall = overallAbilities.isEmpty ? 0 : overallAbilities.reduce((a, b) => a + b) / overallAbilities.length;
      final maxOverall = overallAbilities.isEmpty ? 0 : overallAbilities.reduce((a, b) => a > b ? a : b);
      final minOverall = overallAbilities.isEmpty ? 0 : overallAbilities.reduce((a, b) => a < b ? a : b);
      
      // ポジション別統計
      final positionCounts = <String, int>{};
      for (final player in playerObjects) {
        positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
      }
      
      return {
        'schoolId': schoolId,
        'schoolName': schoolData['name'],
        'totalPlayers': totalPlayers,
        'grade1Players': grade1Players,
        'grade2Players': grade2Players,
        'grade3Players': grade3Players,
        'averageOverall': averageOverall.round(),
        'maxOverall': maxOverall,
        'minOverall': minOverall,
        'positionCounts': positionCounts,
        'strength': calculateSchoolStrength(playerObjects),
      };
    } catch (e) {
      print('SchoolManagementService: 学校統計情報取得エラー: $e');
      rethrow;
    }
  }

  /// 学校の選手を学年別に取得
  Future<Map<int, List<Player>>> getSchoolPlayersByGrade(int schoolId) async {
    try {
      final players = await getSchoolPlayers(schoolId);
      final playerObjects = players.map((p) => Player.fromJson(Map<String, dynamic>.from(p))).toList();
      
      final playersByGrade = <int, List<Player>>{};
      for (int grade = 1; grade <= 3; grade++) {
        playersByGrade[grade] = playerObjects.where((p) => p.grade == grade).toList();
      }
      
      return playersByGrade;
    } catch (e) {
      print('SchoolManagementService: 学年別選手データ取得エラー: $e');
      return {};
    }
  }

  /// 学校の選手をポジション別に取得
  Future<Map<String, List<Player>>> getSchoolPlayersByPosition(int schoolId) async {
    try {
      final players = await getSchoolPlayers(schoolId);
      final playerObjects = players.map((p) => Player.fromJson(Map<String, dynamic>.from(p))).toList();
      
      final playersByPosition = <String, List<Player>>{};
      for (final player in playerObjects) {
        if (!playersByPosition.containsKey(player.position)) {
          playersByPosition[player.position] = [];
        }
        playersByPosition[player.position]!.add(player);
      }
      
      return playersByPosition;
    } catch (e) {
      print('SchoolManagementService: ポジション別選手データ取得エラー: $e');
      return {};
    }
  }
}
