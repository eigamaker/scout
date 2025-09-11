import 'package:flutter/material.dart';
import 'package:scout_game/models/player/player.dart' hide PlayerType;
import 'package:scout_game/models/scouting/scout_report.dart';
import 'package:scout_game/services/scouting/scouting_service.dart';
import 'scout_report/widgets/player_info_widget.dart';
import 'scout_report/widgets/basic_evaluation_widget.dart';
import 'scout_report/widgets/detailed_evaluation_widget.dart';
import 'scout_report/widgets/comments_widget.dart';

class ScoutReportScreen extends StatefulWidget {
  final Player player;
  final String scoutId;
  final String scoutName;

  const ScoutReportScreen({
    Key? key,
    required this.player,
    required this.scoutId,
    required this.scoutName,
  }) : super(key: key);

  @override
  State<ScoutReportScreen> createState() => _ScoutReportScreenState();
}

class _ScoutReportScreenState extends State<ScoutReportScreen> {
  late FuturePotential _futurePotential;
  late ExpectedDraftPosition _expectedDraftPosition;
  late PlayerType _playerType;
  
  final TextEditingController _positionSuitabilityController = TextEditingController();
  final TextEditingController _strengthsController = TextEditingController();
  final TextEditingController _weaknessesController = TextEditingController();
  final TextEditingController _developmentPlanController = TextEditingController();
  final TextEditingController _additionalNotesController = TextEditingController();
  
  double _mentalStrength = 50.0;
  double _injuryRisk = 50.0;
  int _yearsToMLB = 4;
  
