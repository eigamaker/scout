import 'package:flutter/material.dart';

class SlotCopyScreen extends StatefulWidget {
  const SlotCopyScreen({super.key});

  @override
  State<SlotCopyScreen> createState() => _SlotCopyScreenState();
}

class _SlotCopyScreenState extends State<SlotCopyScreen> {
  final List<String> slots = const [
    'セーブ1',
    'セーブ2',
    'セーブ3',
    'オートセーブ',
  ];
  String? fromSlot;
  String? toSlot;
  String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('セーブデータコピー')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('コピー元スロット'),
            DropdownButton<String>(
              value: fromSlot,
              hint: const Text('選択してください'),
              items: slots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => fromSlot = v),
            ),
            const SizedBox(height: 24),
            const Text('コピー先スロット'),
            DropdownButton<String>(
              value: toSlot,
              hint: const Text('選択してください'),
              items: slots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => toSlot = v),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: (fromSlot != null && toSlot != null && fromSlot != toSlot)
                  ? () async {
                      Navigator.pop(context, {'from': fromSlot, 'to': toSlot});
                    }
                  : null,
              child: const Text('コピー実行'),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
} 