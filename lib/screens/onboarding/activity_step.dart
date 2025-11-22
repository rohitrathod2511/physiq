import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'widgets/choice_card.dart';

class ActivityStep extends StatelessWidget {
  final double? activityLevel;
  final ValueChanged<double> onChanged;

  const ActivityStep({super.key, this.activityLevel, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity & Lifestyle', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'How active are you on a daily basis?',
            style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ChoiceCard(
                    text: 'Sedentary',
                    subtitle: 'Little or no exercise',
                    isSelected: activityLevel == 1.2,
                    onTap: () => onChanged(1.2),
                  ),
                  ChoiceCard(
                    text: 'Lightly Active',
                    subtitle: 'Light exercise 1-3 days/week',
                    isSelected: activityLevel == 1.375,
                    onTap: () => onChanged(1.375),
                  ),
                  ChoiceCard(
                    text: 'Moderately Active',
                    subtitle: 'Moderate exercise 3-5 days/week',
                    isSelected: activityLevel == 1.55,
                    onTap: () => onChanged(1.55),
                  ),
                  ChoiceCard(
                    text: 'Very Active',
                    subtitle: 'Hard exercise 6-7 days/week',
                    isSelected: activityLevel == 1.725,
                    onTap: () => onChanged(1.725),
                  ),
                  ChoiceCard(
                    text: 'Athletic',
                    subtitle: 'Physical job or 2x training',
                    isSelected: activityLevel == 1.9,
                    onTap: () => onChanged(1.9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
