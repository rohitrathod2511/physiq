import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/services/my_meals_service.dart';
import 'package:physiq/services/my_meals_service.dart';
import 'package:physiq/screens/meal/food_database_screen.dart';
import 'package:physiq/services/saved_food_service.dart';
import 'package:physiq/models/saved_food_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealDetailScreen extends StatefulWidget {
  final MyMeal meal;
  const MealDetailScreen({super.key, required this.meal});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late TextEditingController _nameController;
  final MyMealsService _service = MyMealsService();

  late List<MealItem> _items;
  late double _totalCalories;
  late double _totalProtein;
  late double _totalCarbs;
  late double _totalFat;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal.name);
    _items = List.from(widget.meal.items);
    _totalCalories = widget.meal.totalCalories;
    _totalProtein = widget.meal.totalProtein;
    _totalCarbs = widget.meal.totalCarbs;
    _totalFat = widget.meal.totalFat;
  }

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
    _autoUpdate();
  }
  
  // Auto-update Firebase when items change
  Future<void> _autoUpdate() async {
      final updatedMeal = MyMeal(
          id: widget.meal.id, // Keep ID
          name: _nameController.text,
          totalCalories: _totalCalories,
          totalProtein: _totalProtein,
          totalCarbs: _totalCarbs,
          totalFat: _totalFat,
          createdAt: widget.meal.createdAt,
          items: _items,
      );
      await _service.saveMyMeal(updatedMeal);
  }
  
  // Update name on lose focus or specific save? 
  // Let's just update on back or have a save button?
  // User req: "Editable... Edit option".
  // Let's just rely on "Update" button or auto-update.
  // I will add a "Update" button to be explicit/safe.

  Future<void> _addItems() async {
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              labelText: "Quantity (${item.servingLabel})",
                              border: const OutlineInputBorder(),
                          ),
                      ),
                  ],
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  TextButton(onPressed: () {
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
                  }, child: const Text("Save")),
              ],
          ),
      );
  }
  
  Future<void> _deleteMeal() async {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text("Delete Meal?"),
              content: const Text("This cannot be undone."),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
              ],
          ),
      );
      
      if (confirm == true) {
          setState(() => _isSaving = true);
          await _service.deleteMyMeal(widget.meal.id);
          if (mounted) Navigator.pop(context);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Meal Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
                IconButton(
                    icon: const Icon(Icons.star_border, color: Colors.black),
                    onPressed: () async {
                       try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          final savedFood = SavedFood(
                            id: '', 
                            userId: user.uid,
                            name: widget.meal.name,
                            sourceType: 'custom_meal',
                            servingSize: 'meal', 
                            servingAmount: 1.0,
                            nutrition: SavedFoodNutrition(
                              calories: _totalCalories,
                              protein: _totalProtein,
                              carbs: _totalCarbs,
                              fat: _totalFat,
                            ),
                            createdAt: DateTime.now(),
                          );
                          
                          await SavedFoodService().saveFood(savedFood);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Saved successfully")),
                            );
                          }
                       } catch (e) {
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                         }
                       }
                    },
                ),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteMeal,
                )
            ],
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
                            onChanged: (val) => _autoUpdate(), // Auto-save name changes
                            decoration: InputDecoration(
                                hintText: "Meal Name",
                                suffixIcon: const Icon(Icons.edit, color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                            ),
                        ),
                        const SizedBox(height: 24),

                        // Macros
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
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.local_fire_department, color: Colors.orange),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text("Calories", style: AppTextStyles.body.copyWith(color: Colors.grey)),
                                            Text("${_totalCalories.toInt()}", style: AppTextStyles.h2),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                            children: [
                                Expanded(child: _buildMiniMacro("Protein", "${_totalProtein.toInt()}g", Colors.red)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildMiniMacro("Carbs", "${_totalCarbs.toInt()}g", Colors.amber)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildMiniMacro("Fats", "${_totalFat.toInt()}g", Colors.blue)),
                            ],
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Meal Items Header
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text("Meal Items", style: AppTextStyles.h2),
                                IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.black),
                                    onPressed: _addItems,
                                )
                            ],
                        ),
                        const SizedBox(height: 16),

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
                                        color: Colors.red,
                                        child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    child: ListTile(
                                        title: Text(item.foodName, style: AppTextStyles.h3),
                                        subtitle: Text("${item.quantity.toStringAsFixed(1)} ${item.servingLabel} • ${item.calories.toInt()} kcal"),
                                        trailing: Text("${item.protein.toInt()}p ${item.carbs.toInt()}c ${item.fat.toInt()}f"),
                                        onTap: () => _editItem(index),
                                    ),
                                );
                            },
                        ),
                    ],
                ),
            ),
    );
  }

  Widget _buildMiniMacro(String label, String value, Color color) {
      return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
              children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(Icons.circle, size: 8, color: color),
                          const SizedBox(width: 6),
                          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
          ),
      );
  }
}
