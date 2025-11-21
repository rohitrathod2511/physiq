import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/utils/design_system.dart';

class WaterStepsCard extends StatelessWidget {
  final Map<String, dynamic> dailySummary;

  const WaterStepsCard({super.key, required this.dailySummary});

  @override
  Widget build(BuildContext context) {
    // Extract data (mocked for now if not in summary)
    final int steps = (dailySummary['steps'] ?? 0).toInt();
    final int stepsGoal = (dailySummary['stepsGoal'] ?? 10000).toInt();
    final double stepsPercent = (steps / stepsGoal).clamp(0.0, 1.0);
    
    final int waterConsumed = (dailySummary['waterConsumed'] ?? 0).toInt(); // in fl oz or ml
    final int waterGoal = (dailySummary['waterGoal'] ?? 64).toInt();
    final double waterPercent = (waterConsumed / waterGoal).clamp(0.0, 1.0);

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
          // --- Top Section: Steps ---
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Steps Progress
                CircularPercentIndicator(
                  radius: 60.0,
                  lineWidth: 10.0,
                  animation: true,
                  percent: stepsPercent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_walk, color: AppColors.steps, size: 28),
                      const SizedBox(height: 4),
                      Text(
                        '$steps',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '/$stepsGoal',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: const Color(0xFFF3F4F6),
                  progressColor: AppColors.steps,
                ),
                
                // Steps Info
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Steps Today',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '0 kcal', // Placeholder calculation
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                     Text(
                      'Connect Health',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          // --- Divider ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
              color: Colors.grey.withOpacity(0.1),
              height: 1,
              thickness: 1,
            ),
          ),

          // --- Bottom Section: Water ---
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop, color: AppColors.water, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Water Intake',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$waterConsumed / $waterGoal fl oz',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Water Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: waterPercent,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.water),
                  ),
                ),
                const SizedBox(height: 20),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildWaterButton(Icons.remove, () {}),
                    const SizedBox(width: 24),
                    Text(
                      '8 fl oz',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildWaterButton(Icons.add, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: const Color(0xFF111827)),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
