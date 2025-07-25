import 'package:flutter/material.dart';
import '../screens/main_menu_screen.dart';
import '../screens/game_screen.dart';
import '../screens/player_list_screen.dart';
import '../screens/player_detail_screen.dart';
import '../screens/news_screen.dart';
import '../screens/news_detail_screen.dart';
import 'theme.dart';
import '../models/player/player.dart';
import '../models/news/news_item.dart';

class ScoutGameApp extends StatelessWidget {
  const ScoutGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scout Game',
      theme: AppTheme.lightTheme,
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/mainMenu': (context) => const MainMenuScreen(),
        '/game': (context) => const GameScreen(),
        '/players': (context) => const PlayerListScreen(),
        '/news': (context) => const NewsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/playerDetail') {
          final player = settings.arguments as Player;
          return MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(player: player),
          );
        }
        if (settings.name == '/newsDetail') {
          final news = settings.arguments as NewsItem;
          return MaterialPageRoute(
            builder: (context) => NewsDetailScreen(news: news),
          );
        }
        return null;
      },
    );
  }
} 