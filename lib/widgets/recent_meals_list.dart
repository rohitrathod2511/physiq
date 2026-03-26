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
import 'package:physiq/screens/meal/food_nutrition_screen.dart';

class RecentMealsList extends ConsumerWidget {
  final List<dynamic>? logs;
  final Function(String)? onMealTap;

  const RecentMealsList({super.key, this.logs, this.onMealTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If logs exist and list is not empty
    final hasLogs = logs != null && logs!.isNotEmpty;
    final theme = Theme.of(context);
    final textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

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
              color: theme.cardColor,
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
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lunch_dining,
                      size: 32,
                      color: theme.iconTheme.color ?? textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap + to add your first meal or workout',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textSecondary,
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
                  _buildWorkoutCard(context, item),
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
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppRadii.bigCard),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete, color: theme.colorScheme.onError),
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
            SnackBar(
              content: const Text('Entry deleted successfully'),
              backgroundColor: theme.colorScheme.inverseSurface,
              duration: const Duration(seconds: 2),
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
                  child: Text(
                    "DELETE",
                    style: TextStyle(color: theme.colorScheme.error),
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
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final id = mealData['id'] as String? ?? '';
    final name = mealData['name'] ?? mealData['meal_title'] ?? 'Meal';
    final protein = (mealData['proteinG'] ?? 0.0);
    final carbs = (mealData['carbsG'] ?? 0.0);
    final fat = (mealData['fatG'] ?? 0.0);
    final calories = (mealData['calories'] ?? 0.0);
    final imageUrl = (mealData['imageUrl'] ?? mealData['image_url']) as String?;

    // Unlogged scans have 'ingredients' field from AI scans
    final bool hasMealData = mealData['ingredients'] is List;
    final bool isUnloggedScan = hasMealData && mealData['proteinG'] == null;
    
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
    final sourceType = mealData['source'] as String? ?? 'snap';
    final bool isDatabaseMeal = sourceType == 'database';
    final bool isLoadingScan = hasMealData &&
        (mealData['ingredients'] as List).isEmpty &&
        displayCal == 0 &&
        displayP == 0 &&
        displayC == 0 &&
        displayF == 0;

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
           if (hasMealData) {
               final meal = Meal.fromJson(mealData, id);
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
                source: 'snap',
               );
               Navigator.push(context, MaterialPageRoute(builder: (_) => MealPreviewScreen(
                 meal: meal,
                 initialFood: dummyFood,
               )));
             } else {
              final source = mealData['source'] as String? ?? 'snap';
              final servingAmount = (mealData['servingAmount'] as num?)?.toDouble() ?? 1.0;
              final servingDescription = mealData['servingDescription'] as String? ?? 'serving';
              
              if (source == 'database') {
                // Reconstruct full Food object from the logged data
                final nutrition = mealData['fullNutritionMap'] as Map<String, dynamic>? ?? {};
                
                // For 'database' logs, 'calories', 'proteinG' etc are TOTALS for the logged amount.
                // FoodNutritionScreen calculates nutrients based on servingAmount.
                // So we need to provide PER-UNIT values to the Food object.
                double unitScaler = servingAmount > 0 ? (1.0 / servingAmount) : 1.0;

                final food = Food(
                  id: id,
                  name: name,
                  category: 'Logged',
                  unit: servingDescription,
                  baseWeightG: 100,
                  calories: displayCal * unitScaler,
                  protein: displayP * unitScaler,
                  carbs: displayC * unitScaler,
                  fat: displayF * unitScaler,
                  saturatedFat: (nutrition['saturatedFat'] as num?)?.toDouble() != null ? (nutrition['saturatedFat'] as num).toDouble() * unitScaler : null,
                  polyunsaturatedFat: (nutrition['polyunsaturatedFat'] as num?)?.toDouble() != null ? (nutrition['polyunsaturatedFat'] as num).toDouble() * unitScaler : null,
                  monounsaturatedFat: (nutrition['monounsaturatedFat'] as num?)?.toDouble() != null ? (nutrition['monounsaturatedFat'] as num).toDouble() * unitScaler : null,
                  cholesterol: (nutrition['cholesterol'] as num?)?.toDouble() != null ? (nutrition['cholesterol'] as num).toDouble() * unitScaler : null,
                  sodium: (nutrition['sodium'] as num?)?.toDouble() != null ? (nutrition['sodium'] as num).toDouble() * unitScaler : null,
                  fiber: (nutrition['fiber'] as num?)?.toDouble() != null ? (nutrition['fiber'] as num).toDouble() * unitScaler : null,
                  sugar: (nutrition['sugar'] as num?)?.toDouble() != null ? (nutrition['sugar'] as num).toDouble() * unitScaler : null,
                  potassium: (nutrition['potassium'] as num?)?.toDouble() != null ? (nutrition['potassium'] as num).toDouble() * unitScaler : null,
                  vitaminA: (nutrition['vitaminA'] as num?)?.toDouble() != null ? (nutrition['vitaminA'] as num).toDouble() * unitScaler : null,
                  vitaminC: (nutrition['vitaminC'] as num?)?.toDouble() != null ? (nutrition['vitaminC'] as num).toDouble() * unitScaler : null,
                  calcium: (nutrition['calcium'] as num?)?.toDouble() != null ? (nutrition['calcium'] as num).toDouble() * unitScaler : null,
                  iron: (nutrition['iron'] as num?)?.toDouble() != null ? (nutrition['iron'] as num).toDouble() * unitScaler : null,
                  source: 'database',
                );

                Navigator.push(context, MaterialPageRoute(builder: (_) => FoodNutritionScreen(
                  food: food,
                  servingAmount: servingAmount,
                  servingUnit: servingDescription,
                )));
              } else {
                // Snap Meal or other -> MealPreviewScreen
                final dummyFood = Food(
                  id: id,
                  name: name,
                  category: 'Logged',
                  unit: servingDescription,
                  baseWeightG: 100,
                  calories: displayCal,
                  protein: displayP,
                  carbs: displayC,
                  fat: displayF,
                  source: source,
                );
                Navigator.push(context, MaterialPageRoute(builder: (_) => MealPreviewScreen(initialFood: dummyFood)));
              }
            }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isDatabaseMeal) ...[
              if (hasImage) ...[
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.35),
                    ),
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
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.fastfood,
                    color: theme.iconTheme.color ?? textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
              ],
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(color: textSecondary, fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      isLoadingScan
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Analyzing...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '${displayCal.round()} kcal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                      if (mealData['logged'] == false) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'UNLOGGED',
                            style: TextStyle(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isLoadingScan)
                    Text(
                      'Waiting for Gemini + USDA nutrition',
                      style: AppTextStyles.smallLabel.copyWith(
                        color: textSecondary,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildMacroChip(
                          'P',
                          '${displayP.round()}g',
                          theme.colorScheme.errorContainer,
                          theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        _buildMacroChip(
                          'C',
                          '${displayC.round()}g',
                          theme.colorScheme.secondaryContainer,
                          theme.colorScheme.onSurface,
                        ),
                        _buildMacroChip(
                          'F',
                          '${displayF.round()}g',
                          theme.colorScheme.tertiaryContainer,
                          theme.colorScheme.onSurface,
                        ),
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

  Widget _buildWorkoutCard(BuildContext context, ExerciseLog log) {
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
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
        color: theme.cardColor,
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
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.primary,
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
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 16,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: AppTextStyles.smallLabel.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal',
                  style: AppTextStyles.label.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detailsText,
                  style: AppTextStyles.body.copyWith(
                    color: textSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withValues(alpha: 0.14)),
      ),
      child: Text(
        '$label $value',
        style: AppTextStyles.smallLabel.copyWith(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
