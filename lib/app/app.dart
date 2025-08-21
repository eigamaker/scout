import 'package:flutter/material.dart';
import '../screens/main_menu_screen.dart';
import '../screens/game_screen.dart';
import '../screens/player_list_screen.dart';
import '../screens/player_detail_screen.dart';
import '../screens/news_screen.dart';
import '../screens/news_detail_screen.dart';
import '../screens/load_game_screen.dart';
import '../screens/school_list_screen.dart';
import '../screens/scout_skill_screen.dart';
import '../screens/team_requests_screen.dart';
import '../screens/professional_teams_screen.dart';
import '../screens/team_detail_screen.dart';
import '../screens/pennant_race_screen.dart';
import '../widgets/tournament_list_widget.dart';

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
        '/load': (context) => const LoadGameScreen(),
        '/schools': (context) => const SchoolListScreen(),
        '/scoutSkill': (context) => const ScoutSkillScreen(),
        '/teamRequests': (context) => const TeamRequestsScreen(),
        '/professionalTeams': (context) => const ProfessionalTeamsScreen(),
        '/pennantRace': (context) => const PennantRaceScreen(),

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
        if (settings.name == '/tournaments') {
          return MaterialPageRoute(
            builder: (context) => const TournamentListWidget(),
          );
        }
        return null;
      },
    );
  }
} 