import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/services/my_meals_service.dart';
import 'package:physiq/screens/meal/food_database_screen.dart';

class CreateMealScreen extends StatefulWidget {
  const CreateMealScreen({super.key});

  @override
  State<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends State<CreateMealScreen> {
  final TextEditingController _nameController = TextEditingController();
  final MyMealsService _service = MyMealsService();

  List<MealItem> _items = [];
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _recalculate() {
    double c = 0, p = 0, k = 0, f = 0;
    for (var item in _items) {
      c += item.calories;
      p += item.protein;
      k += item.carbs;
      f += item.fat;
    }
    setState(() {
      _totalCalories = c;
      _totalProtein = p;
      _totalCarbs = k;
      _totalFat = f;
    });
  }

  Future<void> _addItems() async {
    // Navigate to FoodDatabaseScreen in selection mode
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FoodDatabaseScreen(isSelectionMode: true),
      ),
    );

    if (result != null && result is MealItem) {
      setState(() {
        _items.add(result);
      });
      _recalculate();
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _recalculate();
  }

  void _editItem(int index) {
    final item = _items[index];
    final controller = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Quantity: ${item.foodName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Quantity (${item.servingLabel})",
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() {
                  final ratio = val / item.quantity;
                  _items[index] = MealItem(
                    foodId: item.foodId,
                    foodName: item.foodName,
                    quantity: val,
                    servingLabel: item.servingLabel,
                    calories: item.calories * ratio,
                    protein: item.protein * ratio,
                    carbs: item.carbs * ratio,
                    fat: item.fat * ratio,
                  );
                });
                _recalculate();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeal() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a meal name")));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one item")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final mealId = "meal_${DateTime.now().millisecondsSinceEpoch}";
      final meal = MyMeal(
        id: mealId,
        name: name,
        totalCalories: _totalCalories,
        totalProtein: _totalProtein,
        totalCarbs: _totalCarbs,
        totalFat: _totalFat,
        createdAt: DateTime.now(),
        items: _items,
      );

      await _service.saveMyMeal(meal);

      if (mounted) {
        Navigator.pop(context); // Return to My Meal Screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
        setState(() => _isSaving = false);
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
    final Color proteinAccent = theme.colorScheme.error;
    final Color carbsAccent = theme.colorScheme.secondary;
    final Color fatsAccent = theme.colorScheme.primary;

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
          "Create Meal",
          style: AppTextStyles.h2.copyWith(color: textPrimary),
        ),
        centerTitle: true,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name Input
                  TextField(
                    controller: _nameController,
                    style: AppTextStyles.h2,
                    decoration: InputDecoration(
                      hintText: "Tap Name",
                      hintStyle: AppTextStyles.h2.copyWith(
                        color: textSecondary,
                      ),
                      suffixIcon: Icon(Icons.edit, color: textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          theme.inputDecorationTheme.fillColor ??
                          theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Macros
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
                          padding: const EdgeInsets.all(12),
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
                              "Calories",
                              style: AppTextStyles.body.copyWith(
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              "${_totalCalories.toInt()}",
                              style: AppTextStyles.h2,
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
                        child: _buildMiniMacro(
                          "Protein",
                          "${_totalProtein.toInt()}g",
                          proteinAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniMacro(
                          "Carbs",
                          "${_totalCarbs.toInt()}g",
                          carbsAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniMacro(
                          "Fats",
                          "${_totalFat.toInt()}g",
                          fatsAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Meal Items Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          color: textSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text("Meal Items", style: AppTextStyles.h2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add Item Button
                  OutlinedButton.icon(
                    onPressed: _addItems,
                    icon: Icon(Icons.add, color: textPrimary),
                    label: Text(
                      "Add items to this meal",
                      style: TextStyle(color: textPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // List of Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: UniqueKey(),
                        onDismissed: (_) => _removeItem(index),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: theme.colorScheme.error,
                          child: Icon(
                            Icons.delete,
                            color: theme.colorScheme.onError,
                          ),
                        ),
                        child: ListTile(
                          title: Text(item.foodName, style: AppTextStyles.h3),
                          subtitle: Text(
                            "${item.quantity.toStringAsFixed(1)} ${item.servingLabel} • ${item.calories.toInt()} kcal",
                          ),
                          trailing: Text(
                            "${item.protein.toInt()}p ${item.carbs.toInt()}c ${item.fat.toInt()}f",
                          ),
                          onTap: () => _editItem(index),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Create Button
                  ElevatedButton(
                    onPressed: _saveMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      "Create Meal",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniMacro(String label, String value, Color color) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
