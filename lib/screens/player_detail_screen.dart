import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../services/scouting/accuracy_calculator.dart';
import '../config/debug_config.dart';
import 'debug_player_detail_screen.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  // スカウトスキル（仮の値、本来は実際のスカウトから取得）
  Map<String, int> get _scoutSkills => {
    'observation': 5,
    'analysis': 4,
    'insight': 3,
    'communication': 4,
    'exploration': 3,
  };

  // スカウト精度を考慮した能力値取得
  int _getVisibleAbility(String abilityName, int scoutSkill) {
    final trueValue = _getTrueAbilityValue(abilityName);
    final baseKnowledge = player.abilityKnowledge[abilityName] ?? 0;
    final scoutKnowledge = scoutSkill;
    final combinedKnowledge = (baseKnowledge + scoutKnowledge) / 2;
    
    final range = _getVisibleAbilityRange(combinedKnowledge.round());
    final error = Random().nextInt(range * 2 + 1) - range;
    return (trueValue + error).clamp(0, 100);
  }

  // 真の能力値を取得
  int _getTrueAbilityValue(String abilityName) {
    switch (abilityName) {
      case 'fastballVelo':
        return player.veloScore;
      case 'control':
        return player.getTechnicalAbility(TechnicalAbility.control);
      case 'stamina':
        return player.getPhysicalAbility(PhysicalAbility.stamina);
      case 'breakAvg':
        return player.getTechnicalAbility(TechnicalAbility.breakingBall);
      case 'batPower':
        return player.getTechnicalAbility(TechnicalAbility.power);
      case 'batControl':
        return player.getTechnicalAbility(TechnicalAbility.batControl);
      case 'run':
        return player.getPhysicalAbility(PhysicalAbility.pace);
      case 'field':
        return player.getTechnicalAbility(TechnicalAbility.fielding);
      case 'arm':
        return player.getTechnicalAbility(TechnicalAbility.throwing);
      default:
        return 25;
    }
  }

  // スカウトスキルに基づく能力値の表示範囲を取得
  int _getVisibleAbilityRange(int scoutSkill) {
    if (scoutSkill >= 80) return 5; // ±5の誤差
    if (scoutSkill >= 60) return 10; // ±10の誤差
    if (scoutSkill >= 40) return 20; // ±20の誤差
    if (scoutSkill >= 20) return 30; // ±30の誤差
    return 50; // ±50の誤差（ほぼ見えない）
  }

  // スカウト精度を考慮した才能ランク取得
  int _getVisibleTalent() {
    if (DebugConfig.showTrueValues) {
      return player.talent;
    }
    
    final scoutSkill = _scoutSkills['analysis'] ?? 4;
    final baseKnowledge = player.abilityKnowledge['talent'] ?? 0;
    final combinedKnowledge = (baseKnowledge + scoutSkill) / 2;
    
    final range = _getVisibleAbilityRange(combinedKnowledge.round());
    final error = Random().nextInt(range * 2 + 1) - range;
    final visibleTalent = (player.talent + error).clamp(1, 6);
    return visibleTalent;
  }

  // スカウト精度を考慮した成長タイプ取得
  String _getVisibleGrowthType() {
    if (DebugConfig.showTrueValues) {
      return player.growthType;
    }
    
    final scoutSkill = _scoutSkills['insight'] ?? 3;
    final baseKnowledge = player.abilityKnowledge['growthType'] ?? 0;
    final combinedKnowledge = (baseKnowledge + scoutSkill) / 2;
    
    // 成長タイプは完全に正確か、完全に間違っているかのどちらか
    if (combinedKnowledge >= 60) {
      return player.growthType;
    } else {
      final types = ['early', 'normal', 'late', 'spurt'];
      final random = Random();
      return types[random.nextInt(types.length)];
    }
  }

  // スカウト精度を考慮した精神力取得
  int _getVisibleMentalGrit() {
    if (DebugConfig.showTrueValues) {
      return (player.mentalGrit * 100).round();
    }
    
    final scoutSkill = _scoutSkills['insight'] ?? 3;
    final baseKnowledge = player.abilityKnowledge['mentalGrit'] ?? 0;
    final combinedKnowledge = (baseKnowledge + scoutSkill) / 2;
    
    final range = _getVisibleAbilityRange(combinedKnowledge.round());
    final error = Random().nextInt(range * 2 + 1) - range;
    final trueValue = (player.mentalGrit * 100).round();
    return (trueValue + error).clamp(0, 100);
  }

  // スカウト精度を考慮したポテンシャル取得
  int _getVisiblePeakAbility() {
    if (DebugConfig.showTrueValues) {
      return player.peakAbility;
    }
    
    final scoutSkill = _scoutSkills['analysis'] ?? 4;
    final baseKnowledge = player.abilityKnowledge['peakAbility'] ?? 0;
    final combinedKnowledge = (baseKnowledge + scoutSkill) / 2;
    
    final range = _getVisibleAbilityRange(combinedKnowledge.round());
    final error = Random().nextInt(range * 2 + 1) - range;
    return (player.peakAbility + error).clamp(50, 150);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;
    final cardBg = Colors.grey[900]!;
    final primaryColor = Colors.blue[400]!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name}の詳細'),
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
                    builder: (context) => DebugPlayerDetailScreen(player: player),
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
                
                // 基本情報カード（横に広げて表示）
                _buildBasicInfoCard(context, textColor, cardBg),
                const SizedBox(height: 16),
                
                // 能力値システム
                if (player.isDiscovered || player.fameLevel >= 2) ...[
                  _buildNewAbilityCard(context, textColor, cardBg, primaryColor),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                

                

                
                // 球種情報（発掘済みまたは知名度が高い場合のみ表示）
                if ((player.isDiscovered || player.fameLevel >= 3) && player.isPitcher && player.pitches != null && player.pitches!.isNotEmpty) ...[
                  _buildPitchesCard(context, textColor, cardBg),
                  const SizedBox(height: 16),
                ],
                
                // ポジション適性（発掘済みまたは知名度が高い場合のみ表示）
                if (player.isDiscovered || player.fameLevel >= 3) ...[
                  _buildPositionFitCard(context, textColor, cardBg, primaryColor),
                  const SizedBox(height: 16),
                ],
                
                // スカウト評価・メモ（発掘済みの場合のみ表示）
                if (player.isDiscovered) ...[
                  _buildScoutNotesCard(context, textColor, cardBg),
                  const SizedBox(height: 16),
                ],
                
                // 情報が表示されない場合のメッセージ
                if (!player.isDiscovered && player.fameLevel < 2) ...[
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
                player.isPitcher ? Icons.sports_baseball : Icons.person,
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
                    player.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${player.school} ${player.grade}年',
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
                      player.position,
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
                _buildStatusChip('知名度', player.fameLevelName, _getFameColor(player.fameLevel)),
                const SizedBox(height: 4),
                _buildStatusChip('信頼度', '${player.trustLevel}', _getTrustColor(player.trustLevel)),
                const SizedBox(height: 4),
                _buildStatusChip(
                  '発掘状態',
                  player.isDiscovered ? '発掘済み' : '未発掘',
                  player.isDiscovered ? Colors.green : Colors.orange,
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
                  child: _buildCompactInfoRow('名前', player.name, textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('学校', player.school, textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('学年', '${player.grade}年生', textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoRow('ポジション', player.position, textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('性格', player.personality, textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('才能', 'ランク${_getVisibleTalent()}', textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCompactInfoRow('成長', _getVisibleGrowthType(), textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('精神力', '${_getVisibleMentalGrit()}%', textColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCompactInfoRow('ポテンシャル', '${_getVisiblePeakAbility()}', textColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 能力値カード
  Widget _buildAbilityCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '能力値',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (player.isDiscovered || player.fameLevel >= 2) ...[
              // 投手能力値
              Text(
                '投手',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              _buildAbilityBar('球速', _getVisibleAbility('fastballVelo', _scoutSkills['observation'] ?? 4), textColor),
              _buildAbilityBar('制球', _getVisibleAbility('control', _scoutSkills['analysis'] ?? 4), textColor),
              _buildAbilityBar('スタミナ', _getVisibleAbility('stamina', _scoutSkills['analysis'] ?? 4), textColor),
              _buildAbilityBar('変化', _getVisibleAbility('breakAvg', _scoutSkills['analysis'] ?? 4), textColor),
              const SizedBox(height: 16),
              // 野手能力値
              Text(
                '野手',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              _buildAbilityBar('パワー', _getVisibleAbility('batPower', _scoutSkills['analysis'] ?? 4), textColor),
              _buildAbilityBar('バットコントロール', _getVisibleAbility('batControl', _scoutSkills['analysis'] ?? 4), textColor),
              _buildAbilityBar('走力', _getVisibleAbility('run', _scoutSkills['observation'] ?? 4), textColor),
              _buildAbilityBar('守備', _getVisibleAbility('field', _scoutSkills['observation'] ?? 4), textColor),
              _buildAbilityBar('肩', _getVisibleAbility('arm', _scoutSkills['observation'] ?? 4), textColor),
            ] else ...[
              Text(
                '情報不足のため能力値を表示できません',
                style: TextStyle(color: textColor.withOpacity(0.6)),
              ),
            ],
          ],
        ),
      ),
    );
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
            ...player.pitches!.map((pitch) => Padding(
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
              children: player.positionFit.entries.map((entry) => 
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
            if (player.scoutEvaluation != null && player.scoutEvaluation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '評価: ${player.scoutEvaluation!}',
                  style: TextStyle(color: textColor),
                ),
              ),
            if (player.scoutNotes != null && player.scoutNotes!.isNotEmpty)
              Text(
                'メモ: ${player.scoutNotes!}',
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

  // ヘルパーメソッド
  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
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

  Widget _buildAbilityBar(String label, int value, Color textColor) {
    final percentage = value / 100.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '$value/100',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.red[700],
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(6),
                ),
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
  
  // 能力値システムカード
  Widget _buildNewAbilityCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 技術面能力値（投手、打者、守備に分けて表示）
        _buildTechnicalAbilitiesCard(context, textColor, cardBg, primaryColor),
        const SizedBox(height: 16),
        
        // メンタル面能力値（緑色）
        _buildMentalAbilitiesCard(context, textColor, cardBg, Colors.green),
        const SizedBox(height: 16),
        
        // フィジカル面能力値（オレンジ色）
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
                _buildAbilityRow(ability.displayName, player.getTechnicalAbility(ability), textColor, primaryColor)
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
                _buildAbilityRow(ability.displayName, player.getTechnicalAbility(ability), textColor, primaryColor)
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
                _buildAbilityRow(ability.displayName, player.getTechnicalAbility(ability), textColor, primaryColor)
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
                _buildAbilityRow(ability.displayName, player.getMentalAbility(ability), textColor, categoryColor)
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
                _buildAbilityRow(ability.displayName, player.getMentalAbility(ability), textColor, categoryColor)
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
                _buildAbilityRow(ability.displayName, player.getMentalAbility(ability), textColor, categoryColor)
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
                _buildAbilityRow(ability.displayName, player.getPhysicalAbility(ability), textColor, categoryColor)
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
                _buildAbilityRow(ability.displayName, player.getPhysicalAbility(ability), textColor, categoryColor)
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAbilityCategory(BuildContext context, Color textColor, Color primaryColor, String title, List<Widget> abilities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...abilities,
      ],
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
    final displayValue = isFastball ? player.getFastballVelocityKmh() : value;
    final displayText = isFastball ? '${displayValue}km/h' : '$value';
    
    // デバッグモードの場合、真の値も表示
    final debugInfo = DebugConfig.showTrueValues ? 
      (isFastball ? ' (球速: ${player.getFastballVelocityKmh()}km/h)' : ' (球速: $value)') : '';
    
    // ポテンシャル値を取得
    int? potentialValue;
    if (DebugConfig.showPotentials && player.individualPotentials != null) {
      if (isFastball) {
        potentialValue = player.individualPotentials!['fastballVelo'];
      } else {
        // ラベルから能力値名を取得
        final abilityName = _getAbilityNameFromLabel(label);
        if (abilityName != null) {
          potentialValue = player.individualPotentials![abilityName];
        }
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
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryColor,
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
                    color: textColor,
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
    switch (label) {
      case '制球': return 'control';
      case 'スタミナ': return 'stamina';
      case '変化': return 'breakAvg';
      case 'パワー': return 'batPower';
      case 'バットコントロール': return 'batControl';
      case '走力': return 'run';
      case '守備': return 'field';
      case '肩': return 'arm';
      case 'ミート': return 'contact';
      case 'パワー': return 'power';
      case '選球眼': return 'plateDiscipline';
      case 'バント': return 'bunt';
      case '流し打ち': return 'oppositeFieldHitting';
      case 'プルヒッティング': return 'pullHitting';
      case 'バットコントロール': return 'batControl';
      case 'スイングスピード': return 'swingSpeed';
      case '捕球': return 'fielding';
      case '送球': return 'throwing';
      case '捕手リード': return 'catcherAbility';
      case 'コントロール': return 'control';
      case '球速': return 'fastball';
      case '変化球': return 'breakingBall';
      case '球種変化量': return 'pitchMovement';
      case '集中力': return 'concentration';
      case '予測力': return 'anticipation';
      case '視野': return 'vision';
      case '冷静さ': return 'composure';
      case '積極性': return 'aggression';
      case '勇気': return 'bravery';
      case 'リーダーシップ': return 'leadership';
      case '仕事量': return 'workRate';
      case '自己管理': return 'selfDiscipline';
      case '野心': return 'ambition';
      case '加速': return 'acceleration';
      case '敏捷性': return 'agility';
      case 'バランス': return 'balance';
      case '跳躍力': return 'jumpingReach';
      case '自然な健康': return 'naturalFitness';
      case '怪我の傾向': return 'injuryProneness';
      case '持久力': return 'stamina';
      case '強度': return 'strength';
      case 'スピード': return 'pace';
      default: return null;
    }
  }
} 