import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/utils/design_system.dart';

class CalorieAndMacrosPage extends StatelessWidget {
  final Map<String, dynamic> dailySummary;

  const CalorieAndMacrosPage({super.key, required this.dailySummary});

  @override
  Widget build(BuildContext context) {
    // Extract data with safe defaults
    final int caloriesGoal = (dailySummary['caloriesGoal'] ?? 2000).toInt();
    final int caloriesConsumed = (dailySummary['caloriesConsumed'] ?? 0).toInt();
    
    final int caloriesLeft = (caloriesGoal - caloriesConsumed).clamp(0, 9999);
    final double caloriesPercent = (caloriesGoal > 0) ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0) : 0.0;

    // Macros
    final int carbsGoal = (dailySummary['carbsGoal'] ?? 100).toInt();
    final int carbsConsumed = (dailySummary['carbsConsumed'] ?? 0).toInt();
    final int carbsLeft = (carbsGoal - carbsConsumed).clamp(0, 999);
    final double carbsPercent = (carbsGoal > 0) ? (carbsConsumed / carbsGoal).clamp(0.0, 1.0) : 0.0;

    final int proteinGoal = (dailySummary['proteinGoal'] ?? 100).toInt();
    final int proteinConsumed = (dailySummary['proteinConsumed'] ?? 0).toInt();
    final int proteinLeft = (proteinGoal - proteinConsumed).clamp(0, 999);
    final double proteinPercent = (proteinGoal > 0) ? (proteinConsumed / proteinGoal).clamp(0.0, 1.0) : 0.0;

    final int fatGoal = (dailySummary['fatGoal'] ?? 50).toInt();
    final int fatConsumed = (dailySummary['fatConsumed'] ?? 0).toInt();
    final int fatLeft = (fatGoal - fatConsumed).clamp(0, 999);
    final double fatPercent = (fatGoal > 0) ? (fatConsumed / fatGoal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // --- Main Calorie Card ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.bigCard),
            boxShadow: [AppShadows.card],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$caloriesLeft',
                    style: AppTextStyles.largeNumber,
                  ),
                  Text(
                    'Calories left',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText),
                  ),
                ],
              ),
              CircularPercentIndicator(
                radius: 50.0, // 100 diameter
                lineWidth: 12.0,
                animation: true,
                percent: caloriesPercent,
                center: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.local_fire_department_rounded, color: AppColors.primaryText, size: 24),
                  ),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: const Color(0xFFF3F4F6),
                progressColor: Colors.grey.shade300, // Placeholder color, adjust if needed
                // To match the image exactly, the ring is greyish/white and maybe has a gradient or specific color.
                // The image shows a very light grey ring.
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- Macro Cards ---
        SizedBox(
          height: 160, // Adjust height as needed
          child: PageView(
            physics: const BouncingScrollPhysics(),
            children: [
              // Page 1: Main Macros
              Row(
                children: [
                  Expanded(
                    child: _buildVerticalMacroCard(
                      label: 'Protein',
                      leftValue: '${proteinLeft}g',
                      percent: proteinPercent,
                      icon: Icons.restaurant, // Placeholder icon
                      color: const Color(0xFFF87171), // Red/Pink
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVerticalMacroCard(
                      label: 'Carbs',
                      leftValue: '${carbsLeft}g',
                      percent: carbsPercent,
                      icon: Icons.grass, // Placeholder icon
                      color: const Color(0xFFFACC15), // Yellow
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVerticalMacroCard(
                      label: 'Fats',
                      leftValue: '${fatLeft}g',
                      percent: fatPercent,
                      icon: Icons.water_drop, // Placeholder icon
                      color: const Color(0xFF60A5FA), // Blue
                    ),
                  ),
                ],
              ),
              // Page 2: Micro Nutrients (Example)
              Row(
                children: [
                  Expanded(
                    child: _buildVerticalMacroCard(
                      label: 'Sodium',
                      leftValue: '${(dailySummary['sodiumConsumed'] ?? 0).toInt()}mg',
                      percent: 0.5,
                      icon: Icons.grain,
                      color: const Color(0xFFA78BFA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVerticalMacroCard(
                      label: 'Sugar',
                      leftValue: '${(dailySummary['sugarConsumed'] ?? 0).toInt()}g',
                      percent: 0.3,
                      icon: Icons.cake,
                      color: const Color(0xFFF472B6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVerticalMacroCard(
                      label: 'Fiber',
                      leftValue: '${(dailySummary['fiberConsumed'] ?? 0).toInt()}g',
                      percent: 0.7,
                      icon: Icons.eco,
                      color: const Color(0xFF34D399),
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

  Widget _buildVerticalMacroCard({
    required String label,
    required String leftValue,
    required double percent,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.smallCard),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftValue,
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                    ),
                    TextSpan(
                      text: ' left',
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: CircularPercentIndicator(
              radius: 30.0, // 60 diameter
              lineWidth: 6.0,
              animation: true,
              percent: percent,
              center: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: const Color(0xFFF3F4F6),
              progressColor: color.withOpacity(0.3), // Softer color for ring
            ),
          ),
        ],
      ),
    );
  }
}
