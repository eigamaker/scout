import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/school/school.dart';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../services/game_manager.dart';
import '../services/scouting/action_service.dart';
import '../models/game/game.dart';

class SchoolDetailScreen extends StatefulWidget {
  final School school;
  
  const SchoolDetailScreen({
    Key? key,
    required this.school,
  }) : super(key: key);

  @override
  State<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends State<SchoolDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedPosition = 'すべて';
  int? _selectedTalentRank;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.school.name),
        backgroundColor: _getRankColor(widget.school.rank),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '基本情報'),
            Tab(text: '所属選手'),
            Tab(text: 'スカウト計画'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildPlayersTab(),
          _buildScoutingTab(),
        ],
      ),
    );
  }

  /// 基本情報タブを構築
  Widget _buildBasicInfoTab() {
    final generatedPlayerCount = widget.school.players.where((p) => p.talent >= 3).length;
    final defaultPlayerCount = widget.school.players.where((p) => p.talent < 3).length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 学校概要カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _getRankColor(widget.school.rank),
                        child: Text(
                          widget.school.rank.name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.school.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.school.location,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getRankColor(widget.school.rank),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.school.rank.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 学校詳細情報
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '学校詳細',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('都道府県', widget.school.prefecture),
                  _buildDetailRow('場所', widget.school.location),
                  _buildDetailRow('監督', widget.school.coachName),
                  _buildDetailRow('監督信頼度', '${widget.school.coachTrust}'),
                                     _buildDetailRow('基本能力値', '${widget.school.getDefaultAbilityValue()}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 所属選手タブを構築
  Widget _buildPlayersTab() {
    final filteredPlayers = _getFilteredPlayers();
    
    return Column(
      children: [
        // 検索・フィルターバー
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: '選手名で検索...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  // ポジションフィルター
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPosition,
                      decoration: const InputDecoration(
                        labelText: 'ポジション',
                        border: OutlineInputBorder(),
                      ),
                      items: <String>[
                        'すべて',
                        '投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'
                      ].map((pos) => DropdownMenuItem<String>(value: pos, child: Text(pos))).toList(),
                                              onChanged: (value) {
                          setState(() {
                            _selectedPosition = value as String;
                          });
                        },
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // 才能ランクフィルター
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedTalentRank,
                      decoration: const InputDecoration(
                        labelText: '才能ランク',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('すべて')),
                        ...List.generate(6, (i) => i + 1).map((rank) => 
                          DropdownMenuItem(value: rank, child: Text('ランク$rank'))
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTalentRank = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 選手リスト
        Expanded(
          child: filteredPlayers.isEmpty
              ? const Center(child: Text('条件に合う選手が見つかりません'))
              : ListView.builder(
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    return _buildPlayerCard(player);
                  },
                ),
        ),
      ],
    );
  }

  /// スカウト計画タブを構築
  Widget _buildScoutingTab() {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    
    if (game == null) {
      return const Center(child: Text('ゲームが開始されていません'));
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'スカウトアクション',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 練習視察
          Card(
            child: ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('練習視察'),
              subtitle: const Text('AP: 2, 予算: ¥20,000'),
              trailing: ElevatedButton(
                onPressed: () => _addPracticeWatchAction(context, gameManager, game),
                child: const Text('追加'),
              ),
            ),
          ),
          
          // 練習試合観戦
          Card(
            child: ListTile(
              leading: const Icon(Icons.sports_baseball, color: Colors.orange),
              title: const Text('練習試合観戦'),
              subtitle: const Text('AP: 2, 予算: ¥30,000'),
              trailing: ElevatedButton(
                onPressed: () => _addScrimmageAction(context, gameManager, game),
                child: const Text('追加'),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 現在のAPと予算
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('現在のAP'),
                        Text(
                          '${game.ap}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('現在の予算'),
                        Text(
                          '¥${game.budget.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// フィルタリングされた選手リストを取得
  List<Player> _getFilteredPlayers() {
    return widget.school.players.where((player) {
      // 検索クエリでフィルタリング
      if (_searchQuery.isNotEmpty) {
        if (!player.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // ポジションでフィルタリング
      if (_selectedPosition != 'すべて' && player.position != _selectedPosition) {
        return false;
      }
      
      // 才能ランクでフィルタリング
      if (_selectedTalentRank != null && player.talent != _selectedTalentRank) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// 選手カードを構築
  Widget _buildPlayerCard(Player player) {
    final isGeneratedPlayer = player.talent >= 3;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isGeneratedPlayer ? Colors.green : Colors.grey,
          child: Text(
            player.position.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          player.name,
          style: TextStyle(
            fontWeight: isGeneratedPlayer ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${player.position} • ${player.grade}年生'),
            Text(
              '才能ランク${player.talent} • ${player.personality}',
              style: TextStyle(
                color: isGeneratedPlayer ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isGeneratedPlayer)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '生成',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              '知名度: ${player.fame}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        onTap: () => _showPlayerDetail(player),
      ),
    );
  }

  /// 統計カードを構築
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 詳細行を構築
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// 学校ランクに応じた色を取得
  Color _getRankColor(SchoolRank rank) {
    switch (rank) {
      case SchoolRank.elite:
        return Colors.red;
      case SchoolRank.strong:
        return Colors.orange;
      case SchoolRank.average:
        return Colors.green;
      case SchoolRank.weak:
        return Colors.grey;
    }
  }

  /// 選手詳細を表示
  void _showPlayerDetail(Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ポジション: ${player.position}'),
              Text('学年: ${player.grade}年生'),
              Text('才能ランク: ${player.talent}'),
              Text('性格: ${player.personality}'),
              Text('知名度: ${player.fame}'),
              if (player.talent >= 3) ...[
                const SizedBox(height: 16),
                const Text('能力値', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildAbilitySection('技術面', player.technicalAbilities),
                _buildAbilitySection('メンタル面', player.mentalAbilities),
                _buildAbilitySection('フィジカル面', player.physicalAbilities),
              ],
            ],
          ),
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

  /// 能力値セクションを構築
  Widget _buildAbilitySection(String title, Map<dynamic, int> abilities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        ...abilities.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text('${entry.key}: ${entry.value}'),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

  /// 練習視察アクションを追加
  void _addPracticeWatchAction(BuildContext context, GameManager gameManager, Game game) {
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'PRAC_WATCH',
      schoolId: game.schools.indexOf(widget.school),
      playerId: null,
      apCost: 2,
      budgetCost: 20000,
      params: {},
    );
    
    if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.school.name}の練習視察を計画に追加しました'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APまたは予算が不足しています'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 練習試合観戦アクションを追加
  void _addScrimmageAction(BuildContext context, GameManager gameManager, Game game) {
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'scrimmage',
      schoolId: game.schools.indexOf(widget.school),
      playerId: null,
      apCost: 2,
      budgetCost: 30000,
      params: {},
    );
    
    if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.school.name}の練習試合観戦を計画に追加しました'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APまたは予算が不足しています'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
