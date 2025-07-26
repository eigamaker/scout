import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player/player.dart';
import '../services/game_manager.dart';
import '../services/player_generator.dart';
import '../widgets/player_card.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  String _selectedFilter = 'discovered'; // デフォルトを「発掘済み」に変更
  String _selectedSort = 'name';

  // フィルター適用
  List<Player> _getFilteredPlayers(List<Player> players) {
    switch (_selectedFilter) {
      case 'discovered':
        return players.where((player) => player.isDiscovered).toList();
      case 'famous':
        return players.where((player) => player.fameLevel >= 3).toList();
      case 'pitcher':
        return players.where((player) => player.isPitcher && player.isDiscovered).toList();
      case 'batter':
        return players.where((player) => !player.isPitcher && player.isDiscovered).toList();
      case 'all':
        return players; // 全ての選手（発掘済み＋未発掘）
      default:
        return players.where((player) => player.isDiscovered).toList();
    }
  }

  // ソート適用
  List<Player> _getSortedPlayers(List<Player> players) {
    switch (_selectedSort) {
      case 'fame':
        players.sort((a, b) => b.totalFamePoints.compareTo(a.totalFamePoints));
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
      default:
        players.sort((a, b) => a.name.compareTo(b.name));
    }
    return players;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター・ソート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // フィルター
            const Text('フィルター:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: const Text('発掘済み'),
              subtitle: const Text('視察で発掘した選手のみ'),
              value: 'discovered',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            RadioListTile<String>(
              title: const Text('全ての選手'),
              subtitle: const Text('発掘済み＋未発掘の全選手'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            RadioListTile<String>(
              title: const Text('有名選手'),
              subtitle: const Text('知名度の高い選手'),
              value: 'famous',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            RadioListTile<String>(
              title: const Text('投手'),
              subtitle: const Text('発掘済みの投手のみ'),
              value: 'pitcher',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            RadioListTile<String>(
              title: const Text('野手'),
              subtitle: const Text('発掘済みの野手のみ'),
              value: 'batter',
              groupValue: _selectedFilter,
              onChanged: (value) => setState(() => _selectedFilter = value!),
            ),
            const Divider(),
            // ソート
            const Text('ソート:', style: TextStyle(fontWeight: FontWeight.bold)),
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
    // テスト用の選手リスト（本来はgameManager.currentGame?.discoveredPlayersなどを使う）
    final List<Player> allPlayers = gameManager.currentGame?.discoveredPlayers ?? PlayerGenerator.generateTestPlayers();
    
    // フィルターとソートを適用
    final filteredPlayers = _getFilteredPlayers(allPlayers);
    final sortedPlayers = _getSortedPlayers(filteredPlayers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('選手リスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // フィルター情報表示
          if (_selectedFilter != 'discovered' || _selectedSort != 'name')
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'フィルター: ${_getFilterName(_selectedFilter)} | ソート: ${_getSortName(_selectedSort)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          // 選手リスト
          Expanded(
            child: sortedPlayers.isEmpty
                ? const Center(child: Text('条件に合う選手がいません'))
                : ListView.builder(
                    itemCount: sortedPlayers.length,
                    itemBuilder: (context, index) {
                      final player = sortedPlayers[index];
                      return PlayerCard(
                        player: player,
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
      ),
    );
  }

  String _getFilterName(String filter) {
    switch (filter) {
      case 'discovered': return '発掘済み';
      case 'famous': return '有名選手';
      case 'pitcher': return '投手';
      case 'batter': return '野手';
      default: return '全て';
    }
  }

  String _getSortName(String sort) {
    switch (sort) {
      case 'fame': return '知名度順';
      case 'talent': return '才能順';
      case 'potential': return 'ポテンシャル順';
      case 'grade': return '学年順';
      default: return '名前順';
    }
  }
} 