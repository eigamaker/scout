import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';

import '../models/game/game.dart';
import '../models/school/school.dart';
import 'school_detail_screen.dart';

class SchoolListScreen extends StatefulWidget {
  const SchoolListScreen({super.key});

  @override
  State<SchoolListScreen> createState() => _SchoolListScreenState();
}

class _SchoolListScreenState extends State<SchoolListScreen> {
  String _selectedPrefecture = 'すべて';
  SchoolRank? _selectedRank;
  int _currentPage = 0;
  static const int _schoolsPerPage = 50;

  @override
  void initState() {
    super.initState();
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final prefecture = gameManager.currentGame?.scoutPrefecture;
    if (prefecture != null && prefecture.isNotEmpty) {
      _selectedPrefecture = prefecture;
    }
  }

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
      ),
      body: Column(
        children: [
          // フィルタリングバー
          _buildFilterBar(),
          
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
      // 都道府県でフィルタリング
      if (_selectedPrefecture != 'すべて' && school.prefecture != _selectedPrefecture) {
        return false;
      }
      
      // 学校ランクでフィルタリング
      if (_selectedRank != null && school.rank != _selectedRank) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// フィルタリングバーを構築
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      child: Row(
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
          const SizedBox(width: 8),
          // リセットボタン
          TextButton(
            onPressed: () {
              setState(() {
                _selectedPrefecture = 'すべて';
                _selectedRank = null;
                _currentPage = 0;
              });
            },
            child: const Text('リセット'),
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



  /// 学校カードを構築
  Widget _buildSchoolCard(BuildContext context, School school, GameManager gameManager, Game game) {
    
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
            // 1行目: 学校名とランク
            Row(
              children: [
                Expanded(
                  child: Text(
                    school.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 2行目: 場所とボタン
            Row(
              children: [
                Text(
                  school.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                // 練習視察ボタン
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: () => _addPracticeWatchAction(context, school, gameManager, game),
                    icon: const Icon(Icons.visibility, size: 14),
                    label: const Text('練習視察', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      backgroundColor: Colors.blue[100],
                      foregroundColor: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 練習試合観戦ボタン
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: () => _addScrimmageAction(context, school, gameManager, game),
                    icon: const Icon(Icons.sports_baseball, size: 14),
                    label: const Text('練習試合', style: TextStyle(fontSize: 10)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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


} 