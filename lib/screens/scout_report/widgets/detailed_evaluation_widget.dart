import 'package:flutter/material.dart';
import '../../../models/player/player.dart' hide PlayerType;

/// 詳細評価ウィジェット
class DetailedEvaluationWidget extends StatefulWidget {
  final Player player;
  final Function(double) onMentalStrengthChanged;
  final Function(double) onInjuryRiskChanged;
  final Function(int) onYearsToMLBChanged;

  const DetailedEvaluationWidget({
    Key? key,
    required this.player,
    required this.onMentalStrengthChanged,
    required this.onInjuryRiskChanged,
    required this.onYearsToMLBChanged,
  }) : super(key: key);

  @override
  State<DetailedEvaluationWidget> createState() => _DetailedEvaluationWidgetState();
}

class _DetailedEvaluationWidgetState extends State<DetailedEvaluationWidget> {
  late double _mentalStrength;
  late double _injuryRisk;
  late int _yearsToMLB;

  @override
  void initState() {
    super.initState();
    _mentalStrength = _calculateMentalStrength();
    _injuryRisk = _calculateInjuryRisk();
    _yearsToMLB = _calculateYearsToMLB();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '詳細評価',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              'メンタル強度',
              _mentalStrength,
              0.0,
              100.0,
              (value) {
                setState(() {
                  _mentalStrength = value;
                });
                widget.onMentalStrengthChanged(value);
              },
              () => _mentalStrengthText,
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              '怪我リスク',
              _injuryRisk,
              0.0,
              100.0,
              (value) {
                setState(() {
                  _injuryRisk = value;
                });
                widget.onInjuryRiskChanged(value);
              },
              () => _injuryRiskText,
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              'MLB到達年数',
              _yearsToMLB.toDouble(),
              1.0,
              10.0,
              (value) {
                setState(() {
                  _yearsToMLB = value.round();
                });
                widget.onYearsToMLBChanged(_yearsToMLB);
              },
              () => _yearsToMLBText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderField(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String Function() getText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              getText(),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  double _calculateMentalStrength() {
    // メンタル能力の平均を計算
    final mentalAbilities = widget.player.mentalAbilities;
    if (mentalAbilities.isEmpty) return 50.0;
    
    final total = mentalAbilities.values.reduce((a, b) => a + b);
    return total / mentalAbilities.length;
  }

  double _calculateInjuryRisk() {
    // 怪我しやすさを計算（低い方が良い）
    final injuryProneness = widget.player.physicalAbilities['injuryProneness'] ?? 50;
    return 100 - injuryProneness.toDouble();
  }

  int _calculateYearsToMLB() {
    // 才能ランクと年齢に基づいて計算
    final talent = widget.player.talent;
    final age = widget.player.age;
    
    int baseYears = 5; // 基本年数
    
    // 才能ランクによる調整
    baseYears -= (talent - 3) * 2; // 才能ランク3を基準
    
    // 年齢による調整
    if (age >= 18) {
      baseYears -= (age - 18) ~/ 2; // 年齢が高いほど短縮
    }
    
    return baseYears.clamp(1, 10);
  }

  String get _mentalStrengthText {
    if (_mentalStrength >= 80) return '非常に強い';
    if (_mentalStrength >= 60) return '強い';
    if (_mentalStrength >= 40) return '普通';
    if (_mentalStrength >= 20) return '弱い';
    return '非常に弱い';
  }

  String get _injuryRiskText {
    if (_injuryRisk >= 80) return '非常に高い';
    if (_injuryRisk >= 60) return '高い';
    if (_injuryRisk >= 40) return '普通';
    if (_injuryRisk >= 20) return '低い';
    return '非常に低い';
  }

  String get _yearsToMLBText {
    return '${_yearsToMLB}年後';
  }
}
