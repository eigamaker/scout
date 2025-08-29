import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_manager.dart';
import '../services/data_service.dart';
import '../services/default_school_data.dart';
import 'game_screen.dart';

class ScoutProfileScreen extends StatefulWidget {
  const ScoutProfileScreen({super.key});

  @override
  State<ScoutProfileScreen> createState() => _ScoutProfileScreenState();
}

class _ScoutProfileScreenState extends State<ScoutProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController =
      TextEditingController(text: 'あなた');
  String _selectedPrefecture = DefaultSchoolData.prefectures.first;

  Future<void> _startGame(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final gameManager = Provider.of<GameManager>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);

    await dataService.deleteDatabase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ゲームを準備しています...'),
            SizedBox(height: 24),
            LinearProgressIndicator(),
          ],
        ),
      ),
    );

    try {
      await gameManager.startNewGameWithDb(
        _nameController.text,
        _selectedPrefecture,
        dataService,
      );
    } finally {
      if (mounted) Navigator.pop(context);
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('スカウトプロフィール設定')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'スカウト名'),
                validator: (value) =>
                    value == null || value.isEmpty ? '名前を入力してください' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPrefecture,
                decoration: const InputDecoration(labelText: '所在地'),
                items: DefaultSchoolData.prefectures
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPrefecture = value;
                    });
                  }
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startGame(context),
                  child: const Text('ゲーム開始'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

