import 'package:flutter/material.dart';
import 'package:physiq/utils/design_system.dart';

class WeightGoalCard extends StatelessWidget {
  final double currentWeight;
  final double goalWeight;
  final VoidCallback onTap;

  const WeightGoalCard({
    super.key,
    required this.currentWeight,
    required this.goalWeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [AppShadows.card],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Weight', style: AppTextStyles.smallLabel),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currentWeight.toStringAsFixed(1),
                  style: AppTextStyles.heading1.copyWith(fontSize: 32),
                ),
                const SizedBox(width: 4),
                Text('kg', style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Goal: ${goalWeight.toStringAsFixed(1)} kg',
              style: AppTextStyles.bodyMedium?.copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
