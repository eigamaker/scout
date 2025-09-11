import 'package:flutter/material.dart';

/// コメント入力ウィジェット
class CommentsWidget extends StatelessWidget {
  final TextEditingController positionSuitabilityController;
  final TextEditingController strengthsController;
  final TextEditingController weaknessesController;
  final TextEditingController developmentPlanController;
  final TextEditingController additionalNotesController;

  const CommentsWidget({
    Key? key,
    required this.positionSuitabilityController,
    required this.strengthsController,
    required this.weaknessesController,
    required this.developmentPlanController,
    required this.additionalNotesController,
  }) : super(key: key);

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
              'コメント',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: positionSuitabilityController,
              label: 'ポジション適性',
              hint: '選手のポジション適性について記述してください',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: strengthsController,
              label: '強み',
              hint: '選手の強みや長所について記述してください',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: weaknessesController,
              label: '課題',
              hint: '選手の課題や改善点について記述してください',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: developmentPlanController,
              label: '育成計画',
              hint: '選手の育成計画や成長のポイントについて記述してください',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: additionalNotesController,
              label: 'その他のコメント',
              hint: 'その他の特記事項があれば記述してください',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12.0),
          ),
        ),
      ],
    );
  }
}
