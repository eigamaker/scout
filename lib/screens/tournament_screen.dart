import 'package:flutter/material.dart';
import '../models/game/high_school_tournament.dart';
import '../models/school/school.dart';
import '../widgets/tournament_list_widget.dart';

class TournamentScreen extends StatelessWidget {
  final List<HighSchoolTournament> tournaments;
  final List<School> schools;

  const TournamentScreen({
    Key? key,
    required this.tournaments,
    required this.schools,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高校野球大会'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: TournamentListWidget(
        tournaments: tournaments,
        schools: schools,
      ),
    );
  }
}
