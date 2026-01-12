import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/screens/exercise/exercise_detail_screen.dart';

class ExerciseCategoryScreen extends StatelessWidget {
  final String categoryId;
  final String title;

  const ExerciseCategoryScreen({super.key, required this.categoryId, required this.title});

  @override
  Widget build(BuildContext context) {
    final exercises = _getExercises(categoryId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final ex = exercises[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: [AppShadows.card],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseDetailScreen(
                        exerciseId: ex['id']!,
                        name: ex['name']!,
                        category: categoryId,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(child: Text(ex['name']!, style: AppTextStyles.bodyBold)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, String>> _getExercises(String catId) {
    if (catId == 'home') {
      return [
        {'id': 'push_ups', 'name': 'Push-ups'},
        {'id': 'squats', 'name': 'Squats'},
        {'id': 'lunges', 'name': 'Lunges'},
        {'id': 'plank', 'name': 'Plank'},
        {'id': 'burpees', 'name': 'Burpees'},
        {'id': 'mountain_climbers', 'name': 'Mountain Climbers'},
      ];
    } else {
      return [
        {'id': 'bench_press', 'name': 'Bench Press'},
        {'id': 'deadlift', 'name': 'Deadlift'},
        {'id': 'squat_barbell', 'name': 'Squat (Barbell)'},
        {'id': 'lat_pulldown', 'name': 'Lat Pulldown'},
        {'id': 'bicep_curl', 'name': 'Bicep Curl'},
        {'id': 'shoulder_press', 'name': 'Shoulder Press'},
      ];
    }
  }
}
