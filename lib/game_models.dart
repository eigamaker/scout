// ゲームのデータモデル
import 'dart:math';
import 'package:flutter/material.dart';
import 'game_system.dart';
import 'models/scouting_action.dart';
import 'models/scout_skills.dart';
import 'models/player.dart';
import 'models/pitch.dart';
import 'models/scout_report.dart';

// 高校クラス
class School {
  final String name;
  final String location;
  final List<Player> players;
  final int coachTrust; // 監督の信頼度 0-100
  final String coachName;
  
  School({
    required this.name,
    required this.location,
    required this.players,
    required this.coachTrust,
    required this.coachName,
  });
  
  Player _generateNewPlayer(int grade) {
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final personalities = ['真面目', '明るい', 'クール', 'リーダー', '努力家'];
    
    final position = positions[Random().nextInt(positions.length)];
    final isPitcher = position == '投手';
    
    // 隠し能力値を生成
    final mentalGrit = (Random().nextDouble() - 0.5) * 0.3; // -0.15〜+0.15
    final growthRate = 0.85 + Random().nextDouble() * 0.3; // 0.85-1.15
    final peakAbility = 80 + Random().nextInt(71); // 80-150
    
    // ポジション適性を生成
    final positionFit = <String, int>{};
    for (final pos in positions) {
      if (pos == position) {
        positionFit[pos] = 70 + Random().nextInt(21); // メインポジション 70-90
      } else {
        positionFit[pos] = 40 + Random().nextInt(31); // サブポジション 40-70
      }
    }
    
    Player player;
    
    if (isPitcher) {
      // 投手の能力値を生成
      final fastballVelo = 130 + Random().nextInt(26); // 130-155 km/h
      final control = 30 + Random().nextInt(41); // 30-70
      final stamina = 40 + Random().nextInt(41); // 40-80
      final breakAvg = 35 + Random().nextInt(41); // 35-75
      
      // 球種を生成
      final pitchTypes = ['直球', 'カーブ', 'スライダー', 'フォーク', 'チェンジアップ'];
      final pitches = <Pitch>[];
      
      // 直球は必ず習得
      pitches.add(Pitch(
        type: '直球',
        breakAmount: 10 + Random().nextInt(21), // 10-30
        breakPot: 15 + Random().nextInt(26), // 15-40
        unlocked: true,
      ));
      
      // 他の球種はランダムに習得
      for (final type in pitchTypes.skip(1)) {
        if (Random().nextBool()) {
          pitches.add(Pitch(
            type: type,
            breakAmount: 20 + Random().nextInt(41), // 20-60
            breakPot: 25 + Random().nextInt(51), // 25-75
            unlocked: true,
          ));
        }
      }
      
      player = Player(
        name: names[Random().nextInt(names.length)] + 
              (Random().nextInt(999) + 1).toString().padLeft(3, '0'),
        school: name,
        grade: grade,
        position: position,
        personality: personalities[Random().nextInt(personalities.length)],
        fastballVelo: fastballVelo,
        control: control,
        stamina: stamina,
        breakAvg: breakAvg,
        pitches: pitches.isEmpty ? null : pitches,
        mentalGrit: mentalGrit,
        growthRate: growthRate,
        peakAbility: peakAbility,
        positionFit: positionFit,
      );
    } else {
      // 野手の能力値を生成
      final batPower = 35 + Random().nextInt(41); // 35-75
      final batControl = 40 + Random().nextInt(41); // 40-80
      final run = 45 + Random().nextInt(41); // 45-85
      final field = 40 + Random().nextInt(41); // 40-80
      final arm = 35 + Random().nextInt(41); // 35-75
      
      player = Player(
        name: names[Random().nextInt(names.length)] + 
              (Random().nextInt(999) + 1).toString().padLeft(3, '0'),
        school: name,
        grade: grade,
        position: position,
        personality: personalities[Random().nextInt(personalities.length)],
        batPower: batPower,
        batControl: batControl,
        run: run,
        field: field,
        arm: arm,
        mentalGrit: mentalGrit,
        growthRate: growthRate,
        peakAbility: peakAbility,
        positionFit: positionFit,
      );
    }
    
    // 知名度を計算
    player.calculateInitialFame();
    
    return player;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'players': players.map((p) => p.toJson()).toList(),
    'coachTrust': coachTrust,
    'coachName': coachName,
  };

  factory School.fromJson(Map<String, dynamic> json) => School(
    name: json['name'],
    location: json['location'],
    players: (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
    coachTrust: json['coachTrust'],
    coachName: json['coachName'],
  );
}

// ニュースアイテムクラス
class NewsItem {
  final String headline; // 見出し
  final String content; // 本文
  final String category; // カテゴリ
  final int importance; // 重要度 1-5
  final String icon; // アイコン
  final DateTime timestamp; // タイムスタンプ
  final String? school; // 関連学校
  final String? player; // 関連選手
  
  NewsItem({
    required this.headline,
    required this.content,
    required this.category,
    required this.importance,
    required this.icon,
    required this.timestamp,
    this.school,
    this.player,
  });
  
  // 重要度に応じた色を取得
  Color getImportanceColor() {
    switch (importance) {
      case 5: return Colors.red;
      case 4: return Colors.orange;
      case 3: return Colors.yellow;
      case 2: return Colors.blue;
      case 1: return Colors.grey;
      default: return Colors.grey;
    }
  }
  
  // カテゴリに応じた色を取得
  Color getCategoryColor() {
    switch (category) {
      case '試合': return Colors.red;
      case '選手': return Colors.blue;
      case '学校': return Colors.green;
      case 'スカウト': return Colors.purple;
      case '一般': return Colors.grey;
      default: return Colors.grey;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'headline': headline,
    'content': content,
    'category': category,
    'importance': importance,
    'icon': icon,
    'timestamp': timestamp.toIso8601String(),
    'school': school,
    'player': player,
  };
  
  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    headline: json['headline'],
    content: json['content'],
    category: json['category'],
    importance: json['importance'],
    icon: json['icon'],
    timestamp: DateTime.parse(json['timestamp']),
    school: json['school'],
    player: json['player'],
  );
}

// 今週の予定クラス
class ScheduleItem {
  final String title;
  final String description;
  final String school;
  final String type; // '試合', '練習', '大会', '視察'
  final DateTime scheduledTime;
  final int importance; // 1-5
  
  ScheduleItem({
    required this.title,
    required this.description,
    required this.school,
    required this.type,
    required this.scheduledTime,
    required this.importance,
  });
  
