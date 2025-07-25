import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _startNewGame(BuildContext context) async {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    
    // スカウト名入力ダイアログ
    final scoutName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スカウト名を入力'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'スカウト名',
            hintText: '例：田中スカウト',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final textController = (context.findRenderObject() as RenderBox)
                  .findChild<EditableText>()
                  ?.controller as TextEditingController?;
              Navigator.pop(context, textController?.text ?? '名無しスカウト');
            },
            child: const Text('開始'),
          ),
        ],
      ),
    );

    if (scoutName != null && scoutName.isNotEmpty) {
      gameManager.startNewGame(scoutName);
      Navigator.pushReplacementNamed(context, '/game');
    }
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
              child: const Text('新しいゲーム'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/players');
              },
              child: const Text('選手リスト'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/news');
              },
              child: const Text('ニュース一覧'),
            ),
          ],
        ),
      ),
    );
  }
} 