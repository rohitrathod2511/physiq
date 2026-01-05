import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/theme/design_system.dart';

class CalorieAndMacrosPage extends StatelessWidget {
  final Map<String, dynamic> dailySummary;

  const CalorieAndMacrosPage({super.key, required this.dailySummary});

  @override
  Widget build(BuildContext context) {
    // Extract data with safe defaults
    final int caloriesGoal = (dailySummary['caloriesGoal'] ?? 2000).toInt();
    final int caloriesConsumed = (dailySummary['caloriesConsumed'] ?? 0).toInt();
    final int caloriesBurned = (dailySummary['caloriesBurned'] ?? 0).toInt();

    final int caloriesLeft = (caloriesGoal - caloriesConsumed + caloriesBurned).clamp(0, 9999);
    final double caloriesPercent = (caloriesGoal > 0) 
        ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0) 
        : 0.0;

    // Macros
    final int carbsGoal = (dailySummary['carbsGoal'] ?? 100).toInt();
    final int carbsConsumed = (dailySummary['carbsConsumed'] ?? 0).toInt();
    final double carbsPercent = (carbsGoal > 0) ? (carbsConsumed / carbsGoal).clamp(0.0, 1.0) : 0.0;

    final int proteinGoal = (dailySummary['proteinGoal'] ?? 100).toInt();
    final int proteinConsumed = (dailySummary['proteinConsumed'] ?? 0).toInt();
    final double proteinPercent = (proteinGoal > 0) ? (proteinConsumed / proteinGoal).clamp(0.0, 1.0) : 0.0;

    final int fatGoal = (dailySummary['fatGoal'] ?? 50).toInt();
    final int fatConsumed = (dailySummary['fatConsumed'] ?? 0).toInt();
    final double fatPercent = (fatGoal > 0) ? (fatConsumed / fatGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        // Use MainAxisAlignment.spaceEvenly to distribute vertical space if parent forces height
        mainAxisAlignment: MainAxisAlignment.spaceAround, 
        children: [
          // Top Row: Eaten - Ring - Burned
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Eaten
              _buildTopStat(
                label: 'Eaten',
                value: '$caloriesConsumed',
                icon: Icons.restaurant,
              ),

              // Center Ring
              CircularPercentIndicator(
                radius: 85.0, // Diameter 170
                lineWidth: 12.0,
                animation: true,
                percent: caloriesPercent,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: const Color(0xFFF3F4F6),
                progressColor: const Color(0xFF34D399), 
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$caloriesLeft',
                      style: AppTextStyles.heading1.copyWith(fontSize: 36), // Slightly larger font
                    ),
                    Text(
                      'Calories left',
                      style: AppTextStyles.smallLabel,
                    ),
                  ],
                ),
              ),

              // Burned
              _buildTopStat(
                label: 'Burned',
                value: '$caloriesBurned',
                icon: Icons.local_fire_department,
              ),
            ],
          ),

          const SizedBox(height: 16), 

          // Bottom Row: Macros
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildCircularMacro(
                  label: 'Carbs',
                  value: '${carbsConsumed}g',
                  percent: carbsPercent,
                  color: const Color(0xFFFACC15), // Yellow
                ),
                _buildCircularMacro(
                  label: 'Protein',
                  value: '${proteinConsumed}g',
                  percent: proteinPercent,
                  color: const Color(0xFFF87171), // Red
                ),
                _buildCircularMacro(
                  label: 'Fat',
                  value: '${fatConsumed}g',
                  percent: fatPercent,
                  color: const Color(0xFF60A5FA), // Blue
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStat({required String label, required String value, required IconData icon}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: AppColors.primaryText),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading2,
        ),
        Text(
          label,
          style: AppTextStyles.smallLabel,
        ),
      ],
    );
  }

  Widget _buildCircularMacro({
    required String label,
    required String value,
    required double percent,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularPercentIndicator(
          radius: 36.0, // Diameter 72
          lineWidth: 6.0, // Slightly thicker
          animation: true,
          percent: percent,
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: color.withOpacity(0.1),
          progressColor: color,
          center: Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.smallLabel,
        ),
      ],
    );
  }
}