  Color getTypeColor() {
    switch (type) {
      case '試合': return Colors.red;
      case '練習': return Colors.blue;
      case '大会': return Colors.orange;
      case '視察': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'school': school,
    'type': type,
    'scheduledTime': scheduledTime.toIso8601String(),
    'importance': importance,
  };
  
  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
    title: json['title'],
    description: json['description'],
    school: json['school'],
    type: json['type'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    importance: json['importance'],
  );
}

// ゲーム状態クラス
class GameState {
  int currentWeek;
  int currentYear;
  int actionPoints;
  int budget;
  int reputation;
  List<School> schools;
  List<Player> discoveredPlayers;
  List<NewsItem> news;
  List<ActionResult> lastWeekActions; // 先週のアクション結果
  List<ScheduleItem> thisWeekSchedule; // 今週の予定
  List<GameResult> gameResults; // 試合結果
  ScoutSkills scoutSkills; // スカウトの能力
  SelectedActionManager selectedActionManager; // 選択されたアクション管理
  ScoutReportManager scoutReportManager; // スカウトレポート管理
  
  GameState({
    this.currentWeek = 1,
    this.currentYear = 2025,
    this.actionPoints = 6,
    this.budget = 1000000,
    this.reputation = 0,
    List<School>? schools,
    List<Player>? discoveredPlayers,
    List<NewsItem>? news,
    List<ActionResult>? lastWeekActions,
    List<ScheduleItem>? thisWeekSchedule,
    List<GameResult>? gameResults,
    ScoutSkills? scoutSkills,
    SelectedActionManager? selectedActionManager,
    ScoutReportManager? scoutReportManager,
  }) : 
    schools = schools ?? [],
    discoveredPlayers = discoveredPlayers ?? [],
    news = news ?? [],
    lastWeekActions = lastWeekActions ?? [],
    thisWeekSchedule = thisWeekSchedule ?? [],
    gameResults = gameResults ?? [],
    scoutSkills = scoutSkills ?? ScoutSkills(),
    selectedActionManager = selectedActionManager ?? SelectedActionManager(),
    scoutReportManager = scoutReportManager ?? ScoutReportManager() {
    
    // 既存選手の知名度を計算
    for (final school in this.schools) {
      for (final player in school.players) {
        player.calculateInitialFame();
      }
    }
    
    // 発見済み選手の知名度も計算
    for (final player in this.discoveredPlayers) {
      player.calculateInitialFame();
    }
  }
  
  // 週から月を計算
  String getCurrentMonth() {
    // 各月の週数（4月から3月まで）
    final weeksPerMonth = [4, 4, 5, 4, 4, 5, 5, 4, 4, 4, 4, 5]; // 4月-3月
    final monthNames = [
      '4月', '5月', '6月', '7月', '8月', '9月', 
      '10月', '11月', '12月', '1月', '2月', '3月'
    ];
    
    int weekCount = 0;
    for (int i = 0; i < weeksPerMonth.length; i++) {
      weekCount += weeksPerMonth[i];
      if (currentWeek <= weekCount) {
        return monthNames[i];
      }
    }
    return '3月'; // フォールバック
  }
  
  // 月内での週数を計算
  int getWeekInMonth() {
    // 各月の週数（4月から3月まで）
    final weeksPerMonth = [4, 4, 5, 4, 4, 5, 5, 4, 4, 4, 4, 5]; // 4月-3月
    
    int weekCount = 0;
    for (int i = 0; i < weeksPerMonth.length; i++) {
      weekCount += weeksPerMonth[i];
      if (currentWeek <= weekCount) {
        return currentWeek - (weekCount - weeksPerMonth[i]);
      }
    }
    return currentWeek; // フォールバック
  }
  
  // 週を進める
  void advanceWeek() {
    // 先週のアクション結果を保存
    _saveLastWeekActions();
    
    // 選択されたアクションをクリア
    selectedActionManager.clearAll();
    
    // 前週のアクション結果をクリア（新しい週の開始時）
    lastWeekActions.clear();
    
    // 3月1週目で卒業処理
    if (currentWeek == 49) { // 3月1週目（4+4+5+4+4+5+5+4+4+4+4+1 = 49週目）
      _processGraduation();
    }
    
    currentWeek++;
    
    // 4月1週目で入学処理
    if (currentWeek == 1) {
      _processEnrollment();
    }
    
    if (currentWeek > 52) {
      currentWeek = 1;
      currentYear++;
    }
    
    // APと予算をリセット
    actionPoints = 6;
    budget = 1000000;
    
    // 今週の予定を生成
    _generateThisWeekSchedule();
    
    // ニュースを生成
    _generateNews();
  }
  
  // 先週のアクション結果を保存
  void _saveLastWeekActions() {
    // 先週のアクション結果は保持する（クリアしない）
    // 新しい週が始まる際に、前週の結果を表示するために必要
  }
  
  // 今週の予定を生成
  void _generateThisWeekSchedule() {
    thisWeekSchedule.clear();
    final random = Random();
    
    // 練習試合の予定
    if (random.nextBool()) {
      final school1 = schools[random.nextInt(schools.length)];
      final school2 = schools[random.nextInt(schools.length)];
      if (school1 != school2) {
        thisWeekSchedule.add(ScheduleItem(
          title: '${school1.name} vs ${school2.name}',
          description: '練習試合が予定されています。選手の実力を確認するチャンスです。',
          school: '${school1.name}・${school2.name}',
          type: '試合',
          scheduledTime: DateTime.now().add(Duration(days: random.nextInt(7))),
          importance: 4,
        ));
        
        // 試合結果を自動生成
        final gameResult = GameSimulator.simulateGame(school1, school2, '練習試合');
        gameResults.add(gameResult);
      }
    }
    
    // 大会の予定（月によって）
    final currentMonth = getCurrentMonth();
    if (currentMonth == '6月' || currentMonth == '7月' || currentMonth == '8月') {
      if (random.nextBool()) {
        final school = schools[random.nextInt(schools.length)];
        final opponent = schools[random.nextInt(schools.length)];
        if (school != opponent) {
          thisWeekSchedule.add(ScheduleItem(
            title: '夏の大会',
            description: '${school.name}が夏の大会に出場します。',
            school: school.name,
            type: '大会',
            scheduledTime: DateTime.now().add(Duration(days: random.nextInt(7))),
            importance: 5,
          ));
          
          // 大会の試合結果を自動生成
          final gameResult = GameSimulator.simulateGame(school, opponent, '大会');
          gameResults.add(gameResult);
        }
      }
    }
    
    // 練習視察の予定
    if (random.nextBool()) {
      final school = schools[random.nextInt(schools.length)];
      thisWeekSchedule.add(ScheduleItem(
        title: '${school.name}練習視察',
        description: '${school.name}の練習を視察する予定です。',
        school: school.name,
        type: '視察',
        scheduledTime: DateTime.now().add(Duration(days: random.nextInt(7))),
        importance: 3,
      ));
    }
    
    // 一般練習の予定
    if (random.nextBool()) {
      final school = schools[random.nextInt(schools.length)];
      thisWeekSchedule.add(ScheduleItem(
        title: '${school.name}練習',
        description: '${school.name}の通常練習が行われます。',
        school: school.name,
        type: '練習',
        scheduledTime: DateTime.now().add(Duration(days: random.nextInt(7))),
        importance: 2,
      ));
    }
  }
  
