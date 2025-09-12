import '../models/news/news_item.dart';
import '../models/player/player.dart';
import '../models/player/player_abilities.dart';
import '../models/school/school.dart';
import '../models/game/high_school_tournament.dart';
import 'dart:math';

class NewsService {
  final List<NewsItem> _newsList = [];
  final Random _random = Random();

  List<NewsItem> get newsList => List.unmodifiable(_newsList);

  /// 最新順にソートされたニュースリストを取得
  List<NewsItem> getSortedNewsList() {
    final sortedList = List<NewsItem>.from(_newsList);
    sortedList.sort((a, b) => b.date.compareTo(a.date));
    return sortedList;
  }

  /// 1か月経過したニュースを削除
  void removeOldNews() {
    final oneMonthAgo = DateTime.now().subtract(Duration(days: 30));
    _newsList.removeWhere((news) => news.date.isBefore(oneMonthAgo));
  }

  /// 全てのニュースを削除
  void clearAllNews() {
    _newsList.clear();
  }

  NewsService() {
    _initializeDummyNews();
  }

  /// ゲーム内日付からDateTimeを生成するヘルパーメソッド
  DateTime _getNewsDate(int year, int month, int weekOfMonth, {int daysOffset = 0}) {
    // 4月1週を基準として計算
    int totalDays = 0;
    
    // 4月から指定月までの日数を計算
    for (int m = 4; m < month; m++) {
      totalDays += _getDaysInMonth(m);
    }
    
    // 指定月の週数から日数を計算（1週=7日）
    totalDays += (weekOfMonth - 1) * 7;
    
    // オフセットを追加
    totalDays += daysOffset;
    
    // 基準日（4月1日）から計算
    final baseDate = DateTime(year, 4, 1);
    return baseDate.add(Duration(days: totalDays));
  }

  /// 月の日数を取得
  int _getDaysInMonth(int month) {
    switch (month) {
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      case 2:
        return 28; // 簡略化
      default:
        return 31;
    }
  }

  void _initializeDummyNews() {
    _newsList.addAll([
      NewsItem(
        title: 'ドラフト会議の日程が決定',
        content: '今年のドラフト会議は10月25日に開催されることが決定した。各球団のスカウト陣が注目選手の調査を強化している。',
        date: DateTime(2024, 10, 20), // 固定日付に変更
        importance: NewsImportance.medium,
        category: NewsCategory.draft,
      ),
      NewsItem(
        title: '新設校が初勝利',
        content: '新設の希望高校が創部初勝利を挙げた。野球部創設からわずか1年での快挙に、地域の野球ファンからも注目が集まっている。',
        date: DateTime(2024, 4, 15), // 固定日付に変更
        importance: NewsImportance.low,
        category: NewsCategory.school,
      ),
    ]);
  }

  void addNews(NewsItem news) {
    _newsList.add(news);
  }

  /// 大会関連のニュースを生成
  void generateTournamentNews(List<HighSchoolTournament> tournaments, int year, int month, int week) {
    for (final tournament in tournaments) {
      if (!tournament.isCompleted && tournament.isInProgress) {
        // 大会開始のニュース
        if (tournament.games.any((game) => game.isCompleted) && 
            !_newsList.any((news) => news.title.contains(tournament.type.name))) {
          _addTournamentStartNews(tournament, year, month, week);
        }
        
        // 決勝戦のニュース
        final championshipGames = tournament.games.where((game) => 
          game.round == GameRound.championship && game.isCompleted
        ).toList();
        
        if (championshipGames.isNotEmpty && 
            !_newsList.any((news) => news.title.contains('決勝') && news.title.contains(tournament.type.name))) {
          _addChampionshipNews(tournament, championshipGames.first, year, month, week);
        }
      }
      
      // 大会終了のニュース
      if (tournament.isCompleted && 
          !_newsList.any((news) => news.title.contains('終了') && news.title.contains(tournament.type.name))) {
        _addTournamentEndNews(tournament, year, month, week);
      }
    }
  }

