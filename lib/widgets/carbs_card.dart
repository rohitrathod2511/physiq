import 'package:flutter/material.dart';
import 'package:physiq/utils/design_system.dart';

class CarbsCard extends StatelessWidget {
  final Map<String, dynamic> dailySummary;

  const CarbsCard({super.key, required this.dailySummary});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.smallCard),
          boxShadow: [AppShadows.card],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('151g', style: AppTextStyles.nutrientValue),
                Text('Carbs left', style: AppTextStyles.label),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: const Center(child: Text('🌾', style: TextStyle(fontSize: 18))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
