import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class RecentMealsList extends ConsumerWidget {
  final List<dynamic>? logs;
  final Function(String)? onMealTap;

  const RecentMealsList({super.key, this.logs, this.onMealTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If logs exist and list is not empty
    final hasLogs = logs != null && logs!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Text("Today's logs", style: AppTextStyles.heading2),
        ),

        if (!hasLogs)
          // Placeholder Card matching the image
          Container(
            width: double.infinity,
            height: 140, // Reduced height
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16), // Reduced padding
            decoration: BoxDecoration(
              color: AppColors.card,
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
                    child: Icon(
                      Icons.lunch_dining,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap + to add your first meal or workout',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
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
                return _buildDismissible(
                  context,
                  ref,
                  item.id,
                  item.timestamp,
                  false,
                  _buildWorkoutCard(item),
                );
              } else if (item is Map<String, dynamic>) {
                final id = item['id'] as String? ?? '';
                DateTime timestamp = DateTime.now();
                if (item['timestamp'] is Timestamp) {
                  timestamp = (item['timestamp'] as Timestamp).toDate();
                }
                return _buildDismissible(
                  context,
                  ref,
                  id,
                  timestamp,
                  true,
                  _buildMealCard(item),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildDismissible(
    BuildContext context,
    WidgetRef ref,
    String id,
    DateTime date,
    bool isMeal,
    Widget child,
  ) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(AppRadii.bigCard),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (direction) {
        // 1. Immediately notify ViewModel to remove locally
        final viewModel = ref.read(homeViewModelProvider.notifier);

        // We perform the local removal and total recalculation immediately
        // to avoid "Dismissed widget still in tree" error and ensure reactive UI.
        if (isMeal) {
          viewModel.deleteMealLocally(id);
          // 2. Call Firebase delete async
          viewModel.deleteMealFirebase(id, date);
        } else {
          viewModel.deleteExerciseLocally(id);
          // 2. Call Firebase delete async
          viewModel.deleteExerciseFirebase(id, date);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entry deleted successfully'),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Delete"),
              content: const Text(
                "Are you sure you want to delete this entry?",
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("CANCEL"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "DELETE",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: child,
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final name = meal['name'] ?? 'Meal';
    final calories = meal['calories'] ?? 0;
    final protein = meal['proteinG'] ?? 0;
    final carbs = meal['carbsG'] ?? 0;
    final fat = meal['fatG'] ?? 0;
    final imageUrl = meal['imageUrl'] as String?;
    final source = meal['source'] as String? ?? '';

    // Only show image for Snap Meal items
    final bool showImage = source == 'snap';

    // Time Formatting
    String timeStr = '';
    if (meal['timestamp'] is Timestamp) {
      timeStr = DateFormat(
        'h:mm a',
      ).format((meal['timestamp'] as Timestamp).toDate());
    } else if (meal['timestamp'] is String) {
      // Try parsing ISO8601 if strictly string, but assuming Timestamp from Firestore
      timeStr = '';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image container only for Snap Meal
          if (showImage) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.hardEdge,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.file(
                      File(imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) =>
                          const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : const Icon(Icons.fastfood, color: Colors.grey, size: 32),
            ),
            const SizedBox(width: 16),
          ],
          // Details - Automatically expands to full width when image is hidden
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
                    _buildMacroChip(
                      'P',
                      '${protein}g',
                      Colors.purple.shade100,
                      Colors.purple.shade700,
                    ),
                    const SizedBox(width: 8),
                    _buildMacroChip(
                      'C',
                      '${carbs}g',
                      Colors.orange.shade100,
                      Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    _buildMacroChip(
                      'F',
                      '${fat}g',
                      Colors.blue.shade100,
                      Colors.blue.shade700,
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

  Widget _buildWorkoutCard(ExerciseLog log) {
    final name = log.name;
    final calories = log.calories.toInt();
    final source = log.source;

    // Only show image/icon if it was a "snap" (unlikely for workouts, but following the rule)
    final bool showImage = source == 'snap';

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
      detailsText =
          '${log.durationMinutes} min • ${log.details['rounds']} rounds';
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon/Image container only for Snap
          if (showImage) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Details - Automatically expands to full width when icon is hidden
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
