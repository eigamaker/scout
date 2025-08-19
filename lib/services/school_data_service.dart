import 'package:sqflite/sqflite.dart';
import '../models/school/school.dart';
import 'default_school_data.dart';

/// 学校データのデータベース操作を専門に扱うサービス
class SchoolDataService {
  final Database _db;

  SchoolDataService(this._db);

  /// デフォルトの学校データをデータベースに挿入
  Future<void> insertDefaultSchools() async {
    try {
      // 既存の学校データを削除
      await _db.delete('School');
      
      // デフォルトの学校データを取得
      final schools = DefaultSchoolData.getAllSchools();
      
      // データベースに挿入
      for (final school in schools) {
        await _db.insert('School', {
          'name': school.name,
          'type': '高校',
          'location': school.location,
          'prefecture': school.prefecture,
          'rank': school.rank.name,
          'school_strength': 50,
          'last_year_strength': 50,
          'scouting_popularity': 50,
          'coach_trust': school.coachTrust,
          'coach_name': school.coachName,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      print('デフォルト学校データを${schools.length}校挿入しました');
    } catch (e) {
      print('学校データの挿入でエラー: $e');
      rethrow;
    }
  }

  /// データベースから学校データを取得
  Future<List<School>> getAllSchools() async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query('School');
      
      return maps.map((map) => School(
        id: map['id'] as int?,
        name: map['name'] as String,
        location: map['location'] as String,
        prefecture: map['prefecture'] as String,
        rank: SchoolRank.values.firstWhere((r) => r.name == map['rank']),
        players: [], // 選手は別途取得
        coachTrust: map['coach_trust'] as int? ?? 50,
        coachName: map['coach_name'] as String? ?? '未設定',
      )).toList();
    } catch (e) {
      print('学校データの取得でエラー: $e');
      rethrow;
    }
  }

  /// 都道府県別の学校データを取得
  Future<List<School>> getSchoolsByPrefecture(String prefecture) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'School',
        where: 'prefecture = ?',
        whereArgs: [prefecture],
      );
      
      return maps.map((map) => School(
        id: map['id'] as int?,
        name: map['name'] as String,
        location: map['location'] as String,
        prefecture: map['prefecture'] as String,
        rank: SchoolRank.values.firstWhere((r) => r.name == map['rank']),
        players: [], // 選手は別途取得
        coachTrust: map['coach_trust'] as int? ?? 50,
        coachName: map['coach_name'] as String? ?? '未設定',
      )).toList();
    } catch (e) {
      print('都道府県別学校データの取得でエラー: $e');
      rethrow;
    }
  }

  /// ランク別の学校データを取得
  Future<List<School>> getSchoolsByRank(SchoolRank rank) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'School',
        where: 'rank = ?',
        whereArgs: [rank.name],
      );
      
      return maps.map((map) => School(
        id: map['id'] as int?,
        name: map['name'] as String,
        location: map['location'] as String,
        prefecture: map['prefecture'] as String,
        rank: SchoolRank.values.firstWhere((r) => r.name == map['rank']),
        players: [], // 選手は別途取得
        coachTrust: map['coach_trust'] as int? ?? 50,
        coachName: map['coach_name'] as String? ?? '未設定',
      )).toList();
    } catch (e) {
      print('ランク別学校データの取得でエラー: $e');
      rethrow;
    }
  }

  /// 学校の統計情報を取得
  Future<Map<String, dynamic>> getSchoolStatistics() async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query('School');
      
      final totalSchools = maps.length;
      final rankCounts = <String, int>{};
      final prefectureCounts = <String, int>{};
      
      for (final map in maps) {
        final rank = map['rank'] as String;
        final prefecture = map['prefecture'] as String;
        
        rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
        prefectureCounts[prefecture] = (prefectureCounts[prefecture] ?? 0) + 1;
      }
      
      return {
        'total_schools': totalSchools,
        'rank_distribution': rankCounts,
        'prefecture_distribution': prefectureCounts,
      };
    } catch (e) {
      print('学校統計情報の取得でエラー: $e');
      rethrow;
    }
  }

  /// 学校データが存在するかチェック
  Future<bool> hasSchools() async {
    try {
      final result = await _db.rawQuery('SELECT COUNT(*) as count FROM School');
      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      print('学校データ存在チェックでエラー: $e');
      return false;
    }
  }
}
