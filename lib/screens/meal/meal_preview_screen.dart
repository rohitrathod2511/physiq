import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/services/ai_food_service.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

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
  late Map<String, double> _servingMultipliers;
  late List<String> _servingOptions;
  late String _selectedServing;
  late double _servingMultiplier;
  late Food _food;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _food = widget.initialFood;

    if (_food.isPartial && _food.fdcId != null) {
      _fetchFullDetails();
    } else {
      _initServingData();
    }
  }

  Future<void> _fetchFullDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final fullFood = await FoodService().getFoodDetails(_food.fdcId!);
      if (fullFood != null && mounted) {
        setState(() {
          _food = fullFood;
          _isLoadingDetails = false;
          _initServingData();
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching full details: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingDetails = false;
        _initServingData();
      });
    }
  }

  void _initServingData() {
    _servingMultipliers = _buildServingMultipliers(_food);
    _servingOptions = _servingMultipliers.keys.toList();

    final preferred = _food.unit.trim();
    _selectedServing = preferred.isNotEmpty && _servingOptions.contains(preferred)
        ? preferred
        : _servingOptions.first;
    _servingMultiplier = _getServingMultiplier(_selectedServing);
  }

  Map<String, double> _buildServingMultipliers(Food food) {
    final multipliers = <String, double>{};

    // USDA Serving Options (TASK 4)
    if (food.servingOptions.isNotEmpty) {
      for (final option in food.servingOptions) {
        // USDA data is per 100g, so multiplier is grams / 100
        multipliers[option.label] = option.grams / 100.0;
      }
    }

    // Default 100g option
    if (!multipliers.containsKey('100g')) {
      multipliers['100g'] = 1.0;
    }

    // Legacy fallback
    if (multipliers.length <= 1) {
      final baseWeight = food.baseWeightG > 0 ? food.baseWeightG : 100.0;
      final baseLabel = food.unit.trim().isEmpty ? 'serving' : food.unit.trim();
      
      final normalized = baseLabel.toLowerCase().replaceAll(' ', '');
      if (normalized != '100g') {
        multipliers[baseLabel] = baseWeight / 100.0;
      }
    }

    return multipliers;
  }

  double _getServingMultiplier(String servingLabel) {
    return _servingMultipliers[servingLabel] ?? 1.0;
  }

  void _updateQuantity(double delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(0.1, 99.0);
    });
  }

  double _selectedScale() {
    return _servingMultiplier * _quantity;
  }

  double _getNutrient(double? baseValue) {
    return (baseValue ?? 0) * _selectedScale();
  }

  Future<void> _saveMeal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final calories = _getNutrient(_food.calories);
    final protein = _getNutrient(_food.protein);
    final carbs = _getNutrient(_food.carbs);
    final fat = _getNutrient(_food.fat);

    if (widget.meal != null) {
      await AiFoodService().logMeal(user.uid, widget.meal!.id);
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (widget.isSelectionMode) {
      final item = MealItem(
        foodId: _food.id,
        foodName: _food.name,
        quantity: _quantity,
        servingLabel: _selectedServing,
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
      name: _food.name,
      calories: calories.round(),
      proteinG: protein.round(),
      carbsG: carbs.round(),
      fatG: fat.round(),
      timestamp: DateTime.now(),
      imageUrl: widget.imagePath,
      source: _food.source,
      servingDescription: _selectedServing,
      servingAmount: _quantity,
      fullNutritionMap: {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'saturatedFat': _getNutrient(_food.saturatedFat),
        'polyunsaturatedFat': _getNutrient(_food.polyunsaturatedFat),
        'monounsaturatedFat': _getNutrient(_food.monounsaturatedFat),
        'cholesterol': _getNutrient(_food.cholesterol),
        'sodium': _getNutrient(_food.sodium),
        'fiber': _getNutrient(_food.fiber),
        'sugar': _getNutrient(_food.sugar),
        'potassium': _getNutrient(_food.potassium),
        'vitaminA': _getNutrient(_food.vitaminA),
        'vitaminC': _getNutrient(_food.vitaminC),
        'calcium': _getNutrient(_food.calcium),
        'iron': _getNutrient(_food.iron),
      },
    );

    ref.read(homeViewModelProvider.notifier).logMeal(meal);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildSourceBadge(String source, ThemeData theme) {
    String label = 'USDA';
    Color color = Colors.green;

    if (source.toLowerCase().contains('open_food_facts') || source.toLowerCase().contains('off')) {
      label = 'OFF';
      color = Colors.orange;
    } else if (source.toLowerCase().contains('gemini') || source.toLowerCase().contains('estimate')) {
      label = 'AI';
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withOpacity(0.7);
    final proteinAccent = theme.colorScheme.error;
    final carbsAccent = theme.colorScheme.secondary;
    final fatsAccent = theme.colorScheme.primary;

    final mealIngredients = widget.meal?.ingredients ?? [];
    final hasMealIngredients = mealIngredients.isNotEmpty;

    final displayIngredients = hasMealIngredients
        ? mealIngredients.map((i) => "${i.name} (${i.amount})").toList()
        : _food.aliases
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final calories = _getNutrient(_food.calories).round();
    final protein = _getNutrient(_food.protein).round();
    final carbs = _getNutrient(_food.carbs).round();
    final fat = _getNutrient(_food.fat).round();

    if (_isLoadingDetails) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((widget.imagePath != null && widget.imagePath!.isNotEmpty) || (widget.meal?.imageUrl.isNotEmpty ?? false))
                    Container(
                      width: double.infinity,
                      height: 220,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color:
                            theme.inputDecorationTheme.fillColor ??
                            theme.colorScheme.surfaceContainerHighest.withOpacity(
                              0.45,
                            ),
                      ),
                      child: widget.imagePath != null && widget.imagePath!.isNotEmpty 
                        ? Image.file(
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
                          )
                        : Image.network(
                            widget.meal!.imageUrl,
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
                  if ((widget.imagePath != null && widget.imagePath!.isNotEmpty) || (widget.meal?.imageUrl.isNotEmpty ?? false))
                    const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.meal?.title ?? _food.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      _buildSourceBadge(_food.source, theme),
                    ],
                  ),
                  if (displayIngredients.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displayIngredients
                          .map(
                            (name) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(color: textPrimary),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Serving Size',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedServing,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor:
                          theme.inputDecorationTheme.fillColor ?? theme.cardColor,
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
                    items: _servingOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedServing = value;
                        _servingMultiplier = _getServingMultiplier(value);
                      });
                    },
                  ),
                  const SizedBox(height: 24),
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
                              '$calories',
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
                    _getNutrient(widget.initialFood.saturatedFat),
                    'g',
                  ),
                  _buildFactRow(
                    'Polyunsaturated Fat',
                    _getNutrient(widget.initialFood.polyunsaturatedFat),
                    'g',
                  ),
                  _buildFactRow(
                    'Monounsaturated Fat',
                    _getNutrient(widget.initialFood.monounsaturatedFat),
                    'g',
                  ),
                  _buildFactRow(
                    'Cholesterol',
                    _getNutrient(widget.initialFood.cholesterol),
                    'mg',
                  ),
                  _buildFactRow(
                    'Sodium',
                    _getNutrient(widget.initialFood.sodium),
                    'mg',
                  ),
                  _buildFactRow(
                    'Fiber',
                    _getNutrient(widget.initialFood.fiber),
                    'g',
                  ),
                  _buildFactRow(
                    'Sugar',
                    _getNutrient(widget.initialFood.sugar),
                    'g',
                  ),
                  _buildFactRow(
                    'Potassium',
                    _getNutrient(widget.initialFood.potassium),
                    'mg',
                  ),
                  _buildFactRow(
                    'Vitamin A',
                    _getNutrient(widget.initialFood.vitaminA),
                    'mcg',
                  ),
                  _buildFactRow(
                    'Vitamin C',
                    _getNutrient(widget.initialFood.vitaminC),
                    'mg',
                  ),
                  _buildFactRow(
                    'Calcium',
                    _getNutrient(widget.initialFood.calcium),
                    'mg',
                  ),
                  _buildFactRow(
                    'Iron',
                    _getNutrient(widget.initialFood.iron),
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
                  widget.isSelectionMode ? 'Add' : (widget.meal != null ? 'Done' : 'Save'),
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
    final theme = Theme.of(context);
    final textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary =
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
    final theme = Theme.of(context);
    final textPrimary =
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
