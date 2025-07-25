import 'package:flutter/material.dart';

class LoadGameScreen extends StatelessWidget {
  const LoadGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('セーブデータ選択')),
      body: ListView.builder(
        itemCount: 3, // 仮に3スロット
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: ListTile(
              leading: Icon(Icons.save),
              title: Text('セーブスロット${index + 1}'),
              subtitle: Text('セーブデータの詳細（今後実装）'),
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: セーブデータをロードしてゲーム画面へ遷移
                  Navigator.pushReplacementNamed(context, '/game');
                },
                child: const Text('ロード'),
              ),
            ),
          );
        },
      ),
    );
  }
} 