  // アクション結果を追加
  void addActionResult(ActionResult result) {
    lastWeekActions.add(result);
    
    // スカウトレポートを生成
    _generateScoutReport(result);
  }
  
  // スカウトレポートを生成
  void _generateScoutReport(ActionResult result) {
    final random = Random();
    final reportId = 'report_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}';
    
    ReportUpdateType reportType;
    String title;
    String description;
    
    switch (result.actionName) {
      case '練習視察':
        reportType = ReportUpdateType.schoolVisited;
        title = '${result.school}練習視察レポート';
        description = result.success 
          ? '${result.school}の練習を視察し、選手の基本能力を確認しました。'
          : '${result.school}の練習視察は失敗しました。';
        break;
        
      case 'インタビュー':
        reportType = ReportUpdateType.interviewConducted;
        title = '${result.player ?? result.school}インタビューレポート';
        description = result.success 
          ? '${result.player ?? result.school}へのインタビューが成功し、選手の性格や考え方を把握しました。'
          : '${result.player ?? result.school}へのインタビューは失敗しました。';
        break;
        
      case 'ビデオ分析':
        reportType = ReportUpdateType.videoAnalyzed;
        title = '${result.player ?? result.school}ビデオ分析レポート';
        description = result.success 
          ? '${result.player ?? result.school}の動画分析が完了し、詳細な技術分析ができました。'
          : '${result.player ?? result.school}の動画分析は失敗しました。';
        break;
        
      case '球団訪問':
        reportType = ReportUpdateType.teamVisited;
        title = 'プロ野球球団訪問レポート';
        description = result.success 
          ? 'プロ野球球団への訪問が成功し、球団関係者との関係が深まりました。'
          : 'プロ野球球団への訪問は失敗しました。';
        break;
        
      case '情報交換':
        reportType = ReportUpdateType.infoExchanged;
        title = '${result.school}地域情報交換レポート';
        description = result.success 
          ? '${result.school}地域のスカウトとの情報交換が成功し、新しい情報を得ました。'
          : '${result.school}地域のスカウトとの情報交換は失敗しました。';
        break;
        
      case 'ニュース確認':
        reportType = ReportUpdateType.infoExchanged;
        title = '最新ニュース確認レポート';
        description = result.success 
          ? '最新ニュースの確認が完了し、重要な情報を得ました。'
          : '最新ニュースの確認は失敗しました。';
        break;
        
      default:
        reportType = ReportUpdateType.schoolVisited;
        title = '${result.actionName}レポート';
        description = result.result;
    }
    
    final report = ScoutReportUpdate(
      id: reportId,
      type: reportType,
      title: title,
      description: description,
      schoolName: result.school != '不明' ? result.school : null,
      playerName: result.player,
      timestamp: result.timestamp,
      additionalData: result.additionalData,
    );
    
    scoutReportManager.addReport(report);
  }
  
  // 卒業処理（3月1週目）
  void _processGraduation() {
    news.add(NewsItem(
      headline: '🎓 卒業シーズンが始まりました',
      content: '',
      category: '学校',
      importance: 5,
      icon: '🎓',
      timestamp: DateTime.now(),
    ));
    
    for (var school in schools) {
      final graduatingPlayers = school.players.where((player) => player.grade == 3).toList();
      if (graduatingPlayers.isNotEmpty) {
        final topPlayer = graduatingPlayers.reduce((a, b) => 
          (a.isPitcher ? a.getPitcherEvaluation() : a.getBatterEvaluation()).compareTo(
            b.isPitcher ? b.getPitcherEvaluation() : b.getBatterEvaluation()
          ) > 0 ? a : b);
        news.add(NewsItem(
          headline: '${school.name}の${topPlayer.name}選手が卒業します',
          content: '',
          category: '学校',
          importance: 5,
          icon: '🎓',
          timestamp: DateTime.now(),
        ));
      }
    }
  }
  
  // 入学処理（4月1週目）
  void _processEnrollment() {
    news.add(NewsItem(
      headline: '🆕 新年度が始まりました！',
      content: '',
      category: '学校',
      importance: 5,
      icon: '🆕',
      timestamp: DateTime.now(),
    ));
    
    for (var school in schools) {
      // 3年生を削除（卒業）
      school.players.removeWhere((player) => player.grade == 3);
      
      // 1年生、2年生を進級
      for (var player in school.players) {
        if (player.grade < 3) {
          player.grade++;
          // 進級時に少し成長
          player.grow();
        }
      }
      
      // 新しい1年生を追加（入学）
      final newStudentCount = Random().nextInt(4) + 4; // 4-7名の新入生
      for (int i = 0; i < newStudentCount; i++) {
        school.players.add(school._generateNewPlayer(1));
      }
      
      news.add(NewsItem(
        headline: '${school.name}に${newStudentCount}名の新入生が入学しました',
        content: '',
        category: '学校',
        importance: 5,
        icon: '🆕',
        timestamp: DateTime.now(),
      ));
    }
    
    // 古いニュースを削除（最大15件まで）
    if (news.length > 15) {
      news.removeRange(0, news.length - 15);
    }
  }
  
  void _startNewYear() {
    // このメソッドは使用しない（_processGraduationと_processEnrollmentに分離）
  }
  
  void _generateNews() {
    final random = Random();
    
    // 実際のゲーム状態に基づくニュースを優先的に生成
    final dynamicNews = _generateDynamicNews();
    if (dynamicNews != null) {
      news.add(dynamicNews);
    } else {
      // 動的ニュースがない場合は通常のテンプレートニュースを生成
      _generateTemplateNews();
    }
    
    // 古いニュースを削除（最大15件まで）
    if (news.length > 15) {
      news.removeAt(0);
    }
  }
  
