import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'widgets/choice_card.dart';

class GenderStep extends StatelessWidget {
  final String? gender;
  final ValueChanged<String> onChanged;

  const GenderStep({super.key, this.gender, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your Gender', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'This will be used to calibrate your custom plan.',
            style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 32),
          ChoiceCard(
            text: 'Female',
            isSelected: gender == 'female',
            onTap: () => onChanged('female'),
          ),
          ChoiceCard(
            text: 'Male',
            isSelected: gender == 'male',
            onTap: () => onChanged('male'),
          ),
          ChoiceCard(
            text: 'Other',
            isSelected: gender == 'other',
            onTap: () => onChanged('other'),
          ),
        ],
      ),
    );
  }
}