  /// 大会開始のニュースを追加
  void _addTournamentStartNews(HighSchoolTournament tournament, int year, int month, int week) {
    final tournamentName = _getTournamentName(tournament.type);
    final news = NewsItem(
      title: '$tournamentName開始',
      content: '$tournamentNameが開始されました。${tournament.participatingSchools.length}校が参加し、熱戦が繰り広げられます。',
      date: _getNewsDate(year, month, week),
      importance: NewsImportance.high,
      category: NewsCategory.tournament,
    );
    addNews(news);
  }

  /// 決勝戦のニュースを追加
  void _addChampionshipNews(HighSchoolTournament tournament, TournamentGame game, int year, int month, int week) {
    final tournamentName = _getTournamentName(tournament.type);
    final homeSchool = tournament.standings[game.homeSchoolId]?.schoolName ?? '不明';
    final awaySchool = tournament.standings[game.awaySchoolId]?.schoolName ?? '不明';
    
    final news = NewsItem(
      title: '$tournamentName決勝戦',
      content: '$tournamentNameの決勝戦が行われました。$homeSchool vs $awaySchoolの対戦で、${game.result?.isHomeWin == true ? homeSchool : awaySchool}が優勝しました。',
      date: _getNewsDate(year, month, week),
      importance: NewsImportance.critical,
      category: NewsCategory.tournament,
    );
    addNews(news);
  }

  /// 大会終了のニュースを追加
  void _addTournamentEndNews(HighSchoolTournament tournament, int year, int month, int week) {
    final tournamentName = _getTournamentName(tournament.type);
    final champion = tournament.championSchoolName ?? '不明';
    
    final news = NewsItem(
      title: '$tournamentName終了',
      content: '$tournamentNameが終了しました。優勝は$championです。',
      date: _getNewsDate(year, month, week),
      importance: NewsImportance.high,
      category: NewsCategory.tournament,
    );
    addNews(news);
  }

  /// 大会名を取得
  String _getTournamentName(TournamentType type) {
    switch (type) {
      case TournamentType.spring:
        return '春の大会';
      case TournamentType.summer:
        return '夏の大会';
      case TournamentType.autumn:
        return '秋の大会';
      case TournamentType.springNational:
        return '春の全国大会';
    }
  }

  void markAsRead(NewsItem news) {
    final index = _newsList.indexOf(news);
    if (index != -1) {
      _newsList[index] = NewsItem(
        title: news.title,
        content: news.content,
        date: news.date,
        importance: news.importance,
        category: news.category,
        relatedPlayerId: news.relatedPlayerId,
        relatedSchoolId: news.relatedSchoolId,
        isRead: true,
      );
    }
  }

  /// 選手に基づくニュース生成
  void generatePlayerNews(Player player, School school, {int? year, int? month, int? weekOfMonth}) {
    final totalAbility = player.trueTotalAbility;
    final fame = player.fame;
    final position = player.position;
    
    // 高能力選手（70以上）のニュース生成
    if (totalAbility >= 70) {
      _generateHighAbilityPlayerNews(player, school, totalAbility, year: year, month: month, weekOfMonth: weekOfMonth);
    }
    
    // 知名度の高い選手（fame >= 60）のニュース生成
    if (fame >= 60) {
      _generateFamousPlayerNews(player, school, fame, year: year, month: month, weekOfMonth: weekOfMonth);
    }
    
    // 特別な実績を持つ選手のニュース生成
    if (player.achievements.isNotEmpty) {
      _generateAchievementNews(player, school, year: year, month: month, weekOfMonth: weekOfMonth);
    }
    
    // 投手の特別なニュース生成
    if (position == '投手') {
      _generatePitcherNews(player, school, totalAbility, year: year, month: month, weekOfMonth: weekOfMonth);
    }
    
    // 野手の特別なニュース生成
    if (position != '投手') {
      _generateBatterNews(player, school, totalAbility, year: year, month: month, weekOfMonth: weekOfMonth);
    }
  }

