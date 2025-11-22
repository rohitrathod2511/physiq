import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/utils/design_system.dart';

class ProgressRingCard extends StatelessWidget {
  final double percent; // 0.0 to 1.0

  const ProgressRingCard({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 10.0,
            percent: percent,
            center: Text(
              "${(percent * 100).toInt()}%",
              style: AppTextStyles.heading2,
            ),
            progressColor: AppColors.accent,
            backgroundColor: AppColors.background,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(height: 12),
          Text(
            "Towards Goal",
            style: AppTextStyles.smallLabel,
          ),
        ],
      ),
    );
  }
}
