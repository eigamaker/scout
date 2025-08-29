import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player/player.dart';
import '../services/game_manager.dart';
import '../widgets/player_list_card.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSort = 'name';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 分類別の選手リストを取得（学校リストと同じ方式）
  List<Player> _getPlayersByCategory(List<Player> allPlayers, PlayerCategory category) {
    List<Player> result;
    
    switch (category) {
      case PlayerCategory.favorite:
        // お気に入り: isScoutFavorite = true
        result = allPlayers.where((player) => player.isScoutFavorite).toList();
        break;
      case PlayerCategory.discovered:
        // 発掘済み: isDiscovered = true かつ isPubliclyKnown = false（スカウトが視察で発掘した選手のみ）
        result = allPlayers.where((player) => player.isDiscovered && !player.isPubliclyKnown).toList();
        break;
      case PlayerCategory.famous:
        // 注目選手: isPubliclyKnown = true
        result = allPlayers.where((player) => player.isPubliclyKnown).toList();
        break;
      case PlayerCategory.graduated:
        // 卒業生: isGraduated = true
        result = allPlayers.where((player) => player.isGraduated).toList();
        break;
      case PlayerCategory.unknown:
            // 未発掘: isDiscovered = false かつ isPubliclyKnown = false
    result = allPlayers.where((player) => !player.isDiscovered && !player.isPubliclyKnown).toList();
        break;
    }
    
    print('カテゴリ ${category.name} の選手数: ${result.length}名');
    if (result.isNotEmpty) {
      print('最初の選手: ${result.first.name}, isPubliclyKnown: ${result.first.isPubliclyKnown}, isDiscovered: ${result.first.isDiscovered}');
    }
    return result;
  }



  // ソート適用
  List<Player> _getSortedPlayers(List<Player> players) {
    switch (_selectedSort) {
      case 'fame':
        players.sort((a, b) => b.fame.compareTo(a.fame));
        break;
      case 'talent':
        players.sort((a, b) => b.talent.compareTo(a.talent));
        break;
      case 'potential':
        players.sort((a, b) => b.peakAbility.compareTo(a.peakAbility));
        break;
      case 'grade':
        players.sort((a, b) => a.grade.compareTo(b.grade));
        break;
      case 'school':
        players.sort((a, b) => a.school.compareTo(b.school));
        break;
      default:
        players.sort((a, b) => a.name.compareTo(b.name));
    }
    return players;
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ソート順'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('名前順'),
              value: 'name',
              groupValue: _selectedSort,
              onChanged: (value) => setState(() => _selectedSort = value!),
            ),
            RadioListTile<String>(
              title: const Text('知名度順'),
              value: 'fame',
              groupValue: _selectedSort,
              onChanged: (value) => setState(() => _selectedSort = value!),
            ),
            RadioListTile<String>(
              title: const Text('才能順'),
              value: 'talent',
              groupValue: _selectedSort,
              onChanged: (value) => setState(() => _selectedSort = value!),
            ),
            RadioListTile<String>(
              title: const Text('ポテンシャル順'),
              value: 'potential',
              groupValue: _selectedSort,
              onChanged: (value) => setState(() => _selectedSort = value!),
            ),
            RadioListTile<String>(
              title: const Text('学年順'),
              value: 'grade',
              groupValue: _selectedSort,
              onChanged: (value) => setState(() => _selectedSort = value!),
            ),
            RadioListTile<String>(
              title: const Text('学校順'),
              value: 'school',
              groupValue: _selectedSort,
              onChanged: (value) => setState(() => _selectedSort = value!),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    // 全学校の全選手を取得し、所在地でフィルタリング
    final scoutPrefecture = gameManager.currentGame?.scoutPrefecture;
    final schoolPrefMap = {
      for (var s in gameManager.currentGame?.schools ?? []) s.name: s.prefecture
    };
    final List<Player> allPlayers = gameManager
        .getAllPlayers()
        .where((player) {
          if (scoutPrefecture == null || scoutPrefecture.isEmpty) return true;
          return schoolPrefMap[player.school] == scoutPrefecture;
        }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('選手リスト'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.favorite, color: Colors.red),
              text: 'お気に入り',
            ),
            Tab(
              icon: Icon(Icons.search, color: Colors.blue),
              text: '発掘済み',
            ),
            Tab(
              icon: Icon(Icons.star, color: Colors.orange),
              text: '注目選手',
            ),
            Tab(
              icon: Icon(Icons.school, color: Colors.purple),
              text: '卒業生',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // お気に入り選手タブ
          _buildPlayerList(
            _getSortedPlayers(_getPlayersByCategory(allPlayers, PlayerCategory.favorite)),
            'お気に入り選手',
            '個人的に気に入っている選手です。成長をモニタリングできます。',
          ),
          // 発掘済み選手タブ
          _buildPlayerList(
            _getSortedPlayers(_getPlayersByCategory(allPlayers, PlayerCategory.discovered)),
            '発掘済み選手',
            '視察で発掘・分析済みの選手です。詳細な能力値を確認できます。',
          ),
          // 注目選手タブ
          _buildPlayerList(
            _getSortedPlayers(_getPlayersByCategory(allPlayers, PlayerCategory.famous)),
            '注目選手',
            '知名度が高く世間に知られている選手です。視察で発掘できます。',
          ),
          // 卒業生タブ
          _buildPlayerList(
            _getSortedPlayers(allPlayers.where((p) => p.isGraduated).toList()),
            '卒業生',
            '卒業した選手です。彼らの活躍を振り返ってみましょう。',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List<Player> players, String title, String description) {
    return Column(
      children: [
        // ヘッダー情報
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${players.length}名',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.sort, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getSortName(_selectedSort),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 選手リスト
        Expanded(
          child: players.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '選手がいません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '視察や発掘で選手を追加してください',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    
                    return PlayerListCard(
                      player: player,
                      showActions: true,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/playerDetail',
                          arguments: player,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getSortName(String sort) {
    switch (sort) {
      case 'fame': return '知名度順';
      case 'talent': return '才能順';
      case 'potential': return 'ポテンシャル順';
      case 'grade': return '学年順';
      case 'school': return '学校順';
      default: return '名前順';
    }
  }
} 