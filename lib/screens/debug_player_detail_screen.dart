import 'package:flutter/material.dart';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../config/debug_config.dart';

class DebugPlayerDetailScreen extends StatefulWidget {
  final Player player;

  const DebugPlayerDetailScreen({
    super.key,
    required this.player,
  });

  @override
  State<DebugPlayerDetailScreen> createState() => _DebugPlayerDetailScreenState();
}

class _DebugPlayerDetailScreenState extends State<DebugPlayerDetailScreen> {
  int scoutSkill = 50; // デフォルトのスカウトスキル

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;
    final cardBg = Colors.black.withOpacity(0.7);
    final primaryColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text('デバッグ: ${widget.player.name}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showDebugSettings(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF0a0a0a),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // スカウトスキル設定
              _buildScoutSkillCard(context, textColor, cardBg),
              const SizedBox(height: 16),

              // 基本情報
              _buildBasicInfoCard(context, textColor, cardBg),
              const SizedBox(height: 16),

              // 真の能力値 vs 表示能力値
              _buildComparisonCard(context, textColor, cardBg, primaryColor),
              const SizedBox(height: 16),

              // 技術面能力値比較
              _buildTechnicalComparisonCard(context, textColor, cardBg, primaryColor),
              const SizedBox(height: 16),

              // メンタル面能力値比較
              _buildMentalComparisonCard(context, textColor, cardBg, primaryColor),
              const SizedBox(height: 16),

              // フィジカル面能力値比較
              _buildPhysicalComparisonCard(context, textColor, cardBg, primaryColor),
              const SizedBox(height: 16),

              // 精度計算詳細
              if (DebugConfig.showCalculationDetails)
                _buildAccuracyCalculationCard(context, textColor, cardBg),
              const SizedBox(height: 16),

              // 個別ポテンシャル
              _buildIndividualPotentialsCard(context, textColor, cardBg, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoutSkillCard(BuildContext context, Color textColor, Color cardBg) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'スカウトスキル設定',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'スカウトスキル: $scoutSkill',
                    style: TextStyle(color: textColor),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: scoutSkill.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        scoutSkill = value.round();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
            _buildInfoRow('名前', widget.player.name, textColor),
            _buildInfoRow('学校', widget.player.school, textColor),
            _buildInfoRow('学年', '${widget.player.grade}年生', textColor),
            _buildInfoRow('ポジション', widget.player.position, textColor),
            _buildInfoRow('知名度', '${widget.player.fameLevelName} (${widget.player.fame})', textColor),
            _buildInfoRow('発掘状態', widget.player.isDiscovered ? '発掘済み' : '未発掘', textColor),
            _buildInfoRow('才能ランク（真）', '${widget.player.talent}', textColor),
            _buildInfoRow('成長タイプ（真）', widget.player.growthType, textColor),
            _buildInfoRow('平均ポテンシャル（真）', '${widget.player.peakAbility}', textColor),
            _buildInfoRow('精神力（真）', '${(widget.player.mentalGrit * 100).round()}%', textColor),
            _buildInfoRow('成長スピード（真）', '${(widget.player.growthRate * 100).round()}%', textColor),
            _buildInfoRow('ポジション適性', _formatPositionFit(widget.player.positionFit), textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '能力値比較（真の値 vs 表示値）',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.player.isPitcher) ...[
              _buildAbilityComparisonRow('球速（古いシステム）', widget.player.getFastballVelocityKmhOld(), widget.player.getFastballVelocityKmhOld(), textColor, primaryColor),
              _buildAbilityComparisonRow('球速（新しいシステム）', widget.player.getTechnicalAbility(TechnicalAbility.fastball), widget.player.getFastballVelocityKmh(), textColor, primaryColor),
              _buildAbilityComparisonRow('球速比較', widget.player.getFastballVelocityKmhOld(), widget.player.getFastballVelocityKmh(), textColor, primaryColor),
              _buildAbilityComparisonRow('制球', widget.player.control ?? 0, widget.player.getVisibleAbility('control', scoutSkill), textColor, primaryColor),
              _buildAbilityComparisonRow('スタミナ', widget.player.stamina ?? 0, widget.player.getVisibleAbility('stamina', scoutSkill), textColor, primaryColor),
              _buildAbilityComparisonRow('変化', widget.player.breakAvg ?? 0, widget.player.getVisibleAbility('breakAvg', scoutSkill), textColor, primaryColor),
            ] else ...[
              _buildAbilityComparisonRow('パワー', widget.player.batPower ?? 0, widget.player.getVisibleAbility('batPower', scoutSkill), textColor, primaryColor),
              _buildAbilityComparisonRow('バットコントロール', widget.player.batControl ?? 0, widget.player.getVisibleAbility('batControl', scoutSkill), textColor, primaryColor),
              _buildAbilityComparisonRow('走力', widget.player.run ?? 0, widget.player.getVisibleAbility('run', scoutSkill), textColor, primaryColor),
              _buildAbilityComparisonRow('守備', widget.player.field ?? 0, widget.player.getVisibleAbility('field', scoutSkill), textColor, primaryColor),
              _buildAbilityComparisonRow('肩', widget.player.arm ?? 0, widget.player.getVisibleAbility('arm', scoutSkill), textColor, primaryColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalComparisonCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '技術面能力値比較',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...TechnicalAbility.values.map((ability) => 
              _buildAbilityComparisonRow(
                ability.displayName,
                widget.player.getTechnicalAbility(ability),
                _getVisibleTechnicalAbility(ability),
                textColor,
                primaryColor,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentalComparisonCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'メンタル面能力値比較',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...MentalAbility.values.map((ability) => 
              _buildAbilityComparisonRow(
                ability.displayName,
                widget.player.getMentalAbility(ability),
                _getVisibleMentalAbility(ability),
                textColor,
                primaryColor,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalComparisonCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'フィジカル面能力値比較',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...PhysicalAbility.values.map((ability) => 
              _buildAbilityComparisonRow(
                ability.displayName,
                widget.player.getPhysicalAbility(ability),
                _getVisiblePhysicalAbility(ability),
                textColor,
                primaryColor,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCalculationCard(BuildContext context, Color textColor, Color cardBg) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '精度計算詳細',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('知名度レベル', '${widget.player.fameLevel} (${widget.player.fameLevelName})', textColor),
            _buildInfoRow('初期情報精度', '${_getInitialKnowledgeLevel()}%', textColor),
            _buildInfoRow('スカウトスキル', '$scoutSkill', textColor),
            _buildInfoRow('合成精度', '${_getCombinedKnowledge()}%', textColor),
            _buildInfoRow('誤差範囲', '±${_getErrorRange()}', textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualPotentialsCard(BuildContext context, Color textColor, Color cardBg, Color primaryColor) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '個別ポテンシャル',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.player.individualPotentials != null) ...[
              ...widget.player.individualPotentials!.entries.map((entry) {
                final ability = entry.key;
                final value = entry.value;
                return _buildInfoRow(ability, '$value', textColor);
              }).toList(),
            ] else ...[
              Text(
                'ポテンシャル情報なし',
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityComparisonRow(String label, int trueValue, int displayValue, Color textColor, Color primaryColor) {
    final difference = displayValue - trueValue;
    final differenceColor = difference == 0 
        ? Colors.grey 
        : difference > 0 
            ? Colors.green 
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          SizedBox(
            width: 40,
            child: Text(
              '$trueValue',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Text(' → ', style: TextStyle(color: Colors.grey)),
          SizedBox(
            width: 40,
            child: Text(
              '$displayValue',
              style: TextStyle(
                color: differenceColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (difference != 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: differenceColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${difference > 0 ? '+' : ''}$difference',
                style: TextStyle(
                  color: differenceColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 表示用の技術面能力値を取得（簡易実装）
  int _getVisibleTechnicalAbility(TechnicalAbility ability) {
    final trueValue = widget.player.getTechnicalAbility(ability);
    final accuracy = _getCombinedKnowledge() / 100.0;
    final errorRange = (1.0 - accuracy) * 50; // 精度に応じた誤差範囲
    final error = (DateTime.now().millisecondsSinceEpoch % (errorRange * 2 + 1)) - errorRange;
    return (trueValue + error).round().clamp(0, 100);
  }

  // 表示用のメンタル面能力値を取得（簡易実装）
  int _getVisibleMentalAbility(MentalAbility ability) {
    final trueValue = widget.player.getMentalAbility(ability);
    final accuracy = _getCombinedKnowledge() / 100.0;
    final errorRange = (1.0 - accuracy) * 50;
    final error = (DateTime.now().millisecondsSinceEpoch % (errorRange * 2 + 1)) - errorRange;
    return (trueValue + error).round().clamp(0, 100);
  }

  // 表示用のフィジカル面能力値を取得（簡易実装）
  int _getVisiblePhysicalAbility(PhysicalAbility ability) {
    final trueValue = widget.player.getPhysicalAbility(ability);
    final accuracy = _getCombinedKnowledge() / 100.0;
    final errorRange = (1.0 - accuracy) * 50;
    final error = (DateTime.now().millisecondsSinceEpoch % (errorRange * 2 + 1)) - errorRange;
    return (trueValue + error).round().clamp(0, 100);
  }

  int _getInitialKnowledgeLevel() {
    switch (widget.player.fameLevel) {
      case 5: return 80;
      case 4: return 60;
      case 3: return 40;
      case 2: return 20;
      case 1: return 0;
      default: return 0;
    }
  }

  int _getCombinedKnowledge() {
    final baseKnowledge = _getInitialKnowledgeLevel();
    return ((baseKnowledge + scoutSkill) / 2).round();
  }

  int _getErrorRange() {
    final combinedKnowledge = _getCombinedKnowledge();
    if (combinedKnowledge >= 80) return 5;
    if (combinedKnowledge >= 60) return 10;
    if (combinedKnowledge >= 40) return 20;
    if (combinedKnowledge >= 20) return 30;
    return 50;
  }

  void _showDebugSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('デバッグ設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('デバッグモード'),
              value: DebugConfig.isDebugMode,
              onChanged: (value) {
                DebugConfig.isDebugMode = value;
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('真の能力値表示'),
              value: DebugConfig.showTrueValues,
              onChanged: (value) {
                DebugConfig.showTrueValues = value;
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('精度詳細表示'),
              value: DebugConfig.showAccuracyDetails,
              onChanged: (value) {
                DebugConfig.showAccuracyDetails = value;
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('計算詳細表示'),
              value: DebugConfig.showCalculationDetails,
              onChanged: (value) {
                DebugConfig.showCalculationDetails = value;
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('ポテンシャル表示'),
              value: DebugConfig.showPotentials,
              onChanged: (value) {
                DebugConfig.showPotentials = value;
                setState(() {});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  String _formatPositionFit(Map<String, int> positionFit) {
    final entries = positionFit.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value)); // 適性値の高い順にソート
    
    return entries.take(3).map((entry) => '${entry.key}: ${entry.value}').join(', ');
  }
} 