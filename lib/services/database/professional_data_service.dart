import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../utils/name_generator.dart';

/// プロ野球データ管理に関する機能を担当するサービス
class ProfessionalDataService {
  final Database _db;

  ProfessionalDataService(this._db);

  /// プロ野球団の初期データを挿入（最適化版 - バッチ処理）
  Future<void> insertProfessionalTeams() async {
    print('ProfessionalDataService: プロ野球団初期データ挿入開始');
    final stopwatch = Stopwatch()..start();
    
    try {
      // 既存のプロ野球団データを削除
      await _db.delete('ProfessionalTeam');
      
      final teams = _getDefaultProfessionalTeams();
      
      // バッチ挿入でプロ野球団を一括挿入
      await _db.transaction((txn) async {
      for (final team in teams) {
          await txn.insert('ProfessionalTeam', team);
      }
      });
      
      print('ProfessionalDataService: プロ野球団バッチ挿入完了 - ${teams.length}チーム');
      
      // プロ選手の初期データを生成・挿入（バッチ処理版）
      await _insertProfessionalPlayersBatch();
      
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
        'division': 'west',
        'home_stadium': 'MAZDA Zoom-Zoom スタジアム広島',
        'city': '広島県',
        'budget': 60000,
        'strategy': '投手重視',
        'strengths': '["投手力", "若手育成", "チームワーク"]',
        'weaknesses': '["資金力", "知名度"]',
        'popularity': 75,
        'success': 70,
      },
      {
        'id': 'dragons',
        'name': '中日ドラゴンズ',
        'short_name': '中日',
        'league': 'central',
        'division': 'west',
        'home_stadium': 'バンテリンドーム ナゴヤ',
        'city': '愛知県',
        'budget': 65000,
        'strategy': '守備重視',
        'strengths': '["守備力", "投手力"]',
        'weaknesses': '["打撃力", "長打力"]',
        'popularity': 70,
        'success': 65,
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
        'strategy': '打撃重視',
        'strengths': '["打撃力", "スピード"]',
        'weaknesses': '["投手力", "資金力"]',
        'popularity': 65,
        'success': 60,
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
        'strategy': 'バランス型',
        'strengths': '["若手育成", "スピード"]',
        'weaknesses': '["投手力", "守備力"]',
        'popularity': 70,
        'success': 65,
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
        'strengths': '["投手力", "資金力", "若手育成"]',
        'weaknesses': '["知名度"]',
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
        'budget': 70000,
        'strategy': '打撃重視',
        'strengths': '["打撃力", "長打力"]',
        'weaknesses': '["投手力", "守備力"]',
        'popularity': 75,
        'success': 70,
      },
      {
        'id': 'eagles',
        'name': '東北楽天ゴールデンイーグルス',
        'short_name': '楽天',
        'league': 'pacific',
        'division': 'east',
        'home_stadium': '楽天生命パーク宮城',
        'city': '宮城県',
        'budget': 75000,
        'strategy': 'バランス型',
        'strengths': '["投手力", "守備力", "若手育成"]',
        'weaknesses': '["打撃力", "知名度"]',
        'popularity': 70,
        'success': 75,
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

  /// プロ選手の初期データを生成・挿入（バッチ処理版）
  Future<void> _insertProfessionalPlayersBatch() async {
    print('ProfessionalDataService: プロ選手初期データ生成開始（バッチ処理）');
    final stopwatch = Stopwatch()..start();
    
    try {
      // プロ野球団のリストを取得
      final teamMaps = await _db.query('ProfessionalTeam');
      if (teamMaps.isEmpty) {
        print('ProfessionalDataService: プロ野球団が見つかりません');
        return;
      }
      
      // 全プロ選手のデータを準備
      final personDataList = <Map<String, dynamic>>[];
      final playerDataList = <Map<String, dynamic>>[];
      
      int totalPlayersGenerated = 0;
      
      // 各チームのプロ選手データを準備
      for (final teamMap in teamMaps) {
        final teamId = teamMap['id'] as String;
        final teamName = teamMap['name'] as String;
        
        print('ProfessionalDataService: $teamName のプロ選手データ準備開始');
        
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
        
        // 各ポジションの選手データを準備
        for (final entry in positionCounts.entries) {
          final position = entry.key;
          final count = entry.value;
          
          for (int i = 0; i < count; i++) {
            final playerData = _generateProfessionalPlayerData(teamId, teamName, position);
            personDataList.add(playerData['person']);
            playerDataList.add(playerData['player']);
            totalPlayersGenerated++;
          }
        }
        
        print('ProfessionalDataService: $teamName のプロ選手データ準備完了 - 合計${positionCounts.values.reduce((a, b) => a + b)}名');
      }
      
      // バッチ挿入実行
      await _db.transaction((txn) async {
        // Personテーブルにバッチ挿入
        final personIds = <int>[];
        for (final personData in personDataList) {
          final personId = await txn.insert('Person', personData);
          personIds.add(personId);
        }
        
        // Playerテーブルにバッチ挿入
        final playerIds = <int>[];
        for (int i = 0; i < playerDataList.length; i++) {
          final playerData = Map<String, dynamic>.from(playerDataList[i]);
          playerData['person_id'] = personIds[i];
          final playerId = await txn.insert('Player', playerData);
          playerIds.add(playerId);
        }
        
        // ProfessionalPlayerテーブルにバッチ挿入
        int playerIndex = 0;
        for (final teamMap in teamMaps) {
          final teamId = teamMap['id'] as String;
          final positionCounts = {
            '投手': 12, '捕手': 3, '一塁手': 2, '二塁手': 2, '三塁手': 2,
            '遊撃手': 2, '左翼手': 2, '中堅手': 2, '右翼手': 2,
          };
          
          for (final entry in positionCounts.entries) {
            final count = entry.value;
            for (int i = 0; i < count; i++) {
              final playerId = playerIds[playerIndex];
              await txn.insert('ProfessionalPlayer', {
                'player_id': playerId,
                'team_id': teamId,
                'contract_year': 1,
                'salary': 1000 + Random().nextInt(2000), // 1000-3000万円
                'contract_type': 'regular',
                'draft_year': DateTime.now().year - 1,
                'draft_round': 1,
                'draft_position': 1,
                'is_active': 1,
                'joined_at': DateTime.now().subtract(Duration(days: 365)).toIso8601String(),
                'left_at': null,
              });
              playerIndex++;
            }
          }
        }
      });
      
      stopwatch.stop();
      print('ProfessionalDataService: プロ選手初期データ生成完了 - 合計${totalPlayersGenerated}名 - ${stopwatch.elapsedMilliseconds}ms');
      
    } catch (e) {
      stopwatch.stop();
      print('ProfessionalDataService: プロ選手初期データ生成エラー: $e');
      rethrow;
    }
  }

  /// プロ選手データを生成（バッチ処理用）
  Map<String, Map<String, dynamic>> _generateProfessionalPlayerData(String teamId, String teamName, String position) {
    final random = Random();
    final nameGenerator = NameGenerator();
    
    // プロ選手の能力値（高めに設定）
    final baseAbility = 60 + random.nextInt(30); // 60-89
    final variation = random.nextInt(10) - 5; // -5 to +5
    
    final personData = {
      'name': nameGenerator.generateJapaneseName(),
      'birth_date': DateTime.now().subtract(Duration(days: random.nextInt(365 * 10) + 365 * 20)).toIso8601String(), // 20-30歳
      'gender': '男性',
      'hometown': '未設定',
      'personality': 'プロフェッショナル',
    };
    
    final playerData = {
      'school_id': null, // プロ選手は学校に所属しない
      'school': teamName,
      'grade': null, // プロ選手は学年なし
      'age': 20 + random.nextInt(10), // 20-29歳
      'position': position,
      'fame': 70 + random.nextInt(30), // 70-99
      'is_famous': 1, // プロ選手は常に注目選手
      'is_scout_favorite': random.nextBool() ? 1 : 0,
      'growth_rate': 0.5 + random.nextDouble() * 0.5, // 0.5-1.0
      'talent': 4 + random.nextInt(2), // 4-5
      'growth_type': 'プロ',
      'mental_grit': baseAbility + variation,
      'peak_ability': baseAbility + variation + 10,
      // Technical abilities
      'contact': baseAbility + variation,
      'power': baseAbility + variation,
      'plate_discipline': baseAbility + variation,
      'bunt': baseAbility + variation,
      'opposite_field_hitting': baseAbility + variation,
      'pull_hitting': baseAbility + variation,
      'bat_control': baseAbility + variation,
      'swing_speed': baseAbility + variation,
      'fielding': baseAbility + variation,
      'throwing': baseAbility + variation,
      'catcher_ability': baseAbility + variation,
      'control': baseAbility + variation,
      'fastball': baseAbility + variation,
      'breaking_ball': baseAbility + variation,
      'pitch_movement': baseAbility + variation,
      // Mental abilities
      'concentration': baseAbility + variation,
      'anticipation': baseAbility + variation,
      'vision': baseAbility + variation,
      'composure': baseAbility + variation,
      'aggression': baseAbility + variation,
      'bravery': baseAbility + variation,
      'leadership': baseAbility + variation,
      'work_rate': baseAbility + variation,
      'self_discipline': baseAbility + variation,
      'ambition': baseAbility + variation,
      'teamwork': baseAbility + variation,
      'positioning': baseAbility + variation,
      'pressure_handling': baseAbility + variation,
      'clutch_ability': baseAbility + variation,
      // Physical abilities
      'acceleration': baseAbility + variation,
      'agility': baseAbility + variation,
      'balance': baseAbility + variation,
      'jumping_reach': baseAbility + variation,
      'natural_fitness': baseAbility + variation,
      'injury_proneness': 20 + random.nextInt(20), // 20-39（低い方が良い）
      'stamina': baseAbility + variation,
      'strength': baseAbility + variation,
      'pace': baseAbility + variation,
      'flexibility': baseAbility + variation,
      // 総合能力値
      'overall': baseAbility + variation,
      'technical': baseAbility + variation,
      'physical': baseAbility + variation,
      'mental': baseAbility + variation,
    };
    
    return {
      'person': personData,
      'player': playerData,
    };
  }
}