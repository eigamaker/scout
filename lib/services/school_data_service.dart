import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/school/school.dart';
 // Stopwatchを使用するために追加

/// 学校データのデータベース操作を専門に扱うサービス
class SchoolDataService {
  final Database _db;

  SchoolDataService(this._db);


  /// CSVファイルから学校データをデータベースに挿入
  Future<void> insertSchoolsFromCsv() async {
    try {
      final stopwatch = Stopwatch()..start();
      print('SchoolDataService.insertSchoolsFromCsv: 開始');
      
      // 既存の学校データを削除
      final deleteStart = Stopwatch()..start();
      await _db.delete('School');
      deleteStart.stop();
      print('SchoolDataService.insertSchoolsFromCsv: 既存データ削除完了 - ${deleteStart.elapsedMilliseconds}ms');
      
      // CSVファイルをアセットから読み込み
      final csvReadStart = Stopwatch()..start();
      final csvContent = await rootBundle.loadString('assets/data/School.csv');
      final lines = csvContent.split('\n');
      csvReadStart.stop();
      print('SchoolDataService.insertSchoolsFromCsv: CSV読み込み完了 - ${csvReadStart.elapsedMilliseconds}ms (${lines.length}行)');
      
      // ヘッダー行をスキップ
      final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
      print('SchoolDataService.insertSchoolsFromCsv: データ行数: ${dataLines.length}');
      
      // 事前にデータを準備（最適化版）
      final dataPrepStart = Stopwatch()..start();
      final List<Map<String, dynamic>> allData = [];
      final now = DateTime.now().toIso8601String(); // 一度だけ生成
      
      // ランク変換マップを事前定義
      final rankMap = {
        '名門': SchoolRank.elite.name,
        '強豪': SchoolRank.strong.name,
        '中堅': SchoolRank.average.name,
        '弱小': SchoolRank.weak.name,
      };
      
      for (final line in dataLines) {
        final fields = line.split(',');
        if (fields.length >= 7) {
          try {
            // CSVの各フィールドを取得（trimを最小限に）
            final id = fields[0].trim();
            final name = fields[1].trim();
            final type = fields[2].trim();
            final location = fields[3].trim();
            final prefecture = fields[4].trim();
            final rankStr = fields[5].trim();
            final schoolStrength = int.tryParse(fields[6].trim()) ?? 50;
            
            // ランクの変換（マップを使用）
            final rank = rankMap[rankStr] ?? SchoolRank.weak.name;
            
            // データをリストに追加
            allData.add({
              'id': id,
              'name': name,
              'type': type,
              'location': location,
              'prefecture': prefecture,
              'rank': rank,
              'school_strength': schoolStrength,
              'created_at': now,
              'updated_at': now,
            });
          } catch (e) {
            print('CSV行の処理でエラー: $line, エラー: $e');
            // エラーが発生しても処理を続行
          }
        }
      }
      dataPrepStart.stop();
      print('SchoolDataService.insertSchoolsFromCsv: データ準備完了 - ${dataPrepStart.elapsedMilliseconds}ms (${allData.length}件)');
      
      // より効率的なバッチ挿入実行（大きなバッチサイズで分割）
      final insertStart = Stopwatch()..start();
      const int batchSize = 500; // 500件ずつバッチ処理（より大きなバッチサイズ）
      int totalInserted = 0;
      
      for (int i = 0; i < allData.length; i += batchSize) {
        final end = (i + batchSize < allData.length) ? i + batchSize : allData.length;
        final batch = allData.sublist(i, end);
        
        await _db.transaction((txn) async {
          for (final data in batch) {
            await txn.insert('School', data);
          }
        });
        
        totalInserted += batch.length;
        print('SchoolDataService.insertSchoolsFromCsv: バッチ挿入進捗: $totalInserted/${allData.length}件完了');
      }
      
      insertStart.stop();
      print('SchoolDataService.insertSchoolsFromCsv: バッチ挿入完了 - ${insertStart.elapsedMilliseconds}ms');
      
      stopwatch.stop();
      print('SchoolDataService.insertSchoolsFromCsv: 全体完了 - ${stopwatch.elapsedMilliseconds}ms (${totalInserted}校挿入)');
    } catch (e) {
      print('CSVからの学校データ挿入でエラー: $e');
      rethrow;
    }
  }


  /// データベースから学校データを取得
  Future<List<School>> getAllSchools() async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query('School');
      
      return maps.map((map) => School(
        id: map['id']?.toString() ?? '',
        name: map['name'] as String,
        shortName: _generateShortName(map['name'] as String),
        location: map['location'] as String,
        prefecture: map['prefecture'] as String,
        rank: SchoolRank.values.firstWhere((r) => r.name == map['rank']),
        players: [], // 選手は別途取得
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
        id: map['id']?.toString() ?? '',
        name: map['name'] as String,
        shortName: _generateShortName(map['name'] as String),
        location: map['location'] as String,
        prefecture: map['prefecture'] as String,
        rank: SchoolRank.values.firstWhere((r) => r.name == map['rank']),
        players: [], // 選手は別途取得
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
        id: map['id']?.toString() ?? '',
        name: map['name'] as String,
        shortName: _generateShortName(map['name'] as String),
        location: map['location'] as String,
        prefecture: map['prefecture'] as String,
        rank: SchoolRank.values.firstWhere((r) => r.name == map['rank']),
        players: [], // 選手は別途取得
      )).toList();
    } catch (e) {
      print('ランク別学校データの取得でエラー: $e');
      rethrow;
    }
  }

  /// 学校名から略称を生成
  String _generateShortName(String fullName) {
    // 「高等学校」「高校」「学園」「学院」を除去
    String shortName = fullName
        .replaceAll('高等学校', '')
        .replaceAll('高校', '')
        .replaceAll('学園', '')
        .replaceAll('学院', '');
    
    // 「県立」「市立」「私立」「国立」「都立」「府立」「町立」「村立」を除去
    shortName = shortName
        .replaceAll('県立', '')
        .replaceAll('市立', '')
        .replaceAll('私立', '')
        .replaceAll('国立', '')
        .replaceAll('都立', '')
        .replaceAll('府立', '')
        .replaceAll('町立', '')
        .replaceAll('村立', '');
    
    return shortName.isEmpty ? fullName : shortName;
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
