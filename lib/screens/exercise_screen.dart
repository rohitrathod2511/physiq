import 'package:flutter/material.dart';
import 'package:physiq/utils/design_system.dart';

import 'package:physiq/widgets/header_widget.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.background,
              scrolledUnderElevation: 0,
              elevation: 0,
              toolbarHeight: 80,
              titleSpacing: 0,
              title: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: HeaderWidget(title: 'Exercise'),
              ),
            ),
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fitness_center, size: 64, color: AppColors.secondaryText),
                    const SizedBox(height: 16),
                    Text(
                      'Exercise Tracking',
                      style: AppTextStyles.heading2.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Coming Soon',
                      style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
