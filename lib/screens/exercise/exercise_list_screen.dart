import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/exercise_viewmodel.dart';
import 'package:physiq/screens/exercise/cardio_screen.dart';
import 'package:physiq/screens/exercise/weightlifting_screen.dart';
import 'package:physiq/screens/exercise/exercise_category_screen.dart';
import 'package:physiq/screens/exercise/describe_exercise_screen.dart';
import 'package:physiq/screens/exercise/manual_entry_screen.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(exerciseViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text('Exercise', style: AppTextStyles.heading1), // Bigger font
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0, // No color change on scroll
        automaticallyImplyLeading: false, // Remove back button
        centerTitle: false, // Top-left
        titleSpacing: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: viewModel.loadCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading categories'));
          }

          final categories = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _buildCategoryCard(context, cat);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    IconData iconData;
    switch (category['icon']) {
      case 'home': iconData = Icons.home; break;
      case 'fitness_center': iconData = Icons.fitness_center; break;
      case 'directions_run': iconData = Icons.directions_run; break;
      case 'directions_bike': iconData = Icons.directions_bike; break;
      case 'edit': iconData = Icons.edit; break;
      case 'add_circle_outline': iconData = Icons.add_circle_outline; break;
      default: iconData = Icons.fitness_center;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          onTap: () => _navigateToCategory(context, category['id'], category['title']),
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category['title'], style: AppTextStyles.bodyBold),
                      const SizedBox(height: 4),
                      Text(category['subtitle'], style: AppTextStyles.smallLabel),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, String id, String title) {
    if (id == 'run' || id == 'cycling') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => CardioScreen(type: id)));
    } else if (id == 'weightlifting') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightliftingScreen()));
    } else if (id == 'home' || id == 'gym') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseCategoryScreen(categoryId: id, title: title)));
    } else if (id == 'describe') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DescribeExerciseScreen()));
    } else if (id == 'manual') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualEntryScreen()));
    }
  }
}
