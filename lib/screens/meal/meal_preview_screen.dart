import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/fatsecret_food_model.dart';
import 'package:physiq/models/fatsecret_serving_model.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/services/fatsecret_service.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class MealPreviewScreen extends ConsumerStatefulWidget {
  final Food initialFood;
  final double initialQuantity;
  final bool isSelectionMode;
  final String? imagePath;

  const MealPreviewScreen({
    super.key,
    required this.initialFood,
    this.initialQuantity = 1.0,
    this.isSelectionMode = false,
    this.imagePath,
  });

  @override
  ConsumerState<MealPreviewScreen> createState() => _MealPreviewScreenState();
}

class _MealPreviewScreenState extends ConsumerState<MealPreviewScreen> {
  final FatSecretService _fatSecretService = FatSecretService();

  bool _isLoading = true;
  FatSecretFood? _detailedFood;
  FatSecretServing? _selectedServing;
  double _quantity = 1.0;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _loadFoodDetails();
  }

  Future<void> _loadFoodDetails() async {
    if (widget.initialFood.source != 'fatsecret') {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    String foodId = widget.initialFood.id;
    if (foodId.startsWith('fs_')) {
      foodId = foodId.substring(3);
    }

    try {
      final food = await _fatSecretService.getFoodDetails(foodId);
      if (!mounted) return;

      final selected = _pickInitialServing(food);
      setState(() {
        _detailedFood = food;
        _selectedServing = selected;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading details: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  FatSecretServing? _pickInitialServing(FatSecretFood food) {
    if (food.servings.isEmpty) return null;

    final targetUnit = widget.initialFood.unit.toLowerCase();
    try {
      return food.servings.firstWhere(
        (serving) =>
            serving.description.toLowerCase() == targetUnit ||
            serving.description.toLowerCase().contains(targetUnit) ||
            serving.metricServingUnit.toLowerCase() == targetUnit,
      );
    } catch (_) {
      return food.servings.first;
    }
  }

  void _updateQuantity(double delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(0.1, 99.0);
    });
  }

  double _getNutrient(
    double Function(FatSecretServing) selector,
    double? fallback,
  ) {
    if (_selectedServing != null) {
      return selector(_selectedServing!) * _quantity;
    }
    return (fallback ?? 0) * _quantity;
  }

  Future<void> _saveMeal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final calories = _getNutrient(
      (s) => s.calories,
      widget.initialFood.calories,
    );
    final protein = _getNutrient((s) => s.protein, widget.initialFood.protein);
    final carbs = _getNutrient((s) => s.carbs, widget.initialFood.carbs);
    final fat = _getNutrient((s) => s.fat, widget.initialFood.fat);

    if (widget.isSelectionMode) {
      final item = MealItem(
        foodId: _detailedFood?.id ?? widget.initialFood.id,
        foodName: _detailedFood?.name ?? widget.initialFood.name,
        quantity: _quantity,
        servingLabel: _selectedServing?.description ?? widget.initialFood.unit,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
      Navigator.pop(context, item);
      return;
    }

    final meal = MealModel(
      id: '',
      userId: user.uid,
      name: _detailedFood?.name ?? widget.initialFood.name,
      calories: calories.round(),
      proteinG: protein.round(),
      carbsG: carbs.round(),
      fatG: fat.round(),
      timestamp: DateTime.now(),
      imageUrl: widget.imagePath,
      source: _detailedFood != null ? 'fatsecret' : widget.initialFood.source,
      servingDescription:
          _selectedServing?.description ?? widget.initialFood.unit,
      servingAmount: _quantity,
      fullNutritionMap: _selectedServing != null
          ? {
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fat,
              'saturatedFat': _getNutrient(
                (s) => s.saturatedFat,
                widget.initialFood.saturatedFat,
              ),
              'polyunsaturatedFat': _getNutrient(
                (s) => s.polyunsaturatedFat,
                widget.initialFood.polyunsaturatedFat,
              ),
              'monounsaturatedFat': _getNutrient(
                (s) => s.monounsaturatedFat,
                widget.initialFood.monounsaturatedFat,
              ),
              'cholesterol': _getNutrient(
                (s) => s.cholesterol,
                widget.initialFood.cholesterol,
              ),
              'sodium': _getNutrient(
                (s) => s.sodium,
                widget.initialFood.sodium,
              ),
              'fiber': _getNutrient((s) => s.fiber, widget.initialFood.fiber),
              'sugar': _getNutrient((s) => s.sugar, widget.initialFood.sugar),
              'potassium': _getNutrient(
                (s) => s.potassium,
                widget.initialFood.potassium,
              ),
              'vitaminA': _getNutrient(
                (s) => s.vitaminA,
                widget.initialFood.vitaminA,
              ),
              'vitaminC': _getNutrient(
                (s) => s.vitaminC,
                widget.initialFood.vitaminC,
              ),
              'calcium': _getNutrient(
                (s) => s.calcium,
                widget.initialFood.calcium,
              ),
              'iron': _getNutrient((s) => s.iron, widget.initialFood.iron),
            }
          : {},
    );

    ref.read(homeViewModelProvider.notifier).logMeal(meal);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final Color proteinAccent = theme.colorScheme.error;
    final Color carbsAccent = theme.colorScheme.secondary;
    final Color fatsAccent = theme.colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cals = _getNutrient(
      (s) => s.calories,
      widget.initialFood.calories,
    ).round();
    final protein = _getNutrient(
      (s) => s.protein,
      widget.initialFood.protein,
    ).round();
    final carbs = _getNutrient(
      (s) => s.carbs,
      widget.initialFood.carbs,
    ).round();
    final fat = _getNutrient((s) => s.fat, widget.initialFood.fat).round();
    final servings = _detailedFood?.servings ?? const <FatSecretServing>[];
    final selectedServingIndex =
        (_selectedServing != null && servings.isNotEmpty)
        ? servings.indexWhere((serving) => serving.id == _selectedServing!.id)
        : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Nutrition',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 220,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color:
                            theme.inputDecorationTheme.fillColor ??
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                      ),
                      child: Image.file(
                        File(widget.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: textSecondary,
                              size: 36,
                            ),
                          );
                        },
                      ),
                    ),
                  if (widget.imagePath != null && widget.imagePath!.isNotEmpty)
                    const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _detailedFood?.name ?? widget.initialFood.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark_border, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (servings.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serving Size',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: selectedServingIndex < 0
                              ? 0
                              : selectedServingIndex,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                theme.inputDecorationTheme.fillColor ??
                                theme.cardColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                          items: List<DropdownMenuItem<int>>.generate(
                            servings.length,
                            (index) {
                              final serving = servings[index];
                              return DropdownMenuItem<int>(
                                value: index,
                                child: Text(
                                  serving.description,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                          onChanged: (index) {
                            if (index == null) return;
                            setState(() {
                              _selectedServing = servings[index];
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serving Size',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            widget.initialFood.unit,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Serving Amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _updateQuantity(-0.5),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Text(
                                _quantity % 1 == 0
                                    ? _quantity.toInt().toString()
                                    : _quantity.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(0.5),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calories',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$cals',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroCard(
                          label: 'Protein',
                          value: '${protein}g',
                          icon: Icons.restaurant,
                          color: proteinAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MacroCard(
                          label: 'Carbs',
                          value: '${carbs}g',
                          icon: Icons.grain,
                          color: carbsAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MacroCard(
                          label: 'Fats',
                          value: '${fat}g',
                          icon: Icons.water_drop,
                          color: fatsAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    'Other nutrition facts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFactRow(
                    'Saturated Fat',
                    _getNutrient(
                      (s) => s.saturatedFat,
                      widget.initialFood.saturatedFat,
                    ),
                    'g',
                  ),
                  _buildFactRow(
                    'Polyunsaturated Fat',
                    _getNutrient(
                      (s) => s.polyunsaturatedFat,
                      widget.initialFood.polyunsaturatedFat,
                    ),
                    'g',
                  ),
                  _buildFactRow(
                    'Monounsaturated Fat',
                    _getNutrient(
                      (s) => s.monounsaturatedFat,
                      widget.initialFood.monounsaturatedFat,
                    ),
                    'g',
                  ),
                  _buildFactRow(
                    'Cholesterol',
                    _getNutrient(
                      (s) => s.cholesterol,
                      widget.initialFood.cholesterol,
                    ),
                    'mg',
                  ),
                  _buildFactRow(
                    'Sodium',
                    _getNutrient((s) => s.sodium, widget.initialFood.sodium),
                    'mg',
                  ),
                  _buildFactRow(
                    'Fiber',
                    _getNutrient((s) => s.fiber, widget.initialFood.fiber),
                    'g',
                  ),
                  _buildFactRow(
                    'Sugar',
                    _getNutrient((s) => s.sugar, widget.initialFood.sugar),
                    'g',
                  ),
                  _buildFactRow(
                    'Potassium',
                    _getNutrient(
                      (s) => s.potassium,
                      widget.initialFood.potassium,
                    ),
                    'mg',
                  ),
                  _buildFactRow(
                    'Vitamin A',
                    _getNutrient(
                      (s) => s.vitaminA,
                      widget.initialFood.vitaminA,
                    ),
                    'mcg',
                  ),
                  _buildFactRow(
                    'Vitamin C',
                    _getNutrient(
                      (s) => s.vitaminC,
                      widget.initialFood.vitaminC,
                    ),
                    'mg',
                  ),
                  _buildFactRow(
                    'Calcium',
                    _getNutrient((s) => s.calcium, widget.initialFood.calcium),
                    'mg',
                  ),
                  _buildFactRow(
                    'Iron',
                    _getNutrient((s) => s.iron, widget.initialFood.iron),
                    'mg',
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  widget.isSelectionMode ? 'Add' : 'Save',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactRow(String label, double value, String unit) {
    if (value == 0) return _FactRow(label, '0$unit');
    return _FactRow(
      label,
      '${value < 1 ? value.toStringAsFixed(1) : value.round()}$unit',
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.edit,
                size: 12,
                color: textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;

  const _FactRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.45)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: textPrimary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
