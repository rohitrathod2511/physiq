import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/services/custom_food_service.dart';
import 'package:physiq/screens/food/create_food_screen.dart';
import 'package:physiq/screens/food/custom_food_detail_screen.dart';

class MyFoodsScreen extends StatefulWidget {
  const MyFoodsScreen({super.key});

  @override
  State<MyFoodsScreen> createState() => _MyFoodsScreenState();
}

class _MyFoodsScreenState extends State<MyFoodsScreen> {
  final CustomFoodService _service = CustomFoodService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CustomFood>>(
      stream: _service.getUserCustomFoods(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allFoods = snapshot.data ?? [];

        if (allFoods.isEmpty) {
          return _buildEmptyState(context);
        }

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: allFoods.length,
                  itemBuilder: (context, index) {
                    final food = allFoods[index];
                    return _buildFoodCard(context, food, _service);
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.black,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateFoodScreen()),
            ),
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
          const Icon(Icons.lunch_dining, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "My Foods",
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 8),
          const Text(
            "Add a custom food to your personal list",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateFoodScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text("Add Food"),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, CustomFood food, CustomFoodService service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey[50], // Light grey background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomFoodDetailScreen(food: food)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.description,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                onPressed: () async {
                  await service.logCustomFood(food, DateTime.now());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Logged ${food.description}")),
                    );
                    Navigator.pop(context); // Go back to home/log screen
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
