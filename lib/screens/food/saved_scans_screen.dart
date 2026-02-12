import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search saved items',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.black, width: 2), // Matching log food search style
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<SavedFood>>(
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
                  : allFoods.where((f) => f.name.toLowerCase().contains(_searchQuery)).toList();

              if (foods.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: foods.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final food = foods[index];
                  return _buildFoodCard(food);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Saved Scans",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Your saved foods and meals will appear here",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(SavedFood food) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light grey background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Convert to Food model and open preview
            final previewFood = Food(
              id: food.id, // Use saved ID as reference
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${food.nutrition.calories.toInt()} cal • ${food.servingSize}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 28),
                  onPressed: () async {
                    try {
                      await _service.logSavedFood(food, DateTime.now());
                      
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null && mounted) {
                        ref.read(homeViewModelProvider.notifier).fetchRecentMeals(uid);
                        ref.read(homeViewModelProvider.notifier).fetchDailySummary(DateTime.now(), uid);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Logged ${food.name}"),
                            backgroundColor: Colors.green,
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
