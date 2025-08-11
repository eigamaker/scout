import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../models/scouting/scout.dart';
import '../services/scouting/accuracy_calculator.dart';
import '../services/scouting/scout_analysis_service.dart';
import '../services/data_service.dart';
import '../services/game_manager.dart';
import '../config/debug_config.dart';
import 'debug_player_detail_screen.dart';

// カテゴリ状況の判定
enum CategoryStatus { complete, partial, unknown }

class PlayerDetailScreen extends StatefulWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  final DataService _dataService = DataService();
  final ScoutAnalysisService _scoutAnalysisService = ScoutAnalysisService(DataService());
  bool _isLoading = true;
  Map<String, int>? _scoutAnalysisData;
  Map<String, dynamic>? _basicInfoAnalysisData;

  // 表示名からデータベースカラム名への変換マップ
  static final Map<String, String> _displayNameToColumnName = {
    // Technical abilities
    'ミート': 'contact_scouted',
    'パワー': 'power_scouted',
    '選球眼': 'plate_discipline_scouted',
    'バント': 'bunt_scouted',
    '流し打ち': 'opposite_field_hitting_scouted',
    'プルヒッティング': 'pull_hitting_scouted',
    'バットコントロール': 'bat_control_scouted',
    'スイングスピード': 'swing_speed_scouted',
    '捕球': 'fielding_scouted',
    '送球': 'throwing_scouted',
    '捕手リード': 'catcher_ability_scouted',
    'コントロール': 'control_scouted',
    '球速': 'fastball_scouted',
    '変化球': 'breaking_ball_scouted',
    '球種変化量': 'pitch_movement_scouted',
    
    // Mental abilities
    '集中力': 'concentration_scouted',
    '予測力': 'anticipation_scouted',
    '視野': 'vision_scouted',
    '冷静さ': 'composure_scouted',
    '積極性': 'aggression_scouted',
    '勇敢さ': 'bravery_scouted',
    'リーダーシップ': 'leadership_scouted',
    '勤勉さ': 'work_rate_scouted',
    '自己管理': 'self_discipline_scouted',
    '野心': 'ambition_scouted',
    'チームワーク': 'teamwork_scouted',
    'ポジショニング': 'positioning_scouted',
    'プレッシャー耐性': 'pressure_handling_scouted',
    '勝負強さ': 'clutch_ability_scouted',
    
    // Physical abilities
    '加速力': 'acceleration_scouted',
    '敏捷性': 'agility_scouted',
    'バランス': 'balance_scouted',
    '走力': 'pace_scouted',
    '持久力': 'stamina_scouted',
    '筋力': 'strength_scouted',
    '柔軟性': 'flexibility_scouted',
    'ジャンプ力': 'jumping_reach_scouted',
    '自然体力': 'natural_fitness_scouted',
    '怪我しやすさ': 'injury_proneness_scouted',
  };

  @override
  void initState() {
    super.initState();
    _loadScoutAnalysisData();
    _debugTableStructure();
  }

  /// テーブル構造をデバッグ出力
  Future<void> _debugTableStructure() async {
    try {
      await _scoutAnalysisService.debugTableStructure();
    } catch (e) {
      print('テーブル構造確認エラー: $e');
    }
  }

  /// スカウト分析データを読み込み
  Future<void> _loadScoutAnalysisData() async {
    if (widget.player.id != null) {
      try {
        final scoutId = '1'; // 現在のスカウトID（action_service.dartと統一）
        print('スカウト分析データ読み込み開始: プレイヤーID ${widget.player.id}, スカウトID $scoutId');
        
        // 能力値の分析データを読み込み
        final analysisData = await _scoutAnalysisService.getLatestScoutAnalysis(
          widget.player.id!, 
          scoutId
        );
        print('能力値分析データ: $analysisData');
        
        // 基本情報の分析データを読み込み
        final basicInfoData = await _scoutAnalysisService.getLatestBasicInfoAnalysis(
          widget.player.id!, 
          scoutId
        );
        print('基本情報分析データ: $basicInfoData');
        
        setState(() {
          _scoutAnalysisData = analysisData;
          _basicInfoAnalysisData = basicInfoData;
          _isLoading = false;
        });
        
        print('スカウト分析データ読み込み完了');
      } catch (e) {
        print('スカウト分析データの読み込みエラー: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('プレイヤーIDがnullのため、スカウト分析データを読み込めません');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 表示用能力値を取得（常にスカウト分析データを優先、デバッグでは真の値も併記）
  int _getDisplayAbility(String abilityName) {
    // スカウト分析データを優先（_scoutAnalysisDataまたはwidget.player.scoutAnalysisData）
    final scoutData = _scoutAnalysisData ?? widget.player.scoutAnalysisData;
    
    if (scoutData != null && scoutData.containsKey(abilityName)) {
      final value = scoutData[abilityName]!;
      print('能力値取得: $abilityName = $value (スカウト分析データ)');
      return value;
    }
    
    // スカウト分析データがない場合は0を返す（不明として扱う）
    print('能力値取得: $abilityName = 不明 (スカウト分析データなし)');
    return 0;
  }

  /// 技術面能力値を取得
  int _getDisplayTechnicalAbility(TechnicalAbility ability) {
    final abilityName = _getTechnicalAbilityName(ability);
    if (abilityName == null) {
      print('技術面能力値名取得失敗: $ability');
      return 0; // 不明として扱う
    }
    return _getDisplayAbility(abilityName);
  }

  /// メンタル面能力値を取得
  int _getDisplayMentalAbility(MentalAbility ability) {
    final abilityName = _getMentalAbilityName(ability);
    if (abilityName == null) {
      print('メンタル面能力値名取得失敗: $ability');
      return 0; // 不明として扱う
    }
    return _getDisplayAbility(abilityName);
  }

  /// フィジカル面能力値を取得
  int _getDisplayPhysicalAbility(PhysicalAbility ability) {
    final abilityName = _getPhysicalAbilityName(ability);
    if (abilityName == null) {
      print('フィジカル面能力値名取得失敗: $ability');
      return 0; // 不明として扱う
    }
    return _getDisplayAbility(abilityName);
  }

  /// 真の能力値を取得
  int _getTrueAbilityValue(String abilityName) {
    switch (abilityName) {
      case 'fastballVelo':
        return widget.player.veloScore;
      case 'contact':
        return widget.player.getTechnicalAbility(TechnicalAbility.contact);
      case 'power':
        return widget.player.getTechnicalAbility(TechnicalAbility.power);
      case 'plateDiscipline':
        return widget.player.getTechnicalAbility(TechnicalAbility.plateDiscipline);
      case 'bunt':
        return widget.player.getTechnicalAbility(TechnicalAbility.bunt);
      case 'oppositeFieldHitting':
        return widget.player.getTechnicalAbility(TechnicalAbility.oppositeFieldHitting);
      case 'pullHitting':
        return widget.player.getTechnicalAbility(TechnicalAbility.pullHitting);
      case 'batControl':
        return widget.player.getTechnicalAbility(TechnicalAbility.batControl);
      case 'swingSpeed':
        return widget.player.getTechnicalAbility(TechnicalAbility.swingSpeed);
      case 'fielding':
        return widget.player.getTechnicalAbility(TechnicalAbility.fielding);
      case 'throwing':
        return widget.player.getTechnicalAbility(TechnicalAbility.throwing);
      case 'catcherAbility':
        return widget.player.getTechnicalAbility(TechnicalAbility.catcherAbility);
      case 'control':
        return widget.player.getTechnicalAbility(TechnicalAbility.control);
      case 'fastball':
        return widget.player.getTechnicalAbility(TechnicalAbility.fastball);
      case 'breakingBall':
        return widget.player.getTechnicalAbility(TechnicalAbility.breakingBall);
      case 'pitchMovement':
        return widget.player.getTechnicalAbility(TechnicalAbility.pitchMovement);
      case 'concentration':
        return widget.player.getMentalAbility(MentalAbility.concentration);
      case 'anticipation':
        return widget.player.getMentalAbility(MentalAbility.anticipation);
      case 'vision':
        return widget.player.getMentalAbility(MentalAbility.vision);
      case 'composure':
        return widget.player.getMentalAbility(MentalAbility.composure);
      case 'aggression':
        return widget.player.getMentalAbility(MentalAbility.aggression);
      case 'bravery':
        return widget.player.getMentalAbility(MentalAbility.bravery);
      case 'leadership':
        return widget.player.getMentalAbility(MentalAbility.leadership);
      case 'workRate':
        return widget.player.getMentalAbility(MentalAbility.workRate);
      case 'selfDiscipline':
        return widget.player.getMentalAbility(MentalAbility.selfDiscipline);
      case 'ambition':
        return widget.player.getMentalAbility(MentalAbility.ambition);
      case 'teamwork':
        return widget.player.getMentalAbility(MentalAbility.teamwork);
      case 'positioning':
        return widget.player.getMentalAbility(MentalAbility.positioning);
      case 'pressureHandling':
        return widget.player.getMentalAbility(MentalAbility.pressureHandling);
      case 'clutchAbility':
        return widget.player.getMentalAbility(MentalAbility.clutchAbility);
      case 'acceleration':
        return widget.player.getPhysicalAbility(PhysicalAbility.acceleration);
      case 'agility':
        return widget.player.getPhysicalAbility(PhysicalAbility.agility);
      case 'balance':
        return widget.player.getPhysicalAbility(PhysicalAbility.balance);
      case 'pace':
        return widget.player.getPhysicalAbility(PhysicalAbility.pace);
      case 'stamina':
        return widget.player.getPhysicalAbility(PhysicalAbility.stamina);
      case 'strength':
        return widget.player.getPhysicalAbility(PhysicalAbility.strength);
      case 'flexibility':
        return widget.player.getPhysicalAbility(PhysicalAbility.flexibility);
      case 'jumpingReach':
        return widget.player.getPhysicalAbility(PhysicalAbility.jumpingReach);
      case 'naturalFitness':
        return widget.player.getPhysicalAbility(PhysicalAbility.naturalFitness);
      case 'injuryProneness':
        return widget.player.getPhysicalAbility(PhysicalAbility.injuryProneness);
      default:
        return 25;
    }
  }

  /// ポテンシャル値を取得
  int? _getPotentialValue(String abilityName) {
    if (!DebugConfig.showPotentials || widget.player.individualPotentials == null) {
    return null;
  }
      return widget.player.individualPotentials![abilityName];
  }

  /// 技術面能力値のデータベースカラム名を取得
  String? _getTechnicalAbilityName(TechnicalAbility ability) {
    switch (ability) {
      case TechnicalAbility.contact: return 'contact_scouted';
      case TechnicalAbility.power: return 'power_scouted';
      case TechnicalAbility.plateDiscipline: return 'plate_discipline_scouted';
      case TechnicalAbility.bunt: return 'bunt_scouted';
      case TechnicalAbility.oppositeFieldHitting: return 'opposite_field_hitting_scouted';
      case TechnicalAbility.pullHitting: return 'pull_hitting_scouted';
      case TechnicalAbility.batControl: return 'bat_control_scouted';
      case TechnicalAbility.swingSpeed: return 'swing_speed_scouted';
      case TechnicalAbility.fielding: return 'fielding_scouted';
      case TechnicalAbility.throwing: return 'throwing_scouted';
      case TechnicalAbility.catcherAbility: return 'catcher_ability_scouted';
      case TechnicalAbility.control: return 'control_scouted';
      case TechnicalAbility.fastball: return 'fastball_scouted';
      case TechnicalAbility.breakingBall: return 'breaking_ball_scouted';
      case TechnicalAbility.pitchMovement: return 'pitch_movement_scouted';
    }
  }

  /// メンタル面能力値のデータベースカラム名を取得
  String? _getMentalAbilityName(MentalAbility ability) {
    switch (ability) {
      case MentalAbility.concentration: return 'concentration_scouted';
      case MentalAbility.anticipation: return 'anticipation_scouted';
      case MentalAbility.vision: return 'vision_scouted';
      case MentalAbility.composure: return 'composure_scouted';
      case MentalAbility.aggression: return 'aggression_scouted';
      case MentalAbility.bravery: return 'bravery_scouted';
      case MentalAbility.leadership: return 'leadership_scouted';
      case MentalAbility.workRate: return 'work_rate_scouted';
      case MentalAbility.selfDiscipline: return 'self_discipline_scouted';
      case MentalAbility.ambition: return 'ambition_scouted';
      case MentalAbility.teamwork: return 'teamwork_scouted';
      case MentalAbility.positioning: return 'positioning_scouted';
      case MentalAbility.pressureHandling: return 'pressure_handling_scouted';
      case MentalAbility.clutchAbility: return 'clutch_ability_scouted';
    }
  }

  /// フィジカル面能力値のデータベースカラム名を取得
  String? _getPhysicalAbilityName(PhysicalAbility ability) {
    switch (ability) {
      case PhysicalAbility.acceleration: return 'acceleration_scouted';
      case PhysicalAbility.agility: return 'agility_scouted';
      case PhysicalAbility.balance: return 'balance_scouted';
      case PhysicalAbility.jumpingReach: return 'jumping_reach_scouted';
      case PhysicalAbility.flexibility: return 'flexibility_scouted';
      case PhysicalAbility.naturalFitness: return 'natural_fitness_scouted';
      case PhysicalAbility.injuryProneness: return 'injury_proneness_scouted';
      case PhysicalAbility.stamina: return 'stamina_scouted';
      case PhysicalAbility.strength: return 'strength_scouted';
      case PhysicalAbility.pace: return 'pace_scouted';
    }
  }

  /// スカウトの分析精度を計算
  double _getScoutAnalysisAccuracy(String skillType) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final scout = gameManager.currentScout;
    
    if (scout == null) {
      return 0.0; // スカウトが存在しない場合は精度0
    }
    
    switch (skillType) {
      case 'personality':
        return (scout.getSkill(ScoutSkill.communication) * 0.7 + scout.getSkill(ScoutSkill.insight) * 0.3) * 8;
      case 'talent':
        return (scout.getSkill(ScoutSkill.exploration) * 0.5 + scout.getSkill(ScoutSkill.insight) * 0.5) * 8;
      case 'growth':
        return (scout.getSkill(ScoutSkill.analysis) * 0.6 + scout.getSkill(ScoutSkill.observation) * 0.4) * 8;
      case 'mental':
        return (scout.getSkill(ScoutSkill.insight) * 0.6 + scout.getSkill(ScoutSkill.communication) * 0.4) * 8;
      case 'potential':
        return (scout.getSkill(ScoutSkill.insight) * 0.6 + scout.getSkill(ScoutSkill.analysis) * 0.4) * 8;
      default:
        return 0.0;
    }
  }

  /// スカウト完了度を計算
  double _getScoutCompletionRate() {
    if (!widget.player.isDiscovered) {
      return 0.0;
    }
    
    // 能力値の把握度を計算
    final abilityKnowledge = widget.player.abilityKnowledge;
    if (abilityKnowledge.isEmpty) {
      return 0.0;
    }
    
    // 全能力値の把握度の平均を計算
    final totalKnowledge = abilityKnowledge.values.reduce((a, b) => a + b);
    final averageKnowledge = totalKnowledge / abilityKnowledge.length;
    
    return averageKnowledge / 100.0; // 0.0-1.0の範囲に正規化
  }

  /// スカウト完了度の表示テキストを取得
  String _getScoutCompletionText() {
    final completionRate = _getScoutCompletionRate();
    
    if (completionRate == 0.0) {
      return '未発掘';
    } else if (completionRate < 0.2) {
      return '初期スカウト';
    } else if (completionRate < 0.4) {
      return '基本調査済み';
    } else if (completionRate < 0.6) {
      return '詳細調査中';
    } else if (completionRate < 0.8) {
      return 'ほぼ完了';
    } else {
      return '完全スカウト済み';
    }
  }

  /// スカウト完了度の色を取得
  Color _getScoutCompletionColor() {
    final completionRate = _getScoutCompletionRate();
    
    if (completionRate == 0.0) {
      return Colors.grey;
    } else if (completionRate < 0.2) {
      return Colors.orange;
    } else if (completionRate < 0.4) {
      return Colors.yellow;
    } else if (completionRate < 0.6) {
      return Colors.lightBlue;
    } else if (completionRate < 0.8) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  /// 分析データが存在するかを確認
  bool _hasAnyAnalysisData() {
    // スカウト分析データまたは基本情報分析データがあるかを確認
    final hasScoutData = _scoutAnalysisData != null && _scoutAnalysisData!.isNotEmpty;
    final hasBasicInfoData = _basicInfoAnalysisData != null && _basicInfoAnalysisData!.isNotEmpty;
    return hasScoutData || hasBasicInfoData;
  }

  /// 表示用性格を取得
  String _getDisplayPersonality() {
    if (DebugConfig.showTrueValues) {
      return widget.player.personality;
    }
    
    // 保存された分析データがある場合はそれを使用
    if (_basicInfoAnalysisData != null && _basicInfoAnalysisData!['personality'] != null) {
      return _basicInfoAnalysisData!['personality'] as String;
    }
    
    // 分析データがない場合はリアルタイムで計算
    final accuracy = _getScoutAnalysisAccuracy('personality');
    
    if (accuracy < 30) {
      return '性格不明';
    } else if (accuracy < 50) {
      // 基本的な性格傾向のみ把握
      final personalities = ['内向的', '外向的', 'リーダー型', 'フォロワー型'];
      return personalities[widget.player.talent % personalities.length];
    } else if (accuracy < 70) {
      // より詳細な性格特徴を把握
      final personalities = ['冷静沈着', '情に厚い', '負けず嫌い', '謙虚'];
      return personalities[widget.player.talent % personalities.length];
    } else {
      // 高度な性格分析
      final personalities = ['勝負強さがある', 'チームプレー重視', '個人主義的'];
      return personalities[widget.player.talent % personalities.length];
    }
  }

  /// 表示用才能ランクを取得
  String _getDisplayTalent() {
    if (DebugConfig.showTrueValues) {
      return 'ランク${widget.player.talent}';
    }
    
    // 保存された分析データがある場合はそれを使用
    if (_basicInfoAnalysisData != null && _basicInfoAnalysisData!['talent'] != null) {
      return _basicInfoAnalysisData!['talent'] as String;
    }
    
    // 分析データがない場合はリアルタイムで計算
    final accuracy = _getScoutAnalysisAccuracy('talent');
    
    if (accuracy < 30) {
      return '才能不明';
    } else if (accuracy < 50) {
      return widget.player.talent >= 7 ? '才能あり' : '才能なし';
    } else if (accuracy < 70) {
      if (widget.player.talent >= 8) return '隠れた才能';
      else if (widget.player.talent >= 6) return '期待の星';
      else return '平均的';
    } else {
      if (widget.player.talent >= 9) return '超高校級';
      else if (widget.player.talent >= 7) return '一流';
      else if (widget.player.talent >= 5) return '有望';
      else return '平均';
    }
  }

  /// 表示用成長タイプを取得
  String _getDisplayGrowthType() {
    if (DebugConfig.showTrueValues) {
      return widget.player.growthType;
    }
    
    // 保存された分析データがある場合はそれを使用
    if (_basicInfoAnalysisData != null && _basicInfoAnalysisData!['growth'] != null) {
      return _basicInfoAnalysisData!['growth'] as String;
    }
    
    // 分析データがない場合はリアルタイムで計算
    final accuracy = _getScoutAnalysisAccuracy('growth');
    
    if (accuracy < 30) {
      return '成長不明';
    } else if (accuracy < 50) {
      return widget.player.growthRate > 0.5 ? '成長中' : '停滞中';
    } else if (accuracy < 70) {
      if (widget.player.growthRate > 0.7) return '急成長';
      else if (widget.player.growthRate > 0.4) return '安定成長';
      else return '緩やか成長';
    } else {
      if (widget.player.growthRate > 0.8) return '爆発的成長';
      else if (widget.player.growthRate > 0.6) return '順調成長';
      else if (widget.player.growthRate > 0.3) return '緩やか成長';
      else return '停滞';
    }
  }

  /// 表示用精神力を取得
  String _getDisplayMentalGrit() {
    if (DebugConfig.showTrueValues) {
      return '${(widget.player.mentalGrit * 100).round()}%';
    }
    
    // 保存された分析データがある場合はそれを使用
    if (_basicInfoAnalysisData != null && _basicInfoAnalysisData!['mental_grit'] != null) {
      return _basicInfoAnalysisData!['mental_grit'] as String;
    }
    
    // 分析データがない場合はリアルタイムで計算
    final accuracy = _getScoutAnalysisAccuracy('mental');
    
    if (accuracy < 30) {
      return '精神力不明';
    } else if (accuracy < 50) {
      if (widget.player.mentalGrit > 0.7) return '強い';
      else if (widget.player.mentalGrit > 0.4) return '普通';
      else return '弱い';
    } else if (accuracy < 70) {
      if (widget.player.mentalGrit > 0.8) return '鋼の精神';
      else if (widget.player.mentalGrit > 0.5) return '安定した精神';
      else return '不安定';
    } else {
      if (widget.player.mentalGrit > 0.8) return '逆境に強い';
      else if (widget.player.mentalGrit < 0.3) return 'プレッシャーに弱い';
      else return '勝負強さあり';
    }
  }

  /// 表示用ポテンシャルを取得
  String _getDisplayPeakAbility() {
    if (DebugConfig.showTrueValues) {
      return '${widget.player.peakAbility}';
    }
    
    // 保存された分析データがある場合はそれを使用
    if (_basicInfoAnalysisData != null && _basicInfoAnalysisData!['potential'] != null) {
      return _basicInfoAnalysisData!['potential'] as String;
    }
    
    // 分析データがない場合はリアルタイムで計算
    final accuracy = _getScoutAnalysisAccuracy('potential');
    
    if (accuracy < 30) {
      return '将来性不明';
    } else if (accuracy < 50) {
      if (widget.player.peakAbility >= 80) return '有望';
      else if (widget.player.peakAbility >= 60) return '普通';
      else return '期待薄';
    } else if (accuracy < 70) {
      if (widget.player.peakAbility >= 85) return '大物候補';
      else if (widget.player.peakAbility >= 70) return '期待の星';
      else return '平均的将来性';
    } else {
      if (widget.player.peakAbility >= 90) return 'プロ級';
      else if (widget.player.peakAbility >= 80) return '大学トップ級';
      else if (widget.player.peakAbility >= 65) return '実業団級';
      else return 'アマチュア級';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.player.name}の詳細'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final textColor = Colors.white;
    final cardBg = Colors.grey[900]!;
    final primaryColor = Colors.blue[400]!;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('${widget.player.name}の詳細'),
            const SizedBox(width: 8),
            // 分類バッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.player.categoryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.player.categoryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (DebugConfig.isDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DebugPlayerDetailScreen(player: widget.player),
                  ),
                );
              },
              tooltip: 'デバッグ画面',
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景グラデーション
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color.fromARGB(180, 0, 0, 0),
                ],
              ),
            ),
          ),
          // メイン内容
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー情報
                _buildHeaderCard(context, textColor, cardBg, primaryColor),
                const SizedBox(height: 16),
                
                // 基本情報カード
                _buildBasicInfoCard(context, textColor, cardBg),
                const SizedBox(height: 16),
                
                // 能力値システム
                if (widget.player.isDiscovered || widget.player.fame >= 65) ...[
                  _buildNewAbilityCard(context, textColor, cardBg, primaryColor),
                  const SizedBox(height: 16),
                ],
                
                // 球種情報
                if ((widget.player.isDiscovered || widget.player.fame >= 80) && 
                    widget.player.isPitcher && widget.player.pitches != null && 
                    widget.player.pitches!.isNotEmpty) ...[
                  _buildPitchesCard(context, textColor, cardBg),
                  const SizedBox(height: 16),
                ],
                
                // ポジション適性
                if (widget.player.isDiscovered || widget.player.fame >= 80) ...[
                  _buildPositionFitCard(context, textColor, cardBg, primaryColor),
                  const SizedBox(height: 16),
                ],
                
                // スカウト評価・メモ
                if (widget.player.isDiscovered) ...[
                  _buildScoutNotesCard(context, textColor, cardBg),
                  const SizedBox(height: 16),
                ],
                
                // 情報が表示されない場合のメッセージ
                if (!widget.player.isDiscovered && widget.player.fame < 65) ...[
                  _buildInfoInsufficientCard(context, textColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ヘッダーカード
  Widget _buildHeaderCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 選手名（フル表示）
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.player.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // お気に入りボタン
                IconButton(
                  icon: Icon(
                    widget.player.isScoutFavorite ? Icons.favorite : Icons.favorite_border,
                    color: widget.player.isScoutFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () async {
                    // GameManagerを通じてお気に入り状態を更新
                    final gameManager = Provider.of<GameManager>(context, listen: false);
                    final dataService = Provider.of<DataService>(context, listen: false);
                    await gameManager.togglePlayerFavorite(widget.player, dataService);
                    
                    // UIを更新
                    setState(() {});
                  },
                  tooltip: widget.player.isScoutFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 学校・学年・ポジション・スカウト状態
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.player.school} ${widget.player.grade}年',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.player.position,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_hasAnyAnalysisData())
                            _buildStatusChip(
                              '分析済み',
                              '✓',
                              Colors.green,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 基本情報カード
  Widget _buildBasicInfoCard(BuildContext context, Color textColor, Color cardBg) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本情報',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoRow('性格', _getDisplayPersonality(), textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('才能', _getDisplayTalent(), textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('成長', _getDisplayGrowthType(), textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoRow('精神力', _getDisplayMentalGrit(), textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('ポテンシャル', _getDisplayPeakAbility(), textColor),
                ),
                const SizedBox(width: 16),
                // 空のスペースを追加して3列のレイアウトを維持
                Expanded(
                  child: Container(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 能力値システムカード
  Widget _buildNewAbilityCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 技術面能力値
        _buildTechnicalAbilitiesCard(context, textColor, cardBg, primaryColor),
        const SizedBox(height: 16),
        
        // メンタル面能力値
        _buildMentalAbilitiesCard(context, textColor, cardBg, Colors.green),
        const SizedBox(height: 16),
        
        // フィジカル面能力値
        _buildPhysicalAbilitiesCard(context, textColor, cardBg, Colors.orange),
      ],
    );
  }
  
  // 技術面能力値カード
  Widget _buildTechnicalAbilitiesCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    final categoryStatus = _getTechnicalAbilityCategoryStatus();
    
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '技術面',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildCategoryStatusIcon(categoryStatus),
              ],
            ),
            const SizedBox(height: 8),
            
            // カテゴリ状況メッセージ
            _buildCategoryStatusMessage(categoryStatus, '技術面', '試合観戦や練習試合観戦', textColor),
            const SizedBox(height: 16),
            
            // 投手技術
            _buildAbilitySubCategory(
              context, 
              textColor, 
              primaryColor, 
              '投手技術', 
              [
                TechnicalAbility.control,
                TechnicalAbility.fastball,
                TechnicalAbility.breakingBall,
                TechnicalAbility.pitchMovement,
              ].map((ability) => 
                _buildAbilityRow(ability.displayName, _getDisplayTechnicalAbility(ability), textColor, primaryColor)
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // 打撃技術
            _buildAbilitySubCategory(
              context, 
              textColor, 
              primaryColor, 
              '打撃技術', 
              [
                TechnicalAbility.contact,
                TechnicalAbility.power,
                TechnicalAbility.plateDiscipline,
                TechnicalAbility.bunt,
                TechnicalAbility.oppositeFieldHitting,
                TechnicalAbility.pullHitting,
                TechnicalAbility.batControl,
                TechnicalAbility.swingSpeed,
              ].map((ability) => 
                _buildAbilityRow(ability.displayName, _getDisplayTechnicalAbility(ability), textColor, primaryColor)
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // 守備技術
            _buildAbilitySubCategory(
              context, 
              textColor, 
              primaryColor, 
              '守備技術', 
              [
                TechnicalAbility.fielding,
                TechnicalAbility.throwing,
                TechnicalAbility.catcherAbility,
              ].map((ability) => 
                _buildAbilityRow(ability.displayName, _getDisplayTechnicalAbility(ability), textColor, primaryColor)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  // メンタル面能力値カード
  Widget _buildMentalAbilitiesCard(BuildContext context, Color textColor, Color cardBg, Color categoryColor) {
    final categoryStatus = _getMentalAbilityCategoryStatus();
    
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'メンタル面',
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildCategoryStatusIcon(categoryStatus),
              ],
            ),
            const SizedBox(height: 8),
            
            // カテゴリ状況メッセージ
            _buildCategoryStatusMessage(categoryStatus, 'メンタル面', 'インタビュー', textColor),
            const SizedBox(height: 16),
            
            // 集中力・判断力
            _buildAbilitySubCategory(
              context, 
              textColor, 
              categoryColor, 
              '集中力・判断力', 
              [
                MentalAbility.concentration,
                MentalAbility.anticipation,
                MentalAbility.vision,
                MentalAbility.composure,
              ].map((ability) => 
                _buildAbilityRow(ability.displayName, _getDisplayMentalAbility(ability), textColor, categoryColor)
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // 性格・精神面
            _buildAbilitySubCategory(
              context, 
              textColor, 
              categoryColor, 
              '性格・精神面', 
              [
                MentalAbility.aggression,
                MentalAbility.bravery,
                MentalAbility.leadership,
                MentalAbility.workRate,
                MentalAbility.selfDiscipline,
                MentalAbility.ambition,
              ].map((ability) => 
                _buildAbilityRow(ability.displayName, _getDisplayMentalAbility(ability), textColor, categoryColor)
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // チームプレー
            _buildAbilitySubCategory(
              context, 
              textColor, 
              categoryColor, 
              'チームプレー', 
              [
                MentalAbility.teamwork,
                MentalAbility.positioning,
                MentalAbility.pressureHandling,
                MentalAbility.clutchAbility,
              ].map((ability) => 
                _buildAbilityRow(ability.displayName, _getDisplayMentalAbility(ability), textColor, categoryColor)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  // フィジカル面能力値カード
  Widget _buildPhysicalAbilitiesCard(BuildContext context, Color textColor, Color cardBg, Color categoryColor) {
    final categoryStatus = _getPhysicalAbilityCategoryStatus();
    
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'フィジカル面',
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildCategoryStatusIcon(categoryStatus),
              ],
            ),
            const SizedBox(height: 8),
            
            // カテゴリ状況メッセージ
            _buildCategoryStatusMessage(categoryStatus, 'フィジカル面', '練習視察', textColor),
            const SizedBox(height: 16),
            
            // 運動能力
            _buildAbilitySubCategory(
              context, 
              textColor, 
              categoryColor, 
              '運動能力', 
              [
                PhysicalAbility.acceleration,
                PhysicalAbility.agility,
                PhysicalAbility.balance,
                PhysicalAbility.pace,
              ].map((ability) => 
                _buildAbilityRow(ability.displayName, _getDisplayPhysicalAbility(ability), textColor, categoryColor)
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // 体力・筋力
            _buildAbilitySubCategory(
              context, 
              textColor, 
              categoryColor, 
              '体力・筋力', 
              [
                PhysicalAbility.stamina,
                PhysicalAbility.strength,
                PhysicalAbility.flexibility,
                PhysicalAbility.jumpingReach,
              ].map((ability) => 
                _buildAbilityRow(ability.displayName, _getDisplayPhysicalAbility(ability), textColor, categoryColor)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAbilitySubCategory(BuildContext context, Color textColor, Color primaryColor, String title, List<Widget> abilities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryColor.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...abilities,
      ],
    );
  }
  
  Widget _buildAbilityRow(String label, int value, Color textColor, Color primaryColor) {
    // 球速の場合は実際のkm/hで表示
    final isFastball = label == '球速';
    
    // スカウト分析データの確認
    final scoutData = _scoutAnalysisData ?? widget.player.scoutAnalysisData;
    final abilityName = _getAbilityNameFromLabel(label);
    final hasScoutData = scoutData != null && abilityName != null && scoutData.containsKey(abilityName);
    
    // 判定しきれていない場合の処理
    final isUnknown = !hasScoutData || value == 0; // スカウト分析データがない場合または0の場合は不明
    
    int finalDisplayValue;
    String displayText;
    Color displayColor;
    
    if (isUnknown) {
      // 判定しきれていない場合は「不明」と表示
      finalDisplayValue = 0;
      displayText = '不明';
      displayColor = Colors.grey;
    } else if (isFastball) {
      // スカウト分析の値（0-100）を球速に変換
      // 高校生の場合：25-100 → 125-155km/h
      if (value <= 100) {
        finalDisplayValue = 125 + ((value - 25) * 30 / 75).round();
      } else {
        // 100を超える場合は155km/hに制限
        finalDisplayValue = 155;
      }
      displayText = '${finalDisplayValue}km/h';
      displayColor = textColor;
    } else {
      finalDisplayValue = value;
      displayText = '$finalDisplayValue';
      displayColor = textColor;
    }
    
    // デバッグモードの場合、真の値も表示
    final debugInfo = DebugConfig.showTrueValues ? 
      (isFastball ? ' (真の球速: ${widget.player.getFastballVelocityKmh()}km/h)' : ' (真の値: ${_getTrueAbilityValueFromLabel(label)})') : '';
    
    // ポテンシャル値を取得
    int? potentialValue;
    if (DebugConfig.showPotentials && widget.player.individualPotentials != null) {
      final abilityName = _getAbilityNameFromLabel(label);
      if (isFastball) {
        potentialValue = widget.player.individualPotentials!['fastballVelo'];
      } else if (abilityName != null) {
        potentialValue = widget.player.individualPotentials![abilityName];
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              if (!isFastball) ...[
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isUnknown ? Colors.grey.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: isUnknown ? 0.0 : (finalDisplayValue / 100.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnknown ? Colors.grey : primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: isFastball ? 60 : 40,
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: displayColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (DebugConfig.showTrueValues) ...[
                const SizedBox(width: 8),
                Text(
                  debugInfo,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        // スカウト分析データがない場合のメッセージ
        if (!hasScoutData) ...[
          Padding(
            padding: const EdgeInsets.only(left: 120, right: 8),
            child: Text(
              '分析不足',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        // デバッグモードでポテンシャルを表示
        if (DebugConfig.showPotentials && potentialValue != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 120, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: potentialValue / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ポテンシャル: $potentialValue',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  // ラベルからデータベースカラム名を取得
  String? _getAbilityNameFromLabel(String label) {
    return _displayNameToColumnName[label];
  }

  // ラベルから真の能力値を取得
  int _getTrueAbilityValueFromLabel(String label) {
    final abilityName = _getAbilityNameFromLabel(label);
    if (abilityName == null) return 0;
    return _getTrueAbilityValue(abilityName);
  }

  // 球種カード
  Widget _buildPitchesCard(BuildContext context, Color textColor, Color cardBg) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '球種',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.player.pitches!.map((pitch) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      pitch.type,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '変化量: ${pitch.breakAmount} / 潜在: ${pitch.breakPot}',
                      style: TextStyle(color: textColor.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  // ポジション適性カード
  Widget _buildPositionFitCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ポジション適性',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.player.positionFit.entries.map((entry) => 
                _buildPositionChip(entry.key, entry.value, textColor, primaryColor)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // スカウトメモカード
  Widget _buildScoutNotesCard(BuildContext context, Color textColor, Color cardBg) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スカウトメモ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.player.scoutEvaluation != null && widget.player.scoutEvaluation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '評価: ${widget.player.scoutEvaluation!}',
                  style: TextStyle(color: textColor),
                ),
              ),
            if (widget.player.scoutNotes != null && widget.player.scoutNotes!.isNotEmpty)
              Text(
                'メモ: ${widget.player.scoutNotes!}',
                style: TextStyle(color: textColor),
              ),
          ],
        ),
      ),
    );
  }

  // 情報不足カード
  Widget _buildInfoInsufficientCard(BuildContext context, Color textColor) {
    return Card(
      color: Colors.orange.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '情報収集が必要',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'この選手についての情報が不足しています。\n以下のアクションを実行して情報を収集してください：',
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 12),
            _buildActionRecommendations(context, textColor),
          ],
        ),
      ),
    );
  }

  // アクション推奨表示
  Widget _buildActionRecommendations(BuildContext context, Color textColor) {
    final recommendations = <Widget>[];
    
    // 基本情報が不明な場合
    if (_getDisplayPersonality() == '性格不明' || _getDisplayTalent() == '才能不明' || 
        _getDisplayGrowthType() == '成長不明' || _getDisplayMentalGrit() == '精神力不明' || 
        _getDisplayPeakAbility() == '将来性不明') {
      recommendations.add(_buildActionRecommendation(
        context,
        '📹 ビデオ分析',
        '才能、成長タイプ、ポテンシャルを分析します',
        Colors.purple,
        textColor,
      ));
    }
    
    // 技術面の能力値が不明な場合
    if (_hasUnknownTechnicalAbilities()) {
      recommendations.add(_buildActionRecommendation(
        context,
        '🏟️ 練習試合観戦',
        '技術面の能力値を観察します',
        Colors.orange,
        textColor,
      ));
    }
    
    // フィジカル面の能力値が不明な場合
    if (_hasUnknownPhysicalAbilities()) {
      recommendations.add(_buildActionRecommendation(
        context,
        '🏃 練習視察',
        'フィジカル面の能力値を観察します',
        Colors.blue,
        textColor,
      ));
    }
    
    // メンタル面の能力値が不明な場合
    if (_hasUnknownMentalAbilities()) {
      recommendations.add(_buildActionRecommendation(
        context,
        '💬 インタビュー',
        'メンタル面の能力値を把握します',
        Colors.green,
        textColor,
      ));
    }
    
    // 全体的な情報が不足している場合
    if (recommendations.isEmpty) {
      recommendations.add(_buildActionRecommendation(
        context,
        '⚾ 試合観戦',
        '技術面とフィジカル面の能力値を観察します',
        Colors.red,
        textColor,
      ));
    }
    
    return Column(
      children: recommendations,
    );
  }

  // アクション推奨カード
  Widget _buildActionRecommendation(
    BuildContext context,
    String title,
    String description,
    Color color,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 技術面の能力値が不明かチェック
  bool _hasUnknownTechnicalAbilities() {
    final technicalAbilities = [
      'contact', 'power', 'plateDiscipline', 'bunt', 'oppositeFieldHitting',
      'pullHitting', 'batControl', 'swingSpeed', 'fielding', 'throwing',
      'catcherAbility', 'control', 'fastball', 'breakingBall', 'pitchMovement'
    ];
    
    for (final ability in technicalAbilities) {
      if (_getDisplayAbility(ability) == 0) {
        return true;
      }
    }
    return false;
  }

  // フィジカル面の能力値が不明かチェック
  bool _hasUnknownPhysicalAbilities() {
    final physicalAbilities = [
      'acceleration', 'agility', 'balance', 'pace', 'stamina', 'strength',
      'flexibility', 'jumpingReach', 'naturalFitness', 'injuryProneness'
    ];
    
    for (final ability in physicalAbilities) {
      if (_getDisplayAbility(ability) == 0) {
        return true;
      }
    }
    return false;
  }

  // メンタル面の能力値が不明かチェック
  bool _hasUnknownMentalAbilities() {
    final mentalAbilities = [
      'concentration', 'anticipation', 'vision', 'composure', 'aggression',
      'bravery', 'leadership', 'workRate', 'selfDiscipline', 'ambition',
      'teamwork', 'positioning', 'pressureHandling', 'clutchAbility'
    ];
    
    for (final ability in mentalAbilities) {
      if (_getDisplayAbility(ability) == 0) {
        return true;
      }
    }
    return false;
  }

  Widget _buildCompactInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // カテゴリ状況の判定

  CategoryStatus _getTechnicalAbilityCategoryStatus() {
    final scoutData = _scoutAnalysisData ?? widget.player.scoutAnalysisData;
    if (scoutData == null) return CategoryStatus.unknown;

    final technicalAbilities = [
      'control', 'fastball', 'breakingBall', 'pitchMovement',
      'contact', 'power', 'plateDiscipline', 'bunt', 'oppositeFieldHitting',
      'pullHitting', 'batControl', 'swingSpeed',
      'fielding', 'throwing', 'catching', 'positioning'
    ];

    int knownCount = 0;
    for (final ability in technicalAbilities) {
      if (scoutData.containsKey(ability) && scoutData[ability] != 0) {
        knownCount++;
      }
    }

    if (knownCount == 0) return CategoryStatus.unknown;
    if (knownCount == technicalAbilities.length) return CategoryStatus.complete;
    return CategoryStatus.partial;
  }

  CategoryStatus _getMentalAbilityCategoryStatus() {
    final scoutData = _scoutAnalysisData ?? widget.player.scoutAnalysisData;
    if (scoutData == null) return CategoryStatus.unknown;

    final mentalAbilities = [
      'concentration', 'anticipation', 'vision', 'composure',
      'aggression', 'bravery', 'leadership', 'workRate',
      'selfDiscipline', 'ambition', 'teamwork', 'positioning',
      'pressureHandling', 'clutchAbility'
    ];

    int knownCount = 0;
    for (final ability in mentalAbilities) {
      if (scoutData.containsKey(ability) && scoutData[ability] != 0) {
        knownCount++;
      }
    }

    if (knownCount == 0) return CategoryStatus.unknown;
    if (knownCount == mentalAbilities.length) return CategoryStatus.complete;
    return CategoryStatus.partial;
  }

  CategoryStatus _getPhysicalAbilityCategoryStatus() {
    final scoutData = _scoutAnalysisData ?? widget.player.scoutAnalysisData;
    if (scoutData == null) return CategoryStatus.unknown;

    final physicalAbilities = [
      'acceleration', 'agility', 'balance', 'pace',
      'stamina', 'strength', 'flexibility', 'jumpingReach'
    ];

    int knownCount = 0;
    for (final ability in physicalAbilities) {
      if (scoutData.containsKey(ability) && scoutData[ability] != 0) {
        knownCount++;
      }
    }

    if (knownCount == 0) return CategoryStatus.unknown;
    if (knownCount == physicalAbilities.length) return CategoryStatus.complete;
    return CategoryStatus.partial;
  }

  Widget _buildCategoryStatusIcon(CategoryStatus status) {
    switch (status) {
      case CategoryStatus.complete:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case CategoryStatus.partial:
        return const Icon(Icons.schedule, color: Colors.orange, size: 20);
      case CategoryStatus.unknown:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 20);
    }
  }

  Widget _buildCategoryStatusMessage(CategoryStatus status, String categoryName, String actionName, Color textColor) {
    String message;
    Color messageColor;

    switch (status) {
      case CategoryStatus.complete:
        message = '$categoryNameの能力値は完全に把握済みです';
        messageColor = Colors.green;
        break;
      case CategoryStatus.partial:
        message = '$categoryNameの一部の能力値を把握しています（$actionNameで追加情報を取得可能）';
        messageColor = Colors.orange;
        break;
      case CategoryStatus.unknown:
        message = '$categoryNameの能力値を把握するには$actionNameを実行してください';
        messageColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: messageColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: messageColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: messageColor, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: messageColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPositionChip(String position, int fit, Color textColor, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPositionFitColor(fit).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getPositionFitColor(fit)),
      ),
      child: Text(
        '$position ($fit)',
        style: TextStyle(
          color: _getPositionFitColor(fit),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getFameColor(int fameLevel) {
    switch (fameLevel) {
      case 1: return Colors.grey;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.orange;
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getTrustColor(int trustLevel) {
    if (trustLevel >= 80) return Colors.green;
    if (trustLevel >= 60) return Colors.blue;
    if (trustLevel >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getPositionFitColor(int fit) {
    if (fit >= 8) return Colors.green;
    if (fit >= 6) return Colors.blue;
    if (fit >= 4) return Colors.orange;
    return Colors.red;
  }
} 