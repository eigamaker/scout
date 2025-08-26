import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../models/game/game.dart';
import '../models/professional/professional_team.dart';
import '../models/game/pennant_race.dart';
import '../models/player/player.dart';
import '../services/draft_strategy_service.dart';

class DraftScreen extends StatefulWidget {
  const DraftScreen({Key? key}) : super(key: key);

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  int _currentRound = 1; // 現在の巡目（1-10）
  int _currentPick = 0; // 現在の巡目内での選択順
  bool _isDraftInProgress = false;
  bool _isDraftCompleted = false; // ドラフト完了フラグ
  List<String> _draftOrder = [];
  Map<String, dynamic> _draftOrderDetails = {};
  List<Map<String, dynamic>> _draftResults = [];
  Map<String, int> _teamPickCounts = {}; // 各チームの選択回数

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDraft();
    });
  }

  void _initializeDraft() {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    _draftOrder = gameManager.determineDraftOrder();
    _draftOrderDetails = gameManager.getDraftOrderDetails();
    setState(() {});
  }

  void _startDraft() {
    setState(() {
      _isDraftInProgress = true;
      _isDraftCompleted = false;
      _currentRound = 1;
      _currentPick = 0;
      _draftResults.clear();
      _teamPickCounts.clear();
      
      // 各チームの選択回数を初期化
      for (final teamId in _draftOrder) {
        _teamPickCounts[teamId] = 0;
      }
    });
  }

  void _nextPick() {
    if (_currentRound <= 10) {
      final teamId = _draftOrder[_currentPick];
      final team = Provider.of<GameManager>(context, listen: false)
          .currentGame?.professionalTeams.getTeam(teamId);
      
      if (team != null) {
        // 選手選択
        final selectedPlayer = _selectPlayerForTeam(team);
        
        if (!selectedPlayer.containsKey('error')) {
          // ドラフト結果を上に追加（新しい選択が上に表示される）
          _draftResults.insert(0, {
            'round': _currentRound,
            'pick': _currentPick + 1,
            'teamId': teamId,
            'teamName': team.name,
            'teamShortName': team.shortName,
            'selectedPlayer': selectedPlayer,
            'timestamp': DateTime.now(),
          });
          
          // チームの選択回数を更新
          _teamPickCounts[teamId] = (_teamPickCounts[teamId] ?? 0) + 1;
        }
      }
      
      setState(() {
        _currentPick++;
        
        // 1巡目が終わったら2巡目へ
        if (_currentPick >= _draftOrder.length) {
          _currentRound++;
          _currentPick = 0;
        }
      });
    }
  }

  Map<String, dynamic> _selectPlayerForTeam(ProfessionalTeam team) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final game = gameManager.currentGame;
    
    if (game == null) {
      return {'error': 'ゲームデータが見つかりません'};
    }
    
    // 利用可能な選手を取得（高校卒業済み、未引退、デフォルト選手以外、24歳以下）
    final availablePlayers = game.discoveredPlayers.where((player) {
      // 高校卒業済み
      if (!(player.isGraduated ?? false)) return false;
      
      // 未引退
      if (player.isRetired ?? false) return false;
      
      // デフォルト選手以外（学校名がデフォルトでない）
      if (player.school.contains('デフォルト') || player.school.contains('default')) return false;
      
      // 24歳以下
      if ((player.age ?? 0) > 24) return false;
      
      return true;
    }).toList();
    
    if (availablePlayers.isEmpty) {
      return {'error': '選択可能な選手がいません'};
    }
    
    // 球団のニーズを分析
    final teamNeeds = DraftStrategyService.analyzeTeamNeeds(
      team,
      game.pennantRace?.standings ?? {},
      team.professionalPlayers ?? [],
    );
    
    // ニーズに基づいて選手を選択
    final selection = DraftStrategyService.selectPlayerForTeam(
      team,
      teamNeeds,
      availablePlayers,
    );
    
    if (selection.containsKey('error')) {
      return selection;
    }
    
    final selectedPlayer = selection['selectedPlayer'] as Player;
    final reason = selection['reason'] as String;
    
    return {
      'name': selectedPlayer.name,
      'position': selectedPlayer.position,
      'school': selectedPlayer.school,
      'age': selectedPlayer.age ?? 0,
      'reason': reason,
      'teamNeeds': DraftStrategyService.generateDraftStrategySummary(teamNeeds),
    };
    }
  
  /// ドラフト完了後の表示
  Widget _buildDraftCompleted() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            const Text(
              'ドラフト会議が完了しました！',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentRound - 1}巡目まで完了 - 合計${_draftResults.length}名の選手が指名されました',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(
                  'ドラフト会議は一度のみ開催されます',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 高校卒業済み選手の状態を「未所属」として表示
  String _getPlayerStatus(Player player) {
    if (player.isGraduated ?? false) {
      return '未所属';
    }
    return '在学中';
  }

  void _completeDraft() {
    setState(() {
      _isDraftInProgress = false;
      _isDraftCompleted = true;
    });
    
    // ドラフト完了の処理
    // 実際の実装では、選択された選手をプロチームに割り当てるなどの処理が必要
    
    // 完了メッセージを表示
    final totalPicks = _draftResults.length;
    final totalRounds = _currentRound - 1;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ドラフト会議が完了しました！${totalRounds}巡目までで${totalPicks}名の選手が指名されました。'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ドラフト会議'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Consumer<GameManager>(
        builder: (context, gameManager, child) {
          final game = gameManager.currentGame;
          if (game == null) {
            return const Center(child: Text('ゲームデータが見つかりません'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ドラフト順位表
                _buildDraftOrderTable(),
                const SizedBox(height: 24),
                
                // 球団戦略情報
                _buildTeamStrategyInfo(),
                const SizedBox(height: 24),
                
                                  // ドラフト進行状況
                  if (_isDraftInProgress) _buildDraftProgress(),
                  
                  // ドラフト完了後の表示
                  if (_isDraftCompleted) _buildDraftCompleted(),
                  
                  // ドラフト結果
                  if (_draftResults.isNotEmpty) _buildDraftResults(),
                
                const SizedBox(height: 24),
                
                // 操作ボタン
                _buildActionButtons(gameManager),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamStrategyInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  '球団戦略情報',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_draftOrderDetails.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('ドラフト順位が決定されていません'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _draftOrderDetails.length,
                itemBuilder: (context, index) {
                  final pick = _draftOrderDetails.keys.elementAt(index);
                  final details = _draftOrderDetails[pick] as Map<String, dynamic>;
                  final teamId = details['teamId'] as String;
                  
                  // 球団の戦略情報を取得
                  final gameManager = Provider.of<GameManager>(context, listen: false);
                  final game = gameManager.currentGame;
                  final team = game?.professionalTeams.getTeam(teamId);
                  
                  if (team == null) return const SizedBox.shrink();
                  
                  final teamNeeds = DraftStrategyService.analyzeTeamNeeds(
                    team,
                    game?.pennantRace?.standings ?? {},
                    team.professionalPlayers ?? [],
                  );
                  
                  final strategySummary = DraftStrategyService.generateDraftStrategySummary(teamNeeds);
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$pick: ${details['teamShortName']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  details['league'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '成績: ${details['wins']}勝${details['losses']}敗 (勝率: ${(details['winningPercentage'] * 100).toStringAsFixed(3)}%)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '戦略: $strategySummary',
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftOrderTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_baseball, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'ドラフト順位表',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_draftOrderDetails.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('ドラフト順位が決定されていません'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('順位')),
                    DataColumn(label: Text('チーム')),
                    DataColumn(label: Text('リーグ')),
                    DataColumn(label: Text('勝率')),
                    DataColumn(label: Text('成績')),
                  ],
                  rows: _draftOrderDetails.entries.map((entry) {
                    final pick = entry.key;
                    final details = entry.value as Map<String, dynamic>;
                    
                    return DataRow(
                      cells: [
                        DataCell(Text(pick)),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                details['teamShortName'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                details['teamName'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(details['league'])),
                        DataCell(Text('${(details['winningPercentage'] * 100).toStringAsFixed(3)}')),
                        DataCell(Text('${details['wins']}勝${details['losses']}敗')),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftProgress() {
    if (_currentRound > 10) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text(
                'ドラフト会議が完了しました！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '10巡目まで完了 - 合計${_draftResults.length}名の選手が指名されました',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentTeamId = _draftOrder[_currentPick];
    final currentTeam = Provider.of<GameManager>(context, listen: false)
        .currentGame?.professionalTeams.getTeam(currentTeamId);

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_baseball, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  '${_currentRound}巡目指名中',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentTeam != null)
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      currentTeam.shortName[0],
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTeam.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${currentTeam.league.toString().split('.').last}・${currentTeam.division.toString().split('.').last}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPick,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('選手選択'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_currentRound - 1 + (_currentPick + 1) / _draftOrder.length) / 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
            const SizedBox(height: 8),
            Text(
              '進行状況: ${_currentRound}巡目 ${_currentPick + 1}/${_draftOrder.length} (全体: ${((_currentRound - 1 + (_currentPick + 1) / _draftOrder.length) / 10 * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentRound}巡目: ${_draftOrder.length}球団中${_currentPick + 1}球団目',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'ドラフト結果',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _draftResults.length,
              itemBuilder: (context, index) {
                final result = _draftResults[index];
                final player = result['selectedPlayer'] as Map<String, dynamic>;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Text(
                        '${result['round']}',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('${result['teamShortName']} - ${player['name']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${player['position']} (${player['school']}) - ${player['age']}歳'),
                        if (player['reason'] != null)
                          Text(
                            '理由: ${player['reason']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${result['pick']}位',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_teamPickCounts[result['teamId']] ?? 0}/10',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(GameManager gameManager) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!_isDraftInProgress && !_isDraftCompleted)
          ElevatedButton.icon(
            onPressed: _startDraft,
            icon: const Icon(Icons.play_arrow),
            label: const Text('ドラフト開始'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        if (_isDraftInProgress && _currentRound > 10)
          ElevatedButton.icon(
            onPressed: _completeDraft,
            icon: const Icon(Icons.check),
            label: const Text('ドラフト完了'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('戻る'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
