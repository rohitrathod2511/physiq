import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/services/custom_food_service.dart';
import 'package:physiq/screens/food/create_food_screen.dart';
import 'package:physiq/screens/food/custom_food_detail_screen.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class MyFoodsScreen extends ConsumerStatefulWidget {
  const MyFoodsScreen({super.key});

  @override
  ConsumerState<MyFoodsScreen> createState() => _MyFoodsScreenState();
}

class _MyFoodsScreenState extends ConsumerState<MyFoodsScreen> {
  final CustomFoodService _service = CustomFoodService();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<CustomFood>>(
            stream: _service.getUserCustomFoods(),
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
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: foods.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == foods.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30, top: 10),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateFoodScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.add, color: textPrimary),
                        label: Text(
                          "Create New Food",
                          style: TextStyle(color: textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }
                  final food = foods[index];
                  return _buildFoodCard(context, ref, food, _service);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use icon if asset fails or just icon for consistency with My Meals
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            "My Foods",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a custom food to your personal list",
            style: TextStyle(color: textSecondary),
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
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Add Food",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(
    BuildContext context,
    WidgetRef ref,
    CustomFood food,
    CustomFoodService service,
  ) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomFoodDetailScreen(food: food),
              ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${food.nutrition.calories.toInt()} kcal • ${food.servingSize}",
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: textPrimary,
                    size: 28,
                  ),
                  onPressed: () async {
                    try {
                      await service.logCustomFood(food, DateTime.now());

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null && context.mounted) {
                        ref
                            .read(homeViewModelProvider.notifier)
                            .fetchRecentMeals(uid);
                        ref
                            .read(homeViewModelProvider.notifier)
                            .fetchDailySummary(DateTime.now(), uid);
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Logged ${food.description}"),
                            backgroundColor: theme.colorScheme.primary,
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
