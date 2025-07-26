import 'package:flutter/material.dart';
import '../models/scouting/action.dart' as scouting;
import '../models/scouting/scout.dart';
import '../models/scouting/scouting_history.dart';
import '../models/scouting/skill.dart';
import '../services/scouting/action_service.dart';

class ScoutTestScreen extends StatefulWidget {
  const ScoutTestScreen({super.key});

  @override
  State<ScoutTestScreen> createState() => _ScoutTestScreenState();
}

class _ScoutTestScreenState extends State<ScoutTestScreen> {
  late Scout scout;
  ScoutingHistory? history;
  int currentWeek = 1;
  List<String> logMessages = [];

  @override
  void initState() {
    super.initState();
    scout = Scout.createDefault(id: '1', name: 'テストスカウト');
    history = ScoutingHistory.create(
      scoutId: scout.id,
      targetId: 'player_1',
      targetType: 'player',
    );
  }

  void _executeAction(scouting.Action action) {
    final result = ActionService.executeAction(
      action: action,
      scout: scout,
      targetId: 'player_1',
      targetType: 'player',
      history: history,
      currentWeek: currentWeek,
    );

    setState(() {
      scout = result.scout;
      
      if (result.isSuccessful && result.record != null) {
        history = history?.addRecord(result.record!);
      }

      // ログメッセージを追加
      final message = result.isSuccessful
          ? '${action.name}: 成功 (精度: ${result.accuracy?.toStringAsFixed(1)}%)'
          : '${action.name}: 失敗 (${result.failureReason})';
      
      logMessages.insert(0, message);
      if (logMessages.length > 10) {
        logMessages.removeLast();
      }
    });
  }

  void _resetScout() {
    setState(() {
      scout = Scout.createDefault(id: '1', name: 'テストスカウト');
      history = ScoutingHistory.create(
        scoutId: scout.id,
        targetId: 'player_1',
        targetType: 'player',
      );
      logMessages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スカウトシステムテスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetScout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // スカウト情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'スカウト: ${scout.name}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('レベル: ${scout.level}'),
                    Text('AP: ${scout.actionPoints}/${scout.maxActionPoints}'),
                    Text('体力: ${scout.stamina}/${scout.maxStamina}'),
                    Text('所持金: ¥${scout.money.toStringAsFixed(0)}'),
                    Text('信頼度: ${scout.trustLevel}'),
                    Text('成功率: ${(scout.successRate * 100).toStringAsFixed(1)}%'),
                    const SizedBox(height: 8),
                    Text('視察回数: ${history?.totalVisits ?? 0}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // スキル表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'スキル',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: Skill.values.map((skill) {
                        final value = scout.getSkill(skill);
                        return Chip(
                          label: Text('${skill.displayName}: $value'),
                          backgroundColor: value >= 7 
                              ? Colors.green[100] 
                              : value >= 5 
                                  ? Colors.orange[100] 
                                  : Colors.grey[100],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // アクションボタン
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'アクション',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                                      Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: scouting.Action.getAll().length,
                        itemBuilder: (context, index) {
                          final action = scouting.Action.getAll()[index];
                        final canExecute = scout.actionPoints >= action.actionPoints &&
                                         scout.money >= action.cost &&
                                         scout.stamina >= action.actionPoints * 5;
                        
                        return ElevatedButton(
                          onPressed: canExecute ? () => _executeAction(action) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canExecute ? null : Colors.grey[300],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                action.name,
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'AP: ${action.actionPoints} ¥: ${action.cost}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ログ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '実行ログ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        itemCount: logMessages.length,
                        itemBuilder: (context, index) {
                          final message = logMessages[index];
                          final isSuccess = message.contains('成功');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              message,
                              style: TextStyle(
                                color: isSuccess ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 