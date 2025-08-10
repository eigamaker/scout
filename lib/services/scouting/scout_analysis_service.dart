import 'dart:math';
import '../../models/player/player.dart';
import '../../models/player/player_abilities.dart';
import '../data_service.dart';

class ScoutAnalysisService {
  final DataService _dataService;
  
  ScoutAnalysisService(this._dataService);
  
  /// スカウト分析データを保存
  Future<void> saveScoutAnalysis(Player player, String scoutId, double accuracy) async {
    final random = Random();
    final errorRange = _calculateErrorRange(accuracy);
    
    print('スカウト分析開始: プレイヤー ${player.name}, 精度 $accuracy, 誤差範囲 ±$errorRange');
    
    // スカウトされた能力値を生成
    final scoutedAbilities = <String, int>{};
    
    // 技術的能力値
    for (final ability in TechnicalAbility.values) {
      int trueValue;
      
      // 球速の場合は特別な処理
      if (ability == TechnicalAbility.fastball) {
        trueValue = player.veloScore; // 既に制限された球速スコアを使用
      } else {
        trueValue = player.getTechnicalAbility(ability);
      }
      
      final scoutedValue = _generateScoutedValue(trueValue, errorRange, random);
      if (scoutedValue != null) {
        final columnName = _getColumnName(ability.name);
        scoutedAbilities[columnName] = scoutedValue;
        print('技術面能力値生成: ${ability.name} = $trueValue → $scoutedValue (誤差: ${scoutedValue - trueValue})');
      } else {
        print('技術面能力値生成失敗: ${ability.name} = $trueValue (誤差範囲: ±$errorRange)');
      }
    }
    
    // 精神的能力値
    for (final ability in MentalAbility.values) {
      final trueValue = player.getMentalAbility(ability);
      final scoutedValue = _generateScoutedValue(trueValue, errorRange, random);
      if (scoutedValue != null) {
        final columnName = _getColumnName(ability.name);
        scoutedAbilities[columnName] = scoutedValue;
        print('精神面能力値生成: ${ability.name} = $trueValue → $scoutedValue (誤差: ${scoutedValue - trueValue})');
      } else {
        print('精神面能力値生成失敗: ${ability.name} = $trueValue (誤差範囲: ±$errorRange)');
      }
    }
    
    // 身体的能力値
    for (final ability in PhysicalAbility.values) {
      final trueValue = player.getPhysicalAbility(ability);
      final scoutedValue = _generateScoutedValue(trueValue, errorRange, random);
      if (scoutedValue != null) {
        final columnName = _getColumnName(ability.name);
        scoutedAbilities[columnName] = scoutedValue;
        print('身体面能力値生成: ${ability.name} = $trueValue → $scoutedValue (誤差: ${scoutedValue - trueValue})');
      } else {
        print('身体面能力値生成失敗: ${ability.name} = $trueValue (誤差範囲: ±$errorRange)');
      }
    }
    
    try {
      final db = await _dataService.database;
      final insertData = {
        'player_id': player.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(), // TEXT形式で保存
        'accuracy': accuracy,
        ...scoutedAbilities,
      };
      
      print('スカウト分析データ保存: プレイヤーID ${player.id}, 精度 $accuracy, 生成された能力値数: ${scoutedAbilities.length}件');
      print('生成された能力値: $scoutedAbilities');
      await db.insert('ScoutAnalysis', insertData);
      print('スカウト分析データ保存完了');

    } catch (e) {
      print('データベース保存エラー: $e');
    }
  }
  
