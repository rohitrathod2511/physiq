import 'dart:async';

import 'package:flutter/material.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/screens/meal/food_nutrition_screen.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/theme/design_system.dart';

class FoodSearchForMealScreen extends StatefulWidget {
  const FoodSearchForMealScreen({super.key});

  @override
  State<FoodSearchForMealScreen> createState() =>
      _FoodSearchForMealScreenState();
}

class _FoodSearchForMealScreenState extends State<FoodSearchForMealScreen> {
  late TextEditingController _searchController;
  final FoodService _foodService = FoodService();

  List<Food> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;
  String? _addingFoodId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _foodService.searchFoods(query);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _hasSearched = true;
        });
      } catch (error) {
        debugPrint('Search error: $error');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasSearched = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Search failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _openFoodDetails(Food food) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodNutritionScreen(food: food),
      ),
    );
  }

  Future<void> _addFoodToMeal(Food food) async {
    if (_addingFoodId != null) return;

    setState(() {
      _addingFoodId = food.id;
    });

    try {
      var selectedFood = food;

      if (food.isPartial && (food.fdcId?.isNotEmpty ?? false)) {
        final detailedFood = await _foodService.getFoodDetails(food.fdcId!);
        if (detailedFood != null) {
          selectedFood = detailedFood;
        }
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        MealItem(
          foodId: selectedFood.id,
          foodName: selectedFood.name,
          quantity: 1,
          servingLabel: selectedFood.unit.isNotEmpty
              ? selectedFood.unit
              : '1 serving',
          calories: selectedFood.calories,
          protein: selectedFood.protein,
          carbs: selectedFood.carbs,
          fat: selectedFood.fat,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _addingFoodId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to add food: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.body.copyWith(color: textPrimary),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Describe what you ate',
                  hintStyle: AppTextStyles.body.copyWith(color: textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  prefixIcon: Icon(Icons.search, color: textSecondary),
                  suffixIcon: _searchController.text.isEmpty
                      ? IconButton(
                          icon: Icon(Icons.mic, color: textPrimary),
                          onPressed: () async {
                            final text = await showVoiceSearchDialog(context);
                            if (text != null && text.isNotEmpty) {
                              _searchController.text = text;
                              _onSearchChanged(text);
                            }
                          },
                        )
                      : IconButton(
                          icon: Icon(Icons.clear, color: textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasSearched ? Icons.search_off : Icons.search,
                            size: 64,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasSearched
                                ? 'No results, try another search'
                                : 'Search for food',
                            style: AppTextStyles.h3.copyWith(
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _hasSearched
                                ? 'Try another term to add a food item.'
                                : 'e.g. Apple, Chicken Biryani, Rice',
                            style: AppTextStyles.body.copyWith(
                              color: textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final food = _searchResults[index];
                      final isAdding = _addingFoodId == food.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _openFoodDetails(food),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Text(
                              food.name.isNotEmpty
                                  ? food.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            food.name,
                            style: AppTextStyles.h3.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${food.calories.toInt()} cal - ${food.unit}',
                              style: AppTextStyles.label.copyWith(
                                color: textSecondary,
                              ),
                            ),
                          ),
                          trailing: isAdding
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : IconButton(
                                  onPressed: () => _addFoodToMeal(food),
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
