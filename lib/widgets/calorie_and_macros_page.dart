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
    final int caloriesBurned = (dailySummary['caloriesBurned'] ?? 0).toInt();
    
    final int caloriesLeft = (caloriesGoal - caloriesConsumed).clamp(0, 9999);
    final double caloriesPercent = (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0);

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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // --- Top Section: Calories ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Changed to center
            children: [
              // Eaten (Left)
              _buildSideStat(
                icon: Icons.restaurant_menu,
                value: caloriesConsumed.toString(),
                label: 'Eaten',
              ),

              const SizedBox(width: 24), // Added spacing

              // Center Circular Indicator
              CircularPercentIndicator(
                radius: 75.0,
                lineWidth: 12.0,
                animation: true,
                percent: caloriesPercent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$caloriesLeft',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calories left',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: const Color(0xFFF3F4F6),
                progressColor: const Color(0xFF4ADE80), // Bright Green
              ),

              const SizedBox(width: 24), // Added spacing

              // Burned (Right)
              _buildSideStat(
                icon: Icons.local_fire_department_rounded,
                value: caloriesBurned.toString(),
                label: 'Burned',
              ),
            ],
          ),

          // --- Divider Removed ---


          // --- Bottom Section: Macros ---
          SizedBox(
            height: 100,
            child: PageView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Page 1: Main Macros
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroItem(
                      label: 'Carbs',
                      value: '${carbsConsumed}g',
                      percent: carbsPercent,
                      color: const Color(0xFF60A5FA), // Blue
                    ),
                    _buildMacroItem(
                      label: 'Protein',
                      value: '${proteinConsumed}g',
                      percent: proteinPercent,
                      color: const Color(0xFFF87171), // Red/Pink
                    ),
                    _buildMacroItem(
                      label: 'Fat',
                      value: '${fatConsumed}g',
                      percent: fatPercent,
                      color: const Color(0xFFFACC15), // Yellow
                    ),
                  ],
                ),
                // Page 2: Micro Nutrients
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroItem(
                      label: 'Sodium',
                      value: '${(dailySummary['sodiumConsumed'] ?? 0).toInt()}mg',
                      percent: ((dailySummary['sodiumConsumed'] ?? 0) / (dailySummary['sodiumGoal'] ?? 2300)).clamp(0.0, 1.0),
                      color: const Color(0xFFA78BFA), // Purple
                    ),
                    _buildMacroItem(
                      label: 'Sugar',
                      value: '${(dailySummary['sugarConsumed'] ?? 0).toInt()}g',
                      percent: ((dailySummary['sugarConsumed'] ?? 0) / (dailySummary['sugarGoal'] ?? 50)).clamp(0.0, 1.0),
                      color: const Color(0xFFF472B6), // Pink
                    ),
                    _buildMacroItem(
                      label: 'Fiber',
                      value: '${(dailySummary['fiberConsumed'] ?? 0).toInt()}g',
                      percent: ((dailySummary['fiberConsumed'] ?? 0) / (dailySummary['fiberGoal'] ?? 30)).clamp(0.0, 1.0),
                      color: const Color(0xFF34D399), // Emerald
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideStat({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF374151), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem({
    required String label,
    required String value,
    required double percent,
    required Color color,
  }) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 26.0,
          lineWidth: 4.5,
          animation: true,
          percent: percent,
          center: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: const Color(0xFFF3F4F6),
          progressColor: color,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
