import 'dart:io';
import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/exercise_log_model.dart';

class RecentMealsList extends StatelessWidget {
  final List<dynamic>? logs;
  final Function(String)? onMealTap;

  const RecentMealsList({super.key, this.logs, this.onMealTap});

  @override
  Widget build(BuildContext context) {
    // If logs exist and list is not empty
    final hasLogs = logs != null && logs!.isNotEmpty;

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
        
        if (!hasLogs)
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
                  'Tap + to add your first meal or workout',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // List of Logs
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs!.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = logs![index];
              if (item is ExerciseLog) {
                return _buildWorkoutCard(item);
              } else if (item is Map<String, dynamic>) {
                return _buildMealCard(item);
              }
              return const SizedBox.shrink();
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

  Widget _buildWorkoutCard(ExerciseLog log) {
    final name = log.name;
    final calories = log.calories.toInt();
    
    // Time Formatting
    String timeStr = DateFormat('h:mm a').format(log.timestamp);
    
    // Details formatting
    String detailsText = '';
    
    // Home Exercises (Sets & Reps)
    if (log.details.containsKey('sets') && log.details['sets'] is List) {
      final setsList = log.details['sets'] as List;
      final count = setsList.length;
      detailsText = '$count sets';
      // Attempt to summarize reps if consistent or just show first
      if (setsList.isNotEmpty) {
        final firstReps = setsList.first['reps'];
        if (firstReps != null) {
          detailsText += ' × $firstReps reps';
        }
      }
    } 
    // Manual/Gym sets stored as simple count? 
    // Or Timer Based
    else if (log.details.containsKey('rounds')) {
       // Timer: Total time, rounds
       detailsText = '${log.durationMinutes} min • ${log.details['rounds']} rounds';
    }
    // Cardio / Sports / Describe
    else {
      detailsText = '${log.durationMinutes} min';
      if (log.intensity != 'medium') {
        detailsText += ' • ${log.intensity.toUpperCase()}';
      }
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
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.fitness_center, color: AppColors.primary, size: 28),
            ),
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
                const SizedBox(height: 4),
                Text(
                  detailsText,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
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
