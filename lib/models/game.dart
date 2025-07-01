// 試合クラス
enum GameType { practice, official }

class Game {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final DateTime gameDate;
  final GameType type;

  Game({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.gameDate,
    required this.type,
  });
} 