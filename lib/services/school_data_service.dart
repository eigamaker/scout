import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/school/school.dart';
import 'default_school_data.dart';
import 'dart:io'; // Stopwatchを使用するために追加
import 'dart:convert'; // JSONデコード用

/// 学校データのデータベース操作を専門に扱うサービス
class SchoolDataService {
  final Database _db;

  SchoolDataService(this._db);

  /// JSONファイルから学校データをデータベースに挿入
  Future<void> insertSchoolsFromJson() async {
    try {
      final stopwatch = Stopwatch()..start();
      print('SchoolDataService.insertSchoolsFromJson: 開始');
      
      // 既存の学校データを削除
      final deleteStart = Stopwatch()..start();
      await _db.delete('School');
      deleteStart.stop();
      print('SchoolDataService.insertSchoolsFromJson: 既存データ削除完了 - ${deleteStart.elapsedMilliseconds}ms');
      
      // JSONファイルをアセットから読み込み
      final jsonReadStart = Stopwatch()..start();
      final jsonContent = await rootBundle.loadString('assets/data/schools.json');
      final List<dynamic> jsonData = jsonDecode(jsonContent);
      jsonReadStart.stop();
      print('SchoolDataService.insertSchoolsFromJson: JSON読み込み完了 - ${jsonReadStart.elapsedMilliseconds}ms (${jsonData.length}件)');
      
      // 事前にデータを準備
      final dataPrepStart = Stopwatch()..start();
      final List<Map<String, dynamic>> allData = [];
      
      for (final schoolData in jsonData) {
        try {
          // ランクの変換
          SchoolRank rank;
          switch (schoolData['rank']) {
            case '名門':
              rank = SchoolRank.elite;
              break;
            case '強豪':
              rank = SchoolRank.strong;
              break;
            case '中堅':
              rank = SchoolRank.average;
              break;
            case '弱小':
              rank = SchoolRank.weak;
              break;
            default:
              rank = SchoolRank.weak;
          }
          
          // データをリストに追加
          allData.add({
            'id': schoolData['id'],
            'name': schoolData['name'],
            'type': schoolData['type'],
            'location': schoolData['location'],
            'prefecture': schoolData['prefecture'],
            'rank': rank.name,
            'school_strength': schoolData['school_strength'],
            'coach_trust': schoolData['coach_trust'],
            'coach_name': schoolData['coach_name'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('JSONデータの処理でエラー: $schoolData, エラー: $e');
        }
      }
      
      dataPrepStart.stop();
      print('SchoolDataService.insertSchoolsFromJson: データ準備完了 - ${dataPrepStart.elapsedMilliseconds}ms (${allData.length}件)');
      
      // より効率的なバッチ挿入実行（大きなバッチサイズで分割）
      final insertStart = Stopwatch()..start();
      const int batchSize = 200; // 200件ずつバッチ処理
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
        print('SchoolDataService.insertSchoolsFromJson: バッチ挿入進捗: $totalInserted/${allData.length}件完了');
      }
      
      insertStart.stop();
      print('SchoolDataService.insertSchoolsFromJson: バッチ挿入完了 - ${insertStart.elapsedMilliseconds}ms');
      
      stopwatch.stop();
      print('SchoolDataService.insertSchoolsFromJson: 全体完了 - ${stopwatch.elapsedMilliseconds}ms (${totalInserted}校挿入)');
    } catch (e) {
      print('JSONからの学校データ挿入でエラー: $e');
      rethrow;
    }
  }

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
      
      // 事前にデータを準備
      final dataPrepStart = Stopwatch()..start();
      final List<Map<String, dynamic>> allData = [];
      
      for (final line in dataLines) {
        final fields = line.split(',');
        if (fields.length >= 9) {
          try {
            // CSVの各フィールドを取得
            final id = fields[0].trim();
            final name = fields[1].trim();
            final type = fields[2].trim();
            final location = fields[3].trim();
            final prefecture = fields[4].trim();
            final rankStr = fields[5].trim();
            final schoolStrength = int.tryParse(fields[6].trim()) ?? 50;
            final coachTrust = int.tryParse(fields[7].trim()) ?? 0;
            final coachName = fields[8].trim();
            
            // ランクの変換
            SchoolRank rank;
            switch (rankStr) {
              case '名門':
                rank = SchoolRank.elite;
                break;
              case '強豪':
                rank = SchoolRank.strong;
                break;
              case '中堅':
                rank = SchoolRank.average;
                break;
              case '弱小':
                rank = SchoolRank.weak;
                break;
              default:
                rank = SchoolRank.weak; // デフォルトは弱小
            }
            
            // データをリストに追加
            allData.add({
              'id': id,
              'name': name,
              'type': type,
              'location': location,
              'prefecture': prefecture,
              'rank': rank.name,
              'school_strength': schoolStrength,
              'coach_trust': coachTrust,
              'coach_name': coachName,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
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
      const int batchSize = 200; // 200件ずつバッチ処理（より大きなバッチサイズ）
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

  /// デフォルトの学校データをデータベースに挿入（無効化）
  @Deprecated('CSVデータを使用するため、このメソッドは使用しないでください')
  Future<void> insertDefaultSchools() async {
    print('警告: insertDefaultSchools()は無効化されています。代わりにinsertSchoolsFromCsv()を使用してください');
    // 一時的に有効化してパフォーマンス比較用
    try {
      final stopwatch = Stopwatch()..start();
      print('SchoolDataService.insertDefaultSchools: 開始');
      
      // 既存の学校データを削除
      final deleteStart = Stopwatch()..start();
      await _db.delete('School');
      deleteStart.stop();
      print('SchoolDataService.insertDefaultSchools: 既存データ削除完了 - ${deleteStart.elapsedMilliseconds}ms');
      
      // デフォルトの学校データを取得
      final dataPrepStart = Stopwatch()..start();
      final schools = DefaultSchoolData.getAllSchools();
      dataPrepStart.stop();
      print('SchoolDataService.insertDefaultSchools: データ準備完了 - ${dataPrepStart.elapsedMilliseconds}ms (${schools.length}件)');
      
      // データベースに挿入
      final insertStart = Stopwatch()..start();
      await _db.transaction((txn) async {
        for (final school in schools) {
          await txn.insert('School', {
            'id': school.id,
            'name': school.name,
            'type': '高校',
            'location': school.location,
            'prefecture': school.prefecture,
            'rank': school.rank.name,
            'school_strength': 50,
            'coach_trust': school.coachTrust,
            'coach_name': school.coachName,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      });
      insertStart.stop();
      print('SchoolDataService.insertDefaultSchools: バッチ挿入完了 - ${insertStart.elapsedMilliseconds}ms');
      
      stopwatch.stop();
      print('SchoolDataService.insertDefaultSchools: 全体完了 - ${stopwatch.elapsedMilliseconds}ms (${schools.length}校挿入)');
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
        id: map['id']?.toString() ?? '',
        name: map['name'] as String,
        shortName: _generateShortName(map['name'] as String),
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
        id: map['id']?.toString() ?? '',
        name: map['name'] as String,
        shortName: _generateShortName(map['name'] as String),
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
        id: map['id']?.toString() ?? '',
        name: map['name'] as String,
        shortName: _generateShortName(map['name'] as String),
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
