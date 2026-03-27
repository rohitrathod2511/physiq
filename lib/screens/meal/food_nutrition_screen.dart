import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/models/saved_food_model.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/services/saved_food_service.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
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
  ConsumerState<FoodNutritionScreen> createState() =>
      _FoodNutritionScreenState();
}

class _FoodNutritionScreenState extends ConsumerState<FoodNutritionScreen> {
  final FoodService _foodService = FoodService();

  late Food _baseFood;
  late List<ServingOption> _servingOptions;
  late ServingOption _selectedServing;
  int _servingAmount = 1;
  bool _isLoadingDetails = false;
  bool _isSavingToSaved = false;
  String? _detailsError;

  @override
  void initState() {
    super.initState();
    _baseFood = widget.food;
    _servingAmount = widget.servingAmount?.round().clamp(1, 99) ?? 1;
    _configureServingOptions(preferredLabel: widget.servingUnit);
    _loadFoodDetailsIfNeeded();
  }

  Future<void> _loadFoodDetailsIfNeeded() async {
    if (!_baseFood.isPartial || (_baseFood.fdcId?.isEmpty ?? true)) {
      return;
    }

    setState(() {
      _isLoadingDetails = true;
      _detailsError = null;
    });

    final detailedFood = await _foodService.getFoodDetails(_baseFood.fdcId!);
    if (!mounted) return;

    if (detailedFood == null) {
      setState(() {
        _isLoadingDetails = false;
        _detailsError = 'Nutrition not available';
      });
      return;
    }

    setState(() {
      _baseFood = detailedFood;
      _configureServingOptions(preferredLabel: widget.servingUnit);
      _isLoadingDetails = false;
      _detailsError = null;
    });
  }

  void _configureServingOptions({String? preferredLabel}) {
    final options = <ServingOption>[];

    void addOption(ServingOption option) {
      if (option.grams <= 0) return;
      final alreadyExists = options.any(
        (existing) =>
            existing.label.toLowerCase() == option.label.toLowerCase() &&
            (existing.grams - option.grams).abs() < 0.01,
      );
      if (!alreadyExists) {
        options.add(option);
      }
    }

    addOption(const ServingOption(label: '100g', grams: 100));
    for (final option in _baseFood.servingOptions) {
      addOption(option);
    }

    _servingOptions = options;
    _selectedServing = _servingOptions.firstWhere(
      (option) =>
          preferredLabel != null &&
          option.label.toLowerCase() == preferredLabel.toLowerCase(),
      orElse: () => _servingOptions.first,
    );
  }

  double get _baseGrams =>
      _baseFood.baseWeightG > 0 ? _baseFood.baseWeightG : 100.0;

  double get _selectedServingGrams =>
      _selectedServing.grams > 0 ? _selectedServing.grams : _baseGrams;

  double _getMultiplier() {
    return (_selectedServingGrams * _servingAmount) / _baseGrams;
  }

  double _calculateNutrient(double baseValue) {
    return baseValue * _getMultiplier();
  }

  double? _calculateOptionalNutrient(double? baseValue) {
    if (baseValue == null) return null;
    return baseValue * _getMultiplier();
  }

  bool get _hasNutritionData {
    return _baseFood.calories > 0 ||
        _baseFood.protein > 0 ||
        _baseFood.carbs > 0 ||
        _baseFood.fat > 0 ||
        _baseFood.saturatedFat != null ||
        _baseFood.polyunsaturatedFat != null ||
        _baseFood.monounsaturatedFat != null ||
        _baseFood.cholesterol != null ||
        _baseFood.sodium != null ||
        _baseFood.fiber != null ||
        _baseFood.sugar != null ||
        _baseFood.potassium != null ||
        _baseFood.vitaminA != null ||
        _baseFood.vitaminC != null ||
        _baseFood.calcium != null ||
        _baseFood.iron != null;
  }

  void _updateServingAmount(int delta) {
    setState(() {
      _servingAmount = (_servingAmount + delta).clamp(1, 99);
    });
  }

