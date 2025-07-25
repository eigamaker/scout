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
  final List<bool> _hasData = [false, false, false, false];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkSlots();
  }

  Future<void> _checkSlots() async {
    final dataService = Provider.of<DataService>(context, listen: false);
    for (int i = 0; i < 3; i++) {
      _hasData[i] = await dataService.hasGameDataInSlot(i + 1);
    }
    _hasData[3] = await dataService.hasGameDataInSlot('autosave');
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
              itemCount: 4, // 3スロット＋オートセーブ
              itemBuilder: (context, index) {
                final isAuto = index == 3;
                final slotName = isAuto ? 'オートセーブ' : 'セーブスロット${index + 1}';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: ListTile(
                    leading: Icon(isAuto ? Icons.autorenew : Icons.save),
                    title: Text(slotName),
                    subtitle: Text(_hasData[index] ? 'セーブデータあり' : 'セーブデータなし'),
                    trailing: ElevatedButton(
                      onPressed: _hasData[index]
                          ? () async {
                              final slot = isAuto ? 'autosave' : (index + 1);
                              final dataService = Provider.of<DataService>(context, listen: false);
                              final gameManager = Provider.of<GameManager>(context, listen: false);
                              final json = await dataService.loadGameDataFromSlot(slot);
                              if (json == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('セーブデータがありません')),
                                );
                                return;
                              }
                              gameManager.loadGameFromJson(json);
                              if (gameManager.currentGame != null) {
                                Navigator.pushReplacementNamed(context, '/game');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('ロードに失敗しました')),
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