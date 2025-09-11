import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../models/game/game.dart';
import '../models/professional/professional_team.dart';
import '../models/game/pennant_race.dart';
import '../models/player/player.dart';
import '../services/draft_strategy_service.dart';
import 'draft/widgets/draft_progress_widget.dart';
import 'draft/widgets/draft_order_table_widget.dart';
import 'draft/widgets/draft_results_widget.dart';

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
    });
  }

  void _nextPick() {
    if (!_isDraftInProgress || _isDraftCompleted) return;

    final gameManager = Provider.of<GameManager>(context, listen: false);
    final currentTeamId = _draftOrder[_currentPick];
    // TODO: プロ野球団とドラフト機能の実装が必要
    final currentTeam = null; // gameManager.getProfessionalTeam(currentTeamId);
    
    if (currentTeam == null) {
      _completeDraft();
      return;
    }
    
    // 次の選択に進む
    _currentPick++;
    if (_currentPick >= _draftOrder.length) {
      _currentPick = 0;
      _currentRound++;
      
      if (_currentRound > 10) {
        _completeDraft();
        return;
      }
    }

    setState(() {});
  }

  void _completeDraft() {
    setState(() {
      _isDraftInProgress = false;
      _isDraftCompleted = true;
    });
    
    // ドラフト完了の通知
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ドラフトが完了しました！'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('ドラフト'),
            actions: [
              if (_isDraftInProgress && !_isDraftCompleted)
                TextButton(
                  onPressed: _nextPick,
                  child: const Text('次の選択'),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                DraftProgressWidget(
                  currentRound: _currentRound,
                  currentPick: _currentPick,
                  totalRounds: 10,
                  totalPicksPerRound: _draftOrder.length,
                  isDraftInProgress: _isDraftInProgress,
                  isDraftCompleted: _isDraftCompleted,
                ),
                DraftOrderTableWidget(
                  draftOrder: _draftOrder,
                  draftOrderDetails: _draftOrderDetails,
                  currentRound: _currentRound,
                  currentPick: _currentPick,
                ),
                DraftResultsWidget(
                  draftResults: _draftResults,
                  currentRound: _currentRound,
                  currentPick: _currentPick,
                ),
                const SizedBox(height: 20),
                _buildActionButtons(gameManager),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(GameManager gameManager) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (!_isDraftInProgress && !_isDraftCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startDraft,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'ドラフト開始',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_isDraftInProgress && !_isDraftCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextPick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '次の選択',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_isDraftCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'ドラフト完了 - ゲームに戻る',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}