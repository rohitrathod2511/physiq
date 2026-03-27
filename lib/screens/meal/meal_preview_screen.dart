import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/models/saved_food_model.dart';
import 'package:physiq/services/ai_food_service.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/services/saved_food_service.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:physiq/widgets/macro_icons.dart';

class MealPreviewScreen extends ConsumerStatefulWidget {
  final Food initialFood;
  final Meal? meal;
  final double initialQuantity;
  final bool isSelectionMode;
  final String? imagePath;

  const MealPreviewScreen({
    super.key,
    required this.initialFood,
    this.meal,
    this.initialQuantity = 1.0,
    this.isSelectionMode = false,
    this.imagePath,
  });

  @override
  ConsumerState<MealPreviewScreen> createState() => _MealPreviewScreenState();
}

class _MealPreviewScreenState extends ConsumerState<MealPreviewScreen> {
  late double _quantity;
  late List<String> _servingOptions;
  late String _selectedServing;
  late double _servingMultiplier;
  late Food _food;
  bool _isLoadingDetails = false;
  bool _isSavingToSaved = false;
  Meal? _currentMeal;
  StreamSubscription? _mealSubscription;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _food = widget.initialFood;
    _currentMeal = widget.meal;

    _initServingData();

    if (_currentMeal != null) {
      _listenToMealUpdates();
    }
  }

  @override
  void dispose() {
    _mealSubscription?.cancel();
    super.dispose();
  }

  void _initServingData() {
    _servingOptions = ['1 serving', '100g'];
    _selectedServing = '1 serving';
    _servingMultiplier = 1.0;
  }

  void _listenToMealUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _mealSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meals')
        .doc(_currentMeal!.id)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final updatedMeal = Meal.fromSnapshot(snapshot);
            setState(() {
              _currentMeal = updatedMeal;
              _updateFoodFromMeal(updatedMeal);
            });
          }
        });
  }

  void _updateFoodFromMeal(Meal meal) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;
    double totalCholesterol = 0;
    double totalCalcium = 0;
    double totalIron = 0;
    double totalPotassium = 0;

    for (var ingredient in meal.ingredients) {
      totalCalories += ingredient.caloriesEstimate;
      totalProtein += ingredient.proteinEstimate;
      totalCarbs += ingredient.carbsEstimate;
      totalFat += ingredient.fatEstimate;

      if (ingredient.nutritionPer100g != null &&
          ingredient.estimatedGrams > 0) {
        final scale = ingredient.estimatedGrams / 100.0;
        totalFiber += (ingredient.nutritionPer100g!['fiber'] ?? 0) * scale;
        totalSugar += (ingredient.nutritionPer100g!['sugar'] ?? 0) * scale;
        totalSodium += (ingredient.nutritionPer100g!['sodium'] ?? 0) * scale;
        totalCholesterol +=
            (ingredient.nutritionPer100g!['cholesterol'] ?? 0) * scale;
        totalCalcium += (ingredient.nutritionPer100g!['calcium'] ?? 0) * scale;
        totalIron += (ingredient.nutritionPer100g!['iron'] ?? 0) * scale;
        totalPotassium +=
            (ingredient.nutritionPer100g!['potassium'] ?? 0) * scale;
      }
    }

    setState(() {
      _food = _food.copyWith(
        calories: totalCalories,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
        fiber: totalFiber,
        sugar: totalSugar,
        sodium: totalSodium,
        cholesterol: totalCholesterol,
        calcium: totalCalcium,
        iron: totalIron,
        potassium: totalPotassium,
      );
    });
  }

  void _updateQuantity(double delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(0.5, 10.0);
    });
  }

  double _getNutrient(double? baseValue) {
    return (baseValue ?? 0.0) * _quantity * _servingMultiplier;
  }

  bool get _isScanSource {
    if (_currentMeal != null) return true;
    if ((widget.imagePath ?? '').isNotEmpty) return true;

    final source = _food.source.toLowerCase();
    return source.contains('scan') ||
        source.contains('snap') ||
        source.contains('gemini');
  }

  Future<void> _saveToSavedFoods() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isSavingToSaved) return;

    setState(() {
      _isSavingToSaved = true;
    });

    try {
      final savedFood = SavedFood(
        id: '',
        userId: user.uid,
        name: _currentMeal?.title ?? _food.name,
        type: _isScanSource ? 'scan' : 'usda_food',
        sourceType: _isScanSource ? 'scan' : 'usda_food',
        servingSize: _selectedServing,
        servingAmount: _quantity,
        nutrition: SavedFoodNutrition(
          calories: _getNutrient(_food.calories),
          protein: _getNutrient(_food.protein),
          carbs: _getNutrient(_food.carbs),
          fat: _getNutrient(_food.fat),
          cholesterol: _getNutrient(_food.cholesterol),
          sodium: _getNutrient(_food.sodium),
          potassium: _getNutrient(_food.potassium),
          sugar: _getNutrient(_food.sugar),
          fiber: _getNutrient(_food.fiber),
          vitaminA: _getNutrient(_food.vitaminA),
          calcium: _getNutrient(_food.calcium),
          iron: _getNutrient(_food.iron),
        ),
        createdAt: DateTime.now(),
        originalId: _currentMeal?.id ?? _food.fdcId ?? _food.id,
        sourceData: {
          'food': {
            ..._food.toJson(),
            'id': _food.id,
          },
          if (_currentMeal != null)
            'meal': {
              'id': _currentMeal!.id,
              ..._currentMeal!.toJson(),
            },
          if ((widget.imagePath ?? '').isNotEmpty) 'imagePath': widget.imagePath,
        },
      );

      await SavedFoodService().saveFood(savedFood);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${savedFood.name} saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save item')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToSaved = false;
        });
      }
    }
  }

  Future<void> _saveMeal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mealModel = MealModel(
      id: _currentMeal?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      name: _currentMeal?.title ?? _food.name,
      calories: _getNutrient(_food.calories),
      proteinG: _getNutrient(_food.protein),
      carbsG: _getNutrient(_food.carbs),
      fatG: _getNutrient(_food.fat),
      timestamp: _currentMeal?.createdAt ?? DateTime.now(),
      imageUrl: _currentMeal?.imageUrl,
      source: _currentMeal != null
          ? 'snap'
          : (_food.source.isNotEmpty ? _food.source : 'database'),
      servingAmount: _quantity,
      servingDescription: _selectedServing,
      fullNutritionMap: {
        'fiber': _getNutrient(_food.fiber),
        'sugar': _getNutrient(_food.sugar),
        'sodium': _getNutrient(_food.sodium),
        'cholesterol': _getNutrient(_food.cholesterol),
        'calcium': _getNutrient(_food.calcium),
        'iron': _getNutrient(_food.iron),
        'potassium': _getNutrient(_food.potassium),
      },
    );

    await ref.read(homeViewModelProvider.notifier).logMeal(mealModel);

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _deleteMeal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentMeal == null) return;

    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(homeViewModelProvider.notifier)
          .deleteMeal(_currentMeal!.id, _currentMeal!.createdAt);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .doc(_currentMeal!.id)
          .delete();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    final calories = _getNutrient(_food.calories).round();
    final protein = _getNutrient(_food.protein).round();
    final carbs = _getNutrient(_food.carbs).round();
    final fat = _getNutrient(_food.fat).round();

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          _buildHeroImage(context),
          _buildContentSheet(
            context,
            theme,
            textPrimary,
            textSecondary,
            calories,
            protein,
            carbs,
            fat,
          ),
          _buildTopNavButtons(context),
          _buildBottomActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    final theme = Theme.of(context);

    if ((widget.imagePath == null || widget.imagePath!.isEmpty) &&
        (_currentMeal?.imageUrl.isEmpty ?? true)) {
      return Container(
        height: 380,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 50,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      );
    }

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: widget.imagePath != null && widget.imagePath!.isNotEmpty
          ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
          : Image.network(_currentMeal!.imageUrl, fit: BoxFit.cover),
    );
  }

  Widget _buildTopNavButtons(BuildContext context) {
    final theme = Theme.of(context);
    final overlayColor = theme.colorScheme.scrim.withValues(alpha: 0.35);
    final overlayIconColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.background;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 16,
          right: 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: overlayColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: overlayIconColor, size: 22),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _deleteMeal();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: overlayColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.more_vert,
                  color: overlayIconColor,
                  size: 22,
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Meal',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSheet(
    BuildContext context,
    ThemeData theme,
    Color textPrimary,
    Color textSecondary,
    int totalCalories,
    int protein,
    int carbs,
    int fat,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 320),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookmarkAndTime(theme, textSecondary),
                const SizedBox(height: 20),
                _buildTitleAndQuantityRow(textPrimary, theme),
                const SizedBox(height: 24),
                _buildEnrichmentStatus(theme),
                const SizedBox(height: 12),
                _buildCaloriesCard(
                  totalCalories,
                  textPrimary,
                  textSecondary,
                  theme,
                ),
                const SizedBox(height: 16),
                _buildMacrosRow(protein, carbs, fat, theme),
                const SizedBox(height: 32),
                Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildIngredientsList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkAndTime(ThemeData theme, Color textSecondary) {
    final timeStr = DateFormat(
      'hh:mm a',
    ).format(_currentMeal?.createdAt ?? DateTime.now());
    return Row(
      children: [
        GestureDetector(
          onTap: _isSavingToSaved ? null : _saveToSavedFoods,
          child: Icon(
            Icons.bookmark_border,
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            timeStr,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndQuantityRow(Color textPrimary, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _currentMeal?.title ?? _food.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.remove, size: 20, color: textPrimary),
                onPressed: () => _updateQuantity(-1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),
              Text(
                _quantity.toInt().toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: 20, color: textPrimary),
                onPressed: () => _updateQuantity(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesCard(
    int calories,
    Color textPrimary,
    Color textSecondary,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.24 : 0.08,
            ),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calories',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$calories',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosRow(int protein, int carbs, int fat, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _MacroItem(
            label: 'Protein',
            value: '${protein}g',
            icon: const FishIcon(color: Color(0xFFE57373), size: 20),
            iconBg: const Color(0xFFFFEBEE),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroItem(
            label: 'Carbs',
            value: '${carbs}g',
            icon: const WheatIcon(color: Color(0xFFFFB74D), size: 20),
            iconBg: const Color(0xFFFFF3E0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroItem(
            label: 'Fats',
            value: '${fat}g',
            icon: const AvocadoIcon(color: Color(0xFF64B5F6), size: 18),
            iconBg: const Color(0xFFE3F2FD),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList() {
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    if (_currentMeal == null || _currentMeal!.ingredients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Detecting ingredients...',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return Column(
      children: _currentMeal!.ingredients
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: item.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' - ${item.caloriesEstimate.round()} cal, ${item.amount}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (item.source == 'usda' || item.source == 'off')
                    Icon(
                      Icons.verified,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEnrichmentStatus(ThemeData theme) {
    if (_currentMeal == null) return const SizedBox.shrink();

    final textSecondary =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final total = _currentMeal!.ingredients.length;
    final enriched = _currentMeal!.ingredients
        .where(
          (i) => i.source != 'gemini_estimate' && i.source != 'gemini_fallback',
        )
        .length;
    if (enriched == total && total > 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Verifying nutrition ($enriched/$total)...',
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.3 : 0.12,
              ),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _saveMeal,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Log Meal',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Widget icon;
  final Color iconBg;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: icon,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
