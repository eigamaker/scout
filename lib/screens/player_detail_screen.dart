import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../services/scouting/accuracy_calculator.dart';
import '../services/scouting/scout_analysis_service.dart';
import '../services/data_service.dart';
import '../config/debug_config.dart';
import 'debug_player_detail_screen.dart';

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

  // 表示名から列挙型名への変換マップ
  static final Map<String, String> _displayNameToEnumName = {
    // Technical abilities
    'ミート': 'contact',
    'パワー': 'power',
    '選球眼': 'plateDiscipline',
    'バント': 'bunt',
    '流し打ち': 'oppositeFieldHitting',
    'プルヒッティング': 'pullHitting',
    'バットコントロール': 'batControl',
    'スイングスピード': 'swingSpeed',
    '捕球': 'fielding',
    '送球': 'throwing',
    '捕手リード': 'catcherAbility',
    'コントロール': 'control',
    '球速': 'fastball',
    '変化球': 'breakingBall',
    '球種変化量': 'pitchMovement',
    
    // Mental abilities
    '集中力': 'concentration',
    '予測力': 'anticipation',
    '視野': 'vision',
    '冷静さ': 'composure',
    '積極性': 'aggression',
    '勇敢さ': 'bravery',
    'リーダーシップ': 'leadership',
    '勤勉さ': 'workRate',
    '自己管理': 'selfDiscipline',
    '野心': 'ambition',
    'チームワーク': 'teamwork',
    'ポジショニング': 'positioning',
    'プレッシャー耐性': 'pressureHandling',
    '勝負強さ': 'clutchAbility',
    
    // Physical abilities
    '加速力': 'acceleration',
    '敏捷性': 'agility',
    'バランス': 'balance',
    '走力': 'pace',
    '持久力': 'stamina',
    '筋力': 'strength',
    '柔軟性': 'flexibility',
    'ジャンプ力': 'jumpingReach',
    '自然体力': 'naturalFitness',
    '怪我しやすさ': 'injuryProneness',
  };

  @override
  void initState() {
    super.initState();
    _loadScoutAnalysisData();
  }

  /// スカウト分析データを読み込み
  Future<void> _loadScoutAnalysisData() async {
    if (widget.player.id != null) {
      try {
        final scoutId = 'default_scout'; // 現在のスカウトID
        final analysisData = await _scoutAnalysisService.getLatestScoutAnalysis(
          widget.player.id!, 
          scoutId
        );
        
        setState(() {
          _scoutAnalysisData = analysisData;
          _isLoading = false;
        });
      } catch (e) {
        print('スカウト分析データの読み込みエラー: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
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
      return scoutData[abilityName]!;
    }
    
    // スカウト分析データがない場合は分析不足として25を返す
    return 25;
  }

  /// 技術面能力値を取得
  int _getDisplayTechnicalAbility(TechnicalAbility ability) {
    final abilityName = _getTechnicalAbilityName(ability);
    if (abilityName == null) return 25;
    return _getDisplayAbility(abilityName);
  }

  /// メンタル面能力値を取得
  int _getDisplayMentalAbility(MentalAbility ability) {
    final abilityName = _getMentalAbilityName(ability);
    if (abilityName == null) return 25;
    return _getDisplayAbility(abilityName);
  }

  /// フィジカル面能力値を取得
  int _getDisplayPhysicalAbility(PhysicalAbility ability) {
    final abilityName = _getPhysicalAbilityName(ability);
    if (abilityName == null) return 25;
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

  /// 技術面能力値名を取得
  String? _getTechnicalAbilityName(TechnicalAbility ability) {
    switch (ability) {
      case TechnicalAbility.contact: return 'contact';
      case TechnicalAbility.power: return 'power';
      case TechnicalAbility.plateDiscipline: return 'plateDiscipline';
      case TechnicalAbility.bunt: return 'bunt';
      case TechnicalAbility.oppositeFieldHitting: return 'oppositeFieldHitting';
      case TechnicalAbility.pullHitting: return 'pullHitting';
      case TechnicalAbility.batControl: return 'batControl';
      case TechnicalAbility.swingSpeed: return 'swingSpeed';
      case TechnicalAbility.fielding: return 'fielding';
      case TechnicalAbility.throwing: return 'throwing';
      case TechnicalAbility.catcherAbility: return 'catcherAbility';
      case TechnicalAbility.control: return 'control';
      case TechnicalAbility.fastball: return 'fastball';
      case TechnicalAbility.breakingBall: return 'breakingBall';
      case TechnicalAbility.pitchMovement: return 'pitchMovement';
    }
  }

  /// メンタル面能力値名を取得
  String? _getMentalAbilityName(MentalAbility ability) {
    switch (ability) {
      case MentalAbility.concentration: return 'concentration';
      case MentalAbility.anticipation: return 'anticipation';
      case MentalAbility.vision: return 'vision';
      case MentalAbility.composure: return 'composure';
      case MentalAbility.aggression: return 'aggression';
      case MentalAbility.bravery: return 'bravery';
      case MentalAbility.leadership: return 'leadership';
      case MentalAbility.workRate: return 'workRate';
      case MentalAbility.selfDiscipline: return 'selfDiscipline';
      case MentalAbility.ambition: return 'ambition';
      case MentalAbility.teamwork: return 'teamwork';
      case MentalAbility.positioning: return 'positioning';
      case MentalAbility.pressureHandling: return 'pressureHandling';
      case MentalAbility.clutchAbility: return 'clutchAbility';
    }
  }

  /// フィジカル面能力値名を取得
  String? _getPhysicalAbilityName(PhysicalAbility ability) {
    switch (ability) {
      case PhysicalAbility.acceleration: return 'acceleration';
      case PhysicalAbility.agility: return 'agility';
      case PhysicalAbility.balance: return 'balance';
      case PhysicalAbility.jumpingReach: return 'jumpingReach';
      case PhysicalAbility.flexibility: return 'flexibility';
      case PhysicalAbility.naturalFitness: return 'naturalFitness';
      case PhysicalAbility.injuryProneness: return 'injuryProneness';
      case PhysicalAbility.stamina: return 'stamina';
      case PhysicalAbility.strength: return 'strength';
      case PhysicalAbility.pace: return 'pace';
    }
  }

  /// 表示用才能ランクを取得
  int _getDisplayTalent() {
    if (DebugConfig.showTrueValues) {
      return widget.player.talent;
    }
    return widget.player.talent; // 簡素化: スカウト分析データがない場合は真の値を使用
  }

  /// 表示用成長タイプを取得
  String _getDisplayGrowthType() {
    if (DebugConfig.showTrueValues) {
      return widget.player.growthType;
    }
    return widget.player.growthType; // 簡素化: スカウト分析データがない場合は真の値を使用
  }

  /// 表示用精神力を取得
  int _getDisplayMentalGrit() {
    if (DebugConfig.showTrueValues) {
      return (widget.player.mentalGrit * 100).round();
    }
    return (widget.player.mentalGrit * 100).round(); // 簡素化: スカウト分析データがない場合は真の値を使用
  }

  /// 表示用ポテンシャルを取得
  int _getDisplayPeakAbility() {
    if (DebugConfig.showTrueValues) {
      return widget.player.peakAbility;
    }
    return widget.player.peakAbility; // 簡素化: スカウト分析データがない場合は真の値を使用
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
        title: Text('${widget.player.name}の詳細'),
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
                if (widget.player.isDiscovered || widget.player.fameLevel >= 2) ...[
                  _buildNewAbilityCard(context, textColor, cardBg, primaryColor),
                  const SizedBox(height: 16),
                ],
                
                // 球種情報
                if ((widget.player.isDiscovered || widget.player.fameLevel >= 3) && 
                    widget.player.isPitcher && widget.player.pitches != null && 
                    widget.player.pitches!.isNotEmpty) ...[
                  _buildPitchesCard(context, textColor, cardBg),
                  const SizedBox(height: 16),
                ],
                
                // ポジション適性
                if (widget.player.isDiscovered || widget.player.fameLevel >= 3) ...[
                  _buildPositionFitCard(context, textColor, cardBg, primaryColor),
                  const SizedBox(height: 16),
                ],
                
                // スカウト評価・メモ
                if (widget.player.isDiscovered) ...[
                  _buildScoutNotesCard(context, textColor, cardBg),
                  const SizedBox(height: 16),
                ],
                
                // 情報が表示されない場合のメッセージ
                if (!widget.player.isDiscovered && widget.player.fameLevel < 2) ...[
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
        child: Row(
          children: [
            // 選手アイコン
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                widget.player.isPitcher ? Icons.sports_baseball : Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            // 選手基本情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.player.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.player.school} ${widget.player.grade}年',
                    style: TextStyle(color: textColor.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 4),
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
                ],
              ),
            ),
            // 右側の情報
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusChip('知名度', widget.player.fameLevelName, _getFameColor(widget.player.fameLevel)),
                const SizedBox(height: 4),
                _buildStatusChip('信頼度', '${widget.player.trustLevel}', _getTrustColor(widget.player.trustLevel)),
                const SizedBox(height: 4),
                _buildStatusChip(
                  '発掘状態',
                  widget.player.isDiscovered ? '発掘済み' : '未発掘',
                  widget.player.isDiscovered ? Colors.green : Colors.orange,
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
                  child: _buildCompactInfoRow('名前', widget.player.name, textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('学校', widget.player.school, textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('学年', '${widget.player.grade}年生', textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoRow('ポジション', widget.player.position, textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('性格', widget.player.personality, textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('才能', 'ランク${_getDisplayTalent()}', textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoRow('成長', _getDisplayGrowthType(), textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('精神力', '${_getDisplayMentalGrit()}%', textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('ポテンシャル', '${_getDisplayPeakAbility()}', textColor),
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
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '技術面',
              style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'メンタル面',
              style: TextStyle(
                color: categoryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'フィジカル面',
              style: TextStyle(
                color: categoryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    final finalDisplayValue = isFastball ? 
      (value * 1.5 + 120).round() : value;
    final displayText = isFastball ? '${finalDisplayValue}km/h' : '$finalDisplayValue';
    
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
    
    // スカウト分析データがない場合の表示
    final scoutData = _scoutAnalysisData ?? widget.player.scoutAnalysisData;
    final abilityName = _getAbilityNameFromLabel(label);
    final hasScoutData = scoutData != null && abilityName != null && scoutData.containsKey(abilityName);
    
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
                      color: hasScoutData ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: finalDisplayValue / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasScoutData ? primaryColor : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              SizedBox(
                width: isFastball ? 60 : 30,
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: hasScoutData ? textColor : Colors.grey,
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
  
  // ラベルから能力値名を取得
  String? _getAbilityNameFromLabel(String label) {
    return _displayNameToEnumName[label];
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
                  '情報不足',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'この選手についての情報が不足しています。\nスカウト活動を行って情報を収集してください。',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      ),
    );
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