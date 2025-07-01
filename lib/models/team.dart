// プロ野球球団クラス
class Team {
  final String name;
  final String region;
  final int budget;
  final List<String> needs;

  Team({
    required this.name,
    required this.region,
    this.budget = 50000000,
    this.needs = const [],
  });
}

// 日本のプロ野球12球団＋地域
final List<Team> proTeams = [
  Team(name: '読売ジャイアンツ', region: '関東'),
  Team(name: '阪神タイガース', region: '関西'),
  Team(name: '中日ドラゴンズ', region: '中部'),
  Team(name: '広島東洋カープ', region: '中国'),
  Team(name: '横浜DeNAベイスターズ', region: '関東'),
  Team(name: '東京ヤクルトスワローズ', region: '関東'),
  Team(name: '福岡ソフトバンクホークス', region: '九州'),
  Team(name: '北海道日本ハムファイターズ', region: '北海道'),
  Team(name: '埼玉西武ライオンズ', region: '関東'),
  Team(name: '千葉ロッテマリーンズ', region: '関東'),
  Team(name: 'オリックス・バファローズ', region: '関西'),
  Team(name: '東北楽天ゴールデンイーグルス', region: '東北'),
]; 