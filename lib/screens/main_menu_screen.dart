import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/data_service.dart';
import 'slot_select_screen.dart';
import 'slot_copy_screen.dart';
import 'package:sqflite/sqflite.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  Future<void> _startNewGame(BuildContext context) async {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    // スロット選択画面を表示
    final slot = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const SlotSelectScreen()),
    );
    if (slot == null) return;
    // スロット名をDataServiceにセット
    dataService.currentSlot = slot;
    // DB削除→新規作成
    await dataService.deleteDatabaseWithSlot(slot);
    // 進捗ダイアログ表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('選手を作成しています...'),
            SizedBox(height: 24),
            LinearProgressIndicator(),
          ],
        ),
      ),
    );
    // スロット用DBでニューゲーム開始
    final db = await dataService.getDatabaseWithSlot(slot);
    await gameManager.startNewGameWithDb('あなた', dataService);
    if (!context.mounted) return;
    Navigator.pop(context); // ダイアログを閉じる
    Navigator.pushReplacementNamed(context, '/game');
  }

  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<DataService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scout Game メインメニュー'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // デバッグ用: 現在のDBファイルパスを表示
            FutureBuilder(
              future: getDatabasesPath(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final dbPath = snapshot.data as String;
                final dbName = dataService.currentSlot == 'オートセーブ'
                    ? 'autosave.db'
                    : 'save${dataService.currentSlot == 'セーブ1' ? 1 : dataService.currentSlot == 'セーブ2' ? 2 : 3}.db';
                final path = '$dbPath/$dbName';
                return Text('DB: $path', style: const TextStyle(fontSize: 12, color: Colors.grey));
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _startNewGame(context),
              child: const Text('ニューゲーム'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/load');
              },
              child: const Text('続きから'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<Map<String, String>>(
                  context,
                  MaterialPageRoute(builder: (context) => const SlotCopyScreen()),
                );
                if (result != null && result['from'] != null && result['to'] != null) {
                  final dataService = Provider.of<DataService>(context, listen: false);
                  await dataService.copyDatabaseBetweenSlots(result['from']!, result['to']!);
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text('コピーが完了しました'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('セーブデータコピー'),
            ),
          ],
        ),
      ),
    );
  }
} 