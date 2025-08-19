import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/scouting/action_service.dart';
import '../models/game/game.dart';
import '../models/school/school.dart';
import 'school_detail_screen.dart';

class SchoolListScreen extends StatefulWidget {
  const SchoolListScreen({super.key});

  @override
  State<SchoolListScreen> createState() => _SchoolListScreenState();
}

class _SchoolListScreenState extends State<SchoolListScreen> {
  String _searchQuery = '';
  String _selectedPrefecture = 'すべて';
  SchoolRank? _selectedRank;
  bool _showOnlyWithGeneratedPlayers = false;
  int _currentPage = 0;
  static const int _schoolsPerPage = 50;

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    final game = gameManager.currentGame;
    
    if (game == null) {
      return const Scaffold(
        body: Center(child: Text('ゲームが開始されていません')),
      );
    }

    // フィルタリングされた学校リスト
    final filteredSchools = _getFilteredSchools(game.schools);
    
    // ページネーション
    final totalPages = (filteredSchools.length / _schoolsPerPage).ceil();
    final startIndex = _currentPage * _schoolsPerPage;
    final endIndex = (startIndex + _schoolsPerPage).clamp(0, filteredSchools.length);
    final currentPageSchools = filteredSchools.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text('学校リスト (${filteredSchools.length}校)'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showStatistics(context, game.schools),
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索・フィルタリングバー
          _buildFilterBar(),
          
          // 統計情報
          _buildStatisticsBar(game.schools),
          
          // 学校リスト
          Expanded(
            child: currentPageSchools.isEmpty
                ? const Center(
                    child: Text('条件に合う学校が見つかりません'),
                  )
                : ListView.builder(
                    itemCount: currentPageSchools.length,
                    itemBuilder: (context, index) {
                      final school = currentPageSchools[index];
                      return _buildSchoolCard(context, school, gameManager, game);
                    },
                  ),
          ),
          
          // ページネーション
          if (totalPages > 1) _buildPagination(totalPages),
        ],
      ),
    );
  }

  /// フィルタリングされた学校リストを取得
  List<School> _getFilteredSchools(List<School> allSchools) {
    return allSchools.where((school) {
      // 検索クエリでフィルタリング
      if (_searchQuery.isNotEmpty) {
        if (!school.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !school.location.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // 都道府県でフィルタリング
      if (_selectedPrefecture != 'すべて' && school.prefecture != _selectedPrefecture) {
        return false;
      }
      
      // 学校ランクでフィルタリング
      if (_selectedRank != null && school.rank != _selectedRank) {
        return false;
      }
      
      // 生成選手の有無でフィルタリング
      if (_showOnlyWithGeneratedPlayers) {
        final hasGeneratedPlayers = school.players.any((p) => p.talent >= 3);
        if (!hasGeneratedPlayers) return false;
      }
      
      return true;
    }).toList();
  }

  /// 検索・フィルタリングバーを構築
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      child: Column(
        children: [
          // 検索バー
          TextField(
            decoration: const InputDecoration(
              hintText: '学校名や場所で検索...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 0; // 検索時は最初のページに戻る
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // フィルターボタン
          Row(
            children: [
              // 都道府県フィルター
              Expanded(
                child: _buildPrefectureFilter(),
              ),
              const SizedBox(width: 8),
              // 学校ランクフィルター
              Expanded(
                child: _buildRankFilter(),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // その他のフィルター
          Row(
            children: [
              FilterChip(
                label: const Text('生成選手ありのみ'),
                selected: _showOnlyWithGeneratedPlayers,
                onSelected: (selected) {
                  setState(() {
                    _showOnlyWithGeneratedPlayers = selected;
                    _currentPage = 0;
                  });
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedPrefecture = 'すべて';
                    _selectedRank = null;
                    _showOnlyWithGeneratedPlayers = false;
                    _currentPage = 0;
                  });
                },
                child: const Text('フィルターリセット'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 都道府県フィルターを構築
  Widget _buildPrefectureFilter() {
    final prefectures = [
      'すべて',
      '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
      '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
      '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
      '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
      '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
      '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
      '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
    ];

    return DropdownButtonFormField<String>(
      value: _selectedPrefecture,
      decoration: const InputDecoration(
        labelText: '都道府県',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: prefectures.map((prefecture) {
        return DropdownMenuItem(
          value: prefecture,
          child: Text(prefecture),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedPrefecture = value!;
          _currentPage = 0;
        });
      },
    );
  }

  /// 学校ランクフィルターを構築
  Widget _buildRankFilter() {
    final ranks = [
      const DropdownMenuItem<SchoolRank?>(
        value: null,
        child: Text('すべて'),
      ),
      ...SchoolRank.values.map((rank) => DropdownMenuItem(
        value: rank,
        child: Text(rank.name),
      )),
    ];

    return DropdownButtonFormField<SchoolRank?>(
      value: _selectedRank,
      decoration: const InputDecoration(
        labelText: '学校ランク',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ranks,
      onChanged: (value) {
        setState(() {
          _selectedRank = value;
          _currentPage = 0;
        });
      },
    );
  }

  /// 統計情報バーを構築
  Widget _buildStatisticsBar(List<School> allSchools) {
    final totalSchools = allSchools.length;
    final eliteCount = allSchools.where((s) => s.rank == SchoolRank.elite).length;
    final strongCount = allSchools.where((s) => s.rank == SchoolRank.strong).length;
    final averageCount = allSchools.where((s) => s.rank == SchoolRank.average).length;
    final weakCount = allSchools.where((s) => s.rank == SchoolRank.weak).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.blue[50],
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('総校数', totalSchools.toString(), Colors.blue),
          ),
          Expanded(
            child: _buildStatItem('名門', eliteCount.toString(), Colors.red),
          ),
          Expanded(
            child: _buildStatItem('強豪', strongCount.toString(), Colors.orange),
          ),
          Expanded(
            child: _buildStatItem('中堅', averageCount.toString(), Colors.green),
          ),
          Expanded(
            child: _buildStatItem('弱小', weakCount.toString(), Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 統計項目を構築
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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
    );
  }

  /// 学校カードを構築
  Widget _buildSchoolCard(BuildContext context, School school, GameManager gameManager, Game game) {
    final generatedPlayerCount = school.players.where((p) => p.talent >= 3).length;
    final defaultPlayerCount = school.players.where((p) => p.talent < 3).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: _getRankColor(school.rank)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToSchoolDetail(context, school),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学校名とランク
            Row(
              children: [
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRankColor(school.rank),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            school.rank.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          school.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            ],
          ),
          
          const SizedBox(height: 12),
          
          // アクションボタン
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _addPracticeWatchAction(context, school, gameManager, game),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: Colors.blue[100],
                    foregroundColor: Colors.blue[800],
                  ),
                  child: const Text('練習視察'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _addScrimmageAction(context, school, gameManager, game),
                  icon: const Icon(Icons.sports_baseball, size: 16),
                  label: const Text('練習試合観戦'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: Colors.orange[100],
                    foregroundColor: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
        ],
        ),
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

  /// ページネーションを構築
  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () {
              setState(() {
                _currentPage--;
              });
            } : null,
            icon: const Icon(Icons.chevron_left),
          ),
          
          Text('${_currentPage + 1} / $totalPages'),
          
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () {
              setState(() {
                _currentPage++;
              });
            } : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// 練習視察アクションを追加
  void _addPracticeWatchAction(BuildContext context, School school, GameManager gameManager, Game game) {
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'PRAC_WATCH',
      schoolId: game.schools.indexOf(school),
      playerId: null,
      apCost: 2,
      budgetCost: 20000,
      params: {},
    );
    
    if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${school.name}の練習視察を計画に追加しました（AP: ${action.apCost}, 予算: ¥${action.budgetCost}）'),
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
  void _addScrimmageAction(BuildContext context, School school, GameManager gameManager, Game game) {
    final action = GameAction(
      id: UniqueKey().toString(),
      type: 'scrimmage',
      schoolId: game.schools.indexOf(school),
      playerId: null,
      apCost: 2,
      budgetCost: 30000,
      params: {},
    );
    
    if (game.ap >= action.apCost && game.budget >= action.budgetCost) {
      gameManager.addActionToGame(action);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${school.name}の練習試合観戦を計画に追加しました（AP: ${action.apCost}, 予算: ¥${action.budgetCost}）'),
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

  /// 学校詳細画面にナビゲーション
  void _navigateToSchoolDetail(BuildContext context, School school) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SchoolDetailScreen(school: school),
      ),
    );
  }

  /// 統計情報ダイアログを表示
  void _showStatistics(BuildContext context, List<School> schools) {
    final totalSchools = schools.length;
    final eliteSchools = schools.where((s) => s.rank == SchoolRank.elite).toList();
    final strongSchools = schools.where((s) => s.rank == SchoolRank.strong).toList();
    final averageSchools = schools.where((s) => s.rank == SchoolRank.average).toList();
    final weakSchools = schools.where((s) => s.rank == SchoolRank.weak).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('学校統計情報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('総学校数: $totalSchools校'),
            const SizedBox(height: 16),
            _buildRankStatistics('名門校', eliteSchools, Colors.red),
            _buildRankStatistics('強豪校', strongSchools, Colors.orange),
            _buildRankStatistics('中堅校', averageSchools, Colors.green),
            _buildRankStatistics('弱小校', weakSchools, Colors.grey),
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

  /// ランク別統計を構築
  Widget _buildRankStatistics(String label, List<School> schools, Color color) {
    final totalGeneratedPlayers = schools.fold<int>(0, (sum, school) {
      return sum + school.players.where((p) => p.talent >= 3).length;
    });
    final totalDefaultPlayers = schools.fold<int>(0, (sum, school) {
      return sum + school.players.where((p) => p.talent < 3).length;
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (${schools.length}校)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('生成選手: $totalGeneratedPlayers人'),
                Text('デフォルト選手: $totalDefaultPlayers人'),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 