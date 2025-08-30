import 'package:scout_game/models/scouting/scout_report.dart';
import 'package:scout_game/services/data_service.dart';

/// スカウト関連のサービス
class ScoutingService {
  /// 球団にスカウトレポートを送信
  static Future<void> submitReportToTeam(ScoutReport report) async {
    // TODO: 実際の球団送信ロジックを実装
    // 現在は仮の実装として、レポートを保存するだけ
    
    // レポートをデータベースに保存
    await _saveReportToDatabase(report);
    
    // 球団のスカウト部門に通知
    await _notifyTeamScoutingDepartment(report);
    
    // レポート送信履歴を記録
    await _logReportSubmission(report);
  }
  
  /// レポートをデータベースに保存
  static Future<void> _saveReportToDatabase(ScoutReport report) async {
    final dataService = DataService();
    
    final db = await dataService.database;
    await db.insert('scout_reports', {
      'id': report.id,
      'player_id': report.playerId,
      'player_name': report.playerName,
      'scout_id': report.scoutId,
      'scout_name': report.scoutName,
      'created_at': report.createdAt.toIso8601String(),
      'updated_at': report.updatedAt.toIso8601String(),
      'future_potential': report.futurePotential.name,
      'overall_rating': report.overallRating,
      'expected_draft_position': report.expectedDraftPosition.name,
      'player_type': report.playerType.name,
      'position_suitability': report.positionSuitability,
      'mental_strength': report.mentalStrength,
      'injury_risk': report.injuryRisk,
      'years_to_mlb': report.yearsToMLB,
      'strengths': report.strengths,
      'weaknesses': report.weaknesses,
      'development_plan': report.developmentPlan,
      'additional_notes': report.additionalNotes,
      'is_analysis_complete': report.isAnalysisComplete ? 1 : 0,
    });
    
    print('ScoutingService: レポートをデータベースに保存: ${report.id}');
  }
  
  /// 球団のスカウト部門に通知
  static Future<void> _notifyTeamScoutingDepartment(ScoutReport report) async {
    // TODO: 球団通知ロジックを実装
    print('ScoutingService: 球団スカウト部門に通知: ${report.playerName}');
  }
  
  /// レポート送信履歴を記録
  static Future<void> _logReportSubmission(ScoutReport report) async {
    // TODO: 履歴記録ロジックを実装
    print('ScoutingService: レポート送信履歴を記録: ${report.id}');
  }
  
  /// 選手の分析完了状態をチェック
  static bool isPlayerAnalysisComplete(Map<String, int>? scoutAnalysisData) {
    if (scoutAnalysisData == null) return false;
    
    // 必要な分析項目がすべて完了しているかチェック
    final requiredFields = [
      '投球', '制球', 'スタミナ', // 投手用
      'コンタクト', 'パワー', '走力', '守備', // 野手用
      'リーダーシップ', 'メンタル強度', '練習熱心度', // 精神面
      '耐久性', '柔軟性', 'バランス', // フィジカル面
    ];
    
    // 選手のポジションに応じて必要な項目をチェック
    final hasPitchingData = scoutAnalysisData.containsKey('投球') && 
                           scoutAnalysisData.containsKey('制球') && 
                           scoutAnalysisData.containsKey('スタミナ');
    
    final hasBattingData = scoutAnalysisData.containsKey('コンタクト') && 
                          scoutAnalysisData.containsKey('パワー') && 
                          scoutAnalysisData.containsKey('走力') && 
                          scoutAnalysisData.containsKey('守備');
    
    final hasMentalData = scoutAnalysisData.containsKey('リーダーシップ') && 
                         scoutAnalysisData.containsKey('メンタル強度') && 
                         scoutAnalysisData.containsKey('練習熱心度');
    
    final hasPhysicalData = scoutAnalysisData.containsKey('耐久性') && 
                           scoutAnalysisData.containsKey('柔軟性') && 
                           scoutAnalysisData.containsKey('バランス');
    
    return hasPitchingData && hasBattingData && hasMentalData && hasPhysicalData;
  }
  
  /// 選手の総合能力値を計算
  static double calculateOverallRating(Map<String, int>? scoutAnalysisData, String position) {
    if (scoutAnalysisData == null) return 50.0;
    
    if (position.contains('投手')) {
      final pitching = scoutAnalysisData['投球'] ?? 50;
      final control = scoutAnalysisData['制球'] ?? 50;
      final stamina = scoutAnalysisData['スタミナ'] ?? 50;
      return (pitching + control + stamina) / 3.0;
    } else {
      final contact = scoutAnalysisData['コンタクト'] ?? 50;
      final power = scoutAnalysisData['パワー'] ?? 50;
      final speed = scoutAnalysisData['走力'] ?? 50;
      final fielding = scoutAnalysisData['守備'] ?? 50;
      return (contact + power + speed + fielding) / 4.0;
    }
  }
}
