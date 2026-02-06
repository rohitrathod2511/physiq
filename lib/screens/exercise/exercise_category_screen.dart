import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/screens/exercise/exercise_detail_screen.dart';

class ExerciseCategoryScreen extends StatelessWidget {
  final String categoryId;
  final String title;

  const ExerciseCategoryScreen({super.key, required this.categoryId, required this.title});

  @override
  Widget build(BuildContext context) {
    // If it's the main Gym screen, show categories instead of exercises
    if (categoryId == 'gym') {
      return _buildGymCategories(context);
    }

    final exercises = _getExercises(categoryId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
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

  Widget _buildGymCategories(BuildContext context) {
    final categories = [
      'Chest',
      'Back',
      'Shoulders',
      'Biceps',
      'Triceps',
      'Legs',
      'Abs',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final catName = categories[index];
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
                      builder: (_) => ExerciseCategoryScreen(
                        categoryId: 'gym_${catName.toLowerCase()}',
                        title: catName,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(catName, style: AppTextStyles.bodyBold),
                      Icon(Icons.chevron_right, color: AppColors.primary),
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
        {'id': 'incline_push_ups', 'name': 'Incline Push-ups'},
        {'id': 'decline_push_ups', 'name': 'Decline Push-ups'},
        {'id': 'diamond_push_ups', 'name': 'Diamond Push-ups'},
        {'id': 'pike_push_ups', 'name': 'Pike Push-ups'},
        {'id': 'arm_circles', 'name': 'Arm Circles'},
        {'id': 'jump_squats', 'name': 'Jump Squats'},
        {'id': 'wall_sit', 'name': 'Wall Sit'},
        {'id': 'glute_bridge', 'name': 'Glute Bridge'},
        {'id': 'calf_raises', 'name': 'Calf Raises'},
        {'id': 'step_ups', 'name': 'Step-ups'},
        {'id': 'crunches', 'name': 'Crunches'},
        {'id': 'sit_ups', 'name': 'Sit-ups'},
        {'id': 'bicycle_crunch', 'name': 'Bicycle Crunch'},
        {'id': 'leg_raises', 'name': 'Leg Raises'},
        {'id': 'russian_twist', 'name': 'Russian Twist'},
        {'id': 'flutter_kicks', 'name': 'Flutter Kicks'},
        {'id': 'heel_touches', 'name': 'Heel Touches'},
        {'id': 'jumping_jacks', 'name': 'Jumping Jacks'},
        {'id': 'high_knees', 'name': 'High Knees'},
        {'id': 'skaters', 'name': 'Skaters'},
        {'id': 'bear_crawls', 'name': 'Bear Crawls'},
        {'id': 'butt_kicks', 'name': 'Butt Kicks'},
      ];
    } else if (catId == 'gym_chest') {
      return [
        {'id': 'bench_press', 'name': 'Bench Press'},
        {'id': 'incline_bench_press', 'name': 'Incline Bench Press'},
        {'id': 'decline_bench_press', 'name': 'Decline Bench Press'},
        {'id': 'dumbbell_chest_press', 'name': 'Dumbbell Chest Press'},
        {'id': 'chest_fly', 'name': 'Chest Fly'},
        {'id': 'cable_fly', 'name': 'Cable Fly'},
      ];
    } else if (catId == 'gym_back') {
      return [
        {'id': 'deadlift', 'name': 'Deadlift'},
        {'id': 'lat_pulldown', 'name': 'Lat Pulldown'},
        {'id': 'pull_ups', 'name': 'Pull-ups'},
        {'id': 'seated_cable_row', 'name': 'Seated Cable Row'},
        {'id': 'bent_over_row', 'name': 'Bent Over Row'},
        {'id': 'one_arm_dumbbell_row', 'name': 'One-arm Dumbbell Row'},
      ];
    } else if (catId == 'gym_shoulders') {
      return [
        {'id': 'shoulder_press', 'name': 'Shoulder Press'},
        {'id': 'arnold_press', 'name': 'Arnold Press'},
        {'id': 'lateral_raises', 'name': 'Lateral Raises'},
        {'id': 'front_raises', 'name': 'Front Raises'},
        {'id': 'rear_delt_fly', 'name': 'Rear Delt Fly'},
      ];
    } else if (catId == 'gym_biceps') {
      return [
        {'id': 'barbell_curl', 'name': 'Barbell Curl'},
        {'id': 'dumbbell_curl', 'name': 'Dumbbell Curl'},
        {'id': 'hammer_curl', 'name': 'Hammer Curl'},
        {'id': 'preacher_curl', 'name': 'Preacher Curl'},
        {'id': 'cable_curl', 'name': 'Cable Curl'},
      ];
    } else if (catId == 'gym_triceps') {
      return [
        {'id': 'tricep_pushdown', 'name': 'Tricep Pushdown'},
        {'id': 'skull_crushers', 'name': 'Skull Crushers'},
        {'id': 'overhead_tricep_extension', 'name': 'Overhead Tricep Extension'},
        {'id': 'dips', 'name': 'Dips'},
        {'id': 'close_grip_bench_press', 'name': 'Close-Grip Bench Press'},
      ];
    } else if (catId == 'gym_legs') {
      return [
        {'id': 'squats', 'name': 'Squats'},
        {'id': 'leg_press', 'name': 'Leg Press'},
        {'id': 'lunges', 'name': 'Lunges'},
        {'id': 'leg_extension', 'name': 'Leg Extension'},
        {'id': 'leg_curl', 'name': 'Leg Curl'},
        {'id': 'romanian_deadlift', 'name': 'Romanian Deadlift'},
        {'id': 'calf_raises', 'name': 'Calf Raises'},
      ];
    } else if (catId == 'gym_abs') {
      return [
        {'id': 'cable_crunch', 'name': 'Cable Crunch'},
        {'id': 'hanging_leg_raise', 'name': 'Hanging Leg Raise'},
        {'id': 'ab_crunch_machine', 'name': 'Ab Crunch Machine'},
        {'id': 'russian_twist', 'name': 'Russian Twist'},
        {'id': 'plank', 'name': 'Plank'},
      ];
    } else {
      return [];
    }
  }
}
