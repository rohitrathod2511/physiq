import 'dart:io';
import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecentMealsList extends StatelessWidget {
  final List<Map<String, dynamic>>? meals;
  final Function(String)? onMealTap;

  const RecentMealsList({super.key, this.meals, this.onMealTap});

  @override
  Widget build(BuildContext context) {
    // If meals exist and list is not empty
    final hasMeals = meals != null && meals!.isNotEmpty;

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
        
        if (!hasMeals)
          // Placeholder Card matching the image
          Container(
            width: double.infinity,
            height: 140, // Reduced height
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16), // Reduced padding
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
                  width: 80, // Reduced size
                  height: 50, // Reduced size
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(Icons.lunch_dining, size: 32, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap + to add your first meal of the day',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // List of Meals
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final meal = meals![index];
              return _buildMealCard(meal);
            },
          ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final name = meal['name'] ?? 'Meal';
    final calories = meal['calories'] ?? 0;
    final protein = meal['proteinG'] ?? 0;
    final carbs = meal['carbsG'] ?? 0;
    final fat = meal['fatG'] ?? 0;
    final imageUrl = meal['imageUrl'] as String?;
    
    // Time Formatting
    String timeStr = '';
    if (meal['timestamp'] is Timestamp) {
      timeStr = DateFormat('h:mm a').format((meal['timestamp'] as Timestamp).toDate());
    } else if (meal['timestamp'] is String) {
       // Try parsing ISO8601 if strictly string, but assuming Timestamp from Firestore
       timeStr = ''; 
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image or Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.hardEdge,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.file(File(imageUrl), fit: BoxFit.cover, 
                    errorBuilder: (c, o, s) => const Icon(Icons.broken_image, color: Colors.grey))
                : const Icon(Icons.fastfood, color: Colors.grey, size: 32),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timeStr.isNotEmpty)
                      Text(timeStr, style: AppTextStyles.smallLabel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMacroChip('P', '${protein}g', Colors.purple.shade100, Colors.purple.shade700),
                    const SizedBox(width: 8),
                    _buildMacroChip('C', '${carbs}g', Colors.orange.shade100, Colors.orange.shade700),
                    const SizedBox(width: 8),
                    _buildMacroChip('F', '${fat}g', Colors.blue.shade100, Colors.blue.shade700),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: AppTextStyles.smallLabel.copyWith(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