  /// 最新のスカウト分析データを取得
  Future<Map<String, int>?> getLatestScoutAnalysis(int playerId, String scoutId) async {
    try {
      final db = await _dataService.database;
      print('スカウト分析データ取得開始: プレイヤーID $playerId, スカウトID $scoutId');
      
      final List<Map<String, dynamic>> results = await db.query(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [playerId, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      print('クエリ結果: ${results.length}件 (プレイヤーID: $playerId, スカウトID: $scoutId)');
      if (results.isNotEmpty) {
        print('最新レコード: ${results.first}');
      }
      
      if (results.isNotEmpty) {
        final record = results.first;
        final scoutedAbilities = <String, int>{};
        
        // スカウトされた能力値を抽出（カラム名をそのまま使用）
        for (final key in record.keys) {
          if (key.endsWith('_scouted') && record[key] != null) {
            scoutedAbilities[key] = record[key] as int;
            print('能力値抽出: $key = ${record[key]}');
          }
        }
        
        print('抽出された能力値: $scoutedAbilities');
        return scoutedAbilities;
      } else {
        print('スカウト分析データが見つかりません (プレイヤーID: $playerId, スカウトID: $scoutId)');
        return null;
      }
    } catch (e) {
      print('データベース取得エラー: $e');
      return null;
    }
  }

  /// 基本情報のスカウト分析データを保存
  Future<void> saveBasicInfoAnalysis(Player player, String scoutId, Map<String, double> accuracies) async {
    try {
      final db = await _dataService.database;
      final insertData = {
        'player_id': player.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().toIso8601String(), // TEXT形式で保存
        'accuracy': accuracies.values.reduce((a, b) => a + b) / accuracies.length,
        'personality_analyzed': _generatePersonalityAnalysis(player, accuracies['personality'] ?? 0.0),
        'talent_analyzed': _generateTalentAnalysis(player, accuracies['talent'] ?? 0.0),
        'growth_analyzed': _generateGrowthAnalysis(player, accuracies['growth'] ?? 0.0),
        'mental_grit_analyzed': _generateMentalGritAnalysis(player, accuracies['mental'] ?? 0.0),
        'potential_analyzed': _generatePotentialAnalysis(player, accuracies['potential'] ?? 0.0),
        'personality_accuracy': accuracies['personality'] ?? 0.0,
        'talent_accuracy': accuracies['talent'] ?? 0.0,
        'growth_accuracy': accuracies['growth'] ?? 0.0,
        'mental_grit_accuracy': accuracies['mental'] ?? 0.0,
        'potential_accuracy': accuracies['potential'] ?? 0.0,
      };
      
      print('基本情報分析データ保存: プレイヤーID ${player.id}, データ: $insertData');
      await db.insert('ScoutBasicInfoAnalysis', insertData);
      print('基本情報分析データ保存完了');
      
    } catch (e) {
      print('基本情報分析データ保存エラー: $e');
    }
  }

  /// 最新の基本情報分析データを取得
  Future<Map<String, dynamic>?> getLatestBasicInfoAnalysis(int playerId, String scoutId) async {
    try {
      final db = await _dataService.database;
      print('基本情報分析データ取得開始: プレイヤーID $playerId, スカウトID $scoutId');
      
      final List<Map<String, dynamic>> results = await db.query(
        'ScoutBasicInfoAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [playerId, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      print('基本情報クエリ結果: ${results.length}件 (プレイヤーID: $playerId, スカウトID: $scoutId)');
      
      if (results.isNotEmpty) {
        final record = results.first;
        return {
          'personality': record['personality_analyzed'] as String?,
          'talent': record['talent_analyzed'] as String?,
          'growth': record['growth_analyzed'] as String?,
          'mental_grit': record['mental_grit_analyzed'] as String?,
          'potential': record['potential_analyzed'] as String?,
          'personality_accuracy': record['personality_accuracy'] as double?,
          'talent_accuracy': record['talent_accuracy'] as double?,
          'growth_accuracy': record['growth_accuracy'] as double?,
          'mental_grit_accuracy': record['mental_grit_accuracy'] as double?,
          'potential_accuracy': record['potential_accuracy'] as double?,
        };
      } else {
        print('基本情報分析データが見つかりません (プレイヤーID: $playerId, スカウトID: $scoutId)');
        return null;
      }
    } catch (e) {
      print('基本情報分析データ取得エラー: $e');
      return null;
    }
  }

  /// スカウト精度に基づく誤差範囲を計算
  int _calculateErrorRange(double accuracy) {
    // 精度は0.0〜1.0の範囲で渡される
    if (accuracy < 0.1) return 50; // 判定失敗
    if (accuracy < 0.3) return 20; // ±20の誤差
    if (accuracy < 0.5) return 16; // ±16の誤差
    if (accuracy < 0.7) return 12; // ±12の誤差
    if (accuracy < 0.85) return 8;  // ±8の誤差
    if (accuracy < 0.95) return 6;  // ±6の誤差
    return 3; // ±3の誤差（最大精度）
  }
  
  /// 仮の能力値を生成
  int? _generateScoutedValue(int trueValue, int errorRange, Random random) {
    // スカウトのスキルが非常に低い場合（errorRangeが50の場合）は判定できない
    if (errorRange >= 50) {
      return null; // 判定できない場合はnullを返す
    }
    
    final error = random.nextInt(errorRange * 2 + 1) - errorRange;
    final scoutedValue = (trueValue + error).clamp(0, 100);
    return scoutedValue;
  }

  /// カラム名を取得（camelCase → snake_case）
  String _getColumnName(String enumName) {
    // 特殊なマッピング
    final mapping = {
      'plateDiscipline': 'plate_discipline',
      'oppositeFieldHitting': 'opposite_field_hitting',
      'pullHitting': 'pull_hitting',
      'batControl': 'bat_control',
      'swingSpeed': 'swing_speed',
      'catcherAbility': 'catcher_ability',
      'breakingBall': 'breaking_ball',
      'pitchMovement': 'pitch_movement',
      'workRate': 'work_rate',
      'selfDiscipline': 'self_discipline',
      'pressureHandling': 'pressure_handling',
      'clutchAbility': 'clutch_ability',
      'jumpingReach': 'jumping_reach',
      'naturalFitness': 'natural_fitness',
      'injuryProneness': 'injury_proneness',
    };
    
    String columnName;
    
    // マッピングに存在する場合はそれを使用
    if (mapping.containsKey(enumName)) {
      columnName = '${mapping[enumName]}_scouted';
    } else {
      // それ以外は通常のcamelCase → snake_case変換
      final snakeCase = enumName.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}'
      );
      columnName = '${snakeCase}_scouted';
    }
    
    print('カラム名生成: $enumName -> $columnName');
    return columnName;
  }

  /// カラム名から能力値名を取得
  String? _getAbilityNameFromColumn(String columnName) {
    if (!columnName.endsWith('_scouted')) return null;
    
    // snake_case から camelCase に変換
    final withoutSuffix = columnName.replaceAll('_scouted', '');
    final parts = withoutSuffix.split('_');
    
    String abilityName;
    if (parts.length == 1) {
      abilityName = parts[0];
    } else {
      abilityName = parts[0] + parts.skip(1).map((part) => 
        part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : ''
      ).join('').replaceAll('_', ''); // 末尾の_を削除
    }
    
    print('カラム名変換: $columnName -> $abilityName');
    return abilityName;
  }

  /// 性格の分析結果を生成
  String _generatePersonalityAnalysis(Player player, double accuracy) {
    if (accuracy < 0.3) {
      return '性格不明';
    } else if (accuracy < 0.5) {
      final personalities = ['内向的', '外向的', 'リーダー型', 'フォロワー型'];
      return personalities[player.talent % personalities.length];
    } else if (accuracy < 0.7) {
      final personalities = ['冷静沈着', '情に厚い', '負けず嫌い', '謙虚'];
      return personalities[player.talent % personalities.length];
    } else {
      final personalities = ['勝負強さがある', 'チームプレー重視', '個人主義的'];
      return personalities[player.talent % personalities.length];
    }
  }

  /// 才能の分析結果を生成
  String _generateTalentAnalysis(Player player, double accuracy) {
    if (accuracy < 0.3) {
      return '才能不明';
    } else if (accuracy < 0.5) {
      return player.talent >= 7 ? '才能あり' : '才能なし';
    } else if (accuracy < 0.7) {
      if (player.talent >= 8) return '隠れた才能';
      else if (player.talent >= 6) return '期待の星';
      else return '平均的';
    } else {
      if (player.talent >= 9) return '超高校級';
      else if (player.talent >= 7) return '一流';
      else if (player.talent >= 5) return '有望';
      else return '平均';
    }
  }

  /// 成長の分析結果を生成
  String _generateGrowthAnalysis(Player player, double accuracy) {
    if (accuracy < 0.3) {
      return '成長不明';
    } else if (accuracy < 0.5) {
      return player.growthRate > 0.5 ? '成長中' : '停滞中';
    } else if (accuracy < 0.7) {
      if (player.growthRate > 0.7) return '急成長';
      else if (player.growthRate > 0.4) return '安定成長';
      else return '緩やか成長';
    } else {
      if (player.growthRate > 0.8) return '爆発的成長';
      else if (player.growthRate > 0.6) return '順調成長';
      else if (player.growthRate > 0.3) return '緩やか成長';
      else return '停滞';
    }
  }

  /// 精神力の分析結果を生成
  String _generateMentalGritAnalysis(Player player, double accuracy) {
    if (accuracy < 0.3) {
      return '精神力不明';
    } else if (accuracy < 0.5) {
      if (player.mentalGrit > 0.7) return '強い';
      else if (player.mentalGrit > 0.4) return '普通';
      else return '弱い';
    } else if (accuracy < 0.7) {
      if (player.mentalGrit > 0.8) return '鋼の精神';
      else if (player.mentalGrit > 0.5) return '安定した精神';
      else return '不安定';
    } else {
      if (player.mentalGrit > 0.8) return '逆境に強い';
      else if (player.mentalGrit < 0.3) return 'プレッシャーに弱い';
      else return '勝負強さあり';
    }
  }

  /// ポテンシャルの分析結果を生成
  String _generatePotentialAnalysis(Player player, double accuracy) {
    if (accuracy < 0.3) {
      return '将来性不明';
    } else if (accuracy < 0.5) {
      if (player.peakAbility >= 80) return '有望';
      else if (player.peakAbility >= 60) return '普通';
      else return '期待薄';
    } else if (accuracy < 0.7) {
      if (player.peakAbility >= 85) return '大物候補';
      else if (player.peakAbility >= 70) return '期待の星';
      else return '平均的将来性';
    } else {
      if (player.peakAbility >= 90) return 'プロ級';
      else if (player.peakAbility >= 80) return '大学トップ級';
      else if (player.peakAbility >= 65) return '実業団級';
      else return 'アマチュア級';
    }
  }

  /// データベースのテーブル構造を確認
  Future<void> debugTableStructure() async {
    try {
      final db = await _dataService.database;
      
      // ScoutAnalysisテーブルの構造を確認
      final tableInfo = await db.rawQuery("PRAGMA table_info(ScoutAnalysis)");
      print('ScoutAnalysisテーブル構造:');
      for (final column in tableInfo) {
        print('  ${column['name']}: ${column['type']}');
      }
      
      // テーブル内のデータ数を確認
      final countResult = await db.rawQuery("SELECT COUNT(*) as count FROM ScoutAnalysis");
      final count = countResult.first['count'] as int;
      print('ScoutAnalysisテーブルのデータ数: $count');
      
      // 最新のデータを確認
      if (count > 0) {
        final latestData = await db.rawQuery("SELECT * FROM ScoutAnalysis ORDER BY analysis_date DESC LIMIT 1");
        print('最新のスカウト分析データ: ${latestData.first}');
      }
      
    } catch (e) {
      print('テーブル構造確認エラー: $e');
    }
  }
} 