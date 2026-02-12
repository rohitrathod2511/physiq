import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/models/my_meal_model.dart';
import 'package:physiq/services/my_meals_service.dart';
import 'package:physiq/screens/meal/create_meal_screen.dart';
import 'package:physiq/screens/meal/meal_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyMealsScreen extends ConsumerStatefulWidget {
  const MyMealsScreen({super.key});

  @override
  ConsumerState<MyMealsScreen> createState() => _MyMealsScreenState();
}

class _MyMealsScreenState extends ConsumerState<MyMealsScreen> {
  final MyMealsService _service = MyMealsService();
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() => _query = val.trim().toLowerCase());
  }

  void _navToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateMealScreen()),
    );
  }

  void _logMeal(MyMeal meal) async {
    // Implement immediate logging
    await _service.logMyMeal(meal, DateTime.now());
    
    // Refresh Home ViewModel
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      ref.read(homeViewModelProvider.notifier).fetchRecentMeals(uid);
      // Also update summary if selected date is today, logic inside VM handles selectedDate stream but sometimes manual fetch helps
      ref.read(homeViewModelProvider.notifier).fetchDailySummary(DateTime.now(), uid);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged ${meal.name}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MyMeal>>(
      stream: _service.streamMyMeals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }

        final allMeals = snapshot.data ?? [];
        
        // Filter based on query
        final meals = _query.isEmpty 
            ? allMeals 
            : allMeals.where((m) => m.name.toLowerCase().contains(_query)).toList();

        // 1. Empty State
        if (allMeals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration placeholder
                Icon(Icons.bento, size: 80, color: Colors.grey.shade300), 
                const SizedBox(height: 16),
                Text("My Meals", style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(
                  "Quickly log your go-to meal combinations",
                  style: AppTextStyles.body.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _navToCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text("Create a Meal", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        // 2. List State
        return Column(
          children: [
            // Search Bar (Only if meals exist)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Search my meals",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: meals.length + 1, // +1 for Create Button at bottom or top?
                                             // User req: "Button: Create a Meal" in empty state.
                                             // Does existing state have a create button?
                                             // Reference image usually implies a FAB or a list item.
                                             // Let's add a "Create new meal" button at top or FAB.
                                             // I'll add a CTA row at top if not empty.
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == meals.length) {
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 30, top: 10),
                       child: OutlinedButton.icon(
                         onPressed: _navToCreate,
                         icon: const Icon(Icons.add, color: Colors.black),
                         label: const Text("Create New Meal", style: TextStyle(color: Colors.black)),
                         style: OutlinedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           side: const BorderSide(color: Colors.grey),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                       ),
                     );
                  }

                  final meal = meals[index];
                  return _buildMealCard(meal);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMealCard(MyMeal meal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // Meal Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name, style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(
                    "${meal.items.length} items • ${meal.totalCalories.toInt()} kcal",
                    style: AppTextStyles.body.copyWith(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            
            // Log Button
            IconButton(
              onPressed: () => _logMeal(meal), // Updated to use method
              icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
