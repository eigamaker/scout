import '../../models/game/game.dart';
import '../../models/player/player.dart';
import '../../models/school/school.dart';
import '../data_service.dart';
import '../news_service.dart';
import '../growth_service.dart';
import '../pennant_race_service.dart';
import '../high_school_tournament_service.dart';
import '../scouting/action_service.dart' as scouting;

/// ゲーム進行に関する機能を担当するサービス
class GameProgressionService {
  final DataService _dataService;
  final NewsService _newsService;
  final GrowthService _growthService;

  GameProgressionService(this._dataService, this._newsService, this._growthService);

  /// 週送り時にアクションを実行し、リザルトを返す
  Future<List<String>> advanceWeekWithResults(Game currentGame) async {
    final results = <String>[];
    
    print('GameProgressionService: 週送り処理開始');
    print('GameProgressionService: 現在の状態 - 月: ${currentGame.currentMonth}, 週: ${currentGame.currentWeekOfMonth}, 年: ${currentGame.currentYear}');
    
    try {
      // スカウトアクションを実行
      print('GameProgressionService: スカウトアクション実行開始');
      final scoutResults = await executeScoutActions(currentGame);
      results.addAll(scoutResults);
      print('GameProgressionService: スカウトアクション実行完了 - 結果数: ${scoutResults.length}');
      
      // 週送り（週進行、AP/予算リセット、アクションリセット）
      print('GameProgressionService: 週送り処理開始');
      print('GameProgressionService: 週送り前 - 月: ${currentGame.currentMonth}, 週: ${currentGame.currentWeekOfMonth}');
      
      final advancedGame = currentGame
        .advanceWeek()
        .resetWeeklyResources(newAp: 15, newBudget: currentGame.budget)
        .resetActions();
      
      print('GameProgressionService: 週送り後 - 月: ${advancedGame.currentMonth}, 週: ${advancedGame.currentWeekOfMonth}');
      print('GameProgressionService: 週送り処理完了');

      // ペナントレースの進行
      if (advancedGame.pennantRace != null) {
        print('GameProgressionService: ペナントレース進行開始');
        final pennantResults = await _processPennantRace(advancedGame);
        results.addAll(pennantResults);
        print('GameProgressionService: ペナントレース進行完了 - 結果数: ${pennantResults.length}');
      }

      // 高校野球大会の進行
      if (advancedGame.highSchoolTournament != null) {
        print('GameProgressionService: 高校野球大会進行開始');
        final tournamentResults = await _processHighSchoolTournament(advancedGame);
        results.addAll(tournamentResults);
        print('GameProgressionService: 高校野球大会進行完了 - 結果数: ${tournamentResults.length}');
      }

      // 選手の成長処理
      print('GameProgressionService: 選手成長処理開始');
      final growthResults = await _processPlayerGrowth(advancedGame);
      results.addAll(growthResults);
      print('GameProgressionService: 選手成長処理完了 - 結果数: ${growthResults.length}');

      // ニュース生成
      print('GameProgressionService: ニュース生成開始');
      final newsResults = await _generateNews(advancedGame);
      results.addAll(newsResults);
      print('GameProgressionService: ニュース生成完了 - 結果数: ${newsResults.length}');

      return results;
      
    } catch (e) {
      print('GameProgressionService: 週送り処理エラー: $e');
      rethrow;
    }
  }

  /// スカウトアクションを実行
  Future<List<String>> executeScoutActions(Game currentGame) async {
    final results = <String>[];
    
    try {
      // 週次アクションを実行
      for (final action in currentGame.weeklyActions) {
        final actionResult = await scouting.ActionService.executeAction(action, currentGame, _dataService);
        if (actionResult.isNotEmpty) {
          results.add(actionResult);
        }
      }
      
      return results;
    } catch (e) {
      print('GameProgressionService: スカウトアクション実行エラー: $e');
      return results;
    }
  }

