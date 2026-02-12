
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart'; // helpful for some util
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/services/saved_food_service.dart';
import 'package:physiq/models/saved_food_model.dart';

class MealPreviewScreen extends ConsumerStatefulWidget {
  final Food initialFood;
  final double initialQuantity;

  const MealPreviewScreen({
    super.key, 
    required this.initialFood,
    this.initialQuantity = 1.0,
    this.isSelectionMode = false,
  });

  final bool isSelectionMode;

  @override
  ConsumerState<MealPreviewScreen> createState() => _MealPreviewScreenState();
}

class _MealPreviewScreenState extends ConsumerState<MealPreviewScreen> {
  final FoodService _foodService = FoodService();
  late Food _food;
  late double _quantity;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _food = widget.initialFood;
    _quantity = widget.initialQuantity;
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    // If it's a FatSecret result, we might need full details for serving logic
    if (_food.source == 'fatsecret') {
        try {
            final fullFood = await _foodService.getFoodById(_food.id);
            if (fullFood != null && mounted) {
                setState(() {
                    _food = fullFood;
                    _isLoading = false;
                });
                return;
            }
        } catch (e) {
            print("Error fetching details: $e");
        }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _updateQuantity(double delta) {
    setState(() {
        _quantity = (_quantity + delta).clamp(0.5, 99.0);
    });
  }

  void _saveMeal() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (widget.isSelectionMode) {
      final item = MealItem(
        foodId: _food.id,
        foodName: _food.name,
        quantity: _quantity,
        servingLabel: _food.unit,
        calories: _food.calories * _quantity,
        protein: _food.protein * _quantity,
        carbs: _food.carbs * _quantity,
        fat: _food.fat * _quantity,
      );
      Navigator.pop(context, item);
      return;
    }

    final meal = MealModel(
      id: '',
      userId: user.uid,
      name: _food.name,
      calories: (_food.calories * _quantity).round(),
      proteinG: (_food.protein * _quantity).round(),
      carbsG: (_food.carbs * _quantity).round(),
      fatG: (_food.fat * _quantity).round(),
      timestamp: DateTime.now(),
      imageUrl: null, // FatSecret doesn't easily give image URLs in free tier search sometimes
      source: _food.source,
      // We should probably save serving info too, but MealModel might not have it strictly
    );

    ref.read(homeViewModelProvider.notifier).logMeal(meal);
    
    // Navigate back to Home
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate values
    final cals = (_food.calories * _quantity).round();
    final protein = (_food.protein * _quantity).round();
    final carbs = (_food.carbs * _quantity).round();
    final fat = (_food.fat * _quantity).round();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Nutrition", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120), // Space for fixed bottom button
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food Name & Bookmark
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _food.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border, size: 28),
                          onPressed: () async {
                              try {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;

                                final savedFood = SavedFood(
                                  id: '', 
                                  userId: user.uid,
                                  name: _food.name,
                                  sourceType: _food.source,
                                  servingSize: _food.unit,
                                  servingAmount: _quantity,
                                  nutrition: SavedFoodNutrition(
                                    calories: _food.calories * _quantity,
                                    protein: _food.protein * _quantity,
                                    carbs: _food.carbs * _quantity,
                                    fat: _food.fat * _quantity,
                                  ),
                                  createdAt: DateTime.now(),
                                );

                                await SavedFoodService().saveFood(savedFood);
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Saved successfully")),
                                  );
                                }
                              } catch (e) {
                                print("Save error: $e");
                              }
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Serving Size Measurement
                    const Text(
                      "Serving Size Measurement",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // We will allow toggling between units if Food had alt units, for now, simulate button
                         _UnitPill(label: _food.unit.toUpperCase(), isSelected: true),
                         const SizedBox(width: 8),
                         // Future: add G, Serving buttons logic if supported
                         // _UnitPill(label: "G", isSelected: false),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Serving Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         const Text(
                          "Serving Amount",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                         ),
                         Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xfffff0e0).withOpacity(0.0), // clean white
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                                children: [
                                    IconButton(
                                        icon: const Icon(Icons.remove, size: 20),
                                        onPressed: () => _updateQuantity(-0.5),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        splashRadius: 24,
                                    ),
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text(
                                          _quantity % 1 == 0 ? _quantity.toInt().toString() : _quantity.toString(), 
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                      ),
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.add, size: 20),
                                        onPressed: () => _updateQuantity(0.5),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                        splashRadius: 24,
                                    ),
                                ],
                            ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Large Calories Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                             child: const Icon(Icons.local_fire_department, color: Colors.black),
                           ),
                           const SizedBox(width: 16),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text("Calories", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                               const SizedBox(height: 2),
                               Text("$cals", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                             ],
                           ),
                           const Spacer(),
                           Icon(Icons.edit, size: 16, color: Colors.grey[400])
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Macros Row
                    Row(
                      children: [
                        Expanded(child: _MacroCard(label: "Protein", value: "${protein}g", icon: Icons.restaurant, color: Colors.red)),
                         const SizedBox(width: 8),
                        Expanded(child: _MacroCard(label: "Carbs", value: "${carbs}g", icon: Icons.grain, color: Colors.orange)),
                         const SizedBox(width: 8),
                        Expanded(child: _MacroCard(label: "Fats", value: "${fat}g", icon: Icons.water_drop, color: Colors.blue)),
                      ],
                    ),

                    const SizedBox(height: 32),
                    const Text("Other nutrition facts", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Facts List
                    _FactRow("Saturated Fat", _formatWithUnit(0.0, 'g')),
                    _FactRow("Polyunsaturated Fat", _formatWithUnit(0.0, 'g')), 
                    _FactRow("Monounsaturated Fat", _formatWithUnit(0.0, 'g')),
                    _FactRow("Cholesterol", _formatWithUnit(0.0, 'mg')),
                    _FactRow("Sodium", _formatWithUnit(0.0, 'mg')), 
                    _FactRow("Fiber", _formatWithUnit(0.0, 'g')),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Button
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.isSelectionMode ? "Add to Meal" : "Log Meal",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
    );
  }

  String _formatWithUnit(double width, String unit) {
    if (width == 0) return "-"; // Placeholder logic 
    // Wait, width arg is typo, assume value
    double val = width * _quantity; // rudimentary scaling 
    // Ideally map properly to fields but fine for mocked data
     return "${val.toStringAsFixed(0)}$unit";
  }
}

class _UnitPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _UnitPill({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MacroCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(icon, size: 16, color: color),
               const SizedBox(width: 6),
               Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
               Icon(Icons.edit, size: 14, color: Colors.grey[400])
            ],
          )
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;
  const _FactRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == "-") return const SizedBox.shrink(); 
    // For proper list display:
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)), // faint separator
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}
