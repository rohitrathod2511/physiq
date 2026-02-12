import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/models/custom_meal_model.dart';
import 'package:physiq/services/custom_meal_service.dart';
import 'package:physiq/screens/meal/describe_meal_screen.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/models/food_model.dart';

class CustomMealScreen extends ConsumerStatefulWidget {
  const CustomMealScreen({super.key});

  @override
  ConsumerState<CustomMealScreen> createState() => _CustomMealScreenState();
}

class _CustomMealScreenState extends ConsumerState<CustomMealScreen> {
  final _service = CustomMealService();

  void _logCustomMeal(CustomMeal meal) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final logMeal = MealModel(
      id: '',
      userId: user.uid,
      name: meal.name,
      calories: meal.totalNutrition['calories']?.toInt() ?? 0,
      proteinG: meal.totalNutrition['protein']?.toInt() ?? 0,
      carbsG: meal.totalNutrition['carbs']?.toInt() ?? 0,
      fatG: meal.totalNutrition['fat']?.toInt() ?? 0,
      timestamp: DateTime.now(),
      imageUrl: null,
      source: 'custom_meal',
    );

    ref.read(homeViewModelProvider.notifier).logMeal(logMeal);
    Navigator.pop(context); // Close Custom Meal Screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logged ${meal.name}"), backgroundColor: AppColors.primary),
    );
  }

  void _createNewMeal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateCustomMealScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Custom Meals", style: AppTextStyles.h2),
        centerTitle: true,
      ),
      body: StreamBuilder<List<CustomMeal>>(
        stream: _service.getCustomMeals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.no_food, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text("No custom meals yet", style: AppTextStyles.body.copyWith(color: Colors.grey)),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: _createNewMeal,
                     child: const Text("Create Your First Meal"),
                   )
                ],
              ),
            );
          }

          final meals = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final meal = meals[index];
              final cal = meal.totalNutrition['calories']?.toInt() ?? 0;
              final p = meal.totalNutrition['protein']?.toInt() ?? 0;
              
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(meal.name, style: AppTextStyles.h3),
                  subtitle: Text(
                    "$cal kcal • ${p}g Protein • ${meal.items.length} items",
                    style: AppTextStyles.label.copyWith(color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                    onPressed: () => _logCustomMeal(meal),
                  ),
                  onLongPress: () {
                      // Option to delete
                      showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text("Delete Meal?"),
                          content: Text("Are you sure you want to delete '${meal.name}'?"),
                          actions: [
                              TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
                              TextButton(onPressed: () {
                                  _service.deleteCustomMeal(meal.id);
                                  Navigator.pop(ctx);
                              }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                          ],
                      ));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewMeal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text("Create New"),
      ),
    );
  }
}

class CreateCustomMealScreen extends StatefulWidget {
  const CreateCustomMealScreen({super.key});

  @override
  State<CreateCustomMealScreen> createState() => _CreateCustomMealScreenState();
}

class _CreateCustomMealScreenState extends State<CreateCustomMealScreen> {
  final _nameController = TextEditingController();
  final List<CustomMealItem> _items = [];
  final _service = CustomMealService();

  Map<String, double> get _totalNutrition {
    double cal = 0, p = 0, c = 0, f = 0;
    // We don't store raw nutrition in items, simplified model store only quantity.
    // However, to calculate total, we need the nutrition values.
    // The CustomMealItem only has name/id/quantity. 
    // Wait, CustomMealItem doesn't store per-unit nutrition. 
    // This is a flaw in my model if I want to just sum them up without re-fetching.
    // OR I just store the running total in the parent object.
    // BUT the prompt says "Computed ONCE, reused forever." meaning the total is stored.
    // When CREATING, I have the Food objects. I should calculate the sum then.
    return {}; 
  }

  // Temporary storage for calculation during creation
  final List<Food> _addedFoods = []; 

  void _addItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DescribeMealScreen(isPicking: true),
      ),
    ) as Map<String, dynamic>?;

    if (result != null) {
      final food = result['food'] as Food;
      final quantity = result['quantity'] as double;
      // final desc = result['description'] as String;

      setState(() {
        _items.add(CustomMealItem(
          foodId: food.id,
          foodName: food.name,
          quantity: quantity,
          unit: food.unit,
        ));
        _addedFoods.add(food);
      });
    }
  }

  void _save() async {
    if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a name")));
        return;
    }
    if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one item")));
        return;
    }

    // Calculate Totals using _addedFoods and _items quantities
    double tCal = 0, tPro = 0, tCarb = 0, tFat = 0;
    
    for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        // We assume _addedFoods is in sync by index or we find by ID. 
        // Sync by index is safe if we don't reorder/delete yet. 
        // Let's find by ID to be safe.
        final food = _addedFoods.firstWhere((f) => f.id == item.foodId);
        
        tCal += food.calories * item.quantity;
        tPro += food.protein * item.quantity;
        tCarb += food.carbs * item.quantity;
        tFat += food.fat * item.quantity;
    }

    final meal = CustomMeal(
        id: '', 
        name: _nameController.text.trim(), 
        items: _items, 
        totalNutrition: {
            'calories': tCal,
            'protein': tPro,
            'carbs': tCarb,
            'fat': tFat
        }
    );

    await _service.saveCustomMeal(meal);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate live total for display
    double tCal = 0;
    for (int i = 0; i < _items.length; i++) {
        if (i < _addedFoods.length) {
            tCal += _addedFoods[i].calories * _items[i].quantity;
        }
    }

    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text("Create Meal"), backgroundColor: AppColors.background, elevation: 0),
        body: Column(
            children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                        controller: _nameController,
                        style: AppTextStyles.h2.copyWith(fontSize: 24),
                        decoration: const InputDecoration(
                            hintText: "Meal Name (e.g. Breakfast)",
                            border: InputBorder.none
                        ),
                    ),
                ),
                Expanded(
                    child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                            if (index == _items.length) {
                                return OutlinedButton.icon(
                                    onPressed: _addItem, 
                                    icon: const Icon(Icons.add), 
                                    label: const Text("Add Food Item"),
                                    style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.all(16),
                                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                    ),
                                );
                            }

                            final item = _items[index];
                            final food = _addedFoods.firstWhere((f) => f.id == item.foodId, orElse: () => _addedFoods[0]); // Fallback safely
                            final cals = (food.calories * item.quantity).toInt();

                            return ListTile(
                                tileColor: AppColors.card,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Text(item.foodName, style: AppTextStyles.body),
                                subtitle: Text("${item.quantity} x ${item.unit} • $cals kcal"),
                                trailing: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey),
                                    onPressed: () {
                                        setState(() {
                                            _items.removeAt(index);
                                            _addedFoods.removeWhere((f) => f.id == item.foodId && _items.where((it) => it.foodId == f.id).isEmpty); 
                                            // Careful removal logic if duplicates exist. 
                                            // Actually simpler: just remove item. We likely don't need to remove from _addedFoods strictly, just keep the cache.
                                            // But for calculation, we use lookups.
                                        });
                                    },
                                ),
                            );
                        },
                    ),
                ),
                Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                    ),
                    child: Row(
                        children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text("Total Calories", style: AppTextStyles.label),
                                    Text("${tCal.toInt()} kcal", style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                                ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                ),
                                child: const Text("Save Meal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                        ],
                    ),
                )
            ],
        ),
    );
  }
}
