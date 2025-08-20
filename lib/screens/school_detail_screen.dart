import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/school/school.dart';
import '../models/player/player.dart';
import '../screens/player_detail_screen.dart';

import '../services/game_manager.dart';
import '../services/scouting/action_service.dart';
import '../models/game/game.dart';
import '../widgets/player_list_card.dart';

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
    // 注目選手（isPubliclyKnown）と発掘済み選手（discoveredCount > 0）を表示
    final visiblePlayers = widget.school.players.where((player) => 
      player.isPubliclyKnown || player.discoveredCount > 0
    ).toList();
    
    // デバッグ情報を表示
    final totalPlayers = widget.school.players.length;
    final publiclyKnownPlayers = widget.school.players.where((p) => p.isPubliclyKnown).length;
    final discoveredPlayers = widget.school.players.where((p) => p.discoveredCount > 0).length;
    
    return Column(
      children: [
        // デバッグ情報
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[100],
          child: Text(
            'デバッグ: 総選手数: $totalPlayers, 注目選手: $publiclyKnownPlayers, 発掘済み: $discoveredPlayers, 表示対象: ${visiblePlayers.length}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        
        // 選手リスト
        Expanded(
          child: visiblePlayers.isEmpty
              ? const Center(child: Text('注目選手・発掘済み選手がいません'))
              : ListView.builder(
                  itemCount: visiblePlayers.length,
                  itemBuilder: (context, index) {
                    final player = visiblePlayers[index];
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



  /// 選手カードを構築
  Widget _buildPlayerCard(Player player) {
    return PlayerListCard(
      player: player,
      showActions: true,
      onTap: () => _showPlayerDetail(player),
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

  /// 選手詳細画面に遷移
  void _showPlayerDetail(Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerDetailScreen(player: player),
      ),
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

