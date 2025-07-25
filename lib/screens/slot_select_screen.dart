import 'package:flutter/material.dart';

class SlotSelectScreen extends StatelessWidget {
  final List<String> slots = const [
    'セーブ1',
    'セーブ2',
    'セーブ3',
    'オートセーブ',
  ];

  const SlotSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('セーブスロット選択'),
      ),
      body: ListView.builder(
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                Navigator.pop(context, slot);
              },
              child: Text(slot, style: const TextStyle(fontSize: 18)),
            ),
          );
        },
      ),
    );
  }
} 