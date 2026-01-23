import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class BmiCard extends StatelessWidget {
  final double bmi;
  final String category;

  const BmiCard({super.key, required this.bmi, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. DECREASED SIZE: Reduced vertical padding to make the card less bulky.
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BMI', style: AppTextStyles.heading2),
              IconButton(
                icon: Icon(Icons.help_outline, color: AppColors.secondaryText),
                onPressed: () {
                  // Show info dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      title: Text('BMI Categories', style: AppTextStyles.heading2),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBmiRow('Underweight', '< 18.5', Colors.blue),
                          _buildBmiRow('Healthy', '18.5 - 24.9', Colors.green),
                          _buildBmiRow('Overweight', '25 - 29.9', Colors.orange),
                          _buildBmiRow('Obese', '30+', Colors.red),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: AppTextStyles.button,
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          // 2. ADJUSTED SPACING: Reduced the SizedBox height from 16 to 8.
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(bmi.toStringAsFixed(1), style: AppTextStyles.heading1.copyWith(fontSize: 38)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: AppTextStyles.bodyBold.copyWith(color: _getCategoryColor(category)),
                ),
              ),
            ],
          ),
          // Reduced spacing before the indicator.
          const SizedBox(height: 16),
          _buildVisualIndicator(),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Underweight': return Colors.blue;
      case 'Healthy': return Colors.green;
      case 'Overweight': return Colors.orange;
      case 'Obese': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildVisualIndicator() {
    // Helper to create the text labels
    Widget _buildLabel(String text, int flex, Color color) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.smallLabel.copyWith(color: color, fontSize: 9),
        ),
      );
    }

    return Column(
      children: [
        // The colored bar
        // The colored bar with indicator
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // BMI Scale: Starts ~0 (or lower bound?) let's assume 0-40 for mapped range.
            // Underweight: < 18.5
            // Healthy: 18.5 - 24.9
            // Overweight: 25 - 29.9
            // Obese: 30+
            // The flux values (18, 7, 5, 10) imply a total of 40 units roughly matching the BMI scale.
            
            // Calculate position
            final double maxBmi = 40.0;
            final double position = (bmi.clamp(0, maxBmi) / maxBmi) * width;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4), // Rounded corners for the bar
                  child: Row(
                    children: [
                      Expanded(flex: 18, child: Container(height: 8, color: Colors.blue)),
                      Expanded(flex: 7, child: Container(height: 8, color: Colors.green)),
                      Expanded(flex: 5, child: Container(height: 8, color: Colors.orange)),
                      Expanded(flex: 10, child: Container(height: 8, color: Colors.red)),
                    ],
                  ),
                ),
                Positioned(
                  left: position - 1, // Center the 2px marker
                  top: -2,
                  bottom: -2,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: AppColors.primaryText,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        // 3. ADDED LABELS: New Row with text labels below the bar.
        Row(
          children: [
            _buildLabel('Underweight', 18, Colors.blue),
            _buildLabel('Healthy', 7, Colors.green),
            _buildLabel('Overweight', 5, Colors.orange),
            _buildLabel('Obese', 10, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildBmiRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.bodyMedium),
            ],
          ),
          Text(range, style: AppTextStyles.body.copyWith(fontFamily: 'Inter')),
        ],
      ),
    );
  }
}
