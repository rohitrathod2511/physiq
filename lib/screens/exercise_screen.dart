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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: HeaderWidget(title: 'Exercise', showActions: false),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildExerciseButton(context, 'Home', Icons.home_filled, Colors.orange),
                    _buildExerciseButton(context, 'Gym', Icons.fitness_center, Colors.blue),
                    _buildExerciseButton(context, 'Run', Icons.directions_run, Colors.green),
                    _buildExerciseButton(context, 'Cycling', Icons.directions_bike, Colors.teal),
                    _buildExerciseButton(context, 'Describe', Icons.mic, Colors.purple),
                    _buildExerciseButton(context, 'Manual', Icons.edit, Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseButton(BuildContext context, String label, IconData icon, Color color) {
    // Assuming 2 columns with spacing
    final width = (MediaQuery.of(context).size.width - 48 - 16) / 2;
    
    return Container(
      width: width,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to specific exercise list
          },
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: AppTextStyles.bodyBold,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
