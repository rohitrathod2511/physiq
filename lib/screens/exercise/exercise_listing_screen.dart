import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:physiq/services/exercise_repository.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:physiq/screens/exercise/category_detail_screen.dart';

class ExerciseListingScreen extends ConsumerWidget {
  const ExerciseListingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.read(exerciseRepositoryProvider).getCategories();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Text('Categories', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildCategoryCard(context, categories[index]);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Movement is Medicine', style: AppTextStyles.heading1),
        const SizedBox(height: 8),
        Text(
          'Regular exercise boosts mood, energy, and longevity.',
          style: AppTextStyles.bodyMedium?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Why this works'),
                content: const Text('1. CDC Guidelines: 150min moderate activity/week.\n2. Mayo Clinic: Strength training builds bone density.\n3. Harvard Health: HIIT improves cardiovascular health.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
              ),
            );
          },
          child: Text(
            'Why this works',
            style: AppTextStyles.smallLabel.copyWith(
              color: AppColors.accent,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String category) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CategoryDetailScreen(category: category)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.smallCard),
          boxShadow: [AppShadows.card],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center, color: AppColors.primaryText),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Tap to explore exercises', style: AppTextStyles.smallLabel),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
