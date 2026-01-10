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
                radius: 75.0,
                lineWidth: 12.0,
                animation: true,
                percent: caloriesPercent,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: const Color(0xFFF3F4F6),
                progressColor: Colors.black, // or AppColors.primary
                center: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_fire_department, color: Colors.black, size: 28),
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
                  value: '${proteinConsumed}g',
                  color: const Color(0xFFFEE2E2), // Light Red/Pink
                  iconColor: const Color(0xFFEF4444), // Red
                  icon: Icons.restaurant_menu,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  label: 'Carbs',
                  value: '${carbsConsumed}g',
                  color: const Color(0xFFFEF3C7), // Light Yellow
                  iconColor: const Color(0xFFF59E0B), // Amber
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  label: 'Fats',
                  value: '${fatConsumed}g',
                  color: const Color(0xFFDBEAFE), // Light Blue
                  iconColor: const Color(0xFF3B82F6), // Blue
                  icon: Icons.water_drop_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    required String value,
    required Color color,
    required Color iconColor,
    required IconData icon,
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
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