  String _formatServingLabel(ServingOption option) {
    if (option.label.trim().toLowerCase() == '100g') {
      return '100g';
    }
    return '${option.label} (${_formatQuantity(option.grams)}g)';
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatMacro(double value, {String suffix = 'g'}) {
    return '${_formatQuantity(value)}$suffix';
  }

  String _formatOptionalValue(double? value, {required String suffix}) {
    if (value == null) return 'Nutrition unavailable';
    return '${_formatQuantity(value)}$suffix';
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
        name: _baseFood.name,
        type: 'usda_food',
        sourceType: 'usda_food',
        servingSize: _selectedServing.label,
        servingAmount: _servingAmount.toDouble(),
        nutrition: SavedFoodNutrition(
          calories: _calculateNutrient(_baseFood.calories),
          protein: _calculateNutrient(_baseFood.protein),
          carbs: _calculateNutrient(_baseFood.carbs),
          fat: _calculateNutrient(_baseFood.fat),
          saturatedFat: _calculateOptionalNutrient(_baseFood.saturatedFat) ?? 0,
          polyunsaturatedFat:
              _calculateOptionalNutrient(_baseFood.polyunsaturatedFat) ?? 0,
          monounsaturatedFat:
              _calculateOptionalNutrient(_baseFood.monounsaturatedFat) ?? 0,
          cholesterol: _calculateOptionalNutrient(_baseFood.cholesterol) ?? 0,
          sodium: _calculateOptionalNutrient(_baseFood.sodium) ?? 0,
          potassium: _calculateOptionalNutrient(_baseFood.potassium) ?? 0,
          sugar: _calculateOptionalNutrient(_baseFood.sugar) ?? 0,
          fiber: _calculateOptionalNutrient(_baseFood.fiber) ?? 0,
          vitaminA: _calculateOptionalNutrient(_baseFood.vitaminA) ?? 0,
          calcium: _calculateOptionalNutrient(_baseFood.calcium) ?? 0,
          iron: _calculateOptionalNutrient(_baseFood.iron) ?? 0,
        ),
        createdAt: DateTime.now(),
        originalId: _baseFood.fdcId ?? _baseFood.id,
        sourceData: {
          'food': {..._baseFood.toJson(), 'id': _baseFood.id},
        },
      );

      await SavedFoodService().saveFood(savedFood);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${_baseFood.name} saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save ${_baseFood.name}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToSaved = false;
        });
      }
    }
  }

  Future<void> _onSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
      servingDescription: _selectedServing.label,
      fullNutritionMap: {
        if (_baseFood.saturatedFat != null)
          'saturatedFat': _calculateNutrient(_baseFood.saturatedFat!),
        if (_baseFood.polyunsaturatedFat != null)
          'polyunsaturatedFat': _calculateNutrient(
            _baseFood.polyunsaturatedFat!,
          ),
        if (_baseFood.monounsaturatedFat != null)
          'monounsaturatedFat': _calculateNutrient(
            _baseFood.monounsaturatedFat!,
          ),
        if (_baseFood.cholesterol != null)
          'cholesterol': _calculateNutrient(_baseFood.cholesterol!),
        if (_baseFood.sodium != null)
          'sodium': _calculateNutrient(_baseFood.sodium!),
        if (_baseFood.fiber != null)
          'fiber': _calculateNutrient(_baseFood.fiber!),
        if (_baseFood.sugar != null)
          'sugar': _calculateNutrient(_baseFood.sugar!),
        if (_baseFood.potassium != null)
          'potassium': _calculateNutrient(_baseFood.potassium!),
        if (_baseFood.vitaminA != null)
          'vitaminA': _calculateNutrient(_baseFood.vitaminA!),
        if (_baseFood.vitaminC != null)
          'vitaminC': _calculateNutrient(_baseFood.vitaminC!),
        if (_baseFood.calcium != null)
          'calcium': _calculateNutrient(_baseFood.calcium!),
        if (_baseFood.iron != null) 'iron': _calculateNutrient(_baseFood.iron!),
      },
    );

    await ref.read(homeViewModelProvider.notifier).logMeal(mealModel);

    if (!mounted) return;

    Navigator.popUntil(context, (route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_baseFood.name} logged successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final calories = _hasNutritionData
        ? _calculateNutrient(_baseFood.calories)
        : null;
    final protein = _hasNutritionData
        ? _calculateNutrient(_baseFood.protein)
        : null;
    final carbs = _hasNutritionData
        ? _calculateNutrient(_baseFood.carbs)
        : null;
    final fat = _hasNutritionData ? _calculateNutrient(_baseFood.fat) : null;

    final otherFacts = <({String label, double? value, String unit})>[
      (
        label: 'Saturated Fat',
        value: _calculateOptionalNutrient(_baseFood.saturatedFat),
        unit: 'g',
      ),
      (
        label: 'Polyunsaturated Fat',
        value: _calculateOptionalNutrient(_baseFood.polyunsaturatedFat),
        unit: 'g',
      ),
      (
        label: 'Monounsaturated Fat',
        value: _calculateOptionalNutrient(_baseFood.monounsaturatedFat),
        unit: 'g',
      ),
      (
        label: 'Cholesterol',
        value: _calculateOptionalNutrient(_baseFood.cholesterol),
        unit: 'mg',
      ),
      (
        label: 'Sodium',
        value: _calculateOptionalNutrient(_baseFood.sodium),
        unit: 'mg',
      ),
      (
        label: 'Fiber',
        value: _calculateOptionalNutrient(_baseFood.fiber),
        unit: 'g',
      ),
      (
        label: 'Sugar',
        value: _calculateOptionalNutrient(_baseFood.sugar),
        unit: 'g',
      ),
      (
        label: 'Potassium',
        value: _calculateOptionalNutrient(_baseFood.potassium),
        unit: 'mg',
      ),
      (
        label: 'Vitamin A',
        value: _calculateOptionalNutrient(_baseFood.vitaminA),
        unit: 'mcg',
      ),
      (
        label: 'Vitamin C',
        value: _calculateOptionalNutrient(_baseFood.vitaminC),
        unit: 'mg',
      ),
      (
        label: 'Calcium',
        value: _calculateOptionalNutrient(_baseFood.calcium),
        unit: 'mg',
      ),
      (
        label: 'Iron',
        value: _calculateOptionalNutrient(_baseFood.iron),
        unit: 'mg',
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nutrition',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSavingToSaved ? null : _saveToSavedFoods,
                        icon: Icon(
                          Icons.bookmark_border,
                          size: 28,
                          color: theme.iconTheme.color ?? textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_detailsError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _detailsError!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Serving Size Measurement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _servingOptions
                          .map(
                            (option) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildServingChip(option),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Serving Amount • ${_formatQuantity(_selectedServingGrams)}g each',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => _updateServingAmount(-1),
                              icon: const Icon(Icons.remove, size: 20),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '$_servingAmount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
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
                  _buildCaloriesCard(
                    calories == null
                        ? 'Nutrition unavailable'
                        : _formatQuantity(calories),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMacroCard(
                        'Protein',
                        protein == null
                            ? 'Nutrition unavailable'
                            : _formatMacro(protein),
                        FishIcon(color: theme.colorScheme.error, size: 16),
                        theme.colorScheme.errorContainer,
                      ),
                      const SizedBox(width: 8),
                      _buildMacroCard(
                        'Carbs',
                        carbs == null
                            ? 'Nutrition unavailable'
                            : _formatMacro(carbs),
                        WheatIcon(color: theme.colorScheme.secondary, size: 16),
                        theme.colorScheme.secondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      _buildMacroCard(
                        'Fats',
                        fat == null
                            ? 'Nutrition unavailable'
                            : _formatMacro(fat),
                        AvocadoIcon(
                          color: theme.colorScheme.tertiary,
                          size: 16,
                        ),
                        theme.colorScheme.tertiaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Other nutrition facts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (otherFacts.every((fact) => fact.value == null))
                    _buildNutritionFact('Status', 'Nutrition unavailable')
                  else
                    ...otherFacts
                        .where((fact) => fact.value != null)
                        .map(
                          (fact) => _buildNutritionFact(
                            fact.label,
                            _formatOptionalValue(fact.value, suffix: fact.unit),
                          ),
                        ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
      bottomSheet: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: ElevatedButton(
          onPressed: _isLoadingDetails ? null : _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: Text(
            'Save',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServingChip(ServingOption serving) {
    final ThemeData theme = Theme.of(context);
    final isSelected =
        _selectedServing.label == serving.label &&
        (_selectedServing.grams - serving.grams).abs() < 0.01;

    return GestureDetector(
      onTap: () => setState(() => _selectedServing = serving),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.dividerColor,
          ),
        ),
        child: Text(
          _formatServingLabel(serving),
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCaloriesCard(String value) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
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
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calories',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.edit_outlined, color: textSecondary, size: 20),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String label, String value, Widget icon, Color bg) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
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
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: icon,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.edit_outlined, color: textSecondary, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionFact(String label, String value) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: textPrimary),
            ),
          ),
          const SizedBox(width: 12),
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