  // 実際のゲーム状態に基づくニュースを生成
  NewsItem? _generateDynamicNews() {
    final random = Random();
    
    // 1. 試合結果に基づくニュース
    if (gameResults.isNotEmpty) {
      final recentGame = gameResults.last;
      final gameAge = DateTime.now().difference(recentGame.gameDate).inDays;
      
      if (gameAge <= 7) { // 1週間以内の試合
        return _generateGameResultNews(recentGame);
      }
    }
    
    // 2. 選手の成績に基づくニュース
    final topPerformers = _findTopPerformers();
    if (topPerformers.isNotEmpty && random.nextBool()) {
      return _generatePlayerPerformanceNews(topPerformers);
    }
    
    // 3. 学校の強さに基づくニュース
    final strongSchools = _findStrongSchools();
    if (strongSchools.isNotEmpty && random.nextBool()) {
      return _generateSchoolStrengthNews(strongSchools);
    }
    
    // 4. 選手の成長に基づくニュース
    final growingPlayers = _findGrowingPlayers();
    if (growingPlayers.isNotEmpty && random.nextBool()) {
      return _generatePlayerGrowthNews(growingPlayers);
    }
    
    return null;
  }
  
  // 試合結果に基づくニュースを生成
  NewsItem _generateGameResultNews(GameResult game) {
    final random = Random();
    
    if (game.homeScore > game.awayScore) {
      // ホームチーム勝利
      final winner = schools.firstWhere((s) => s.name == game.homeTeam);
      final loser = schools.firstWhere((s) => s.name == game.awayTeam);
      
      if (game.homeScore - game.awayScore >= 5) {
        return NewsItem(
          headline: '🔥 ${winner.name}が${loser.name}に大勝！',
          content: '${game.homeScore}-${game.awayScore}の圧勝。${winner.name}の打線が爆発し、投手陣も好投を見せました。',
          category: '試合',
          importance: 4,
          icon: '🔥',
          timestamp: DateTime.now(),
          school: winner.name,
        );
      } else {
        return NewsItem(
          headline: '⚾ ${winner.name}が${loser.name}を下す',
          content: '${game.homeScore}-${game.awayScore}で${winner.name}が勝利。接戦を制した${winner.name}の粘り強さが光りました。',
          category: '試合',
          importance: 3,
          icon: '⚾',
          timestamp: DateTime.now(),
          school: winner.name,
        );
      }
    } else {
      // アウェイチーム勝利
      final winner = schools.firstWhere((s) => s.name == game.awayTeam);
      final loser = schools.firstWhere((s) => s.name == game.homeTeam);
      
      return NewsItem(
        headline: '⚾ ${winner.name}が${loser.name}を破る',
        content: '${game.awayScore}-${game.homeScore}で${winner.name}が勝利。アウェイでの勝利で${winner.name}の実力が証明されました。',
        category: '試合',
        importance: 3,
        icon: '⚾',
        timestamp: DateTime.now(),
        school: winner.name,
      );
    }
  }
  
  // トップパフォーマーを探す
  List<PlayerPerformance> _findTopPerformers() {
    final allPerformances = <PlayerPerformance>[];
    
    for (final game in gameResults) {
      allPerformances.addAll(game.performances);
    }
    
    if (allPerformances.isEmpty) return [];
    
    // 投手のトップパフォーマー
    final topPitchers = allPerformances
        .where((p) => (p.inningsPitched ?? 0) > 0)
        .toList()
      ..sort((a, b) => ((b.strikeouts ?? 0) / (b.inningsPitched ?? 1)).compareTo((a.strikeouts ?? 0) / (a.inningsPitched ?? 1)));
    
    // 野手のトップパフォーマー
    final topBatters = allPerformances
        .where((p) => (p.atBats ?? 0) > 0)
        .toList()
      ..sort((a, b) => (b.battingAverage ?? 0).compareTo(a.battingAverage ?? 0));
    
    final topPerformers = <PlayerPerformance>[];
    if (topPitchers.isNotEmpty) topPerformers.add(topPitchers.first);
    if (topBatters.isNotEmpty) topPerformers.add(topBatters.first);
    
    return topPerformers;
  }
  
  // 選手の成績に基づくニュースを生成
  NewsItem _generatePlayerPerformanceNews(List<PlayerPerformance> topPerformers) {
    final performance = topPerformers.first;
    
    if ((performance.inningsPitched ?? 0) > 0) {
      // 投手のニュース
      final kPer9 = ((performance.strikeouts ?? 0) * 9.0) / (performance.inningsPitched ?? 1);
      if (kPer9 >= 10) {
        return NewsItem(
          headline: '🔥 ${performance.playerName}選手が奪三振記録を樹立！',
          content: '${performance.school}の${performance.playerName}選手が9回${performance.strikeouts}奪三振の圧巻の投球。奪三振率${kPer9.toStringAsFixed(1)}を記録しました。',
          category: '選手',
          importance: 4,
          icon: '🔥',
          timestamp: DateTime.now(),
          school: performance.school,
          player: performance.playerName,
        );
      }
    } else if ((performance.atBats ?? 0) > 0) {
      // 野手のニュース
      final avg = performance.battingAverage ?? 0;
      if (avg >= 0.400) {
        return NewsItem(
          headline: '⭐ ${performance.playerName}選手が打率4割を達成！',
          content: '${performance.school}の${performance.playerName}選手が打率${(avg * 100).toStringAsFixed(1)}%を記録。プロ野球界から注目を集めています。',
          category: '選手',
          importance: 4,
          icon: '⭐',
          timestamp: DateTime.now(),
          school: performance.school,
          player: performance.playerName,
        );
      } else if ((performance.homeRuns ?? 0) >= 2) {
        return NewsItem(
          headline: '💪 ${performance.playerName}選手が本塁打を連発！',
          content: '${performance.school}の${performance.playerName}選手が${performance.homeRuns}本の本塁打を放ち、打線の中心として活躍しました。',
          category: '選手',
          importance: 3,
          icon: '💪',
          timestamp: DateTime.now(),
          school: performance.school,
          player: performance.playerName,
        );
      }
    }
    
    // デフォルトの選手ニュース
    return NewsItem(
      headline: '⭐ ${performance.playerName}選手が好成績',
      content: '${performance.school}の${performance.playerName}選手が注目の活躍を見せています。',
      category: '選手',
      importance: 3,
      icon: '⭐',
      timestamp: DateTime.now(),
      school: performance.school,
      player: performance.playerName,
    );
  }
  
  // 強い学校を探す
  List<School> _findStrongSchools() {
    final schoolStrength = <School, double>{};
    
    for (final school in schools) {
      double strength = 0;
      
      // 投手の強さ
      final pitchers = school.players.where((p) => p.isPitcher).toList();
      for (final pitcher in pitchers) {
        strength += (pitcher.control ?? 50) + (pitcher.stamina ?? 50) + pitcher.veloScore + (pitcher.breakAvg ?? 50);
      }
      
      // 野手の強さ
      final batters = school.players.where((p) => !p.isPitcher).toList();
      for (final batter in batters) {
        strength += (batter.batPower ?? 50) + (batter.batControl ?? 50) + (batter.run ?? 50) + (batter.field ?? 50) + (batter.arm ?? 50);
      }
      
      schoolStrength[school] = strength;
    }
    
    final sortedSchools = schoolStrength.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedSchools.take(3).map((e) => e.key).toList();
  }
  