  double? _overallRating;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _calculateOverallRating();
  }

  @override
  void dispose() {
    _positionSuitabilityController.dispose();
    _strengthsController.dispose();
    _weaknessesController.dispose();
    _developmentPlanController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  void _initializeValues() {
    // 将来性を計算
    _futurePotential = _calculateFuturePotential();
    
    // ドラフト予想順位を計算
    _expectedDraftPosition = _calculateExpectedDraftPosition();
    
    // 選手タイプを決定
    _playerType = _determinePlayerType();
    
    // デフォルト値を設定
    _positionSuitabilityController.text = _getDefaultPositionSuitability();
    _strengthsController.text = _getDefaultStrengths();
    _weaknessesController.text = _getDefaultWeaknesses();
    _developmentPlanController.text = _getDefaultDevelopmentPlan();
    _additionalNotesController.text = _getDefaultAdditionalNotes();
    
    // 評価値を計算
    _mentalStrength = _calculateMentalStrength();
    _injuryRisk = _calculateInjuryRisk();
    _yearsToMLB = _calculateYearsToMLB();
  }

  FuturePotential _calculateFuturePotential() {
    final talent = widget.player.talent;
    final age = widget.player.age;
    final growthRate = widget.player.growthRate;
    
    double score = talent * 20 + (100 - age) * 0.5 + growthRate * 50;
    
    if (score >= 80) return FuturePotential.A;
    if (score >= 60) return FuturePotential.B;
    if (score >= 40) return FuturePotential.C;
    return FuturePotential.D;
  }

  ExpectedDraftPosition _calculateExpectedDraftPosition() {
    final talent = widget.player.talent;
    final age = widget.player.age;
    final fame = widget.player.fame;
    
    double score = talent * 20 + (100 - age) * 0.3 + fame * 0.2;
    
    if (score >= 85) return ExpectedDraftPosition.first;
    if (score >= 70) return ExpectedDraftPosition.second;
    if (score >= 55) return ExpectedDraftPosition.third;
    if (score >= 40) return ExpectedDraftPosition.fourth;
    return ExpectedDraftPosition.sixthOrLater;
  }

  PlayerType _determinePlayerType() {
    final position = widget.player.position;
    final technicalAbilities = widget.player.technicalAbilities;
    final physicalAbilities = widget.player.physicalAbilities;
    
    if (position == '投手') {
      final control = technicalAbilities['control'] ?? 50;
      final fastball = technicalAbilities['fastball'] ?? 50;
      
      if (control >= 70 && fastball >= 70) {
        return PlayerType.startingPitcher;
      } else {
        return PlayerType.reliefPitcher;
      }
    } else {
      final power = technicalAbilities['power'] ?? 50;
      final contact = technicalAbilities['contact'] ?? 50;
      final pace = physicalAbilities['pace'] ?? 50;
      final fielding = technicalAbilities['fielding'] ?? 50;
      
      if (power >= 70) return PlayerType.powerHitter;
      if (contact >= 70) return PlayerType.contactHitter;
      if (pace >= 70) return PlayerType.speedster;
      if (fielding >= 70) return PlayerType.defensiveSpecialist;
      return PlayerType.utilityPlayer;
    }
  }

  String _getDefaultPositionSuitability() {
    final position = widget.player.position;
    final positionFit = widget.player.positionFit;
    
    if (positionFit.containsKey(position)) {
      final fit = positionFit[position]!;
      if (fit >= 80) return '${position}として非常に適性が高い';
      if (fit >= 60) return '${position}として適性がある';
      if (fit >= 40) return '${position}として普通の適性';
      return '${position}として適性が低い';
    }
    return 'ポジション適性を評価中';
  }

  String _getDefaultStrengths() {
    final technicalAbilities = widget.player.technicalAbilities;
    final mentalAbilities = widget.player.mentalAbilities;
    final physicalAbilities = widget.player.physicalAbilities;
    
    final strengths = <String>[];
    
    // 技術面の強み
    for (final entry in technicalAbilities.entries) {
      if (entry.value >= 70) {
        strengths.add('${entry.key.name}: ${entry.value}');
      }
    }
    
    // メンタル面の強み
    for (final entry in mentalAbilities.entries) {
      if (entry.value >= 70) {
        strengths.add('${entry.key.name}: ${entry.value}');
      }
    }
    
    // フィジカル面の強み
    for (final entry in physicalAbilities.entries) {
      if (entry.value >= 70) {
        strengths.add('${entry.key.name}: ${entry.value}');
      }
    }
    
    return strengths.isNotEmpty ? strengths.join(', ') : '特筆すべき強みは見られない';
  }

  String _getDefaultWeaknesses() {
    final technicalAbilities = widget.player.technicalAbilities;
    final mentalAbilities = widget.player.mentalAbilities;
    final physicalAbilities = widget.player.physicalAbilities;
    
    final weaknesses = <String>[];
    
    // 技術面の課題
    for (final entry in technicalAbilities.entries) {
      if (entry.value <= 40) {
        weaknesses.add('${entry.key.name}: ${entry.value}');
      }
    }
    
    // メンタル面の課題
    for (final entry in mentalAbilities.entries) {
      if (entry.value <= 40) {
        weaknesses.add('${entry.key.name}: ${entry.value}');
      }
    }
    
    // フィジカル面の課題
    for (final entry in physicalAbilities.entries) {
      if (entry.value <= 40) {
        weaknesses.add('${entry.key.name}: ${entry.value}');
      }
    }
    
    return weaknesses.isNotEmpty ? weaknesses.join(', ') : '特筆すべき課題は見られない';
  }

  String _getDefaultDevelopmentPlan() {
    final talent = widget.player.talent;
    final age = widget.player.age;
    final growthType = widget.player.growthType;
    
    if (talent >= 4) {
      return '高い才能を持つ選手。基本技術の習得とメンタル面の強化に重点を置く。';
    } else if (talent >= 3) {
      return '有望な選手。技術面の向上とフィジカル面の強化を図る。';
    } else {
      return '基礎的な技術の習得から始め、段階的な成長を目指す。';
    }
  }

  String _getDefaultAdditionalNotes() {
    final fame = widget.player.fame;
    final isScoutFavorite = widget.player.isScoutFavorite;
    
    if (fame >= 80) {
      return '注目度の高い選手。多くのスカウトが注目している。';
    } else if (isScoutFavorite) {
      return 'スカウトお気に入りの選手。隠れた才能を秘めている可能性がある。';
    } else {
      return '地道な努力で成長を続けている選手。';
    }
  }

  double _calculateMentalStrength() {
    final mentalAbilities = widget.player.mentalAbilities;
    if (mentalAbilities.isEmpty) return 50.0;
    
    final total = mentalAbilities.values.reduce((a, b) => a + b);
    return total / mentalAbilities.length;
  }

  double _calculateInjuryRisk() {
    final injuryProneness = widget.player.physicalAbilities['injuryProneness'] ?? 50;
    return 100 - injuryProneness.toDouble();
  }

  int _calculateYearsToMLB() {
    final talent = widget.player.talent;
    final age = widget.player.age;
    
    int baseYears = 5;
    baseYears -= (talent - 3) * 2;
    
    if (age >= 18) {
      baseYears -= (age - 18) ~/ 2;
    }
    
    return baseYears.clamp(1, 10);
  }

  double _calculateCurrentOverall() {
    final technicalAbilities = widget.player.technicalAbilities;
    final mentalAbilities = widget.player.mentalAbilities;
    final physicalAbilities = widget.player.physicalAbilities;
    
    double technicalAvg = 0;
    double mentalAvg = 0;
    double physicalAvg = 0;
    
    if (technicalAbilities.isNotEmpty) {
      technicalAvg = technicalAbilities.values.reduce((a, b) => a + b) / technicalAbilities.length;
    }
    
    if (mentalAbilities.isNotEmpty) {
      mentalAvg = mentalAbilities.values.reduce((a, b) => a + b) / mentalAbilities.length;
    }
    
    if (physicalAbilities.isNotEmpty) {
      physicalAvg = physicalAbilities.values.reduce((a, b) => a + b) / physicalAbilities.length;
    }
    
    return (technicalAvg + mentalAvg + physicalAvg) / 3;
  }

  void _calculateOverallRating() {
    final currentOverall = _calculateCurrentOverall();
    final talent = widget.player.talent;
    final age = widget.player.age;
    final growthRate = widget.player.growthRate;
    
    // 総合評価の計算（現在の能力 + 才能 + 成長率 + 年齢要因）
    double rating = currentOverall * 0.4 + 
                   (talent * 20) * 0.3 + 
                   (growthRate * 100) * 0.2 + 
                   ((100 - age) * 0.5) * 0.1;
    
    _overallRating = rating.clamp(0, 100);
  }

  void _updateOverallRating() {
    setState(() {
      _calculateOverallRating();
    });
  }

  Future<void> _submitReport() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final report = ScoutReport(
        playerName: widget.player.name,
        id: '',
        playerId: widget.player.id!.toString(),
        scoutId: widget.scoutId,
        scoutName: widget.scoutName,
        futurePotential: _futurePotential,
        updatedAt: DateTime.now(),
        isAnalysisComplete: true,
        expectedDraftPosition: _expectedDraftPosition,
        playerType: _playerType,
        positionSuitability: _positionSuitabilityController.text,
        strengths: _strengthsController.text,
        weaknesses: _weaknessesController.text,
        developmentPlan: _developmentPlanController.text,
        additionalNotes: _additionalNotesController.text,
        mentalStrength: _mentalStrength,
        injuryRisk: _injuryRisk,
        yearsToMLB: _yearsToMLB,
        overallRating: _overallRating ?? 0,
        createdAt: DateTime.now(),
      );
      
      // TODO: スカウトレポートの保存機能を実装
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('スカウトレポートを保存しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.player.name} - スカウトレポート'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _submitReport,
              child: const Text('保存'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PlayerInfoWidget(player: widget.player),
            BasicEvaluationWidget(
              player: widget.player,
              futurePotential: _futurePotential,
              expectedDraftPosition: _expectedDraftPosition,
              playerType: _playerType,
              overallRating: _overallRating,
            ),
            DetailedEvaluationWidget(
              player: widget.player,
              onMentalStrengthChanged: (value) {
                _mentalStrength = value;
                _updateOverallRating();
              },
              onInjuryRiskChanged: (value) {
                _injuryRisk = value;
                _updateOverallRating();
              },
              onYearsToMLBChanged: (value) {
                _yearsToMLB = value;
                _updateOverallRating();
              },
            ),
            CommentsWidget(
              positionSuitabilityController: _positionSuitabilityController,
              strengthsController: _strengthsController,
              weaknessesController: _weaknessesController,
              developmentPlanController: _developmentPlanController,
              additionalNotesController: _additionalNotesController,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}