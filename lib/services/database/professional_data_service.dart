import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../utils/name_generator.dart';

/// プロ野球データ管理に関する機能を担当するサービス
class ProfessionalDataService {
  final Database _db;

  ProfessionalDataService(this._db);

  /// プロ野球団の初期データを挿入
  Future<void> insertProfessionalTeams() async {
    print('ProfessionalDataService: プロ野球団初期データ挿入開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      // 既存のプロ野球団データを削除
      await _db.delete('ProfessionalTeam');
      
      final teams = _getDefaultProfessionalTeams();
      
      for (final team in teams) {
        await _db.insert('ProfessionalTeam', team);
        print('ProfessionalDataService: プロ野球団を挿入: ${team['name']}');
      }
      
      // プロ選手の初期データを生成・挿入
      await _insertProfessionalPlayers();
      
      stopwatch.stop();
      print('ProfessionalDataService: プロ野球団初期データ挿入完了 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('ProfessionalDataService: プロ野球団初期データ挿入エラー: $e');
      rethrow;
    }
  }

  /// デフォルトプロ野球団データを取得
  List<Map<String, dynamic>> _getDefaultProfessionalTeams() {
    return [
      // セ・リーグ
      {
        'id': 'giants',
        'name': '読売ジャイアンツ',
        'short_name': '巨人',
        'league': 'central',
        'division': 'east',
        'home_stadium': '東京ドーム',
        'city': '東京都',
        'budget': 80000,
        'strategy': '打撃重視',
        'strengths': '["打撃力", "知名度", "資金力"]',
        'weaknesses': '["投手力", "若手育成"]',
        'popularity': 90,
        'success': 85,
      },
      {
        'id': 'tigers',
        'name': '阪神タイガース',
        'short_name': '阪神',
        'league': 'central',
        'division': 'west',
        'home_stadium': '阪神甲子園球場',
        'city': '兵庫県',
        'budget': 70000,
        'strategy': 'バランス型',
        'strengths': '["投手力", "守備力"]',
        'weaknesses': '["打撃力", "長打力"]',
        'popularity': 85,
        'success': 80,
      },
      {
        'id': 'carp',
        'name': '広島東洋カープ',
        'short_name': '広島',
        'league': 'central',
        'division': 'central',
        'home_stadium': 'MAZDA Zoom-Zoom スタジアム広島',
        'city': '広島県',
        'budget': 60000,
        'strategy': '若手育成重視',
        'strengths': '["若手育成", "打撃力"]',
        'weaknesses': '["投手力", "資金力"]',
        'popularity': 75,
        'success': 70,
      },
      {
        'id': 'dragons',
        'name': '中日ドラゴンズ',
        'short_name': '中日',
        'league': 'central',
        'division': 'central',
        'home_stadium': 'バンテリンドーム ナゴヤ',
        'city': '愛知県',
        'budget': 75000,
        'strategy': '投手重視',
        'strengths': '["投手力", "守備力", "伝統"]',
        'weaknesses': '["打撃力", "長打力"]',
        'popularity': 75,
        'success': 75,
      },
      {
        'id': 'baystars',
        'name': '横浜DeNAベイスターズ',
        'short_name': 'DeNA',
        'league': 'central',
        'division': 'east',
        'home_stadium': '横浜スタジアム',
        'city': '神奈川県',
        'budget': 60000,
        'strategy': '打撃重視',
        'strengths': '["打撃力", "長打力", "若手育成"]',
        'weaknesses': '["投手力", "守備力"]',
        'popularity': 65,
        'success': 60,
      },
      {
        'id': 'swallows',
        'name': '東京ヤクルトスワローズ',
        'short_name': 'ヤクルト',
        'league': 'central',
        'division': 'east',
        'home_stadium': '明治神宮野球場',
        'city': '東京都',
        'budget': 55000,
        'strategy': '若手育成重視',
        'strengths': '["若手育成", "打撃力", "スピード"]',
        'weaknesses': '["投手力", "資金力"]',
        'popularity': 60,
        'success': 55,
      },
      // パ・リーグ
      {
        'id': 'hawks',
        'name': '福岡ソフトバンクホークス',
        'short_name': 'ソフトバンク',
        'league': 'pacific',
        'division': 'west',
        'home_stadium': '福岡PayPayドーム',
        'city': '福岡県',
        'budget': 90000,
        'strategy': '投手重視',
        'strengths': '["投手力", "資金力", "戦略性"]',
        'weaknesses': '["内野守備"]',
        'popularity': 80,
        'success': 90,
      },
      {
        'id': 'marines',
        'name': '千葉ロッテマリーンズ',
        'short_name': 'ロッテ',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': 'ZOZOマリンスタジアム',
        'city': '千葉県',
        'budget': 50000,
        'strategy': '若手育成重視',
        'strengths': '["若手育成", "守備力"]',
        'weaknesses': '["投手力", "打撃力", "資金力"]',
        'popularity': 60,
        'success': 55,
      },
      {
        'id': 'eagles',
        'name': '東北楽天ゴールデンイーグルス',
        'short_name': '楽天',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': '楽天生命パーク宮城',
        'city': '宮城県',
        'budget': 65000,
        'strategy': 'バランス型',
        'strengths': '["打撃力", "若手育成"]',
        'weaknesses': '["投手力", "守備力"]',
        'popularity': 70,
        'success': 65,
      },
      {
        'id': 'lions',
        'name': '埼玉西武ライオンズ',
        'short_name': '西武',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': 'ベルーナドーム',
        'city': '埼玉県',
        'budget': 70000,
        'strategy': 'バランス型',
        'strengths': '["投手力", "内野守備", "若手育成"]',
        'weaknesses': '["外野守備", "長打力"]',
        'popularity': 70,
        'success': 75,
      },
      {
        'id': 'fighters',
        'name': '北海道日本ハムファイターズ',
        'short_name': '日本ハム',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': 'エスコンフィールドHOKKAIDO',
        'city': '北海道',
        'budget': 65000,
        'strategy': '投手重視',
        'strengths': '["投手力", "外野守備", "若手育成"]',
        'weaknesses': '["内野守備", "打撃力"]',
        'popularity': 65,
        'success': 60,
      },
      {
        'id': 'buffaloes',
        'name': 'オリックス・バファローズ',
        'short_name': 'オリックス',
        'league': 'pacific',
        'division': 'west',
        'home_stadium': '京セラドーム大阪',
        'city': '大阪府',
        'budget': 80000,
        'strategy': '投手重視',
        'strengths': '["投手力", "守備力", "資金力"]',
        'weaknesses': '["打撃力", "長打力"]',
        'popularity': 75,
        'success': 80,
      },
    ];
  }

  /// プロ選手の初期データを生成・挿入
  Future<void> _insertProfessionalPlayers() async {
    print('ProfessionalDataService: プロ選手初期データ生成開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      // プロ野球団のリストを取得
      final teamMaps = await _db.query('ProfessionalTeam');
      if (teamMaps.isEmpty) {
        print('ProfessionalDataService: プロ野球団が見つかりません');
        return;
      }
      
      int totalPlayersGenerated = 0;
      
      // 各チームにプロ選手を生成・挿入
      for (final teamMap in teamMaps) {
        final teamId = teamMap['id'] as String;
        final teamName = teamMap['name'] as String;
        
        print('ProfessionalDataService: $teamName のプロ選手生成開始');
        
        // チームのポジション別選手数を決定
        final positionCounts = {
          '投手': 12,      // 投手12名
          '捕手': 3,       // 捕手3名
          '一塁手': 2,     // 一塁手2名
          '二塁手': 2,     // 二塁手2名
          '三塁手': 2,     // 三塁手2名
          '遊撃手': 2,     // 遊撃手2名
          '左翼手': 2,     // 左翼手2名
          '中堅手': 2,     // 中堅手2名
          '右翼手': 2,     // 右翼手2名
        };
        
        // 各ポジションの選手を生成・挿入
        for (final entry in positionCounts.entries) {
          final position = entry.key;
          final count = entry.value;
          
          for (int i = 0; i < count; i++) {
            await _generateAndInsertProfessionalPlayer(teamId, position);
            totalPlayersGenerated++;
          }
        }
        
        print('ProfessionalDataService: $teamName のプロ選手生成完了 - 合計${positionCounts.values.reduce((a, b) => a + b)}名');
      }
      
      stopwatch.stop();
      print('ProfessionalDataService: プロ選手初期データ生成完了 - 合計${totalPlayersGenerated}名 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('ProfessionalDataService: プロ選手初期データ生成エラー: $e');
      rethrow;
    }
  }

  /// プロ選手を生成してデータベースに挿入
  Future<void> _generateAndInsertProfessionalPlayer(String teamId, String position) async {
    final random = Random();
    
    // 選手の基本情報を生成
    final playerName = _generateProfessionalPlayerName();
    final age = 18 + random.nextInt(18); // 18-35歳
    final talent = _generateTalentForProfessional(); // 3-5のtalent
    
    // Personテーブルに挿入
    final personId = await _db.insert('Person', {
      'name': playerName,
      'birth_date': DateTime.now().subtract(Duration(days: age * 365)).toIso8601String(),
      'gender': '男性',
      'hometown': '日本',
      'personality': _generateProfessionalPersonality(),
      'is_drafted': 1,
      'drafted_at': DateTime.now().subtract(Duration(days: 365)).toIso8601String(),
    });
    
    // peak_abilityを基準とした能力値生成（95%前後）
    final peakAbility = _calculatePeakAbilityByAge(talent, age);
    final targetAbility = (peakAbility * 0.95).round(); // peak_abilityの95%を目標
    
    // Playerテーブルに挿入
    final playerId = await _db.insert('Player', {
      'person_id': personId,
      'school_id': null, // プロ選手は学校なし
      'grade': 0, // プロ選手は学年なし
      'age': age,
      'position': position,
      'fame': 60 + random.nextInt(41), // 60-100
      'is_publicly_known': 1,
      'is_scout_favorite': 0,
      'is_graduated': 1, // プロ選手は高校卒業済み
      'is_retired': 0, // プロ選手は引退していない
      'status': 'professional', // プロ選手ステータス
      'growth_rate': _calculateGrowthRateByAge(age),
      'talent': talent,
      'growth_type': _getGrowthTypeByAge(age),
      'mental_grit': 0.6 + random.nextDouble() * 0.4, // 0.6-1.0
      'peak_ability': peakAbility,
      // 技術的能力値（peak_abilityの95%前後で生成、上限はpeak_ability+10）
      'contact': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'power': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'plate_discipline': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'bunt': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'opposite_field_hitting': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'pull_hitting': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'bat_control': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'swing_speed': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'fielding': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'throwing': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'catcher_ability': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'control': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'fastball': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'breaking_ball': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'pitch_movement': _generateProPlayerAbility(targetAbility, peakAbility, random),
      // 精神的能力値（peak_abilityの95%前後で生成、上限はpeak_ability+10）
      'concentration': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'anticipation': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'vision': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'composure': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'aggression': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'bravery': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'leadership': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'work_rate': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'self_discipline': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'ambition': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'teamwork': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'positioning': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'pressure_handling': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'clutch_ability': _generateProPlayerAbility(targetAbility, peakAbility, random),
      // 身体的能力値（peak_abilityの95%前後で生成、上限はpeak_ability+10）
      'acceleration': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'agility': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'balance': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'jumping_reach': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'natural_fitness': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'injury_proneness': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'stamina': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'strength': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'pace': _generateProPlayerAbility(targetAbility, peakAbility, random),
      'flexibility': _generateProPlayerAbility(targetAbility, peakAbility, random),
    });
    
    // PlayerPotentialsテーブルに挿入
    await _db.insert('PlayerPotentials', {
      'player_id': playerId,
      // 技術的ポテンシャル（peak_abilityを基準に生成、上限はpeak_ability+15）
      'contact_potential': _generateProPlayerPotential(peakAbility, random),
      'power_potential': _generateProPlayerPotential(peakAbility, random),
      'plate_discipline_potential': _generateProPlayerPotential(peakAbility, random),
      'bunt_potential': _generateProPlayerPotential(peakAbility, random),
      'opposite_field_hitting_potential': _generateProPlayerPotential(peakAbility, random),
      'pull_hitting_potential': _generateProPlayerPotential(peakAbility, random),
      'bat_control_potential': _generateProPlayerPotential(peakAbility, random),
      'swing_speed_potential': _generateProPlayerPotential(peakAbility, random),
      'fielding_potential': _generateProPlayerPotential(peakAbility, random),
      'throwing_potential': _generateProPlayerPotential(peakAbility, random),
      'catcher_ability_potential': _generateProPlayerPotential(peakAbility, random),
      'control_potential': _generateProPlayerPotential(peakAbility, random),
      'fastball_potential': _generateProPlayerPotential(peakAbility, random),
      'breaking_ball_potential': _generateProPlayerPotential(peakAbility, random),
      'pitch_movement_potential': _generateProPlayerPotential(peakAbility, random),
      // 精神的ポテンシャル（peak_abilityを基準に生成、上限はpeak_ability+15）
      'concentration_potential': _generateProPlayerPotential(peakAbility, random),
      'anticipation_potential': _generateProPlayerPotential(peakAbility, random),
      'vision_potential': _generateProPlayerPotential(peakAbility, random),
      'composure_potential': _generateProPlayerPotential(peakAbility, random),
      'aggression_potential': _generateProPlayerPotential(peakAbility, random),
      'bravery_potential': _generateProPlayerPotential(peakAbility, random),
      'leadership_potential': _generateProPlayerPotential(peakAbility, random),
      'work_rate_potential': _generateProPlayerPotential(peakAbility, random),
      'self_discipline_potential': _generateProPlayerPotential(peakAbility, random),
      'ambition_potential': _generateProPlayerPotential(peakAbility, random),
      'teamwork_potential': _generateProPlayerPotential(peakAbility, random),
      'positioning_potential': _generateProPlayerPotential(peakAbility, random),
      'pressure_handling_potential': _generateProPlayerPotential(peakAbility, random),
      'clutch_ability_potential': _generateProPlayerPotential(peakAbility, random),
      // 身体的ポテンシャル（peak_abilityを基準に生成、上限はpeak_ability+15）
      'acceleration_potential': _generateProPlayerPotential(peakAbility, random),
      'agility_potential': _generateProPlayerPotential(peakAbility, random),
      'balance_potential': _generateProPlayerPotential(peakAbility, random),
      'jumping_reach_potential': _generateProPlayerPotential(peakAbility, random),
      'natural_fitness_potential': _generateProPlayerPotential(peakAbility, random),
      'injury_proneness_potential': _generateProPlayerPotential(peakAbility, random),
      'stamina_potential': _generateProPlayerPotential(peakAbility, random),
      'strength_potential': _generateProPlayerPotential(peakAbility, random),
      'pace_potential': _generateProPlayerPotential(peakAbility, random),
      'flexibility_potential': _generateProPlayerPotential(peakAbility, random),
      // 総合ポテンシャル指標（事前計算済み）
      'overall_potential': _calculateProfessionalOverallPotential(peakAbility, position, random),
      'technical_potential': _calculateProfessionalTechnicalPotential(peakAbility, random),
      'mental_potential': _calculateProfessionalMentalPotential(peakAbility, random),
      'physical_potential': _calculateProfessionalPhysicalPotential(peakAbility, random),
    });
    
    // ProfessionalPlayerテーブルに挿入
    await _db.insert('ProfessionalPlayer', {
      'player_id': playerId,
      'team_id': teamId,
      'contract_year': 1,
      'salary': 1000 + (talent * 200) + random.nextInt(500), // 1000-2500万円
      'contract_type': 'regular',
      'draft_year': DateTime.now().year - 1,
      'draft_round': 1,
      'draft_position': 1,
      'is_active': 1,
      'joined_at': DateTime.now().subtract(Duration(days: 365)).toIso8601String(),
      'left_at': null,
    });
  }

  /// プロ選手用の名前生成
  String _generateProfessionalPlayerName() {
    return NameGenerator.generateProfessionalPlayerName();
  }

  /// プロ選手用の性格生成
  String _generateProfessionalPersonality() {
    final personalities = ['リーダー', '積極的', '冷静', '情熱的', '謙虚', '自信家', '努力家', '天才型'];
    final random = DateTime.now().millisecondsSinceEpoch;
    return personalities[random % personalities.length];
  }

  /// プロ選手用のtalent生成（3-5）
  int _generateTalentForProfessional() {
    final random = DateTime.now().millisecondsSinceEpoch;
    if (random % 3 == 0) return 5; // 33%で5
    if (random % 2 == 0) return 4; // 33%で4
    return 3; // 33%で3
  }

  /// 年齢に基づく成長率計算
  double _calculateGrowthRateByAge(int age) {
    if (age <= 22) return 1.1;      // 若手
    else if (age <= 28) return 1.0; // 全盛期
    else if (age <= 32) return 0.9; // ベテラン
    else return 0.8;                // シニア
  }

  /// 年齢に基づく成長タイプ取得
  String _getGrowthTypeByAge(int age) {
    if (age <= 22) return '早期型';
    else if (age <= 28) return '標準型';
    else if (age <= 32) return '晩成型';
    else return '維持型';
  }

  /// 年齢に基づくピーク能力計算
  int _calculatePeakAbilityByAge(int talent, int age) {
    final random = Random();
    final basePeak = 100 + (talent - 3) * 10; // talent 3: 100, 4: 110, 5: 120
    
    if (age <= 22) {
      // 若手：ピーク能力の70-85%（まだ成長の余地あり）
      return (basePeak * (0.7 + random.nextDouble() * 0.15)).round();
    } else if (age <= 28) {
      // 全盛期：ピーク能力の90-105%（ピーク付近）
      return (basePeak * (0.9 + random.nextDouble() * 0.15)).round();
    } else if (age <= 32) {
      // ベテラン：ピーク能力の85-95%（ピークを過ぎたが高いレベル維持）
      return (basePeak * (0.85 + random.nextDouble() * 0.1)).round();
    } else {
      // シニア：ピーク能力の75-85%（能力低下）
      return (basePeak * (0.75 + random.nextDouble() * 0.1)).round();
    }
  }

  /// プロ選手の能力値を生成（peak_abilityを基準とした95%前後）
  int _generateProPlayerAbility(int targetAbility, int peakAbility, Random random) {
    // targetAbility（peak_abilityの95%）を中心とした変動
    final variation = random.nextInt(21) - 10; // -10 から +10 の変動
    final ability = targetAbility + variation;
    
    // 上限はpeak_ability + 10、下限はtargetAbility - 15
    final maxAbility = peakAbility + 10;
    final minAbility = (targetAbility - 15).clamp(0, targetAbility);
    
    return ability.clamp(minAbility, maxAbility);
  }

  /// プロ選手のポテンシャルを生成（peak_abilityを基準とした上限+15）
  int _generateProPlayerPotential(int peakAbility, Random random) {
    // peak_abilityを中心とした変動
    final variation = random.nextInt(21) - 10; // -10 から +10 の変動
    final potential = peakAbility + variation;
    
    // 上限はpeak_ability + 15、下限はpeak_ability - 10
    final maxPotential = peakAbility + 15;
    final minPotential = (peakAbility - 10).clamp(0, peakAbility);
    
    return potential.clamp(minPotential, maxPotential);
  }

  /// プロ選手の総合ポテンシャル値を計算（ポジション別重み付け）
  int _calculateProfessionalOverallPotential(int peakAbility, String position, Random random) {
    // 基本ポテンシャル値を計算
    final technicalPotential = _calculateProfessionalTechnicalPotential(peakAbility, random);
    final mentalPotential = _calculateProfessionalMentalPotential(peakAbility, random);
    final physicalPotential = _calculateProfessionalPhysicalPotential(peakAbility, random);
    
    // ポジション別の重み付けを適用
    if (position == '投手') {
      // 投手: 技術50%、精神30%、身体20%
      return ((technicalPotential * 0.5) + (mentalPotential * 0.3) + (physicalPotential * 0.2)).round();
    } else {
      // 野手: 技術40%、精神25%、身体35%
      return ((technicalPotential * 0.4) + (mentalPotential * 0.25) + (physicalPotential * 0.35)).round();
    }
  }

  /// プロ選手の技術面ポテンシャル値を計算
  int _calculateProfessionalTechnicalPotential(int peakAbility, Random random) {
    // 技術面ポテンシャルは個別能力値の平均
    // 各能力値のポテンシャルはpeak_ability + 0-15の範囲
    final technicalAbilities = [
      peakAbility + random.nextInt(16), // contact
      peakAbility + random.nextInt(16), // power
      peakAbility + random.nextInt(16), // plate_discipline
      peakAbility + random.nextInt(16), // bunt
      peakAbility + random.nextInt(16), // opposite_field_hitting
      peakAbility + random.nextInt(16), // pull_hitting
      peakAbility + random.nextInt(16), // bat_control
      peakAbility + random.nextInt(16), // swing_speed
      peakAbility + random.nextInt(16), // fielding
      peakAbility + random.nextInt(16), // throwing
      peakAbility + random.nextInt(16), // catcher_ability
      peakAbility + random.nextInt(16), // control
      peakAbility + random.nextInt(16), // fastball
      peakAbility + random.nextInt(16), // breaking_ball
      peakAbility + random.nextInt(16), // pitch_movement
    ];
    
    final total = technicalAbilities.reduce((a, b) => a + b);
    return total ~/ technicalAbilities.length;
  }

  /// プロ選手のメンタル面ポテンシャル値を計算
  int _calculateProfessionalMentalPotential(int peakAbility, Random random) {
    // メンタル面ポテンシャルは個別能力値の平均
    // 各能力値のポテンシャルはpeak_ability + 0-15の範囲
    final mentalAbilities = [
      peakAbility + random.nextInt(16), // concentration
      peakAbility + random.nextInt(16), // anticipation
      peakAbility + random.nextInt(16), // vision
      peakAbility + random.nextInt(16), // composure
      peakAbility + random.nextInt(16), // aggression
      peakAbility + random.nextInt(16), // bravery
      peakAbility + random.nextInt(16), // leadership
      peakAbility + random.nextInt(16), // work_rate
      peakAbility + random.nextInt(16), // self_discipline
      peakAbility + random.nextInt(16), // ambition
      peakAbility + random.nextInt(16), // teamwork
      peakAbility + random.nextInt(16), // positioning
      peakAbility + random.nextInt(16), // pressure_handling
      peakAbility + random.nextInt(16), // clutch_ability
    ];
    
    final total = mentalAbilities.reduce((a, b) => a + b);
    return total ~/ mentalAbilities.length;
  }

  /// プロ選手のフィジカル面ポテンシャル値を計算
  int _calculateProfessionalPhysicalPotential(int peakAbility, Random random) {
    // フィジカル面ポテンシャルは個別能力値の平均
    // 各能力値のポテンシャルはpeak_ability + 0-15の範囲
    final physicalAbilities = [
      peakAbility + random.nextInt(16), // acceleration
      peakAbility + random.nextInt(16), // agility
      peakAbility + random.nextInt(16), // balance
      peakAbility + random.nextInt(16), // jumping_reach
      peakAbility + random.nextInt(16), // natural_fitness
      peakAbility + random.nextInt(16), // injury_proneness
      peakAbility + random.nextInt(16), // stamina
      peakAbility + random.nextInt(16), // strength
      peakAbility + random.nextInt(16), // pace
      peakAbility + random.nextInt(16), // flexibility
    ];
    
    final total = physicalAbilities.reduce((a, b) => a + b);
    return total ~/ physicalAbilities.length;
  }
}
