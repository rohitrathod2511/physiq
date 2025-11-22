import 'package:flutter/material.dart';
import 'package:physiq/utils/design_system.dart';

class BmiCard extends StatelessWidget {
  final double bmi;
  final String category;

  const BmiCard({super.key, required this.bmi, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                icon: const Icon(Icons.help_outline, color: AppColors.secondaryText),
                onPressed: () {
                  // Show info dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('BMI Categories'),
                      content: const Text(
                        'Underweight: < 18.5\nHealthy: 18.5 - 24.9\nOverweight: 25 - 29.9\nObese: 30+',
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(bmi.toStringAsFixed(1), style: AppTextStyles.heading1.copyWith(fontSize: 48)),
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
          const SizedBox(height: 24),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 18, child: Container(height: 8, color: Colors.blue)),
            Expanded(flex: 7, child: Container(height: 8, color: Colors.green)),
            Expanded(flex: 5, child: Container(height: 8, color: Colors.orange)),
            Expanded(flex: 10, child: Container(height: 8, color: Colors.red)),
          ],
        ),
        // Pointer logic could be added here, simplified for now
      ],
    );
  }
}
