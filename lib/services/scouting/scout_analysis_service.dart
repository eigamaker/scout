import 'dart:math';
import 'dart:convert';
import '../../models/player/player.dart';
import '../../models/player/player_abilities.dart';
import '../data_service.dart';

class ScoutAnalysisService {
  final DataService _dataService;
  
  ScoutAnalysisService(this._dataService);
  
  /// スカウト分析データを保存
  Future<void> saveScoutAnalysis(Player player, String scoutId, double accuracy) async {
    print('=== スカウト分析データ保存開始 ===');
    print('プレイヤー: ${player.name} (ID: ${player.id})');
    print('スカウトID: $scoutId');
    print('精度: $accuracy');
    
    final random = Random();
    final errorRange = _calculateErrorRange(accuracy);
    
    // スカウトされた能力値を生成
    final scoutedAbilities = <String, int>{};
    
    // 技術的能力値
    for (final ability in TechnicalAbility.values) {
      final trueValue = player.getTechnicalAbility(ability);
      final scoutedValue = _generateScoutedValue(trueValue, errorRange, random);
      final columnName = _getColumnName(ability.name);
      scoutedAbilities[columnName] = scoutedValue;
      print('${ability.name}: 真値=$trueValue, スカウト値=$scoutedValue');
    }
    
    // 精神的能力値
    for (final ability in MentalAbility.values) {
      final trueValue = player.getMentalAbility(ability);
      final scoutedValue = _generateScoutedValue(trueValue, errorRange, random);
      final columnName = _getColumnName(ability.name);
      scoutedAbilities[columnName] = scoutedValue;
      print('${ability.name}: 真値=$trueValue, スカウト値=$scoutedValue');
    }
    
    // 身体的能力値
    for (final ability in PhysicalAbility.values) {
      final trueValue = player.getPhysicalAbility(ability);
      final scoutedValue = _generateScoutedValue(trueValue, errorRange, random);
      final columnName = _getColumnName(ability.name);
      scoutedAbilities[columnName] = scoutedValue;
      print('${ability.name}: 真値=$trueValue, スカウト値=$scoutedValue');
    }
    
    try {
      final db = await _dataService.database;
      final result = await db.insert('ScoutAnalysis', {
        'player_id': player.id ?? 0,
        'scout_id': scoutId,
        'analysis_date': DateTime.now().millisecondsSinceEpoch,
        'accuracy': accuracy,
        ...scoutedAbilities,
      });
      
      print('データベース保存成功: レコードID = $result');
      print('=== スカウト分析データ保存完了 ===');
    } catch (e) {
      print('データベース保存エラー: $e');
    }
  }
  
  /// 最新のスカウト分析データを取得
  Future<Map<String, int>?> getLatestScoutAnalysis(int playerId, String scoutId) async {
    print('=== スカウト分析データ取得開始 ===');
    print('プレイヤーID: $playerId');
    print('スカウトID: $scoutId');
    
    try {
      final db = await _dataService.database;
      final List<Map<String, dynamic>> results = await db.query(
        'ScoutAnalysis',
        where: 'player_id = ? AND scout_id = ?',
        whereArgs: [playerId, scoutId],
        orderBy: 'analysis_date DESC',
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        final record = results.first;
        print('データベースから取得したレコード: $record');
        
        final scoutedAbilities = <String, int>{};
        
        // スカウトされた能力値を抽出
        for (final key in record.keys) {
          if (key.endsWith('_scouted') && record[key] != null) {
            final abilityName = _getAbilityNameFromColumn(key);
            scoutedAbilities[abilityName] = record[key] as int;
            print('$abilityName: ${record[key]}');
          }
        }
        
        print('=== スカウト分析データ取得完了 ===');
        return scoutedAbilities;
      } else {
        print('スカウト分析データが見つかりませんでした');
        print('=== スカウト分析データ取得完了 ===');
        return null;
      }
    } catch (e) {
      print('データベース取得エラー: $e');
      return null;
    }
  }
  
  /// スカウト精度に基づく誤差範囲を計算
  int _calculateErrorRange(double accuracy) {
    if (accuracy >= 0.8) return 5; // ±5の誤差
    if (accuracy >= 0.6) return 10; // ±10の誤差
    if (accuracy >= 0.4) return 20; // ±20の誤差
    if (accuracy >= 0.2) return 30; // ±30の誤差
    return 50; // ±50の誤差（ほぼ見えない）
  }
  
  /// 仮の能力値を生成
  int _generateScoutedValue(int trueValue, int errorRange, Random random) {
    final error = random.nextInt(errorRange * 2 + 1) - errorRange;
    return (trueValue + error).clamp(0, 100);
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
    
    // マッピングに存在する場合はそれを使用
    if (mapping.containsKey(enumName)) {
      return '${mapping[enumName]}_scouted';
    }
    
    // それ以外は通常のcamelCase → snake_case変換
    final snakeCase = enumName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}'
    );
    return '${snakeCase}_scouted';
  }

  /// 能力値名を取得（snake_case → camelCase）
  String _getAbilityNameFromColumn(String columnName) {
    // _scoutedを除去
    final withoutSuffix = columnName.replaceAll('_scouted', '');
    
    // 逆マッピング
    final reverseMapping = {
      'plate_discipline': 'plateDiscipline',
      'opposite_field_hitting': 'oppositeFieldHitting',
      'pull_hitting': 'pullHitting',
      'bat_control': 'batControl',
      'swing_speed': 'swingSpeed',
      'catcher_ability': 'catcherAbility',
      'breaking_ball': 'breakingBall',
      'pitch_movement': 'pitchMovement',
      'work_rate': 'workRate',
      'self_discipline': 'selfDiscipline',
      'pressure_handling': 'pressureHandling',
      'clutch_ability': 'clutchAbility',
      'jumping_reach': 'jumpingReach',
      'natural_fitness': 'naturalFitness',
      'injury_proneness': 'injuryProneness',
    };
    
    // マッピングに存在する場合はそれを使用
    if (reverseMapping.containsKey(withoutSuffix)) {
      return reverseMapping[withoutSuffix]!;
    }
    
    // それ以外は通常のsnake_case → camelCase変換
    return withoutSuffix.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase()
    );
  }
} 