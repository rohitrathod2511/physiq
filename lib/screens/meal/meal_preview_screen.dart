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

  double _getNutrient(double Function(FatSecretServing) selector, double? fallback) {
    if (_selectedServing != null) return selector(_selectedServing!) * _quantity;
    return (fallback ?? 0) * _quantity;
  }

  Future<void> _saveMeal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final calories = _getNutrient((s) => s.calories, widget.initialFood.calories);
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
      servingDescription: _selectedServing?.description ?? widget.initialFood.unit,
      servingAmount: _quantity,
      fullNutritionMap: _selectedServing != null
          ? {
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fat,
              'saturatedFat': _getNutrient((s) => s.saturatedFat, widget.initialFood.saturatedFat),
              'polyunsaturatedFat':
                  _getNutrient((s) => s.polyunsaturatedFat, widget.initialFood.polyunsaturatedFat),
              'monounsaturatedFat':
                  _getNutrient((s) => s.monounsaturatedFat, widget.initialFood.monounsaturatedFat),
              'cholesterol': _getNutrient((s) => s.cholesterol, widget.initialFood.cholesterol),
              'sodium': _getNutrient((s) => s.sodium, widget.initialFood.sodium),
              'fiber': _getNutrient((s) => s.fiber, widget.initialFood.fiber),
              'sugar': _getNutrient((s) => s.sugar, widget.initialFood.sugar),
              'potassium': _getNutrient((s) => s.potassium, widget.initialFood.potassium),
              'vitaminA': _getNutrient((s) => s.vitaminA, widget.initialFood.vitaminA),
              'vitaminC': _getNutrient((s) => s.vitaminC, widget.initialFood.vitaminC),
              'calcium': _getNutrient((s) => s.calcium, widget.initialFood.calcium),
              'iron': _getNutrient((s) => s.iron, widget.initialFood.iron),
            }
          : {},
    );

    ref.read(homeViewModelProvider.notifier).logMeal(meal);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cals = _getNutrient((s) => s.calories, widget.initialFood.calories).round();
    final protein = _getNutrient((s) => s.protein, widget.initialFood.protein).round();
    final carbs = _getNutrient((s) => s.carbs, widget.initialFood.carbs).round();
    final fat = _getNutrient((s) => s.fat, widget.initialFood.fat).round();
    final servings = _detailedFood?.servings ?? const <FatSecretServing>[];
    final selectedServingIndex = (_selectedServing != null && servings.isNotEmpty)
        ? servings.indexWhere((serving) => serving.id == _selectedServing!.id)
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Nutrition',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          )
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
                        color: Colors.grey[100],
                      ),
                      child: Image.file(
                        File(widget.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
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
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                        const Text(
                          'Serving Size',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: selectedServingIndex < 0 ? 0 : selectedServingIndex,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
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
                        const Text(
                          'Serving Size',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            widget.initialFood.unit,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Serving Amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _updateQuantity(-0.5),
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              width: 50,
                              alignment: Alignment.center,
                              child: Text(
                                _quantity % 1 == 0
                                    ? _quantity.toInt().toString()
                                    : _quantity.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(0.5),
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_fire_department, color: Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Calories', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('$cals',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MacroCard(
                          label: 'Carbs',
                          value: '${carbs}g',
                          icon: Icons.grain,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MacroCard(
                          label: 'Fats',
                          value: '${fat}g',
                          icon: Icons.water_drop,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text(
                    'Other nutrition facts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFactRow(
                    'Saturated Fat',
                    _getNutrient((s) => s.saturatedFat, widget.initialFood.saturatedFat),
                    'g',
                  ),
                  _buildFactRow(
                    'Polyunsaturated Fat',
                    _getNutrient((s) => s.polyunsaturatedFat, widget.initialFood.polyunsaturatedFat),
                    'g',
                  ),
                  _buildFactRow(
                    'Monounsaturated Fat',
                    _getNutrient((s) => s.monounsaturatedFat, widget.initialFood.monounsaturatedFat),
                    'g',
                  ),
                  _buildFactRow(
                    'Cholesterol',
                    _getNutrient((s) => s.cholesterol, widget.initialFood.cholesterol),
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
                    _getNutrient((s) => s.potassium, widget.initialFood.potassium),
                    'mg',
                  ),
                  _buildFactRow(
                    'Vitamin A',
                    _getNutrient((s) => s.vitaminA, widget.initialFood.vitaminA),
                    'mcg',
                  ),
                  _buildFactRow(
                    'Vitamin C',
                    _getNutrient((s) => s.vitaminC, widget.initialFood.vitaminC),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  widget.isSelectionMode ? 'Add' : 'Save',
                  style: const TextStyle(
                    color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
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
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.normal),
              ),
              const Spacer(),
              Icon(Icons.edit, size: 12, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
