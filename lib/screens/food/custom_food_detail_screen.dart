import 'package:flutter/material.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/services/custom_food_service.dart';
import 'package:physiq/services/saved_food_service.dart';
import 'package:physiq/models/saved_food_model.dart';
import 'package:physiq/theme/design_system.dart';

class CustomFoodDetailScreen extends StatefulWidget {
  final CustomFood food;
  const CustomFoodDetailScreen({super.key, required this.food});

  @override
  State<CustomFoodDetailScreen> createState() => _CustomFoodDetailScreenState();
}

class _CustomFoodDetailScreenState extends State<CustomFoodDetailScreen> {
  final _service = CustomFoodService();
  bool _isSaving = false;

  Future<void> _saveToSavedScans() async {
    setState(() => _isSaving = true);
    try {
      final savedFood = SavedFood(
        id: '', // Service generates ID
        userId: widget.food.userId,
        name: widget.food.description,
        sourceType: 'custom_food',
        servingSize: widget.food.servingSize,
        servingAmount: 1.0,
        nutrition: SavedFoodNutrition(
          calories: widget.food.nutrition.calories,
          protein: widget.food.nutrition.protein,
          carbs: widget.food.nutrition.carbs,
          fat: widget.food.nutrition.fat,
          saturatedFat: widget.food.nutrition.saturatedFat,
          polyunsaturatedFat: widget.food.nutrition.polyunsaturatedFat,
          monounsaturatedFat: widget.food.nutrition.monounsaturatedFat,
          transFat: widget.food.nutrition.transFat,
          cholesterol: widget.food.nutrition.cholesterol,
          sodium: widget.food.nutrition.sodium,
          potassium: widget.food.nutrition.potassium,
          sugar: widget.food.nutrition.sugar,
          fiber: widget.food.nutrition.fiber,
          vitaminA: widget.food.nutrition.vitaminA,
          calcium: widget.food.nutrition.calcium,
          iron: widget.food.nutrition.iron,
        ),
        createdAt: DateTime.now(),
      );
      await SavedFoodService().saveFood(savedFood);
      if (mounted) {
        final Color primary = Theme.of(context).colorScheme.primary;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Food saved successfully"),
            backgroundColor: primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteFood() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Food?", style: AppTextStyles.h2),
        content: Text(
          "Are you sure you want to delete this food?",
          style: AppTextStyles.body,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: AppTextStyles.button.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              "Delete",
              style: AppTextStyles.button.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteCustomFood(widget.food.id);
      if (mounted) {
        final ThemeData theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Food deleted"),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final nutrition = widget.food.nutrition;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.food.description,
          style: AppTextStyles.h2.copyWith(color: textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.bookmark_border,
              color: _isSaving ? textSecondary : textPrimary,
            ),
            onPressed: _isSaving ? null : _saveToSavedScans,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'delete') _deleteFood();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Delete",
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Serving Info Card
            _buildInfoSection(
              title: "Serving Info",
              children: [
                _buildNutritionRow("Serving Size", widget.food.servingSize),
                _buildNutritionRow(
                  "Amount",
                  "${widget.food.servingPerContainer} serving",
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Calories Highlight Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: [AppShadows.card],
              ),
              child: Column(
                children: [
                  Text("Calories", style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Text(
                    nutrition.calories.toInt().toString(),
                    style: AppTextStyles.largeNumber.copyWith(fontSize: 48),
                  ),
                  Text("kcal", style: AppTextStyles.label),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Macros Card
            _buildInfoSection(
              title: "Macros",
              children: [
                _buildNutritionRow(
                  "Protein",
                  "${nutrition.protein.toStringAsFixed(1)}g",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Carbs",
                  "${nutrition.carbs.toStringAsFixed(1)}g",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Fat",
                  "${nutrition.fat.toStringAsFixed(1)}g",
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Detailed Nutrition
            _buildInfoSection(
              title: "Detailed Nutrition",
              children: [
                _buildNutritionRow(
                  "Saturated Fat",
                  "${nutrition.saturatedFat}g",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Cholesterol",
                  "${nutrition.cholesterol}mg",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Sodium",
                  "${nutrition.sodium}mg",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Fiber",
                  "${nutrition.fiber}g",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Sugars",
                  "${nutrition.sugar}g",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Potassium",
                  "${nutrition.potassium}mg",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Vitamin A",
                  "${nutrition.vitaminA}mcg",
                  showDivider: true,
                ),
                _buildNutritionRow(
                  "Calcium",
                  "${nutrition.calcium}mg",
                  showDivider: true,
                ),
                _buildNutritionRow("Iron", "${nutrition.iron}mg"),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: AppTextStyles.h3),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: [AppShadows.card],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(
    String label,
    String value, {
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body),
              Text(value, style: AppTextStyles.bodyBold),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            height: 16,
          ),
      ],
    );
  }
}