  // 学校の強さに基づくニュースを生成
  NewsItem _generateSchoolStrengthNews(List<School> strongSchools) {
    final school = strongSchools.first;
    final topPlayer = school.players.reduce((a, b) {
      final aScore = a.isPitcher ? (a.control ?? 0) + (a.stamina ?? 0) + a.veloScore + (a.breakAvg ?? 0) 
                                 : (a.batPower ?? 0) + (a.batControl ?? 0) + (a.run ?? 0) + (a.field ?? 0) + (a.arm ?? 0);
      final bScore = b.isPitcher ? (b.control ?? 0) + (b.stamina ?? 0) + b.veloScore + (b.breakAvg ?? 0)
                                 : (b.batPower ?? 0) + (b.batControl ?? 0) + (b.run ?? 0) + (b.field ?? 0) + (b.arm ?? 0);
      return aScore > bScore ? a : b;
    });
    
    return NewsItem(
      headline: '🏆 ${school.name}が最強チームとして注目',
      content: '${school.name}が選手層の厚さで他校を圧倒。特に${topPlayer.name}選手を中心としたチーム力が評価されています。',
      category: '学校',
      importance: 4,
      icon: '🏆',
      timestamp: DateTime.now(),
      school: school.name,
      player: topPlayer.name,
    );
  }
  
  // 成長している選手を探す
  List<Player> _findGrowingPlayers() {
    final growingPlayers = <Player>[];
    
    for (final school in schools) {
      for (final player in school.players) {
        // 最近成長した選手を判定（実際の成長ロジックに基づく）
        if (player.mentalGrit > 0.1 && player.growthRate > 1.0) {
          growingPlayers.add(player);
        }
      }
    }
    
    return growingPlayers;
  }
  
  // 選手の成長に基づくニュースを生成
  NewsItem _generatePlayerGrowthNews(List<Player> growingPlayers) {
    final player = growingPlayers.first;
    
    // 視察済みの学校からのニュースのみ生成
    final visitedSchools = lastWeekActions
        .where((action) => action.success && action.school != '不明')
        .map((action) => action.school)
        .toSet();
    
    if (!visitedSchools.contains(player.school)) {
      // 視察していない学校の場合は一般ニュースを生成
      return NewsItem(
        headline: '📈 選手の成長が話題',
        content: '各校で選手の成長が話題になっています。',
        category: '選手',
        importance: 2,
        icon: '📈',
        timestamp: DateTime.now(),
        school: null,
        player: null,
      );
    }
    
    return NewsItem(
      headline: '📈 ${player.name}選手が急成長中',
      content: '${player.school}の${player.name}選手が練習での成果を実感。能力向上が期待されています。',
      category: '選手',
      importance: 3,
      icon: '📈',
      timestamp: DateTime.now(),
      school: player.school,
      player: player.name,
    );
  }
  
  // テンプレートベースのニュースを生成（従来の方法）
  void _generateTemplateNews() {
    final random = Random();
    
    // 視察済みの学校を取得
    final visitedSchools = lastWeekActions
        .where((action) => action.success && action.school != '不明')
        .map((action) => action.school)
        .toSet();
    
    // 視察済みの学校がない場合は一般ニュースのみ生成
    if (visitedSchools.isEmpty) {
      final generalNewsTemplates = [
        {
          'headline': '🌤️ 好天候で練習環境が良好',
          'content': '今週は晴天が続き、各校の練習が順調に進んでいます。',
          'category': '一般',
          'importance': 1,
          'icon': '🌤️',
        },
        {
          'headline': '📺 高校野球特集番組が放送予定',
          'content': '今週末のテレビ番組で注目選手特集が放送されます。',
          'category': '一般',
          'importance': 2,
          'icon': '📺',
        },
        {
          'headline': '📊 スカウトレポートが更新されました',
          'content': '最新の選手評価データが公開され、注目選手の情報が更新されています。',
          'category': 'スカウト',
          'importance': 2,
          'icon': '📊',
        },
      ];
      
      final selectedNews = generalNewsTemplates[random.nextInt(generalNewsTemplates.length)];
      final newsItem = NewsItem(
        headline: selectedNews['headline'] as String,
        content: selectedNews['content'] as String,
        category: selectedNews['category'] as String,
        importance: selectedNews['importance'] as int,
        icon: selectedNews['icon'] as String,
        timestamp: DateTime.now(),
        school: null,
      );
      
      news.add(newsItem);
      return;
    }
    
    // 視察済みの学校からランダムに選択
    final selectedSchool = visitedSchools.elementAt(random.nextInt(visitedSchools.length));
    
    final newsTemplates = [
      // 試合関連ニュース（視察済み学校のみ）
      {
        'headline': '⚾ ${selectedSchool}が練習試合で勝利',
        'content': '投手陣の好投と打線の爆発で圧勝。来季への期待が高まっています。',
        'category': '試合',
        'importance': 3,
        'icon': '⚾',
      },
      {
        'headline': '🔥 新記録が誕生！${selectedSchool}の投手が完封',
        'content': '9回無失点、奪三振15個の圧巻の投球で新記録を樹立しました。',
        'category': '試合',
        'importance': 4,
        'icon': '🔥',
      },
      // 選手関連ニュース（視察済み学校のみ）
      {
        'headline': '⭐ ${selectedSchool}の${_getRandomPlayerName()}選手が注目',
        'content': '打率.350、本塁打8本の好成績でプロ野球界から注目を集めています。',
        'category': '選手',
        'importance': 4,
        'icon': '⭐',
      },
      {
        'headline': '💪 ${_getRandomPlayerName()}選手が怪我から復帰',
        'content': '3ヶ月のリハビリを経て、今週末の試合から復帰予定です。',
        'category': '選手',
        'importance': 3,
        'icon': '💪',
      },
      // 学校関連ニュース（視察済み学校のみ）
      {
        'headline': '🏫 ${selectedSchool}に新監督就任',
        'content': '元プロ野球選手の新監督が就任し、チーム改革が始まります。',
        'category': '学校',
        'importance': 3,
        'icon': '🏫',
      },
      {
        'headline': '📚 ${selectedSchool}が野球部強化',
        'content': '新たな練習施設の建設が決定し、来年度からの強化が期待されます。',
        'category': '学校',
        'importance': 2,
        'icon': '📚',
      },
      // スカウト関連ニュース（視察済み学校のみ）
      {
        'headline': '👀 他球団スカウトが${selectedSchool}を視察',
        'content': '複数のプロ野球球団のスカウトが同校の選手を視察に訪れました。',
        'category': 'スカウト',
        'importance': 4,
        'icon': '👀',
      },
      // 一般ニュース
      {
        'headline': '🌤️ 好天候で練習環境が良好',
        'content': '今週は晴天が続き、各校の練習が順調に進んでいます。',
        'category': '一般',
        'importance': 1,
        'icon': '🌤️',
      },
      {
        'headline': '📺 高校野球特集番組が放送予定',
        'content': '今週末のテレビ番組で注目選手特集が放送されます。',
        'category': '一般',
        'importance': 2,
        'icon': '📺',
      },
    ];
    
    final selectedNews = newsTemplates[random.nextInt(newsTemplates.length)];
    final newsItem = NewsItem(
      headline: selectedNews['headline'] as String,
      content: selectedNews['content'] as String,
      category: selectedNews['category'] as String,
      importance: selectedNews['importance'] as int,
      icon: selectedNews['icon'] as String,
      timestamp: DateTime.now(),
      school: (selectedNews['headline'] as String).contains('高校') ? selectedSchool : null,
    );
    
    news.add(newsItem);
  }
  
