import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../services/data_service.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  Future<void> _startNewGame(BuildContext context) async {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
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
    await gameManager.startNewGameWithDb('あなた', dataService);
    if (!context.mounted) return;
    Navigator.pop(context); // ダイアログを閉じる
    Navigator.pushReplacementNamed(context, '/game');
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
          ],
        ),
      ),
    );
  }
} 