import 'package:flutter/material.dart';
import 'package:scout_game/models/player/player.dart' hide PlayerType;
import 'package:scout_game/models/scouting/scout_report.dart';
import 'package:scout_game/services/scouting/scouting_service.dart';

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
    // 分析結果から初期値を設定
    _futurePotential = FuturePotential.C;
    _expectedDraftPosition = ExpectedDraftPosition.third;
    _playerType = _determinePlayerType();
    
    // 適性ポジションの初期値
    _positionSuitabilityController.text = _getDefaultPositionSuitability();
    
    // 精神力と怪我リスクの初期値（分析結果から算出）
    _mentalStrength = _calculateMentalStrength();
    _injuryRisk = _calculateInjuryRisk();
    
    // メジャー到達年数の初期値
    _yearsToMLB = _calculateYearsToMLB();
  }

  PlayerType _determinePlayerType() {
    if (widget.player.position.contains('投手')) {
      // 投手の場合、能力値から判断
      final pitching = widget.player.scoutAnalysisData?['投球'] ?? 50;
      final control = widget.player.scoutAnalysisData?['制球'] ?? 50;
      final stamina = widget.player.scoutAnalysisData?['スタミナ'] ?? 50;
      
      if (stamina >= 70 && control >= 60) {
        return PlayerType.startingPitcher;
      } else if (pitching >= 70) {
        return PlayerType.closer;
      } else {
        return PlayerType.reliefPitcher;
      }
    } else {
      // 野手の場合、能力値から判断
      final power = widget.player.scoutAnalysisData?['パワー'] ?? 50;
      final contact = widget.player.scoutAnalysisData?['コンタクト'] ?? 50;
      final speed = widget.player.scoutAnalysisData?['走力'] ?? 50;
      final fielding = widget.player.scoutAnalysisData?['守備'] ?? 50;
      
      if (power >= 70) {
        return PlayerType.powerHitter;
      } else if (contact >= 70) {
        return PlayerType.contactHitter;
      } else if (speed >= 70) {
        return PlayerType.speedster;
      } else if (fielding >= 70) {
        return PlayerType.defensiveSpecialist;
      } else {
        return PlayerType.utilityPlayer;
      }
    }
  }

  String _getDefaultPositionSuitability() {
    if (widget.player.position.contains('投手')) {
      return '投手としての適性が高い';
    } else if (widget.player.position.contains('捕手')) {
      return '捕手としての適性が高い';
    } else if (widget.player.position.contains('内野手')) {
      return '内野手としての適性が高い';
    } else if (widget.player.position.contains('外野手')) {
      return '外野手としての適性が高い';
    }
    return '複数ポジションに対応可能';
  }

  double _calculateMentalStrength() {
    // インタビュー結果から精神力を算出
    final interviewData = widget.player.scoutAnalysisData;
    if (interviewData == null) return 50.0;
    
    double mentalScore = 50.0;
    
    // 各項目の重み付け
    if (interviewData.containsKey('リーダーシップ')) {
      mentalScore += (interviewData['リーダーシップ']! - 50) * 0.3;
    }
    if (interviewData.containsKey('メンタル強度')) {
      mentalScore += (interviewData['メンタル強度']! - 50) * 0.4;
    }
    if (interviewData.containsKey('練習熱心度')) {
      mentalScore += (interviewData['練習熱心度']! - 50) * 0.3;
    }
    
    return mentalScore.clamp(0.0, 100.0);
  }

  double _calculateInjuryRisk() {
    // フィジカル分析結果から怪我リスクを算出
    final physicalData = widget.player.scoutAnalysisData;
    if (physicalData == null) return 50.0;
    
    double riskScore = 50.0;
    
    // 各項目の重み付け（数値が低いほどリスクが高い）
    if (physicalData.containsKey('耐久性')) {
      riskScore += (50 - physicalData['耐久性']!) * 0.4;
    }
    if (physicalData.containsKey('柔軟性')) {
      riskScore += (50 - physicalData['柔軟性']!) * 0.3;
    }
    if (physicalData.containsKey('バランス')) {
      riskScore += (50 - physicalData['バランス']!) * 0.3;
    }
    
    return riskScore.clamp(0.0, 100.0);
  }

  int _calculateYearsToMLB() {
    // 成長率と現在の能力から到達年数を算出
    final growthRate = widget.player.growthRate ?? 1.0;
    final currentOverall = _calculateCurrentOverall();
    
    // 基本到達年数（現在の能力から）
    int baseYears = 8;
    if (currentOverall >= 80) baseYears = 2;
    else if (currentOverall >= 70) baseYears = 4;
    else if (currentOverall >= 60) baseYears = 6;
    
    // 成長率による補正
    if (growthRate >= 1.5) baseYears = (baseYears * 0.7).round();
    else if (growthRate >= 1.2) baseYears = (baseYears * 0.8).round();
    else if (growthRate <= 0.8) baseYears = (baseYears * 1.3).round();
    else if (growthRate <= 0.6) baseYears = (baseYears * 1.5).round();
    
    return baseYears.clamp(1, 10);
  }

  double _calculateCurrentOverall() {
    final data = widget.player.scoutAnalysisData;
    if (data == null) return 50.0;
    
    if (widget.player.position.contains('投手')) {
      final pitching = data['投球'] ?? 50;
      final control = data['制球'] ?? 50;
      final stamina = data['スタミナ'] ?? 50;
      return (pitching + control + stamina) / 3.0;
    } else {
      final contact = data['コンタクト'] ?? 50;
      final power = data['パワー'] ?? 50;
      final speed = data['走力'] ?? 50;
      final fielding = data['守備'] ?? 50;
      return (contact + power + speed + fielding) / 4.0;
    }
  }

  void _calculateOverallRating() {
    final currentOverall = _calculateCurrentOverall();
    final mentalBonus = (_mentalStrength - 50) * 0.1;
    final injuryPenalty = (_injuryRisk - 50) * 0.05;
    
    _overallRating = (currentOverall + mentalBonus - injuryPenalty).clamp(0.0, 100.0);
  }

  void _updateOverallRating() {
    setState(() {
      _calculateOverallRating();
    });
  }

  String get _mentalStrengthText {
    if (_mentalStrength >= 80) return '非常に高い';
    if (_mentalStrength >= 60) return '高い';
    if (_mentalStrength >= 40) return '普通';
    if (_mentalStrength >= 20) return 'やや低い';
    return '低い';
  }

  String get _injuryRiskText {
    if (_injuryRisk <= 20) return '低い';
    if (_injuryRisk <= 40) return 'やや低い';
    if (_injuryRisk <= 60) return '普通';
    if (_injuryRisk <= 80) return 'やや高い';
    return '高い';
  }

  String get _yearsToMLBText {
    if (_yearsToMLB <= 2) return '2年以内';
    if (_yearsToMLB <= 4) return '3-4年';
    if (_yearsToMLB <= 6) return '5-6年';
    if (_yearsToMLB <= 8) return '7-8年';
    return '8年以上';
  }

  Future<void> _submitReport() async {
    if (_overallRating == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final report = ScoutReport(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        playerId: widget.player.id?.toString() ?? '',
        playerName: widget.player.name,
        scoutId: widget.scoutId,
        scoutName: widget.scoutName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        futurePotential: _futurePotential,
        overallRating: _overallRating!,
        expectedDraftPosition: _expectedDraftPosition,
        playerType: _playerType,
        positionSuitability: _positionSuitabilityController.text,
        mentalStrength: _mentalStrength,
        injuryRisk: _injuryRisk,
        yearsToMLB: _yearsToMLB,
        strengths: _strengthsController.text,
        weaknesses: _weaknessesController.text,
        developmentPlan: _developmentPlanController.text,
        additionalNotes: _additionalNotesController.text,
        isAnalysisComplete: true,
      );
      
      // レポートを球団に送信
      await ScoutingService.submitReportToTeam(report);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('スカウトレポートを球団に送信しました')),
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
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlayerInfo(),
                  const SizedBox(height: 24),
                  _buildBasicEvaluation(),
                  const SizedBox(height: 24),
                  _buildDetailedEvaluation(),
                  const SizedBox(height: 24),
                  _buildComments(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildPlayerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '選手情報',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('名前: ${widget.player.name}'),
                      Text('学年: ${widget.player.grade}年'),
                      Text('ポジション: ${widget.player.position}'),
                    ],
                  ),
                ),
                if (_overallRating != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '総合評価: ${_overallRating!.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicEvaluation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本評価',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // 将来性評価
            _buildDropdownField(
              label: '将来性評価',
              value: _futurePotential,
              items: FuturePotential.values,
              onChanged: (value) {
                setState(() {
                  _futurePotential = value!;
                });
              },
              itemBuilder: (value) => Text(_getFuturePotentialText(value)),
            ),
            
            const SizedBox(height: 16),
            
            // 想定ドラフト順位
            _buildDropdownField(
              label: '想定ドラフト順位',
              value: _expectedDraftPosition,
              items: ExpectedDraftPosition.values,
              onChanged: (value) {
                setState(() {
                  _expectedDraftPosition = value!;
                });
              },
              itemBuilder: (value) => Text(_getExpectedDraftPositionText(value)),
            ),
            
            const SizedBox(height: 16),
            
            // 選手タイプ
            _buildDropdownField(
              label: '選手タイプ',
              value: _playerType,
              items: PlayerType.values,
              onChanged: (value) {
                setState(() {
                  _playerType = value!;
                });
              },
              itemBuilder: (value) => Text(_getPlayerTypeText(value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedEvaluation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '詳細評価',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // 適性ポジション
            _buildTextField(
              label: '適性ポジション',
              controller: _positionSuitabilityController,
              hintText: '選手の適性ポジションについて記入してください',
            ),
            
            const SizedBox(height: 16),
            
            // 精神力
            _buildSliderField(
              label: '精神力',
              value: _mentalStrength,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _mentalStrength = value;
                  _updateOverallRating();
                });
              },
              valueText: _mentalStrengthText,
            ),
            
            const SizedBox(height: 16),
            
            // 怪我リスク
            _buildSliderField(
              label: '怪我リスク',
              value: _injuryRisk,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _injuryRisk = value;
                  _updateOverallRating();
                });
              },
              valueText: _injuryRiskText,
            ),
            
            const SizedBox(height: 16),
            
            // メジャー到達年数
            _buildSliderField(
              label: 'メジャー到達年数',
              value: _yearsToMLB.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _yearsToMLB = value.round();
                });
              },
              valueText: _yearsToMLBText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'コメント',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              label: '長所',
              controller: _strengthsController,
              hintText: '選手の長所について記入してください',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              label: '短所',
              controller: _weaknessesController,
              hintText: '選手の短所について記入してください',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              label: '育成方針',
              controller: _developmentPlanController,
              hintText: '選手の育成方針について記入してください',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              label: 'その他特記事項',
              controller: _additionalNotesController,
              hintText: 'その他特記事項があれば記入してください',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: itemBuilder(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Colors.blue[600],
          inactiveColor: Colors.grey[300],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(min.toStringAsFixed(0)),
            Text(max.toStringAsFixed(0)),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                '球団にレポートを送信',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _getFuturePotentialText(FuturePotential potential) {
    switch (potential) {
      case FuturePotential.A:
        return 'A - 将来性抜群';
      case FuturePotential.B:
        return 'B - 高く期待できる';
      case FuturePotential.C:
        return 'C - 一定の期待値';
      case FuturePotential.D:
        return 'D - 限定的な期待値';
      case FuturePotential.E:
        return 'E - 期待値低い';
    }
  }

  String _getExpectedDraftPositionText(ExpectedDraftPosition position) {
    switch (position) {
      case ExpectedDraftPosition.first:
        return '1位';
      case ExpectedDraftPosition.second:
        return '2位';
      case ExpectedDraftPosition.third:
        return '3位';
      case ExpectedDraftPosition.fourth:
        return '4位';
      case ExpectedDraftPosition.fifth:
        return '5位';
      case ExpectedDraftPosition.sixthOrLater:
        return '6位以下';
    }
  }

  String _getPlayerTypeText(PlayerType type) {
    switch (type) {
      case PlayerType.startingPitcher:
        return '先発投手';
      case PlayerType.reliefPitcher:
        return '中継ぎ投手';
      case PlayerType.closer:
        return '抑え投手';
      case PlayerType.utilityPitcher:
        return 'ユーティリティ投手';
      case PlayerType.powerHitter:
        return '長距離打者';
      case PlayerType.contactHitter:
        return '巧打者';
      case PlayerType.speedster:
        return '俊足野手';
      case PlayerType.defensiveSpecialist:
        return '守備専門';
      case PlayerType.utilityPlayer:
        return 'ユーティリティ野手';
    }
  }
}
