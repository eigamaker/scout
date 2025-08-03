import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scouting/scout.dart';
import '../services/game_manager.dart';

class ScoutSkillScreen extends StatefulWidget {
  const ScoutSkillScreen({super.key});

  @override
  State<ScoutSkillScreen> createState() => _ScoutSkillScreenState();
}

class _ScoutSkillScreenState extends State<ScoutSkillScreen> {
  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    final game = gameManager.currentGame;
    
    if (game == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('スカウトスキル')),
        body: const Center(
          child: Text('ゲームが開始されていません'),
        ),
      );
    }

    // スカウト情報を取得
    final scout = gameManager.currentScout ?? Scout.createDefault(game.scoutName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('スカウトスキル'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSkillInfo(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // スカウト基本情報
            _buildScoutInfo(scout),
            const SizedBox(height: 16),
            
            // スキル概要
            _buildSkillOverview(scout),
            const SizedBox(height: 16),
            
            // スキル詳細
            _buildSkillDetails(scout),
            const SizedBox(height: 16),
            
            // 統計情報
            _buildStatistics(scout),
          ],
        ),
      ),
    );
  }

  // スカウト基本情報
  Widget _buildScoutInfo(Scout scout) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 24),
                const SizedBox(width: 8),
                Text(
                  scout.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoRow('レベル', '${scout.level}', Icons.star),
                ),
                Expanded(
                  child: _infoRow('経験値', '${scout.experience}/${scout.maxExperience}', Icons.trending_up),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _infoRow('AP', '${scout.actionPoints}/${scout.maxActionPoints}', Icons.flash_on),
                ),
                Expanded(
                  child: _infoRow('所持金', '¥${scout.money ~/ 1000}k', Icons.attach_money),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _infoRow('信頼度', '${scout.trustLevel}%', Icons.verified_user),
                ),
                Expanded(
                  child: _infoRow('評判', '${scout.reputation}%', Icons.thumb_up),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // スキル概要
  Widget _buildSkillOverview(Scout scout) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, size: 24),
                const SizedBox(width: 8),
                Text(
                  'スキル概要',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statCard('平均スキル', '${scout.averageSkill.toStringAsFixed(1)}', Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard('最高スキル', '${scout.maxSkill}', Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard('最低スキル', '${scout.minSkill}', Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // スキル詳細
  Widget _buildSkillDetails(Scout scout) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 24),
                const SizedBox(width: 8),
                Text(
                  'スキル詳細',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...ScoutSkill.values.map((skill) => _buildSkillRow(scout, skill)),
          ],
        ),
      ),
    );
  }

  // 統計情報
  Widget _buildStatistics(Scout scout) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 24),
                const SizedBox(width: 8),
                Text(
                  '統計情報',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar('レベル進行', scout.skillGrowthRate, Colors.purple),
            const SizedBox(height: 8),
            _buildProgressBar('スキル成長', scout.averageSkill / 10, Colors.blue),
            const SizedBox(height: 8),
            _buildProgressBar('信頼度', scout.trustLevel / 100, Colors.green),
            const SizedBox(height: 8),
            _buildProgressBar('評判', scout.reputation / 100, Colors.orange),
          ],
        ),
      ),
    );
  }

  // スキル行
  Widget _buildSkillRow(Scout scout, ScoutSkill skill) {
    final skillValue = scout.getSkill(skill);
    final skillName = skillNames[skill] ?? skill.name;
    final skillIcon = skillIcons[skill] ?? Icons.help;
    final skillDescription = skillDescriptions[skill] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(skillIcon, size: 20, color: _getSkillColor(skillValue)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  skillName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSkillColor(skillValue),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Lv.$skillValue',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            skillDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: skillValue / 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getSkillColor(skillValue)),
          ),
          // スキル成長ボタン（デバッグ用）
          if (skillValue < 10)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: () => _increaseSkill(skill),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSkillColor(skillValue),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text('スキルアップ'),
              ),
            ),
        ],
      ),
    );
  }

  // スキル増加
  void _increaseSkill(ScoutSkill skill) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    gameManager.increaseScoutSkill(skill, 1);
    
    // UI更新
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${skillNames[skill]}スキルが1アップしました！'),
        backgroundColor: _getSkillColor(gameManager.currentScout?.getSkill(skill) ?? 1),
      ),
    );
  }

  // スキル色を取得
  Color _getSkillColor(int skillValue) {
    if (skillValue >= 8) return Colors.red;
    if (skillValue >= 6) return Colors.orange;
    if (skillValue >= 4) return Colors.yellow[700]!;
    return Colors.grey;
  }

  // 情報行
  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 統計カード
  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // プログレスバー
  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  // スキル情報ダイアログ
  void _showSkillInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スキルについて'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _skillInfoItem('探索', '隠れた才能を持つ選手を発見する能力'),
              _skillInfoItem('観察', '選手の現在の能力値を正確に評価する能力'),
              _skillInfoItem('分析', 'データを統合して将来性を予測する能力'),
              _skillInfoItem('洞察', '選手の内面や潜在的な要素を見抜く能力'),
              _skillInfoItem('コミュニケーション', '選手や関係者との対話を通じて情報を引き出す能力'),
              _skillInfoItem('交渉', '球団や関係者との調整・提案能力'),
              _skillInfoItem('体力', 'スカウト活動の継続性と効率性'),
              _skillInfoItem('直観', '一瞬の判断や予期しない発見'),
              const SizedBox(height: 16),
              const Text(
                'スキルレベル: 1-10段階\n'
                'レベル1-3: 初心者\n'
                'レベル4-6: 中級者\n'
                'レベル7-9: 上級者\n'
                'レベル10: エキスパート',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  // スキル情報アイテム
  Widget _skillInfoItem(String name, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
} 