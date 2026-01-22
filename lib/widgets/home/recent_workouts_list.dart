import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:intl/intl.dart';

class RecentWorkoutsList extends StatelessWidget {
  final List<ExerciseLog>? workouts;

  const RecentWorkoutsList({super.key, this.workouts});

  @override
  Widget build(BuildContext context) {
    // If workouts exist and list is not empty
    final hasWorkouts = workouts != null && workouts!.isNotEmpty;

    if (!hasWorkouts) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Text(
            'Recent Workouts',
            style: AppTextStyles.heading2,
          ),
        ),
        
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: workouts!.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final workout = workouts![index];
            return _buildWorkoutCard(workout);
          },
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(ExerciseLog log) {
    final name = log.name;
    final calories = log.calories.toInt();
    
    // Time Formatting
    String timeStr = DateFormat('h:mm a').format(log.timestamp);
    
    // Details formatting
    String detailsText = '';
    
    // Home Exercises (Sets & Reps)
    if (log.details.containsKey('sets') && log.details['sets'] is List) {
      final setsList = log.details['sets'] as List;
      final count = setsList.length;
      detailsText = '$count sets';
      // Attempt to summarize reps if consistent or just show first
      if (setsList.isNotEmpty) {
        final firstReps = setsList.first['reps'];
        if (firstReps != null) {
          detailsText += ' × $firstReps reps';
        }
      }
    } 
    // Manual/Gym sets stored as simple count? 
    // Or Timer Based
    else if (log.details.containsKey('rounds')) {
       // Timer: Total time, rounds
       detailsText = '${log.durationMinutes} min • ${log.details['rounds']} rounds';
    }
    // Cardio / Sports / Describe
    else {
      detailsText = '${log.durationMinutes} min';
      if (log.intensity != 'medium') {
        detailsText += ' • ${log.intensity.toUpperCase()}';
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.fitness_center, color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(timeStr, style: AppTextStyles.smallLabel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories kcal',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detailsText,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