  String _getRandomPlayerName() {
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    return names[Random().nextInt(names.length)] + 
           (Random().nextInt(999) + 1).toString().padLeft(3, '0');
  }

  Map<String, dynamic> toJson() => {
    'currentWeek': currentWeek,
    'currentYear': currentYear,
    'actionPoints': actionPoints,
    'budget': budget,
    'reputation': reputation,
    'schools': schools.map((s) => s.toJson()).toList(),
    'discoveredPlayers': discoveredPlayers.map((p) => p.toJson()).toList(),
    'news': news.map((n) => n.toJson()).toList(),
    'lastWeekActions': lastWeekActions.map((a) => a.toJson()).toList(),
    'thisWeekSchedule': thisWeekSchedule.map((s) => s.toJson()).toList(),
    'gameResults': gameResults.map((g) => g.toJson()).toList(),
    'scoutSkills': scoutSkills.toJson(),
    'scoutReportManager': scoutReportManager.toJson(),
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    currentWeek: json['currentWeek'],
    currentYear: json['currentYear'],
    actionPoints: json['actionPoints'],
    budget: json['budget'],
    reputation: json['reputation'],
    schools: (json['schools'] as List).map((s) => School.fromJson(s)).toList(),
    discoveredPlayers: (json['discoveredPlayers'] as List).map((p) => Player.fromJson(p)).toList(),
    news: (json['news'] as List).map((n) => NewsItem.fromJson(n)).toList(),
    lastWeekActions: (json['lastWeekActions'] as List?)?.map((a) => ActionResult.fromJson(a)).toList() ?? [],
    thisWeekSchedule: (json['thisWeekSchedule'] as List?)?.map((s) => ScheduleItem.fromJson(s)).toList() ?? [],
    gameResults: (json['gameResults'] as List?)?.map((g) => GameResult.fromJson(g)).toList() ?? [],
    scoutSkills: ScoutSkills.fromJson(json['scoutSkills']),
    scoutReportManager: json['scoutReportManager'] != null 
      ? ScoutReportManager.fromJson(json['scoutReportManager']) 
      : null,
  );

  // スカウトアクションを実行
  ActionResult executeAction(ScoutingAction action, ScoutingTarget target) {
    // アクションが実行可能かチェック
    if (!action.canExecute(scoutSkills, actionPoints, budget)) {
      return ActionResult(
        actionName: action.name,
        result: '実行条件を満たしていません',
        school: target.name,
        player: target.type == 'player' ? target.name : null,
        apUsed: 0,
        budgetUsed: 0,
        timestamp: DateTime.now(),
        success: false,
      );
    }
    
    // リソースを消費
    actionPoints -= action.apCost;
    budget -= action.budgetCost;
    
    // 成功判定
    final success = action.calculateSuccess(scoutSkills);
    
    // 成功時のスキル上昇
    if (success) {
      for (final skillName in action.primarySkills) {
        final improvement = Random().nextInt(3) + 1; // 1-3ポイント上昇
        scoutSkills.improveSkill(skillName, improvement);
      }
    }
    
    // 体力消費（全アクションで）
    final staminaLoss = Random().nextInt(5) + 1; // 1-5ポイント減少
    scoutSkills.improveSkill('stamina', -staminaLoss);
    
    // アクション別の結果を生成
    final result = _generateActionResult(action, success, target);
    
    return ActionResult(
      actionName: action.name,
      result: result.message,
      school: target.name,
      player: target.type == 'player' ? target.name : null,
      apUsed: action.apCost,
      budgetUsed: action.budgetCost,
      timestamp: DateTime.now(),
      success: success,
      additionalData: result.additionalData,
    );
  }
  
  // アクション別の結果を生成
  ActionResultData _generateActionResult(ScoutingAction action, bool success, ScoutingTarget target) {
    if (!success) {
      return ActionResultData('${action.name}に失敗しました。条件を確認してください。');
    }
    
    switch (action.id) {
      case 'PRAC_WATCH':
        return _handlePracticeWatch(target);
      case 'TEAM_VISIT':
        return _handleTeamVisit(target);
      case 'INFO_SWAP':
        return _handleInfoSwap(target);
      case 'NEWS_CHECK':
        return _handleNewsCheck(target);
      case 'GAME_WATCH':
        return _handleGameWatch(target);
      case 'SCRIMMAGE':
        return _handleScrimmage(target);
      case 'INTERVIEW':
        return _handleInterview(target);
      case 'VIDEO_ANALYZE':
        return _handleVideoAnalyze(target);
      case 'REPORT_WRITE':
        return _handleReportWrite(target);
      default:
        return ActionResultData('${action.name}を実行しました。');
    }
  }
  
  // 練習視察の結果
  ActionResultData _handlePracticeWatch(ScoutingTarget target) {
    final random = Random();
    final discoveredPlayers = <Player>[];
    
    // 新しい選手を発見する可能性
    if (random.nextDouble() < 0.3) { // 30%の確率で新選手発見
      final newPlayer = _generateRandomPlayer(target.name);
      discoveredPlayers.add(newPlayer);
    }
    
    return ActionResultData(
      '${target.name}の練習を視察しました。選手の基本能力を確認できました。',
      {
        'discoveredPlayers': discoveredPlayers.map((p) => p.toJson()).toList(),
        'schoolTrust': random.nextInt(10) + 5, // 5-15ポイント上昇
      },
    );
  }
  
