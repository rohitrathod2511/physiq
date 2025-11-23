import 'package:flutter/material.dart';
import 'package:physiq/utils/design_system.dart';

class RecentMealsList extends StatelessWidget {
  final List<Map<String, dynamic>>? meals;
  final Function(String)? onMealTap;

  const RecentMealsList({super.key, this.meals, this.onMealTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Text(
            'Recently uploaded',
            style: AppTextStyles.heading2,
          ),
        ),
        // Placeholder Card matching the image
        Container(
          width: double.infinity,
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.bigCard),
            boxShadow: [AppShadows.card],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mock Image of Salad Bowl
              Container(
                width: 200,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.lunch_dining, size: 48, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap + to add your first meal of the day',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
