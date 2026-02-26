import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/models/saved_food_model.dart';
import 'package:physiq/services/saved_food_service.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart'; // Reuse for consistency

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
                  return _buildFoodCard(food);
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
          onTap: () {
            // Convert to Food model and open preview
            final previewFood = Food(
              id: food.originalId.isNotEmpty
                  ? food.originalId
                  : food.id, // Use original external ID if available
              name: food.name,
              category: 'Saved',
              unit: food.servingSize,
              baseWeightG: 0, // Not stored in SavedFood usually, but okay
              calories: food.nutrition.calories,
              protein: food.nutrition.protein,
              carbs: food.nutrition.carbs,
              fat: food.nutrition.fat,
              source: food.sourceType,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealPreviewScreen(
                  initialFood: previewFood,
                  initialQuantity: food.servingAmount,
                ),
              ),
            );
          },
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
                        "${food.nutrition.calories.toInt()} cal • ${food.servingSize}",
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
                        // Optional: Pop if you want to close, but requirement says "Do NOT delete",
                        // and staying on screen is usually better for quick logging multiple items.
                        // I will NOT pop here to allow multiple logs.
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