  // ランダムな選手を生成
  Player _generateRandomPlayer(String schoolName) {
    final random = Random();
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final grades = [1, 2, 3]; // int型に変更
    final personalities = ['リーダーシップ', 'チームプレイ', '向上心', '冷静', '情熱的'];
    
    final name = names[random.nextInt(names.length)] + 
                (random.nextInt(999) + 1).toString().padLeft(3, '0');
    final position = positions[random.nextInt(positions.length)];
    final grade = grades[random.nextInt(grades.length)];
    final personality = personalities[random.nextInt(personalities.length)];
    
    // 投手か野手かを判定
    final isPitcher = position == '投手';
    
    if (isPitcher) {
      final fastballVelo = 130 + random.nextInt(25); // 130-155km/h
      final control = 30 + random.nextInt(41); // 30-70
      final stamina = 40 + random.nextInt(41); // 40-80
      final breakAvg = 35 + random.nextInt(41); // 35-75
      
      return Player(
        name: name,
        school: schoolName,
        grade: grade,
        position: position,
        personality: personality,
        fastballVelo: fastballVelo,
        control: control,
        stamina: stamina,
        breakAvg: breakAvg,
        mentalGrit: (30 + random.nextInt(41)).toDouble(), // double型に変換
        growthRate: (20 + random.nextInt(31)).toDouble(), // double型に変換
        peakAbility: 100 + random.nextInt(51),
        positionFit: {'P': 60 + random.nextInt(41)}, // Map<String, int>型に修正
      );
    } else {
      final batPower = 35 + random.nextInt(41); // 35-75
      final batControl = 40 + random.nextInt(41); // 40-80
      final run = 45 + random.nextInt(41); // 45-85
      final field = 40 + random.nextInt(41); // 40-80
      final arm = 35 + random.nextInt(41); // 35-75
      
      return Player(
        name: name,
        school: schoolName,
        grade: grade,
        position: position,
        personality: personality,
        batPower: batPower,
        batControl: batControl,
        run: run,
        field: field,
        arm: arm,
        mentalGrit: (30 + random.nextInt(41)).toDouble(), // double型に変換
        growthRate: (20 + random.nextInt(31)).toDouble(), // double型に変換
        peakAbility: 100 + random.nextInt(51),
        positionFit: {'IF': 60 + random.nextInt(41)}, // Map<String, int>型に修正
      );
    }
  }
  
  // 球団訪問の結果
  ActionResultData _handleTeamVisit(ScoutingTarget target) {
    final random = Random();
    final needs = ['投手', '野手', '捕手', '外野手', '内野手'];
    final selectedNeeds = needs.take(random.nextInt(3) + 1).toList();
    
    return ActionResultData(
      '球団を訪問しました。ニーズと指名候補について情報を得ました。',
      {
        'teamNeeds': selectedNeeds,
        'draftPriority': random.nextInt(5) + 1, // 1-5の優先度
        'budget': random.nextInt(50000000) + 10000000, // 1000万-6000万
      },
    );
  }
  
  // 情報交換の結果
  ActionResultData _handleInfoSwap(ScoutingTarget target) {
    final random = Random();
    final regions = ['関東', '関西', '中部', '九州', '東北', '北海道'];
    final selectedRegion = regions[random.nextInt(regions.length)];
    
    // 他地域の選手情報を取得
    final otherPlayers = <Map<String, dynamic>>[];
    for (int i = 0; i < random.nextInt(3) + 1; i++) {
      otherPlayers.add({
        'name': '選手${random.nextInt(999) + 1}',
        'school': '${selectedRegion}高校${random.nextInt(10) + 1}',
        'position': ['投手', '野手'][random.nextInt(2)],
        'evaluation': random.nextInt(20) + 70, // 70-90の評価
      });
    }
    
    return ActionResultData(
      '他地域のスカウトと情報交換しました。${selectedRegion}地域の情報を得ました。',
      {
        'region': selectedRegion,
        'otherPlayers': otherPlayers,
        'reputation': random.nextInt(5) + 1, // 1-5ポイント上昇
      },
    );
  }
  
  // ニュース確認の結果
  ActionResultData _handleNewsCheck(ScoutingTarget target) {
    final random = Random();
    final newsCount = random.nextInt(3) + 1; // 1-3件のニュース
    
    return ActionResultData(
      '最新のニュースを確認しました。${newsCount}件の新しい情報を得ました。',
      {
        'newsCount': newsCount,
        'categories': ['試合', '選手', '学校', 'スカウト'].take(random.nextInt(3) + 1).toList(),
      },
    );
  }
  
  // 試合観戦の結果
  ActionResultData _handleGameWatch(ScoutingTarget target) {
    final random = Random();
    final performanceData = {
      'innings': random.nextInt(9) + 1,
      'hits': random.nextInt(10),
      'runs': random.nextInt(5),
      'strikeouts': random.nextInt(10),
      'walks': random.nextInt(5),
    };
    
    return ActionResultData(
      '${target.name}の試合を観戦しました。詳細なパフォーマンスを確認できました。',
      {
        'performance': performanceData,
        'scoutingAccuracy': random.nextInt(20) + 80, // 80-100%の精度
      },
    );
  }
  
  // 練習試合観戦の結果
  ActionResultData _handleScrimmage(ScoutingTarget target) {
    final random = Random();
    final tendencies = ['積極的', '慎重', '攻撃的', '守備重視', 'バランス型'];
    final selectedTendency = tendencies[random.nextInt(tendencies.length)];
    
    return ActionResultData(
      '${target.name}の練習試合を観戦しました。実戦での傾向を確認できました。',
      {
        'tendency': selectedTendency,
        'teamChemistry': random.nextInt(20) + 70, // 70-90のチーム力
        'coachStyle': ['厳格', '自由', '戦術的'][random.nextInt(3)],
      },
    );
  }
  
  // インタビューの結果
  ActionResultData _handleInterview(ScoutingTarget target) {
    final random = Random();
    final personalities = ['リーダーシップ', 'チームプレイ', '向上心', '冷静', '情熱的'];
    final selectedPersonality = personalities[random.nextInt(personalities.length)];
    
    return ActionResultData(
      '${target.name}にインタビューしました。性格と動機について理解できました。',
      {
        'personality': selectedPersonality,
        'motivation': random.nextInt(20) + 70, // 70-90のモチベーション
        'communication': random.nextInt(20) + 70, // 70-90のコミュニケーション力
        'futurePlans': ['プロ野球', '大学野球', '社会人野球'][random.nextInt(3)],
      },
    );
  }
  