  /// 高能力選手のニュース生成
  void _generateHighAbilityPlayerNews(Player player, School school, int totalAbility, {int? year, int? month, int? weekOfMonth}) {
    final newsTemplates = [
      {
        'title': '${player.name}選手が注目を集める',
        'content': '${school.name}の${player.position}、${player.name}選手（${player.grade}年）が高い能力で注目を集めている。スカウト陣からも高い評価を受けている。',
        'importance': NewsImportance.high,
      },
      {
        'title': '${player.name}選手、ドラフト候補に浮上',
        'content': '${school.name}の${player.name}選手がプロ野球ドラフト候補として注目されている。${player.position}としての高い技術力が評価されている。',
        'importance': NewsImportance.high,
      },
    ];

    if (totalAbility >= 80) {
      newsTemplates.add({
        'title': '${player.name}選手、超高校級の実力',
        'content': '${school.name}の${player.name}選手が超高校級の実力を発揮している。プロ野球界からも注目を集める逸材として期待されている。',
        'importance': NewsImportance.critical,
      });
    }

    final template = newsTemplates[_random.nextInt(newsTemplates.length)];
    
    // ゲーム内日付を使用
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(7))
        : DateTime.now().subtract(Duration(days: _random.nextInt(7)));
    
    addNews(NewsItem(
      title: template['title'] as String,
      content: template['content'] as String,
      date: newsDate,
      importance: template['importance'] as NewsImportance,
      category: NewsCategory.player,
      relatedPlayerId: player.name,
      relatedSchoolId: school.name,
    ));
  }

  /// 有名選手のニュース生成
  void _generateFamousPlayerNews(Player player, School school, int fame, {int? year, int? month, int? weekOfMonth}) {
    final newsTemplates = [
      {
        'title': '${player.name}選手、メディアに登場',
        'content': '${school.name}の${player.name}選手が地元メディアに取り上げられた。${player.position}としての活躍が地域の話題となっている。',
        'importance': NewsImportance.medium,
      },
      {
        'title': '${player.name}選手、ファン感謝デーでサイン会',
        'content': '${school.name}の${player.name}選手がファン感謝デーでサイン会を開催。多くのファンが集まり、人気の高さを実感した。',
        'importance': NewsImportance.medium,
      },
    ];

    if (fame >= 80) {
      newsTemplates.add({
        'title': '${player.name}選手、全国区の注目選手に',
        'content': '${school.name}の${player.name}選手が全国区の注目選手として認知されている。野球専門誌でも特集が組まれるなど、その人気は全国に広がっている。',
        'importance': NewsImportance.high,
      });
    }

    final template = newsTemplates[_random.nextInt(newsTemplates.length)];
    
    // ゲーム内日付を使用
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(14))
        : DateTime.now().subtract(Duration(days: _random.nextInt(14)));
    
    addNews(NewsItem(
      title: template['title'] as String,
      content: template['content'] as String,
      date: newsDate,
      importance: template['importance'] as NewsImportance,
      category: NewsCategory.player,
      relatedPlayerId: player.name,
      relatedSchoolId: school.name,
    ));
  }

  /// 実績に基づくニュース生成
  void _generateAchievementNews(Player player, School school, {int? year, int? month, int? weekOfMonth}) {
    for (final achievement in player.achievements) {
      final newsTemplates = {
        'U-18日本代表': {
          'title': '${player.name}選手、U-18日本代表に選出',
          'content': '${school.name}の${player.name}選手がU-18日本代表に選出された。国際大会での活躍が期待されている。',
          'importance': NewsImportance.critical,
        },
        '全国大会優勝': {
          'title': '${player.name}選手、全国大会で優勝',
          'content': '${school.name}の${player.name}選手が全国大会で優勝を果たした。${player.position}としての実力を証明した。',
          'importance': NewsImportance.high,
        },
        '地方大会優勝': {
          'title': '${player.name}選手、地方大会で優勝',
          'content': '${school.name}の${player.name}選手が地方大会で優勝を果たした。地域の期待を背負っての活躍となった。',
          'importance': NewsImportance.medium,
        },
        '最優秀投手': {
          'title': '${player.name}選手、最優秀投手賞を受賞',
          'content': '${school.name}の${player.name}選手が最優秀投手賞を受賞した。投手としての高い技術力が評価された。',
          'importance': NewsImportance.high,
        },
        'オールスター選出': {
          'title': '${player.name}選手、オールスターに選出',
          'content': '${school.name}の${player.name}選手がオールスターに選出された。ファン投票でも高い支持を得ている。',
          'importance': NewsImportance.medium,
        },
        'リーグ優勝': {
          'title': '${player.name}選手、リーグ戦で優勝',
          'content': '${school.name}の${player.name}選手がリーグ戦で優勝を果たした。チームの中心として活躍した。',
          'importance': NewsImportance.medium,
        },
      };

      final template = newsTemplates[achievement.name];
      if (template != null) {
        // ゲーム内日付を使用
        final newsDate = year != null && month != null && weekOfMonth != null
            ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(30))
            : DateTime.now().subtract(Duration(days: _random.nextInt(30)));
        
        addNews(NewsItem(
          title: template['title'] as String,
          content: template['content'] as String,
          date: newsDate,
          importance: template['importance'] as NewsImportance,
          category: NewsCategory.player,
          relatedPlayerId: player.name,
          relatedSchoolId: school.name,
        ));
      }
    }
  }

  /// 投手の特別ニュース生成
  void _generatePitcherNews(Player player, School school, int totalAbility, {int? year, int? month, int? weekOfMonth}) {
    final fastball = player.technicalAbilities[TechnicalAbility.fastball] ?? 0;
    final control = player.technicalAbilities[TechnicalAbility.control] ?? 0;
    
    // 150km/h投球のニュース
    if (fastball >= 80 && _random.nextDouble() < 0.3) {
      final newsDate = year != null && month != null && weekOfMonth != null
          ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(7))
          : DateTime.now().subtract(Duration(days: _random.nextInt(7)));
      
      addNews(NewsItem(
        title: '${player.name}投手、150km/hを記録',
        content: '${school.name}の${player.name}投手が練習試合で150km/hの速球を記録した。プロ野球界からも注目を集める逸材として期待されている。',
        date: newsDate,
        importance: NewsImportance.high,
        category: NewsCategory.player,
        relatedPlayerId: player.name,
        relatedSchoolId: school.name,
      ));
    }
    
    // 完全試合のニュース
    if (control >= 75 && totalAbility >= 75 && _random.nextDouble() < 0.2) {
      final newsDate = year != null && month != null && weekOfMonth != null
          ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(14))
          : DateTime.now().subtract(Duration(days: _random.nextInt(14)));
      
      addNews(NewsItem(
        title: '${player.name}投手、完全試合を達成',
        content: '${school.name}の${player.name}投手が公式戦で完全試合を達成した。完璧な投球で相手打線を封じ込めた。',
        date: newsDate,
        importance: NewsImportance.critical,
        category: NewsCategory.player,
        relatedPlayerId: player.name,
        relatedSchoolId: school.name,
      ));
    }
    
    // 無失点試合のニュース
    if (control >= 70 && _random.nextDouble() < 0.4) {
      final newsDate = year != null && month != null && weekOfMonth != null
          ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(10))
          : DateTime.now().subtract(Duration(days: _random.nextInt(10)));
      
      addNews(NewsItem(
        title: '${player.name}投手、無失点で勝利',
        content: '${school.name}の${player.name}投手が無失点で勝利を収めた。安定した投球でチームの勝利に貢献した。',
        date: newsDate,
        importance: NewsImportance.medium,
        category: NewsCategory.player,
        relatedPlayerId: player.name,
        relatedSchoolId: school.name,
      ));
    }
  }

  /// 野手の特別ニュース生成
  void _generateBatterNews(Player player, School school, int totalAbility, {int? year, int? month, int? weekOfMonth}) {
    final power = player.technicalAbilities[TechnicalAbility.power] ?? 0;
    final contact = player.technicalAbilities[TechnicalAbility.contact] ?? 0;
    
    // ホームランのニュース
    if (power >= 75 && _random.nextDouble() < 0.3) {
      final newsDate = year != null && month != null && weekOfMonth != null
          ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(7))
          : DateTime.now().subtract(Duration(days: _random.nextInt(7)));
      
      addNews(NewsItem(
        title: '${player.name}選手、特大ホームラン',
        content: '${school.name}の${player.name}選手が特大ホームランを放った。打撃の才能が開花し、注目を集めている。',
        date: newsDate,
        importance: NewsImportance.medium,
        category: NewsCategory.player,
        relatedPlayerId: player.name,
        relatedSchoolId: school.name,
      ));
    }
    
    // 打率のニュース
    if (contact >= 80 && _random.nextDouble() < 0.4) {
      final newsDate = year != null && month != null && weekOfMonth != null
          ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(10))
          : DateTime.now().subtract(Duration(days: _random.nextInt(10)));
      
      addNews(NewsItem(
        title: '${player.name}選手、高打率を維持',
        content: '${school.name}の${player.name}選手が高打率を維持している。安定した打撃でチームの得点源となっている。',
        date: newsDate,
        importance: NewsImportance.medium,
        category: NewsCategory.player,
        relatedPlayerId: player.name,
        relatedSchoolId: school.name,
      ));
    }
  }

  /// ドラフト関連のニュースを生成
  void generateDraftNews({
    required int year,
    required int month,
    required int weekOfMonth,
  }) {
    final newsDate = _getNewsDate(year, month, weekOfMonth);
    
    _newsList.add(NewsItem(
      title: 'ドラフト会議の日程が決定',
      content: '今年のドラフト会議は10月25日に開催されることが決定した。各球団のスカウト陣が注目選手の調査を強化している。',
      date: newsDate,
      importance: NewsImportance.medium,
      category: NewsCategory.draft,
    ));
  }

  /// 卒業生のニュースを生成
  void generateGraduationNews({
    required int year,
    required int month,
    required int weekOfMonth,
    required int totalGraduated,
  }) {
    final newsDate = _getNewsDate(year, month, weekOfMonth);
    
    _newsList.add(NewsItem(
      title: '3年生が卒業',
      content: '今週、全高校で3年生${totalGraduated}名が卒業しました。卒業生たちは新たな道に進み、今後の活躍が期待されています。',
      date: newsDate,
      importance: NewsImportance.medium,
      category: NewsCategory.school,
    ));
  }

  /// 学校関連ニュース生成
  void generateSchoolNews(School school, {int? year, int? month, int? weekOfMonth}) {
    final schoolNewsTemplates = [
      {
        'title': '${school.name}、新入部員を募集',
        'content': '${school.name}が新入部員を募集している。野球部の強化に力を入れている。',
        'importance': NewsImportance.low,
      },
      {
        'title': '${school.name}、練習環境を整備',
        'content': '${school.name}が野球部の練習環境を整備した。選手たちの技術向上が期待されている。',
        'importance': NewsImportance.low,
      },
    ];

    final template = schoolNewsTemplates[_random.nextInt(schoolNewsTemplates.length)];
    
    // ゲーム内日付を使用
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -_random.nextInt(14))
        : DateTime.now().subtract(Duration(days: _random.nextInt(14)));
    
    addNews(NewsItem(
      title: template['title'] as String,
      content: template['content'] as String,
      date: newsDate,
      importance: template['importance'] as NewsImportance,
      category: NewsCategory.school,
      relatedSchoolId: school.name,
    ));
  }

  /// 全選手のニュース生成
  void generateAllPlayerNews(List<School> schools, {int? year, int? month, int? weekOfMonth}) {
    print('NewsService: 全選手ニュース生成開始 - 学校数: ${schools.length}');
    int totalPlayers = 0;
    int highAbilityPlayers = 0;
    int highFamePlayers = 0;
    
    // 重複を防ぐため、既に処理済みの選手IDを記録
    final processedPlayerIds = <String>{};
    
    for (final school in schools) {
      for (final player in school.players) {
        totalPlayers++;
        if (player.trueTotalAbility >= 70) highAbilityPlayers++;
        if (player.fame >= 60) highFamePlayers++;
        
        // 高能力選手（70以上）または高知名度選手（fame >= 60）のニュース生成
        if (player.trueTotalAbility >= 70 || player.fame >= 60) {
          // 重複チェック：同じ選手IDが既に処理済みの場合はスキップ
          final playerKey = '${player.id}_${player.name}_${school.id}';
          if (processedPlayerIds.contains(playerKey)) {
            print('NewsService: 重複選手をスキップ - ${player.name} (ID: ${player.id})');
            continue;
          }
          
          print('NewsService: 選手ニュース生成対象 - ${player.name} (能力: ${player.trueTotalAbility}, 知名度: ${player.fame})');
          generatePlayerNews(player, school, year: year, month: month, weekOfMonth: weekOfMonth);
          
          // 処理済みとして記録
          processedPlayerIds.add(playerKey);
        }
      }
    }
    
    print('NewsService: 全選手ニュース生成完了 - 総選手数: $totalPlayers, 高能力選手: $highAbilityPlayers, 高知名度選手: $highFamePlayers');
  }

  /// 週送り時のニュース生成
  void generateWeeklyNews(List<School> schools, {int? year, int? month, int? weekOfMonth}) {
    final random = Random();
    
    // 週送り時のニュース生成確率（デバッグ用に確率を上げる）
    final weeklyNewsChance = 0.8; // 80%の確率でニュース生成（通常は0.4）
    
    print('NewsService: 週送りニュース生成チェック - 確率: ${(weeklyNewsChance * 100).toInt()}%');
    
    if (random.nextDouble() < weeklyNewsChance) {
      print('NewsService: 週送りニュース生成開始');
      
      // ドラフト関連ニュース（30%の確率に上げる）
      if (random.nextDouble() < 0.3) {
        print('NewsService: ドラフト関連ニュース生成');
        generateDraftNews(
          year: year ?? DateTime.now().year,
          month: month ?? DateTime.now().month,
          weekOfMonth: weekOfMonth ?? 1,
        );
      }
      
      // 学校関連ニュース（50%の確率に上げる）
      if (random.nextDouble() < 0.5) {
        final randomSchool = schools[random.nextInt(schools.length)];
        print('NewsService: 学校関連ニュース生成 - ${randomSchool.name}');
        generateSchoolNews(randomSchool, year: year, month: month, weekOfMonth: weekOfMonth);
      }
      
      // 選手関連ニュース（高能力選手の新しい活躍）
      _generateWeeklyPlayerNews(schools, random, year: year, month: month, weekOfMonth: weekOfMonth);
    } else {
      print('NewsService: 週送りニュース生成スキップ');
    }
  }

  /// 週送り時の選手ニュース生成
  void _generateWeeklyPlayerNews(List<School> schools, Random random, {int? year, int? month, int? weekOfMonth}) {
    // 高能力選手（70以上）からランダムに選択してニュース生成
    final highAbilityPlayers = <Player>[];
    
    // 重複を防ぐため、既に処理済みの選手IDを記録
    final processedPlayerIds = <String>{};
    
    for (final school in schools) {
      for (final player in school.players) {
        if (player.trueTotalAbility >= 70) {
          // 重複チェック：同じ選手IDが既に処理済みの場合はスキップ
          final playerKey = '${player.id}_${player.name}_${school.id}';
          if (processedPlayerIds.contains(playerKey)) {
            continue;
          }
          
          highAbilityPlayers.add(player);
          processedPlayerIds.add(playerKey);
        }
      }
    }
    
    print('NewsService: 高能力選手数: ${highAbilityPlayers.length}');
    if (highAbilityPlayers.isNotEmpty) {
      print('NewsService: 高能力選手リスト: ${highAbilityPlayers.map((p) => '${p.name}(${p.trueTotalAbility})').join(', ')}');
    }
    
    // 高能力選手がいる場合、ランダムに1人選んでニュース生成
    if (highAbilityPlayers.isNotEmpty && random.nextDouble() < 0.5) {
      final selectedPlayer = highAbilityPlayers[random.nextInt(highAbilityPlayers.length)];
      final playerSchool = schools.firstWhere(
        (school) => school.players.contains(selectedPlayer),
      );
      
      print('NewsService: 選手ニュース生成 - ${selectedPlayer.name}(${selectedPlayer.trueTotalAbility}) from ${playerSchool.name}');
      _generateWeeklyPlayerSpecificNews(selectedPlayer, playerSchool, random, year: year, month: month, weekOfMonth: weekOfMonth);
    } else {
      print('NewsService: 選手ニュース生成スキップ - 高能力選手なしまたは確率でスキップ');
    }
  }

  /// 週送り時の選手特化ニュース生成
  void _generateWeeklyPlayerSpecificNews(Player player, School school, Random random, {int? year, int? month, int? weekOfMonth}) {
    final position = player.position;
    final totalAbility = player.trueTotalAbility;
    
    final weeklyNewsTemplates = [
      {
        'title': '${player.name}選手、練習で好調',
        'content': '${school.name}の${player.name}選手が練習で好調を維持している。${position}としての技術向上が期待されている。',
        'importance': NewsImportance.medium,
      },
      {
        'title': '${player.name}選手、スカウト陣の注目を集める',
        'content': '${school.name}の${player.name}選手がスカウト陣の注目を集めている。${position}としての高い技術力が評価されている。',
        'importance': NewsImportance.high,
      },
      {
        'title': '${player.name}選手、チームの中心として活躍',
        'content': '${school.name}の${player.name}選手がチームの中心として活躍している。${position}としての安定したプレーがチームの勝利に貢献している。',
        'importance': NewsImportance.medium,
      },
    ];

    // 投手の特別ニュース
    if (position == '投手') {
      final fastball = player.technicalAbilities[TechnicalAbility.fastball] ?? 0;
      final control = player.technicalAbilities[TechnicalAbility.control] ?? 0;
      
      if (fastball >= 75 && random.nextDouble() < 0.3) {
        weeklyNewsTemplates.add({
          'title': '${player.name}投手、速球で好投',
          'content': '${school.name}の${player.name}投手が速球で好投している。プロ野球界からも注目を集める逸材として期待されている。',
          'importance': NewsImportance.high,
        });
      }
      
      if (control >= 70 && random.nextDouble() < 0.4) {
        weeklyNewsTemplates.add({
          'title': '${player.name}投手、制球力で安定投球',
          'content': '${school.name}の${player.name}投手が制球力で安定した投球を見せている。投手としての高い技術力が評価されている。',
          'importance': NewsImportance.medium,
        });
      }
    }
    
    // 野手の特別ニュース
    if (position != '投手') {
      final power = player.technicalAbilities[TechnicalAbility.power] ?? 0;
      final contact = player.technicalAbilities[TechnicalAbility.contact] ?? 0;
      
      if (power >= 70 && random.nextDouble() < 0.3) {
        weeklyNewsTemplates.add({
          'title': '${player.name}選手、打撃で好調',
          'content': '${school.name}の${player.name}選手が打撃で好調を維持している。長打力でチームの得点源となっている。',
          'importance': NewsImportance.medium,
        });
      }
      
      if (contact >= 75 && random.nextDouble() < 0.4) {
        weeklyNewsTemplates.add({
          'title': '${player.name}選手、安定した打撃',
          'content': '${school.name}の${player.name}選手が安定した打撃を見せている。ミート力でチームの勝利に貢献している。',
          'importance': NewsImportance.medium,
        });
      }
    }

    final template = weeklyNewsTemplates[random.nextInt(weeklyNewsTemplates.length)];
    
    // ゲーム内日付を使用
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -random.nextInt(3))
        : DateTime.now().subtract(Duration(days: random.nextInt(3)));
    
    addNews(NewsItem(
      title: template['title'] as String,
      content: template['content'] as String,
      date: newsDate,
      importance: template['importance'] as NewsImportance,
      category: NewsCategory.player,
      relatedPlayerId: player.name,
      relatedSchoolId: school.name,
    ));
  }

  /// 月別ニュース生成
  void generateMonthlyNews(List<School> schools, int currentMonth, {int? year, int? month, int? weekOfMonth}) {
    final random = Random();
    
    // 月別の特別ニュース
    switch (currentMonth) {
      case 4: // 4月：新年度開始
        _generateAprilNews(schools, random, year: year, month: month, weekOfMonth: weekOfMonth);
        break;
      case 6: // 6月：夏の大会前
        _generateJuneNews(schools, random, year: year, month: month, weekOfMonth: weekOfMonth);
        break;
      case 8: // 8月：夏の大会
        _generateAugustNews(schools, random, year: year, month: month, weekOfMonth: weekOfMonth);
        break;
      case 10: // 10月：ドラフト前
        _generateOctoberNews(schools, random, year: year, month: month, weekOfMonth: weekOfMonth);
        break;
      case 12: // 12月：年末
        _generateDecemberNews(schools, random, year: year, month: month, weekOfMonth: weekOfMonth);
        break;
    }
  }

  /// 4月のニュース生成
  void _generateAprilNews(List<School> schools, Random random, {int? year, int? month, int? weekOfMonth}) {
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -random.nextInt(7))
        : DateTime.now().subtract(Duration(days: random.nextInt(7)));
    
    addNews(NewsItem(
      title: '新年度開始、各校で新入生が活躍',
      content: '新年度が始まり、各学校で新入生が活躍している。野球部の新体制が注目されている。',
      date: newsDate,
      importance: NewsImportance.medium,
      category: NewsCategory.school,
    ));
  }

  /// 6月のニュース生成
  void _generateJuneNews(List<School> schools, Random random, {int? year, int? month, int? weekOfMonth}) {
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -random.nextInt(7))
        : DateTime.now().subtract(Duration(days: random.nextInt(7)));
    
    addNews(NewsItem(
      title: '夏の大会に向けて各校が強化',
      content: '夏の大会に向けて各学校が強化を図っている。選手たちの技術向上が期待されている。',
      date: newsDate,
      importance: NewsImportance.medium,
      category: NewsCategory.general,
    ));
  }

  /// 8月のニュース生成
  void _generateAugustNews(List<School> schools, Random random, {int? year, int? month, int? weekOfMonth}) {
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -random.nextInt(7))
        : DateTime.now().subtract(Duration(days: random.nextInt(7)));
    
    addNews(NewsItem(
      title: '夏の大会が開催中',
      content: '夏の大会が各地で開催されている。選手たちの熱戦が続いている。',
      date: newsDate,
      importance: NewsImportance.high,
      category: NewsCategory.game,
    ));
  }

  /// 10月のニュース生成
  void _generateOctoberNews(List<School> schools, Random random, {int? year, int? month, int? weekOfMonth}) {
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -random.nextInt(7))
        : DateTime.now().subtract(Duration(days: random.nextInt(7)));
    
    addNews(NewsItem(
      title: 'ドラフト会議が近づく',
      content: 'プロ野球ドラフト会議が近づいている。各球団のスカウト陣が最終調査を強化している。',
      date: newsDate,
      importance: NewsImportance.high,
      category: NewsCategory.draft,
    ));
  }

  /// 12月のニュース生成
  void _generateDecemberNews(List<School> schools, Random random, {int? year, int? month, int? weekOfMonth}) {
    final newsDate = year != null && month != null && weekOfMonth != null
        ? _getNewsDate(year, month, weekOfMonth, daysOffset: -random.nextInt(7))
        : DateTime.now().subtract(Duration(days: random.nextInt(7)));
    
    addNews(NewsItem(
      title: '年末の練習試合が各地で開催',
      content: '年末の練習試合が各地で開催されている。選手たちの技術向上が期待されている。',
      date: newsDate,
      importance: NewsImportance.medium,
      category: NewsCategory.game,
    ));
  }

  /// ニュースの古いものを削除（最新100件まで保持）
  void cleanupOldNews() {
    if (_newsList.length > 100) {
      _newsList.sort((a, b) => b.date.compareTo(a.date));
      _newsList.removeRange(100, _newsList.length);
    }
  }
} 