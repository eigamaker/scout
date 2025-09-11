import 'dart:math';
import '../../models/player/player.dart';
import '../../models/school/school.dart';
import '../data_service.dart';
import '../talented_player_generator.dart';
import '../player_assignment_service.dart';

/// 選手管理に関する機能を担当するサービス
class PlayerManagementService {
  final DataService _dataService;

  PlayerManagementService(this._dataService);

  /// 全学校に初期生徒を生成してデータベースに挿入
  Future<void> generateInitialStudentsForAllSchools() async {
    print('PlayerManagementService: 全学校の初期生徒生成開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      // 全学校を取得
      final schools = await _dataService.getAllSchools();
      print('PlayerManagementService: ${schools.length}校の学校データを取得しました');
      
      int totalPlayersGenerated = 0;
      
      for (final school in schools) {
        final schoolId = school['id'] as int;
        final schoolName = school['name'] as String;
        final schoolType = school['type'] as String;
        final schoolLevel = school['level'] as int;
        
        print('PlayerManagementService: $schoolName の生徒生成開始');
        
        // 学校のレベルに応じて生徒数を決定
        final studentCount = _calculateStudentCount(schoolLevel, schoolType);
        
        // 各学年の生徒を生成
        for (int grade = 1; grade <= 3; grade++) {
          final gradeStudentCount = _calculateGradeStudentCount(studentCount, grade);
          await _generateStudentsForGrade(schoolId, schoolName, grade, gradeStudentCount);
          totalPlayersGenerated += gradeStudentCount;
        }
        
        print('PlayerManagementService: $schoolName の生徒生成完了 - 合計${studentCount}名');
      }
      
      stopwatch.stop();
      print('PlayerManagementService: 全学校の初期生徒生成完了 - 合計${totalPlayersGenerated}名 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('PlayerManagementService: 初期生徒生成エラー: $e');
      rethrow;
    }
  }

  /// 学校レベルとタイプに基づいて生徒数を計算
  int _calculateStudentCount(int schoolLevel, String schoolType) {
    // 学校レベルに基づく基本生徒数
    int baseCount = 20 + (schoolLevel * 5); // レベル1: 25名、レベル2: 30名、レベル3: 35名
    
    // 学校タイプによる調整
    switch (schoolType) {
      case '強豪校':
        baseCount = (baseCount * 1.2).round(); // 20%増加
        break;
      case '名門校':
        baseCount = (baseCount * 1.1).round(); // 10%増加
        break;
      case '普通校':
        // 基本数のまま
        break;
      case '弱小校':
        baseCount = (baseCount * 0.8).round(); // 20%減少
        break;
    }
    
    return baseCount.clamp(15, 50); // 最小15名、最大50名
  }

  /// 学年別の生徒数を計算
  int _calculateGradeStudentCount(int totalCount, int grade) {
    // 1年生: 40%, 2年生: 35%, 3年生: 25%
    final gradeRatios = [0.4, 0.35, 0.25];
    return (totalCount * gradeRatios[grade - 1]).round();
  }

  /// 指定学年の生徒を生成
  Future<void> _generateStudentsForGrade(int schoolId, String schoolName, int grade, int count) async {
    final random = Random();
    
    for (int i = 0; i < count; i++) {
      // 選手を生成
      final player = TalentedPlayerGenerator.generatePlayer(
        schoolId: schoolId,
        schoolName: schoolName,
        grade: grade,
        random: random,
      );
      
      // データベースに挿入
      await _dataService.insertPlayer(player);
    }
  }

  /// プロ野球選手をデータベースから読み込み
  Future<void> loadProfessionalPlayersFromDatabase() async {
    print('PlayerManagementService: プロ野球選手の読み込み開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      // プロ野球団を取得
      final teams = await _dataService.getAllProfessionalTeams();
      print('PlayerManagementService: ${teams.length}チームのプロ野球団を取得しました');
      
      int totalProPlayers = 0;
      
      for (final team in teams) {
        final teamId = team['id'] as String;
        final teamName = team['name'] as String;
        
        // チームのプロ選手を取得
        final players = await _dataService.getProfessionalPlayersByTeam(teamId);
        totalProPlayers += players.length;
        
        print('PlayerManagementService: $teamName - ${players.length}名のプロ選手を読み込み');
      }
      
      stopwatch.stop();
      print('PlayerManagementService: プロ野球選手の読み込み完了 - 合計${totalProPlayers}名 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('PlayerManagementService: プロ野球選手読み込みエラー: $e');
      rethrow;
    }
  }

  /// 選手を発掘済みとして登録
  Future<void> discoverPlayer(Player player) async {
    try {
      await _dataService.addDiscoveredPlayer(player.id!);
      print('PlayerManagementService: 選手を発掘済みとして登録: ${player.name}');
    } catch (e) {
      print('PlayerManagementService: 選手発掘登録エラー: $e');
      rethrow;
    }
  }

  /// 選手の能力値把握度を更新
  Future<void> updatePlayerKnowledge(Player player) async {
    try {
      await _dataService.updatePlayerKnowledge(player);
      print('PlayerManagementService: 選手の能力値把握度を更新: ${player.name}');
    } catch (e) {
      print('PlayerManagementService: 選手能力値把握度更新エラー: $e');
      rethrow;
    }
  }

  /// 選手データをデータベースから再読み込み
  Future<void> refreshPlayersFromDatabase() async {
    print('PlayerManagementService: 選手データの再読み込み開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      // 全学校の選手データを再読み込み
      final schools = await _dataService.getAllSchoolsWithPlayers();
      
      int totalPlayers = 0;
      for (final school in schools) {
        final players = school['players'] as List;
        totalPlayers += players.length;
      }
      
      stopwatch.stop();
      print('PlayerManagementService: 選手データの再読み込み完了 - 合計${totalPlayers}名 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('PlayerManagementService: 選手データ再読み込みエラー: $e');
      rethrow;
    }
  }
}