  // ビデオ分析の結果
  ActionResultData _handleVideoAnalyze(ScoutingTarget target) {
    final random = Random();
    final technicalData = {
      'mechanics': random.nextInt(20) + 70, // 70-90のメカニクス
      'consistency': random.nextInt(20) + 70, // 70-90の一貫性
      'potential': random.nextInt(30) + 70, // 70-100のポテンシャル
    };
    
    return ActionResultData(
      '映像分析を完了しました。技術的なメカニクスを詳細に確認できました。',
      {
        'technicalAnalysis': technicalData,
        'improvementAreas': ['投球フォーム', '打撃フォーム', '守備'].take(random.nextInt(2) + 1).toList(),
      },
    );
  }
  
  // レポート作成の結果
  ActionResultData _handleReportWrite(ScoutingTarget target) {
    final random = Random();
    final reportQuality = random.nextInt(20) + 80; // 80-100の品質
    
    return ActionResultData(
      '球団提出用の詳細レポートを作成しました。',
      {
        'reportQuality': reportQuality,
        'pages': random.nextInt(10) + 5, // 5-15ページ
        'recommendations': random.nextInt(3) + 1, // 1-3の推奨事項
        'deadline': DateTime.now().add(Duration(days: random.nextInt(7) + 1)),
      },
    );
  }
}

// 選手の通算成績クラス
class PlayerStats {
  final String playerName;
  final String school;
  final String position;
  
  // 投手通算成績
  int totalInningsPitched = 0;
  int totalHitsAllowed = 0;
  int totalRunsAllowed = 0;
  int totalEarnedRuns = 0;
  int totalWalks = 0;
  int totalStrikeouts = 0;
  double era = 0.0;
  
  // 野手通算成績
  int totalAtBats = 0;
  int totalHits = 0;
  int totalDoubles = 0;
  int totalTriples = 0;
  int totalHomeRuns = 0;
  int totalRbis = 0;
  int totalRuns = 0;
  int totalStolenBases = 0;
  double battingAverage = 0.0;
  double onBasePercentage = 0.0;
  double sluggingPercentage = 0.0;
  
  // 守備通算成績
  int totalPutouts = 0;
  int totalAssists = 0;
  int totalErrors = 0;
  double fieldingPercentage = 0.0;
  
  PlayerStats({
    required this.playerName,
    required this.school,
    required this.position,
  });
  
  // 投手成績を追加
  void addPitchingStats(PlayerPerformance performance) {
    if (performance.inningsPitched != null) {
      totalInningsPitched += performance.inningsPitched!;
      totalHitsAllowed += performance.hitsAllowed ?? 0;
      totalRunsAllowed += performance.runsAllowed ?? 0;
      totalEarnedRuns += performance.earnedRuns ?? 0;
      totalWalks += performance.walks ?? 0;
      totalStrikeouts += performance.strikeouts ?? 0;
      
      // ERA計算
      if (totalInningsPitched > 0) {
        era = (totalEarnedRuns * 9.0) / totalInningsPitched;
      }
    }
  }
  
  // 野手成績を追加
  void addBattingStats(PlayerPerformance performance) {
    if (performance.atBats != null) {
      totalAtBats += performance.atBats!;
      totalHits += performance.hits ?? 0;
      totalDoubles += performance.doubles ?? 0;
      totalTriples += performance.triples ?? 0;
      totalHomeRuns += performance.homeRuns ?? 0;
      totalRbis += performance.rbis ?? 0;
      totalRuns += performance.runs ?? 0;
      totalStolenBases += performance.stolenBases ?? 0;
      
      // 打率計算
      if (totalAtBats > 0) {
        battingAverage = totalHits / totalAtBats;
      }
    }
  }
  
  // 守備成績を追加
  void addFieldingStats(PlayerPerformance performance) {
    totalPutouts += performance.putouts ?? 0;
    totalAssists += performance.assists ?? 0;
    totalErrors += performance.errors ?? 0;
    
    // 守備率計算
    final totalChances = totalPutouts + totalAssists + totalErrors;
    if (totalChances > 0) {
      fieldingPercentage = (totalPutouts + totalAssists) / totalChances;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'school': school,
    'position': position,
    'totalInningsPitched': totalInningsPitched,
    'totalHitsAllowed': totalHitsAllowed,
    'totalRunsAllowed': totalRunsAllowed,
    'totalEarnedRuns': totalEarnedRuns,
    'totalWalks': totalWalks,
    'totalStrikeouts': totalStrikeouts,
    'era': era,
    'totalAtBats': totalAtBats,
    'totalHits': totalHits,
    'totalDoubles': totalDoubles,
    'totalTriples': totalTriples,
    'totalHomeRuns': totalHomeRuns,
    'totalRbis': totalRbis,
    'totalRuns': totalRuns,
    'totalStolenBases': totalStolenBases,
    'battingAverage': battingAverage,
    'onBasePercentage': onBasePercentage,
    'sluggingPercentage': sluggingPercentage,
    'totalPutouts': totalPutouts,
    'totalAssists': totalAssists,
    'totalErrors': totalErrors,
    'fieldingPercentage': fieldingPercentage,
  };
  
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final stats = PlayerStats(
      playerName: json['playerName'],
      school: json['school'],
      position: json['position'],
    );
    
    stats.totalInningsPitched = json['totalInningsPitched'] ?? 0;
    stats.totalHitsAllowed = json['totalHitsAllowed'] ?? 0;
    stats.totalRunsAllowed = json['totalRunsAllowed'] ?? 0;
    stats.totalEarnedRuns = json['totalEarnedRuns'] ?? 0;
    stats.totalWalks = json['totalWalks'] ?? 0;
    stats.totalStrikeouts = json['totalStrikeouts'] ?? 0;
    stats.era = (json['era'] as num?)?.toDouble() ?? 0.0;
    stats.totalAtBats = json['totalAtBats'] ?? 0;
    stats.totalHits = json['totalHits'] ?? 0;
    stats.totalDoubles = json['totalDoubles'] ?? 0;
    stats.totalTriples = json['totalTriples'] ?? 0;
    stats.totalHomeRuns = json['totalHomeRuns'] ?? 0;
    stats.totalRbis = json['totalRbis'] ?? 0;
    stats.totalRuns = json['totalRuns'] ?? 0;
    stats.totalStolenBases = json['totalStolenBases'] ?? 0;
    stats.battingAverage = (json['battingAverage'] as num?)?.toDouble() ?? 0.0;
    stats.onBasePercentage = (json['onBasePercentage'] as num?)?.toDouble() ?? 0.0;
    stats.sluggingPercentage = (json['sluggingPercentage'] as num?)?.toDouble() ?? 0.0;
    stats.totalPutouts = json['totalPutouts'] ?? 0;
    stats.totalAssists = json['totalAssists'] ?? 0;
    stats.totalErrors = json['totalErrors'] ?? 0;
    stats.fieldingPercentage = (json['fieldingPercentage'] as num?)?.toDouble() ?? 0.0;
    
    return stats;
  }
} 