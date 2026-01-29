import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/theme/design_system.dart';
import 'dart:math' as math;

class CalorieAndMacrosPage extends StatelessWidget {
  final Map<String, dynamic> dailySummary;
  final Map<String, dynamic>? currentPlan;

  const CalorieAndMacrosPage({
    super.key,
    required this.dailySummary,
    this.currentPlan,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data
    final int caloriesGoal = (currentPlan?['calories'] ?? dailySummary['caloriesGoal'] ?? 2000).toInt();
    final int caloriesConsumed = (dailySummary['caloriesConsumed'] ?? dailySummary['calories'] ?? 0).toInt();
    final int caloriesBurned = (dailySummary['caloriesBurned'] ?? 0).toInt();

    final double caloriesPercent = (caloriesGoal > 0)
        ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0)
        : 0.0;

    // Macros
    final int carbsConsumed = (dailySummary['carbsConsumed'] ?? dailySummary['carbs'] ?? 0).toInt();
    final int proteinConsumed = (dailySummary['proteinConsumed'] ?? dailySummary['protein'] ?? 0).toInt();
    final int fatConsumed = (dailySummary['fatConsumed'] ?? dailySummary['fat'] ?? 0).toInt();
    
    final int proteinGoal = (currentPlan?['protein'] ?? 150).toInt();
    final int carbsGoal = (currentPlan?['carbs'] ?? 250).toInt();
    final int fatGoal = (currentPlan?['fat'] ?? 70).toInt();

    return Column(
      children: [
        // Main Calorie Card
        Container(
          height: 220,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.card,
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
                      "${math.max(0, caloriesGoal - caloriesConsumed)}",
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
                  goal: proteinGoal,
                  color: const Color(0xFFFEE2E2), 
                  iconColor: const Color(0xFFEF4444), 
                  centerWidget: const Text('🍗', style: TextStyle(fontSize: 24)),
                  percent: _getMacroPercent(proteinConsumed, proteinGoal.toDouble()), 
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  label: 'Carbs',
                  consumed: carbsConsumed,
                  goal: carbsGoal,
                  color: const Color(0xFFFEF3C7), 
                  iconColor: const Color(0xFFF59E0B), 
                  centerWidget: const Text('🌾', style: TextStyle(fontSize: 24)),
                  percent: _getMacroPercent(carbsConsumed, carbsGoal.toDouble()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroCard(
                  label: 'Fats',
                  consumed: fatConsumed,
                  goal: fatGoal,
                  color: const Color(0xFFDBEAFE), 
                  iconColor: const Color(0xFF3B82F6), 
                  centerWidget: const Text('🥑', style: TextStyle(fontSize: 24)),
                  percent: _getMacroPercent(fatConsumed, fatGoal.toDouble()),
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
    required Widget centerWidget,
    required double percent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
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
              center: centerWidget,
            ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.primaryText, height: 1.0),
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

