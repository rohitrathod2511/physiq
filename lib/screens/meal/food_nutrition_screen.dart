import 'package:flutter/material.dart';
import 'dart:io';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/services/cloud_functions_client.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/widgets/macro_icons.dart';

class FoodNutritionScreen extends ConsumerStatefulWidget {
  final Food food;
  final double? servingAmount;
  final String? servingUnit;

  const FoodNutritionScreen({
    super.key,
    required this.food,
    this.servingAmount,
    this.servingUnit,
  });

  @override
  ConsumerState<FoodNutritionScreen> createState() => _FoodNutritionScreenState();
}

class _FoodNutritionScreenState extends ConsumerState<FoodNutritionScreen> {
  late Food _baseFood;
  int _servingAmount = 1;
  late String _selectedUnit; // 'Tbsp', 'G', 'Serving'
  final CloudFunctionsClient _cloudFunctions = CloudFunctionsClient();

  @override
  void initState() {
    super.initState();
    _baseFood = widget.food;
    _servingAmount = widget.servingAmount?.toInt() ?? 1;
    _selectedUnit = widget.servingUnit ?? _getInitialUnit();
  }

  String _getInitialUnit() {
    if (_baseFood.servingOptions.any((o) => o.label.toLowerCase().contains('tbsp'))) {
      return 'Tbsp';
    }
    return 'G';
  }

  double _getMultiplier() {
    double baseGrams = 100.0;
    double targetGrams = 0.0;

    if (_selectedUnit == 'G') {
      targetGrams = 1.0;
    } else if (_selectedUnit == 'Tbsp') {
      final tbspOption = _baseFood.servingOptions.firstWhere(
        (o) => o.label.toLowerCase().contains('tbsp'),
        orElse: () => ServingOption(label: 'Tbsp', grams: 15.0),
      );
      targetGrams = tbspOption.grams;
    } else {
      // 'Serving'
      targetGrams = _baseFood.baseWeightG > 0 ? _baseFood.baseWeightG : 100.0;
    }

    return (targetGrams * _servingAmount) / baseGrams;
  }

  double _calculateNutrient(double baseValue) {
    return baseValue * _getMultiplier();
  }

  void _updateServingAmount(int delta) {
    setState(() {
      _servingAmount = (_servingAmount + delta).clamp(1, 99);
    });
  }

  Future<void> _onSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final multiplier = _getMultiplier();
    final mealModel = MealModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      name: _baseFood.name,
      calories: _calculateNutrient(_baseFood.calories),
      proteinG: _calculateNutrient(_baseFood.protein),
      carbsG: _calculateNutrient(_baseFood.carbs),
      fatG: _calculateNutrient(_baseFood.fat),
      timestamp: DateTime.now(),
      imageUrl: null,
      source: 'database',
      servingAmount: _servingAmount.toDouble(),
      servingDescription: _selectedUnit,
      fullNutritionMap: {
        'saturatedFat': _calculateNutrient(_baseFood.saturatedFat ?? 0),
        'polyunsaturatedFat': _calculateNutrient(_baseFood.polyunsaturatedFat ?? 0),
        'monounsaturatedFat': _calculateNutrient(_baseFood.monounsaturatedFat ?? 0),
        'cholesterol': _calculateNutrient(_baseFood.cholesterol ?? 0),
        'sodium': _calculateNutrient(_baseFood.sodium ?? 0),
        'fiber': _calculateNutrient(_baseFood.fiber ?? 0),
        'sugar': _calculateNutrient(_baseFood.sugar ?? 0),
        'potassium': _calculateNutrient(_baseFood.potassium ?? 0),
        'vitaminA': _calculateNutrient(_baseFood.vitaminA ?? 0),
        'vitaminC': _calculateNutrient(_baseFood.vitaminC ?? 0),
        'calcium': _calculateNutrient(_baseFood.calcium ?? 0),
        'iron': _calculateNutrient(_baseFood.iron ?? 0),
      },
    );

    await ref.read(homeViewModelProvider.notifier).logMeal(mealModel);

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_baseFood.name} logged successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = _calculateNutrient(_baseFood.calories).round();
    final protein = _calculateNutrient(_baseFood.protein).round();
    final carbs = _calculateNutrient(_baseFood.carbs).round();
    final fat = _calculateNutrient(_baseFood.fat).round();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nutrition',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _baseFood.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.bookmark_border, size: 28),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Serving Size Measurement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildUnitTab('Tbsp'),
                const SizedBox(width: 12),
                _buildUnitTab('G'),
                const SizedBox(width: 12),
                _buildUnitTab('Serving'),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Serving Amount',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _updateServingAmount(-1),
                        icon: const Icon(Icons.remove, size: 20),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_servingAmount',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateServingAmount(1),
                        icon: const Icon(Icons.add, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildCaloriesCard(calories),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMacroCard('Protein', '${protein}g', const FishIcon(color: Color(0xFFE57373), size: 16), const Color(0xFFFFEBEE)),
                const SizedBox(width: 8),
                _buildMacroCard('Carbs', '${carbs}g', const WheatIcon(color: Color(0xFFFFB74D), size: 16), const Color(0xFFFFF3E0)),
                const SizedBox(width: 8),
                _buildMacroCard('Fats', '${fat}g', const AvocadoIcon(color: Color(0xFF64B5F6), size: 16), const Color(0xFFE3F2FD)),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Other nutrition facts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildNutritionFact('Saturated Fat', '${_calculateNutrient(_baseFood.saturatedFat ?? 0).round()}g'),
            _buildNutritionFact('Polyunsaturated Fat', '${_calculateNutrient(_baseFood.polyunsaturatedFat ?? 0).round()}g'),
            _buildNutritionFact('Monounsaturated Fat', '${_calculateNutrient(_baseFood.monounsaturatedFat ?? 0).round()}g'),
            _buildNutritionFact('Cholesterol', '${_calculateNutrient(_baseFood.cholesterol ?? 0).round()}mg'),
            _buildNutritionFact('Sodium', '${_calculateNutrient(_baseFood.sodium ?? 0).round()}mg'),
            _buildNutritionFact('Fiber', '${_calculateNutrient(_baseFood.fiber ?? 0).round()}g'),
            _buildNutritionFact('Sugar', '${_calculateNutrient(_baseFood.sugar ?? 0).round()}g'),
            _buildNutritionFact('Potassium', '${_calculateNutrient(_baseFood.potassium ?? 0).round()}mg'),
            _buildNutritionFact('Vitamin A', '${_calculateNutrient(_baseFood.vitaminA ?? 0).round()}mcg'),
            _buildNutritionFact('Vitamin C', '${_calculateNutrient(_baseFood.vitaminC ?? 0).round()}mg'),
            _buildNutritionFact('Calcium', '${_calculateNutrient(_baseFood.calcium ?? 0).round()}mg'),
            _buildNutritionFact('Iron', '${_calculateNutrient(_baseFood.iron ?? 0).round()}mg'),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: Container(
        color: const Color(0xFFFBFBFC),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
          ),
          child: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildUnitTab(String unit) {
    bool isSelected = _selectedUnit == unit;
    return GestureDetector(
      onTap: () => setState(() => _selectedUnit = unit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.1)),
        ),
        child: Text(
          unit,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesCard(int calories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calories', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              Text('$calories', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Icon(Icons.edit_outlined, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String label, String value, Widget icon, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                  child: icon,
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.edit_outlined, color: Colors.grey[300], size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionFact(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
