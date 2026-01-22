import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/screens/exercise/add_burned_calories_screen.dart';
import 'package:physiq/viewmodels/exercise_viewmodel.dart';
import 'package:physiq/models/exercise_log_model.dart';

class DescribeExerciseScreen extends ConsumerStatefulWidget {
  const DescribeExerciseScreen({super.key});

  @override
  ConsumerState<DescribeExerciseScreen> createState() => _DescribeExerciseScreenState();
}

class _DescribeExerciseScreenState extends ConsumerState<DescribeExerciseScreen> {
  final _controller = TextEditingController();
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Describe Workout', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.card),
                boxShadow: [AppShadows.card],
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe workout time, intensity, etc.\nExample: "Played basketball for 45 mins at high intensity"',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isAnalyzing)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _analyzeWithAI,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text('Created by AI', style: AppTextStyles.button.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Calculate Calories', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _analyzeWithAI() async {
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(seconds: 2)); // Mock delay
    // Mock AI parsing
    _controller.text = "Basketball, 45 mins, High intensity";
    setState(() => _isAnalyzing = false);
  }

  void _onContinue() async {
    // Simple heuristic parsing
    final text = _controller.text.toLowerCase();
    int duration = 30;
    String intensity = 'medium';
    String type = 'generic';

    if (text.contains('min')) {
      // Extract number before 'min'
      final regex = RegExp(r'(\d+)\s*min');
      final match = regex.firstMatch(text);
      if (match != null) {
        duration = int.tryParse(match.group(1)!) ?? 30;
      }
    }
    if (text.contains('high')) intensity = 'high';
    if (text.contains('low')) intensity = 'low';

    // Map common keywords to types
    if (text.contains('run')) type = 'run';
    else if (text.contains('cycle') || text.contains('bike')) type = 'cycling';
    else if (text.contains('lift') || text.contains('weight')) type = 'weightlifting';
    else if (text.contains('yoga')) type = 'generic'; // fallback

    const double weightKg = 70.0;
    final viewModel = ref.read(exerciseViewModelProvider.notifier);
    final calories = await viewModel.estimateCalories(
      exerciseType: type,
      intensity: intensity,
      durationMinutes: duration,
      weightKg: weightKg,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBurnedCaloriesScreen(
          initialCalories: calories,
          onLog: (finalCalories) {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null) return;
            viewModel.logExercise(
              userId: uid,
              exerciseId: 'describe',
              name: 'Custom Workout',
              type: ExerciseType.other,
              durationMinutes: duration,
              calories: finalCalories,
              intensity: intensity,
              details: {'description': _controller.text},
              isManualOverride: finalCalories != calories,
            );
            Navigator.popUntil(context, (route) => route.isFirst);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout logged!')));
          },
        ),
      ),
    );
  }
}
