import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/services/custom_food_service.dart';
import 'package:physiq/screens/food/create_food_screen.dart';
import 'package:physiq/screens/food/custom_food_detail_screen.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class MyFoodsScreen extends ConsumerWidget {
  const MyFoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine user ID (from service or auth directly to build query)
    final service = CustomFoodService();

    return StreamBuilder<List<CustomFood>>(
      stream: service.getUserCustomFoods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final foods = snapshot.data ?? [];

        if (foods.isEmpty) {
          return _buildEmptyState(context);
        }

        // Show list
        return Scaffold(
          backgroundColor: Colors.white,
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: foods.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final food = foods[index];
              return _buildFoodCard(context, ref, food, service);
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.black,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateFoodScreen()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/diet.png', // Fallback or placeholder
            height: 100,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            "My Foods",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add a custom food to your personal list",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateFoodScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Add Food", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, WidgetRef ref, CustomFood food, CustomFoodService service) {
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomFoodDetailScreen(food: food)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${food.nutrition.calories.toInt()} kcal • ${food.servingSize}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 28),
                  onPressed: () async {
                    try {
                      await service.logCustomFood(food, DateTime.now());
                      
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null && context.mounted) {
                        ref.read(homeViewModelProvider.notifier).fetchRecentMeals(uid);
                        ref.read(homeViewModelProvider.notifier).fetchDailySummary(DateTime.now(), uid);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Logged ${food.description}"),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        
                        // Close the database screen and return to Home
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
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
