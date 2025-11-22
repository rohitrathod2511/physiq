import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'widgets/choice_card.dart';

class GoalStep extends StatelessWidget {
  final String? goal;
  final ValueChanged<String> onChanged;

  const GoalStep({super.key, this.goal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is Your Goal?', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'We will calculate your calories based on this.',
            style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 32),
          ChoiceCard(
            text: 'Lose Weight',
            isSelected: goal == 'lose',
            onTap: () => onChanged('lose'),
          ),
          ChoiceCard(
            text: 'Maintain Weight',
            isSelected: goal == 'maintain',
            onTap: () => onChanged('maintain'),
          ),
          ChoiceCard(
            text: 'Gain Weight',
            isSelected: goal == 'gain',
            onTap: () => onChanged('gain'),
          ),
        ],
      ),
    );
  }
}
