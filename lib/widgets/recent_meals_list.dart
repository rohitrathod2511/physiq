import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';

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
                } else if (item['created_at'] is Timestamp) {
                   timestamp = (item['created_at'] as Timestamp).toDate();
                }

                return _buildDismissible(
                  context,
                  ref,
                  id,
                  timestamp,
                  true,
                  _buildMealCard(context, item),
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

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> mealData) {
    final id = mealData['id'] as String? ?? '';
    final name = mealData['name'] ?? mealData['meal_title'] ?? 'Meal';
    final protein = (mealData['proteinG'] ?? 0.0);
    final carbs = (mealData['carbsG'] ?? 0.0);
    final fat = (mealData['fatG'] ?? 0.0);
    final calories = (mealData['calories'] ?? 0.0);
    final imageUrl = (mealData['imageUrl'] ?? mealData['image_url']) as String?;

    // Unlogged scans have 'ingredients' field from AI scans
    final bool isUnloggedScan = mealData['ingredients'] != null && mealData['proteinG'] == null;
    
    // Dynamic stats for unlogged scans
    double displayP = protein;
    double displayC = carbs;
    double displayF = fat;
    double displayCal = calories;

    if (isUnloggedScan) {
      final ingredients = mealData['ingredients'] as List;
      for (var i in ingredients) {
        displayCal += (i['calories_estimate'] ?? i['calories'] ?? 0.0);
        displayP += (i['protein_estimate'] ?? i['protein'] ?? 0.0);
        displayC += (i['carbs_estimate'] ?? i['carbs'] ?? 0.0);
        displayF += (i['fat_estimate'] ?? i['fat'] ?? 0.0);
      }
    }

    // Show image if imageUrl is present
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    // Time Formatting
    String timeStr = '';
    final rawTs = mealData['timestamp'] ?? mealData['created_at'];
    if (rawTs is Timestamp) {
      timeStr = DateFormat('h:mm a').format(rawTs.toDate());
    }

    return InkWell(
      onTap: () {
        if (onMealTap != null) {
          onMealTap!(id);
        } else {
           // Direct navigation to preview screen
           if (isUnloggedScan) {
             final meal = Meal.fromJson(mealData, id);
             // initialFood is required, so we provide one from the meal title
             final dummyFood = Food(
               id: meal.id,
               name: meal.title,
               category: 'AI Scan',
               unit: 'serving',
               baseWeightG: 100,
               calories: displayCal,
               protein: displayP,
               carbs: displayC,
               fat: displayF,
             );
             Navigator.push(context, MaterialPageRoute(builder: (_) => MealPreviewScreen(
               meal: meal,
               initialFood: dummyFood,
             )));
           } else {
             // Create a dummy Food object for preview
             final dummyFood = Food(
               id: id,
               name: name,
               category: 'Logged',
               unit: 'serving',
               baseWeightG: 100,
               calories: displayCal,
               protein: displayP,
               carbs: displayC,
               fat: displayF,
             );
             Navigator.push(context, MaterialPageRoute(builder: (_) => MealPreviewScreen(initialFood: dummyFood)));
           }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasImage) ...[
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                clipBehavior: Clip.hardEdge,
                child: imageUrl!.startsWith('http')
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                    : Image.file(File(imageUrl), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
              ),
              const SizedBox(width: 16),
            ] else ...[
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(timeStr, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${displayCal.round()} kcal',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      if (mealData['logged'] == false) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text('UNLOGGED', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMacroChip('P', '${displayP.round()}g', const Color(0xFFFFEBEE), const Color(0xFFE57373)),
                      const SizedBox(width: 8),
                      _buildMacroChip('C', '${displayC.round()}g', const Color(0xFFFFF3E0), const Color(0xFFFFB74D)),
                      const SizedBox(width: 8),
                      _buildMacroChip('F', '${displayF.round()}g', const Color(0xFFE3F2FD), const Color(0xFF64B5F6)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
