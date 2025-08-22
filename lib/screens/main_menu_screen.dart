import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/data_service.dart';
import 'slot_select_screen.dart';
import 'slot_copy_screen.dart';
import 'game_screen.dart';

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
    try {
      // スロット用DBでニューゲーム開始
      final db = await dataService.getDatabaseWithSlot(slot);
      await gameManager.startNewGameWithDb('あなた', dataService);
      
      // デバッグ: ニューゲーム開始後の状態を確認
      print('MainMenuScreen._startNewGame: ニューゲーム開始後の状態確認');
      print('MainMenuScreen._startNewGame: gameManager.currentGame = ${gameManager.currentGame != null ? "loaded" : "null"}');
      if (gameManager.currentGame != null) {
        print('MainMenuScreen._startNewGame: 学校数: ${gameManager.currentGame!.schools.length}');
        print('MainMenuScreen._startNewGame: 発掘選手数: ${gameManager.currentGame!.discoveredPlayers.length}');
      }
      
      // Providerの状態を強制的に更新
      if (context.mounted) {
        setState(() {});
      }
      
      // 少し待機してからゲーム画面に遷移
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      print('MainMenuScreen._startNewGame: ニューゲーム開始でエラーが発生しました: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ゲームの開始に失敗しました: $e')),
        );
      }
      return;
    } finally {
      // 確実にダイアログを閉じる
      if (context.mounted) {
        Navigator.pop(context);
        print('ダイアログを閉じました');
      }
    }
    if (!context.mounted) return;
    
    // SnackBarをクリア
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // 画面を強制リビルド
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        setState(() {});
      }
    });
    
    // ゲームの状態を最終確認
    if (gameManager.currentGame == null) {
      print('MainMenuScreen._startNewGame: エラー - ゲームが開始されていません');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ゲームの開始に失敗しました。もう一度お試しください。')),
        );
      }
      return;
    }
    
    print('MainMenuScreen._startNewGame: ゲーム画面に遷移開始');
    
    // 前の画面スタックをクリアしてゲーム画面に遷移
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scout Game メインメニュー'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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