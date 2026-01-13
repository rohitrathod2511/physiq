import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/theme/design_system.dart';

class CalorieAndMacrosPage extends StatelessWidget {
  final Map<String, dynamic> dailySummary;

  const CalorieAndMacrosPage({super.key, required this.dailySummary});

  @override
  Widget build(BuildContext context) {
    // Extract data
    final int caloriesGoal = (dailySummary['caloriesGoal'] ?? 2000).toInt();
    final int caloriesConsumed = (dailySummary['caloriesConsumed'] ?? 0).toInt();
    final int caloriesBurned = (dailySummary['caloriesBurned'] ?? 0).toInt();

    final double caloriesPercent = (caloriesGoal > 0)
        ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0)
        : 0.0;

    // Macros
    final int carbsConsumed = (dailySummary['carbsConsumed'] ?? 0).toInt();
    final int proteinConsumed = (dailySummary['proteinConsumed'] ?? 0).toInt();
    final int fatConsumed = (dailySummary['fatConsumed'] ?? 0).toInt();

    return Column(
      children: [
        // Main Calorie Card
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Eaten
              _buildTopStat(
                label: 'EATEN',
                value: '$caloriesConsumed',
              ),

              // Center Ring
              CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 14.0,
                animation: true,
                percent: caloriesPercent,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: const Color(0xFFF3F4F6),
                progressColor: Colors.black, // or AppColors.primary
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "3000",
                      style: AppTextStyles.heading2.copyWith(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      "KCAL",
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText, fontSize: 14,  fontStyle: FontStyle.italic),
                    ),
                    Text(
                      "LEFT",
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText, fontSize: 14,  fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

              // Burned
              _buildTopStat(
                label: 'BURNED',
                value: '$caloriesBurned',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bottom Row: Macros
        SizedBox(
          height: 130, // Fixed height for macro cards
          child: Row(
            children: [
              Expanded(
                child: _buildMacroCard(
                  label: 'Protein',
                  consumed: proteinConsumed,
                  goal: 150,
                  color: const Color(0xFFFEE2E2), // Light Red/Pink
                  iconColor: const Color(0xFFEF4444), // Red
                  icon: Icons.restaurant_menu,
                  percent: _getMacroPercent(proteinConsumed, 150.0), 
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  label: 'Carbs',
                  consumed: carbsConsumed,
                  goal: 250,
                  color: const Color(0xFFFEF3C7), // Light Yellow
                  iconColor: const Color(0xFFF59E0B), // Amber
                  icon: Icons.wb_sunny_outlined,
                  percent: _getMacroPercent(carbsConsumed, 250.0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  label: 'Fats',
                  consumed: fatConsumed,
                  goal: 70,
                  color: const Color(0xFFDBEAFE), // Light Blue
                  iconColor: const Color(0xFF3B82F6), // Blue
                  icon: Icons.water_drop_outlined,
                  percent: _getMacroPercent(fatConsumed, 70.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getMacroPercent(dynamic consumed, double goal) {
    double val = (consumed ?? 0).toInt().toDouble();
    return (val / goal).clamp(0.0, 1.0);
  }

  Widget _buildTopStat({required String label, required String value}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.smallLabel.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required String label,
    required int consumed,
    required int goal,
    required Color color,
    required Color iconColor,
    required IconData icon,
    required double percent,
  }) {
    return Container(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            CircularPercentIndicator(
              radius: 32.0, 
              lineWidth: 6.0,
              animation: true,
              percent: percent,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: const Color(0xFFF3F4F6),
              progressColor: iconColor,
              center: Icon(icon, color: iconColor, size: 24),
            ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodyBold.copyWith(color: Colors.black, height: 1.0),
              children: [
                TextSpan(
                  text: '$consumed',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: ' / $goal',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.normal),
                ),
                const TextSpan(
                  text: 'g',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.smallLabel.copyWith(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

