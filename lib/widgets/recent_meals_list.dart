import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/screens/food/custom_food_detail_screen.dart';
import 'package:physiq/screens/meal/food_nutrition_screen.dart';
import 'package:physiq/screens/meal/meal_detail_screen.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class RecentMealsList extends ConsumerWidget {
  final List<dynamic>? logs;
  final Function(String)? onMealTap;

  const RecentMealsList({super.key, this.logs, this.onMealTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Container(
            width: double.infinity,
            height: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(AppRadii.bigCard),
              boxShadow: [AppShadows.card],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 50,
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
              }

              if (item is Map<String, dynamic>) {
                final id = _stringValue(item['id']);
                final timestamp = _dateValue(
                      item['timestamp'] ??
                          item['created_at'] ??
                          item['createdAt'],
                      fallback: DateTime.now(),
                    ) ??
                    DateTime.now();

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
        final viewModel = ref.read(homeViewModelProvider.notifier);

        if (isMeal) {
          viewModel.deleteMealLocally(id);
          viewModel.deleteMealFirebase(id, date);
        } else {
          viewModel.deleteExerciseLocally(id);
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
        return await showDialog<bool>(
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
    final id = _stringValue(mealData['id']);
    final name = _stringValue(
      mealData['name'] ?? mealData['meal_title'],
      fallback: 'Meal',
    );
    final protein = _doubleValue(mealData['proteinG'] ?? mealData['protein']);
    final carbs = _doubleValue(mealData['carbsG'] ?? mealData['carbs']);
    final fat = _doubleValue(
      mealData['fatG'] ?? mealData['fat'] ?? mealData['fats'],
    );
    final calories = _doubleValue(mealData['calories']);
    final imageUrl = _stringValue(mealData['imageUrl'] ?? mealData['image_url']);
    final type = _resolveMealType(mealData);

    final hasMealData = mealData['ingredients'] is List || type == 'scan';
    final isUnloggedScan =
        mealData['ingredients'] is List && mealData['proteinG'] == null;

    double displayP = protein;
    double displayC = carbs;
    double displayF = fat;
    double displayCal = calories;

    if (isUnloggedScan) {
      final ingredients = mealData['ingredients'] as List;
      for (final ingredient in ingredients) {
        final normalized = _normalizeMap(ingredient);
        if (normalized == null) continue;
        displayCal += _doubleValue(
          normalized['calories_estimate'] ?? normalized['calories'],
        );
        displayP += _doubleValue(
          normalized['protein_estimate'] ?? normalized['protein'],
        );
        displayC += _doubleValue(
          normalized['carbs_estimate'] ?? normalized['carbs'],
        );
        displayF += _doubleValue(normalized['fat_estimate'] ?? normalized['fat']);
      }
    }

    final hasImage = imageUrl.isNotEmpty;
    final showLeadingVisual = hasMealData || hasImage;
    final isLoadingScan = mealData['ingredients'] is List &&
        (mealData['ingredients'] as List).isEmpty &&
        displayCal == 0 &&
        displayP == 0 &&
        displayC == 0 &&
        displayF == 0;

    String timeStr = '';
    final rawTs =
        mealData['timestamp'] ?? mealData['created_at'] ?? mealData['createdAt'];
    final time = _dateValue(rawTs);
    if (time != null) {
      timeStr = DateFormat('h:mm a').format(time);
    }

    return InkWell(
      onTap: () {
        if (onMealTap != null) {
          onMealTap!(id);
          return;
        }

        final servingAmount = _doubleValue(
          mealData['servingAmount'] ?? mealData['quantity'],
          fallback: 1.0,
        );
        final servingDescription = _stringValue(
          mealData['servingDescription'] ?? mealData['unit'],
          fallback: 'serving',
        );

        if (type == 'meal') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MealDetailScreen(
                meal: _buildLoggedMeal(mealData, id),
              ),
            ),
          );
          return;
        }

        if (type == 'custom_food') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomFoodDetailScreen(
                food: _buildLoggedCustomFood(mealData, id),
              ),
            ),
          );
          return;
        }

        if (type == 'usda_food') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodNutritionScreen(
                food: _buildLoggedFood(mealData, id),
                servingAmount: servingAmount,
                servingUnit: servingDescription,
              ),
            ),
          );
          return;
        }

        if (type == 'scan') {
          final meal = _buildLoggedScanMeal(mealData, id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MealPreviewScreen(
                initialFood: _buildLoggedScanFood(
                  mealData,
                  id,
                  displayCal,
                  displayP,
                  displayC,
                  displayF,
                ),
                meal: meal,
                initialQuantity: servingAmount > 0 ? servingAmount : 1.0,
                imagePath: _resolveImagePath(mealData, meal),
              ),
            ),
          );
          return;
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
            if (showLeadingVisual) ...[
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
                  child: imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        )
                      : Image.file(
                          File(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
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
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildMacroChip(
                          'P',
                          '${displayP.round()}g',
                          const Color(0xFFF7B5C6),
                          const Color(0xFF7A1630),
                        ),
                        _buildMacroChip(
                          'C',
                          '${displayC.round()}g',
                          const Color(0xFFFFF1B8),
                          const Color(0xFF6F4E00),
                        ),
                        _buildMacroChip(
                          'F',
                          '${displayF.round()}g',
                          const Color(0xFFCFE1FF),
                          const Color(0xFF123C8C),
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
    final showImage = source == 'snap';
    final timeStr = DateFormat('h:mm a').format(log.timestamp);

    String detailsText = '';
    if (log.details.containsKey('sets') && log.details['sets'] is List) {
      final setsList = log.details['sets'] as List;
      final count = setsList.length;
      detailsText = '$count sets';
      if (setsList.isNotEmpty) {
        final firstReps = setsList.first['reps'];
        if (firstReps != null) {
          detailsText += ' x $firstReps reps';
        }
      }
    } else if (log.details.containsKey('rounds')) {
      detailsText = '${log.durationMinutes} min - ${log.details['rounds']} rounds';
    } else {
      detailsText = '${log.durationMinutes} min';
      if (log.intensity != 'medium') {
        detailsText += ' - ${log.intensity.toUpperCase()}';
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

  Widget _buildMacroChip(
    String label,
    String value,
    Color bg,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: AppTextStyles.bodyMedium.copyWith(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _resolveMealType(Map<String, dynamic> mealData) {
    final explicitType = _stringValue(mealData['type']).toLowerCase();
    if (explicitType == 'meal' || explicitType == 'custommeal') {
      return 'meal';
    }
    if (explicitType == 'custom_food') {
      return 'custom_food';
    }
    if (explicitType == 'usda_food') {
      return 'usda_food';
    }
    if (explicitType == 'scan') {
      return 'scan';
    }

    final source = _stringValue(mealData['source']).toLowerCase();
    if (source == 'custom_meal' || source == 'my_meals') {
      return 'meal';
    }
    if (source == 'custom_food') {
      return 'custom_food';
    }
    if (source == 'database' ||
        source == 'usda' ||
        source == 'off' ||
        source == 'all' ||
        source == 'manual' ||
        source == 'open_food_facts') {
      return 'usda_food';
    }
    if (source == 'snap' ||
        source == 'scan' ||
        source == 'gemini_vision' ||
        source == 'gemini_fallback' ||
        source == 'gemini_estimate' ||
        source == 'open_food_facts_scan') {
      return 'scan';
    }

    final sourceData = _normalizeMap(mealData['sourceData']);
    final wrappedMeal = _extractMap(sourceData, 'meal');
    final wrappedFood = _extractMap(sourceData, 'food');

    if (mealData['ingredients'] is List ||
        mealData['image_url'] != null ||
        mealData['meal_title'] != null) {
      return 'scan';
    }
    if (wrappedMeal != null || mealData['mealId'] != null) {
      return 'meal';
    }
    if (wrappedFood != null) {
      final foodSource = _stringValue(wrappedFood['source']).toLowerCase();
      if (foodSource == 'custom_food') {
        return 'custom_food';
      }
      return 'usda_food';
    }

    return 'usda_food';
  }

  MyMeal _buildLoggedMeal(Map<String, dynamic> mealData, String id) {
    final sourceData = _normalizeMap(mealData['sourceData']);
    final mealMap = _extractMap(sourceData, 'meal');
    final itemsData = mealMap?['items'] as List<dynamic>? ?? const [];

    return MyMeal(
      id: _stringValue(
        mealMap?['id'] ?? mealData['mealId'] ?? mealData['originalId'],
        fallback: id,
      ),
      name: _stringValue(mealMap?['name'] ?? mealData['name'], fallback: 'Meal'),
      totalCalories: _doubleValue(
        mealMap?['totalCalories'] ??
            mealData['totalCalories'] ??
            mealData['calories'],
      ),
      totalProtein: _doubleValue(
        mealMap?['totalProtein'] ?? mealData['protein'] ?? mealData['proteinG'],
      ),
      totalCarbs: _doubleValue(
        mealMap?['totalCarbs'] ?? mealData['carbs'] ?? mealData['carbsG'],
      ),
      totalFat: _doubleValue(
        mealMap?['totalFat'] ??
            mealData['fat'] ??
            mealData['fatG'] ??
            mealData['fats'],
      ),
      createdAt: _dateValue(
            mealMap?['createdAt'] ??
                mealData['timestamp'] ??
                mealData['createdAt'] ??
                mealData['created_at'],
          ) ??
          DateTime.now(),
      items: itemsData
          .map(_normalizeMap)
          .whereType<Map<String, dynamic>>()
          .map(MealItem.fromMap)
          .toList(),
    );
  }

  CustomFood _buildLoggedCustomFood(Map<String, dynamic> mealData, String id) {
    final sourceData = _normalizeMap(mealData['sourceData']);
    final foodData = _extractMap(sourceData, 'food');
    final nutritionData =
        _normalizeMap(foodData?['nutrition']) ??
        _normalizeMap(mealData['fullNutritionMap']) ??
        {
          'calories': _doubleValue(mealData['calories']),
          'protein': _doubleValue(mealData['proteinG'] ?? mealData['protein']),
          'carbs': _doubleValue(mealData['carbsG'] ?? mealData['carbs']),
          'fat': _doubleValue(
            mealData['fatG'] ?? mealData['fat'] ?? mealData['fats'],
          ),
        };

    return CustomFood(
      id: _stringValue(foodData?['id'] ?? mealData['originalId'], fallback: id),
      userId: _stringValue(foodData?['userId']),
      brandName: _stringValue(foodData?['brandName'] ?? mealData['brand']),
      description: _stringValue(
        foodData?['description'] ?? mealData['name'],
        fallback: 'Food',
      ),
      servingSize: _stringValue(
        foodData?['servingSize'] ??
            mealData['servingDescription'] ??
            mealData['unit'],
        fallback: '1 serving',
      ),
      servingPerContainer: _doubleValue(
        foodData?['servingPerContainer'] ??
            mealData['servingAmount'] ??
            mealData['quantity'],
        fallback: 1.0,
      ),
      nutrition: CustomFoodNutrition.fromJson(nutritionData),
      createdAt: _dateValue(
            foodData?['createdAt'] ??
                mealData['timestamp'] ??
                mealData['createdAt'] ??
                mealData['created_at'],
          ) ??
          DateTime.now(),
    );
  }

  Food _buildLoggedFood(Map<String, dynamic> mealData, String id) {
    final sourceData = _normalizeMap(mealData['sourceData']);
    final foodData = _extractMap(sourceData, 'food');
    final source = _stringValue(mealData['source'], fallback: 'database');
    final originalId = _stringValue(
      mealData['originalId'],
      fallback: _stringValue(mealData['id'], fallback: id),
    );

    if (foodData != null) {
      final foodId = _stringValue(foodData['id'], fallback: originalId);
      return Food.fromJson(foodData, foodId).copyWith(source: source);
    }

    final servingAmount = _doubleValue(
      mealData['servingAmount'] ?? mealData['quantity'],
      fallback: 1.0,
    );
    final unitScaler = servingAmount > 0 ? 1 / servingAmount : 1.0;
    final nutrition = _normalizeMap(mealData['fullNutritionMap']) ?? const {};

    return Food(
      id: originalId,
      name: _stringValue(mealData['name'], fallback: 'Food'),
      category: 'Logged',
      unit: _stringValue(
        mealData['servingDescription'] ?? mealData['unit'],
        fallback: 'serving',
      ),
      baseWeightG: 100,
      calories: _doubleValue(mealData['calories']) * unitScaler,
      protein: _doubleValue(mealData['proteinG'] ?? mealData['protein']) * unitScaler,
      carbs: _doubleValue(mealData['carbsG'] ?? mealData['carbs']) * unitScaler,
      fat: _doubleValue(
            mealData['fatG'] ?? mealData['fat'] ?? mealData['fats'],
          ) *
          unitScaler,
      saturatedFat: _scaledOptionalNutrition(nutrition['saturatedFat'], unitScaler),
      polyunsaturatedFat: _scaledOptionalNutrition(
        nutrition['polyunsaturatedFat'],
        unitScaler,
      ),
      monounsaturatedFat: _scaledOptionalNutrition(
        nutrition['monounsaturatedFat'],
        unitScaler,
      ),
      cholesterol: _scaledOptionalNutrition(nutrition['cholesterol'], unitScaler),
      sodium: _scaledOptionalNutrition(nutrition['sodium'], unitScaler),
      fiber: _scaledOptionalNutrition(nutrition['fiber'], unitScaler),
      sugar: _scaledOptionalNutrition(nutrition['sugar'], unitScaler),
      calcium: _scaledOptionalNutrition(nutrition['calcium'], unitScaler),
      iron: _scaledOptionalNutrition(nutrition['iron'], unitScaler),
      potassium: _scaledOptionalNutrition(nutrition['potassium'], unitScaler),
      vitaminA: _scaledOptionalNutrition(nutrition['vitaminA'], unitScaler),
      vitaminC: _scaledOptionalNutrition(nutrition['vitaminC'], unitScaler),
      source: source,
      fdcId: originalId,
    );
  }

  Meal? _buildLoggedScanMeal(Map<String, dynamic> mealData, String id) {
    final sourceData = _normalizeMap(mealData['sourceData']);
    final mealMap = _extractMap(sourceData, 'meal');

    if (mealMap != null) {
      final mealId = _stringValue(mealMap['id'], fallback: id);
      return Meal.fromJson(mealMap, mealId);
    }

    if (mealData['ingredients'] is List ||
        mealData['imageUrl'] != null ||
        mealData['image_url'] != null ||
        mealData['meal_title'] != null) {
      return Meal.fromJson(
        mealData,
        _stringValue(mealData['originalId'], fallback: id),
      );
    }

    return null;
  }

  Food _buildLoggedScanFood(
    Map<String, dynamic> mealData,
    String id,
    double displayCal,
    double displayP,
    double displayC,
    double displayF,
  ) {
    final sourceData = _normalizeMap(mealData['sourceData']);
    final foodData = _extractMap(sourceData, 'food');
    final source = _stringValue(mealData['source'], fallback: 'snap');

    if (foodData != null) {
      final foodId = _stringValue(
        foodData['id'],
        fallback: _stringValue(mealData['originalId'], fallback: id),
      );
      return Food.fromJson(foodData, foodId).copyWith(source: 'scan');
    }

    final servingAmount = _doubleValue(
      mealData['servingAmount'] ?? mealData['quantity'],
      fallback: 1.0,
    );
    final unitScaler = servingAmount > 0 ? 1 / servingAmount : 1.0;
    final nutrition = _normalizeMap(mealData['fullNutritionMap']) ?? const {};

    return Food(
      id: _stringValue(mealData['originalId'], fallback: id),
      name: _stringValue(
        mealData['meal_title'] ?? mealData['name'],
        fallback: 'Meal',
      ),
      category: 'AI Scan',
      unit: _stringValue(
        mealData['servingDescription'] ??
            mealData['container'] ??
            mealData['unit'],
        fallback: '1 serving',
      ),
      baseWeightG: 100,
      calories: displayCal * unitScaler,
      protein: displayP * unitScaler,
      carbs: displayC * unitScaler,
      fat: displayF * unitScaler,
      fiber: _scaledOptionalNutrition(nutrition['fiber'], unitScaler),
      sugar: _scaledOptionalNutrition(nutrition['sugar'], unitScaler),
      sodium: _scaledOptionalNutrition(nutrition['sodium'], unitScaler),
      cholesterol: _scaledOptionalNutrition(nutrition['cholesterol'], unitScaler),
      calcium: _scaledOptionalNutrition(nutrition['calcium'], unitScaler),
      iron: _scaledOptionalNutrition(nutrition['iron'], unitScaler),
      potassium: _scaledOptionalNutrition(nutrition['potassium'], unitScaler),
      source: source,
    );
  }

  String? _resolveImagePath(Map<String, dynamic> mealData, Meal? meal) {
    final sourceData = _normalizeMap(mealData['sourceData']);
    final imagePath = _stringValue(sourceData?['imagePath']);
    if (imagePath.isNotEmpty) {
      return imagePath;
    }

    final imageUrl = meal?.imageUrl.isNotEmpty == true
        ? meal!.imageUrl
        : _stringValue(mealData['imageUrl'] ?? mealData['image_url']);
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      return imageUrl;
    }

    return null;
  }

  Map<String, dynamic>? _extractMap(Map<String, dynamic>? source, String key) {
    if (source == null) return null;

    final direct = _normalizeMap(source[key]);
    if (direct != null) {
      return direct;
    }

    if (source.containsKey(key)) {
      return null;
    }

    final hasWrappedSections =
        source.containsKey('food') ||
        source.containsKey('meal') ||
        source.containsKey('imagePath');
    return hasWrappedSections ? null : source;
  }

  Map<String, dynamic>? _normalizeMap(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(key.toString(), nestedValue),
      );
    }
    return null;
  }

  double _doubleValue(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  double? _scaledOptionalNutrition(dynamic value, double scale) {
    if (value == null) return null;
    return _doubleValue(value) * scale;
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  DateTime? _dateValue(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? fallback;
    return fallback;
  }
}
