import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/models/saved_food_model.dart';
import 'package:physiq/screens/food/custom_food_detail_screen.dart';
import 'package:physiq/screens/meal/food_nutrition_screen.dart';
import 'package:physiq/screens/meal/meal_detail_screen.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/services/saved_food_service.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class SavedScansScreen extends ConsumerStatefulWidget {
  const SavedScansScreen({super.key});

  @override
  ConsumerState<SavedScansScreen> createState() => _SavedScansScreenState();
}

class _SavedScansScreenState extends ConsumerState<SavedScansScreen> {
  final _service = SavedFoodService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteFood(String foodId) async {
    final uid = _service.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('saved_scans')
          .doc(uid)
          .collection('items')
          .doc(foodId)
          .delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting food: $e")),
      );
    }
  }

  Future<void> _openSavedItem(SavedFood food) async {
    final route = _buildSavedItemRoute(food);
    if (route == null) return;
    if (food.type == 'scan') {
      await Navigator.of(context, rootNavigator: true).push(route);
    } else {
      await Navigator.push(context, route);
    }
  }

  Route<dynamic>? _buildSavedItemRoute(SavedFood food) {
    switch (food.type) {
      case 'meal':
        return MaterialPageRoute(
          builder: (_) => MealDetailScreen(meal: _buildMeal(food)),
        );
      case 'custom_food':
        return MaterialPageRoute(
          builder: (_) => CustomFoodDetailScreen(food: _buildCustomFood(food)),
        );
      case 'usda_food':
        final hasSourceFood = _extractMap(food.sourceData, 'food') != null;
        return MaterialPageRoute(
          builder: (_) => FoodNutritionScreen(
            food: _buildFood(food, sourceOverride: 'usda_food'),
            servingAmount: hasSourceFood ? food.servingAmount : 1,
            servingUnit: food.servingSize,
          ),
        );
      case 'scan':
        final meal = _buildSavedMeal(food);
        final imagePath = _resolveImagePath(food, meal);
        return MaterialPageRoute(
          builder: (_) => MealPreviewScreen(
            initialFood: _buildFood(food, sourceOverride: 'scan'),
            meal: meal,
            initialQuantity: food.servingAmount,
            imagePath: imagePath,
          ),
        );
      default:
        return null;
    }
  }

  MyMeal _buildMeal(SavedFood food) {
    final mealData = _extractMap(food.sourceData, 'meal');
    final itemsData = mealData?['items'] as List<dynamic>? ?? const [];

    return MyMeal(
      id: _stringValue(
        mealData?['id'],
        fallback: food.originalId.isNotEmpty ? food.originalId : food.id,
      ),
      name: _stringValue(mealData?['name'], fallback: food.name),
      totalCalories: _doubleValue(
        mealData?['totalCalories'],
        fallback: food.nutrition.calories,
      ),
      totalProtein: _doubleValue(
        mealData?['totalProtein'],
        fallback: food.nutrition.protein,
      ),
      totalCarbs: _doubleValue(
        mealData?['totalCarbs'],
        fallback: food.nutrition.carbs,
      ),
      totalFat: _doubleValue(mealData?['totalFat'], fallback: food.nutrition.fat),
      createdAt: _dateValue(mealData?['createdAt'], fallback: food.createdAt),
      items: itemsData
          .map((item) => _normalizeMap(item))
          .whereType<Map<String, dynamic>>()
          .map(MealItem.fromMap)
          .toList(),
    );
  }

  CustomFood _buildCustomFood(SavedFood food) {
    final foodData = _extractMap(food.sourceData, 'food');
    final nutritionData =
        _extractMap(foodData, 'nutrition') ?? food.nutrition.toJson();

    return CustomFood(
      id: _stringValue(
        foodData?['id'],
        fallback: food.originalId.isNotEmpty ? food.originalId : food.id,
      ),
      userId: _stringValue(foodData?['userId'], fallback: food.userId),
      brandName: _stringValue(foodData?['brandName']),
      description: _stringValue(foodData?['description'], fallback: food.name),
      servingSize: _stringValue(foodData?['servingSize'], fallback: food.servingSize),
      servingPerContainer: _doubleValue(
        foodData?['servingPerContainer'],
        fallback: food.servingAmount > 0 ? food.servingAmount : 1.0,
      ),
      nutrition: CustomFoodNutrition.fromJson(nutritionData),
      createdAt: _dateValue(foodData?['createdAt'], fallback: food.createdAt),
    );
  }

  Food _buildFood(SavedFood food, {required String sourceOverride}) {
    final foodData = _extractMap(food.sourceData, 'food');
    if (foodData != null) {
      final id = _stringValue(
        foodData['id'],
        fallback: food.originalId.isNotEmpty ? food.originalId : food.id,
      );
      return Food.fromJson(foodData, id).copyWith(source: sourceOverride);
    }

    return Food(
      id: food.originalId.isNotEmpty ? food.originalId : food.id,
      name: food.name,
      category: 'Saved',
      unit: food.servingSize,
      baseWeightG: 100,
      calories: food.nutrition.calories,
      protein: food.nutrition.protein,
      carbs: food.nutrition.carbs,
      fat: food.nutrition.fat,
      source: sourceOverride,
      saturatedFat:
          food.nutrition.saturatedFat > 0 ? food.nutrition.saturatedFat : null,
      polyunsaturatedFat: food.nutrition.polyunsaturatedFat > 0
          ? food.nutrition.polyunsaturatedFat
          : null,
      monounsaturatedFat: food.nutrition.monounsaturatedFat > 0
          ? food.nutrition.monounsaturatedFat
          : null,
      cholesterol:
          food.nutrition.cholesterol > 0 ? food.nutrition.cholesterol : null,
      sodium: food.nutrition.sodium > 0 ? food.nutrition.sodium : null,
      fiber: food.nutrition.fiber > 0 ? food.nutrition.fiber : null,
      sugar: food.nutrition.sugar > 0 ? food.nutrition.sugar : null,
      calcium: food.nutrition.calcium > 0 ? food.nutrition.calcium : null,
      iron: food.nutrition.iron > 0 ? food.nutrition.iron : null,
      potassium: food.nutrition.potassium > 0 ? food.nutrition.potassium : null,
      vitaminA: food.nutrition.vitaminA > 0 ? food.nutrition.vitaminA : null,
    );
  }

  Meal? _buildSavedMeal(SavedFood food) {
    final mealData = _extractMap(food.sourceData, 'meal');
    if (mealData != null) {
      final id = _stringValue(
        mealData['id'],
        fallback: food.originalId.isNotEmpty ? food.originalId : food.id,
      );
      return Meal.fromJson(mealData, id);
    }

    return Meal(
      id: food.originalId.isNotEmpty ? food.originalId : food.id,
      imageUrl: _stringValue(food.sourceData?['imageUrl']),
      title: food.name,
      container: food.servingSize,
      ingredients: _extractIngredients(food.sourceData?['items']),
      createdAt: food.createdAt,
    );
  }

  List<MealIngredient> _extractIngredients(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => _normalizeMap(item))
        .whereType<Map<String, dynamic>>()
        .map(MealIngredient.fromJson)
        .toList();
  }

  String? _resolveImagePath(SavedFood food, Meal? meal) {
    final imagePath = _stringValue(food.sourceData?['imagePath']);
    if (imagePath.isNotEmpty) {
      return imagePath;
    }

    final imageUrl = meal?.imageUrl ?? _stringValue(food.sourceData?['imageUrl']);
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

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  double _doubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  DateTime _dateValue(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return StreamBuilder<List<SavedFood>>(
      stream: _service.getUserSavedFoods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final allFoods = snapshot.data ?? [];
        final foods = _searchQuery.isEmpty
            ? allFoods
            : allFoods
                  .where((f) => f.name.toLowerCase().contains(_searchQuery))
                  .toList();

        if (allFoods.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search saved items',
                  prefixIcon: Icon(Icons.search, color: textSecondary),
                  filled: true,
                  fillColor:
                      theme.inputDecorationTheme.fillColor ?? theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: foods.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final food = foods[index];
                  return Dismissible(
                    key: Key(food.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: theme.colorScheme.error,
                      child: Icon(
                        Icons.delete,
                        color: theme.colorScheme.onError,
                      ),
                    ),
                    onDismissed: (direction) {
                      _deleteFood(food.id);
                    },
                    child: _buildFoodCard(food),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final ThemeData theme = Theme.of(context);
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text("Saved Scans", style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            "Your saved foods and meals will appear here",
            style: TextStyle(color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(SavedFood food) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openSavedItem(food),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${food.nutrition.calories.toInt()} cal - ${food.servingSize}",
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: textPrimary,
                    size: 28,
                  ),
                  onPressed: () async {
                    try {
                      await _service.logSavedFood(food, DateTime.now());

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null && mounted) {
                        ref
                            .read(homeViewModelProvider.notifier)
                            .fetchRecentMeals(uid);
                        ref
                            .read(homeViewModelProvider.notifier)
                            .fetchDailySummary(DateTime.now(), uid);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Logged ${food.name}"),
                            backgroundColor: theme.colorScheme.primary,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error logging food: $e")),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
