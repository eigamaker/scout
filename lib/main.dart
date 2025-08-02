import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'services/game_manager.dart';
import 'services/data_service.dart';
import 'services/news_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<DataService>(create: (_) => DataService()),
        Provider<NewsService>(create: (_) => NewsService()),
        Provider<GameManager>(create: (context) => GameManager(context.read<DataService>())),
      ],
      child: const ScoutGameApp(),
    ),
  );
}
