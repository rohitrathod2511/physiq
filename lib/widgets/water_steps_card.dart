import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/utils/design_system.dart';

class WaterStepsCard extends StatelessWidget {
  final Map<String, dynamic> dailySummary;

  const WaterStepsCard({super.key, required this.dailySummary});

  @override
  Widget build(BuildContext context) {
    // Extract data
    final int steps = (dailySummary['steps'] ?? 0).toInt();
    final int stepsGoal = (dailySummary['stepsGoal'] ?? 10000).toInt();
    final double stepsPercent = (stepsGoal > 0) ? (steps / stepsGoal).clamp(0.0, 1.0) : 0.0;

    final int waterConsumed = (dailySummary['waterConsumed'] ?? 0).toInt(); // in fl oz
    final int waterGoal = (dailySummary['waterGoal'] ?? 64).toInt();
    final double waterPercent = (waterGoal > 0) ? (waterConsumed / waterGoal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // Top Card: Steps (Matches Calorie Card 220px)
        Container(
          height: 220,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               CircularPercentIndicator(
                  radius: 75.0,
                  lineWidth: 12.0,
                  animation: true,
                  percent: stepsPercent,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: const Color(0xFFF3F4F6),
                  progressColor: AppColors.steps,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       const Icon(Icons.directions_walk, color: AppColors.steps, size: 28),
                       const SizedBox(height: 4),
                       Text(
                        '$steps',
                        style: AppTextStyles.heading1.copyWith(fontSize: 32),
                      ),
                       Text(
                        'Steps',
                        style: AppTextStyles.smallLabel,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bottom Card: Water (Matches Macro Row 130px)
        Container(
          height: 130,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Water Icon & Label
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.water.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.water_drop, color: AppColors.water, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Water',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                  ),
                  Text(
                    '$waterConsumed / $waterGoal fl oz',
                    style: AppTextStyles.smallLabel.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
              const Spacer(),
              // Water Controls and Progress
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _buildWaterButton(Icons.remove, () {}),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('8 oz', style: AppTextStyles.bodyBold),
                      ),
                      _buildWaterButton(Icons.add, () {}),
                    ],
                  ),
                  const SizedBox(height: 16),
                   SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: waterPercent,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.water),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaterButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: const Color(0xFF111827)),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
