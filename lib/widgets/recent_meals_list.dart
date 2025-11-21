import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecentMealsList extends StatelessWidget {
  final List<Map<String, dynamic>>? meals;

  const RecentMealsList({super.key, this.meals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Meals', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        if (meals == null || meals!.isEmpty)
          _buildPlaceholder(context)
        else
          _buildMealList(context),
      ],
    );
  }

  // Simplified the placeholder to be a single, clean card.
  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.food_bank_outlined, size: 48, color: AppColors.secondaryText),
            const SizedBox(height: 16),
            Text(
              'Tap + to add your first meal of the day',
              textAlign: TextAlign.center,
              style: AppTextStyles.label,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealList(BuildContext context) {
    return Column(
      children: [
        ...meals!.map((meal) => _buildMealItem(context, meal)).toList(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/meal-history'),
            child: const Text(
              'Show all',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealItem(BuildContext context, Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () {
        final mealId = meal['id'];
        if (mealId != null) {
          context.go('/mealDetail/$mealId');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.smallCard),
          boxShadow: [AppShadows.card],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.smallCard - 4),
              child: Image.network(
                meal['thumbnailUrl'] ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.background,
                  child: const Icon(Icons.image_not_supported_outlined, color: AppColors.secondaryText),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // This Expanded widget fixes the overflow error.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['name'] ?? 'Unnamed Meal',
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                    overflow: TextOverflow.ellipsis, // Prevents long text from breaking layout
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text('${meal['calories'] ?? 0} kcal', style: AppTextStyles.label),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              meal['timestamp'] != null
                  ? DateFormat.jm().format((meal['timestamp'] as Timestamp).toDate())
                  : '',
              style: AppTextStyles.label,
            ),
          ],
        ),
      ),
    );
  }
}