  /// ペナントレースの進行処理
  Future<List<String>> _processPennantRace(Game currentGame) async {
    final results = <String>[];
    
    try {
      if (currentGame.pennantRace == null) return results;
      
      // ペナントレースの進行
      final updatedPennantRace = await PennantRaceService.advanceWeek(currentGame.pennantRace!);
      
      // 結果を生成
      if (updatedPennantRace != null) {
        results.add('ペナントレースが進行しました');
        
        // 注目すべき試合結果があれば追加
        if (updatedPennantRace.hasNotableGames) {
          results.add('注目の試合が行われました');
        }
      }
      
      return results;
    } catch (e) {
      print('GameProgressionService: ペナントレース進行エラー: $e');
      return results;
    }
  }

  /// 高校野球大会の進行処理
  Future<List<String>> _processHighSchoolTournament(Game currentGame) async {
    final results = <String>[];
    
    try {
      if (currentGame.highSchoolTournament == null) return results;
      
      // 高校野球大会の進行
      final updatedTournament = await HighSchoolTournamentService.advanceWeek(currentGame.highSchoolTournament!);
      
      // 結果を生成
      if (updatedTournament != null) {
        results.add('高校野球大会が進行しました');
        
        // 注目すべき試合結果があれば追加
        if (updatedTournament.hasNotableGames) {
          results.add('注目の試合が行われました');
        }
      }
      
      return results;
    } catch (e) {
      print('GameProgressionService: 高校野球大会進行エラー: $e');
      return results;
    }
  }

  /// 選手の成長処理
  Future<List<String>> _processPlayerGrowth(Game currentGame) async {
    final results = <String>[];
    
    try {
      // 全学校の選手を取得
      final schools = await _dataService.getAllSchoolsWithPlayers();
      
      int totalPlayersProcessed = 0;
      int playersWithGrowth = 0;
      
      for (final schoolData in schools) {
        final players = schoolData['players'] as List;
        
        for (final playerData in players) {
          final player = Player.fromJson(Map<String, dynamic>.from(playerData));
          
          // 成長処理を実行
          final growthResult = await _growthService.processPlayerGrowth(player, currentGame);
          
          if (growthResult.hasGrowth) {
            playersWithGrowth++;
            results.add('${player.name}の能力が向上しました');
          }
          
          totalPlayersProcessed++;
        }
      }
      
      if (playersWithGrowth > 0) {
        results.add('${playersWithGrowth}名の選手が成長しました');
      }
      
      print('GameProgressionService: 成長処理完了 - 処理選手数: $totalPlayersProcessed, 成長選手数: $playersWithGrowth');
      
      return results;
    } catch (e) {
      print('GameProgressionService: 選手成長処理エラー: $e');
      return results;
    }
  }

  /// ニュース生成処理
  Future<List<String>> _generateNews(Game currentGame) async {
    final results = <String>[];
    
    try {
      // ニュースを生成
      final news = await _newsService.generateWeeklyNews(currentGame);
      
      if (news.isNotEmpty) {
        results.add('${news.length}件のニュースが生成されました');
        
        // 重要なニュースがあれば追加
        final importantNews = news.where((n) => n.importance > 7).toList();
        if (importantNews.isNotEmpty) {
          results.add('${importantNews.length}件の重要ニュースがあります');
        }
      }
      
      return results;
    } catch (e) {
      print('GameProgressionService: ニュース生成エラー: $e');
      return results;
    }
  }

  /// ドラフト週かどうかをチェック
  bool isDraftWeek(Game currentGame) {
    return currentGame.currentMonth == 10 && currentGame.currentWeekOfMonth == 4;
  }

  /// ペナントレースが進行中かチェック
  bool isPennantRaceActive(Game currentGame) {
    if (currentGame.pennantRace == null) return false;
    final month = currentGame.currentMonth;
    final week = currentGame.currentWeekOfMonth;
    return month >= 4 && month <= 10 && (month != 4 || week >= 1) && (month != 10 || week <= 2);
  }

  /// 高校野球大会が進行中かチェック
  bool isHighSchoolTournamentActive(Game currentGame) {
    if (currentGame.highSchoolTournament == null) return false;
    final month = currentGame.currentMonth;
    return month >= 7 && month <= 8;
  }
}
