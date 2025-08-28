import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../services/game_manager.dart';

class LoadGameScreen extends StatefulWidget {
  const LoadGameScreen({super.key});

  @override
  State<LoadGameScreen> createState() => _LoadGameScreenState();
}

class _LoadGameScreenState extends State<LoadGameScreen> {
  final List<bool> _hasData = [false];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkSlots();
  }

  Future<void> _checkSlots() async {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    _hasData[0] = await gameManager.hasGameData();
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('セーブデータ選択')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: 1, // 単一セーブスロット
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: ListTile(
                    leading: const Icon(Icons.save),
                    title: const Text('セーブデータ'),
                    subtitle: Text(_hasData[0] ? 'セーブデータあり' : 'セーブデータなし'),
                    trailing: ElevatedButton(
                      onPressed: _hasData[0]
                          ? () async {
                              final loaded = await gameManager.loadGame(dataService);
                              if (loaded) {
                                Navigator.pushReplacementNamed(context, '/game');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ロードに失敗しました')),
                                );
                              }
                            }
                          : null,
                      child: const Text('ロード'),
                    ),
                  ),
                );
              },
            ),
    );
  }
} 