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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Food saved successfully"),
            backgroundColor: Colors.green,
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
                color: AppColors.secondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              "Delete",
              style: AppTextStyles.button.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteCustomFood(widget.food.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Food deleted"),
            backgroundColor: Colors.black,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = widget.food.nutrition;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.food.description, style: AppTextStyles.h2),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.bookmark_border,
              color: _isSaving
                  ? AppColors.secondaryText
                  : AppColors.primaryText,
            ),
            onPressed: _isSaving ? null : _saveToSavedScans,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.primaryText),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'delete') _deleteFood();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text("Delete", style: TextStyle(color: Colors.red)),
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
                color: AppColors.card,
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
            color: AppColors.card,
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
          Divider(color: Colors.grey.withOpacity(0.1), height: 16),
      ],
    );
  }
}
