import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/widgets/exercise/intensity_slider.dart';
import 'package:physiq/widgets/exercise/duration_selector.dart';
import 'package:physiq/screens/exercise/add_burned_calories_screen.dart';
import 'package:physiq/viewmodels/exercise_viewmodel.dart';
import 'package:physiq/services/user_repository.dart';
import 'package:physiq/models/exercise_log_model.dart';

class CardioScreen extends ConsumerStatefulWidget {
  final String type; // 'run' or 'cycling'

  const CardioScreen({super.key, required this.type});

  @override
  ConsumerState<CardioScreen> createState() => _CardioScreenState();
}

class _CardioScreenState extends ConsumerState<CardioScreen> {
  String _intensity = 'medium';
  int _duration = 30;
  bool _isOutdoor = true; // For cycling

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'run' ? 'Run' : 'Cycling';
    final icon = widget.type == 'run' ? Icons.directions_run : Icons.directions_bike;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryText),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.heading2),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IntensitySlider(
                    currentIntensity: _intensity,
                    onChanged: (val) => setState(() => _intensity = val),
                  ),
                  const SizedBox(height: 32),
                  DurationSelector(
                    initialDuration: _duration,
                    onChanged: (val) => setState(() => _duration = val),
                  ),
                  if (widget.type == 'cycling') ...[
                    const SizedBox(height: 32),
                    Text('Environment', style: AppTextStyles.heading2),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildToggleOption('Outdoor', _isOutdoor, () => setState(() => _isOutdoor = true)),
                        const SizedBox(width: 16),
                        _buildToggleOption('Indoor', !_isOutdoor, () => setState(() => _isOutdoor = false)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Continue', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected ? Colors.white : AppColors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onContinue() async {
    // 1. Get user weight
    // In a real app, we'd await ref.read(userRepositoryProvider).getUser(uid)
    // For now, mock or assume cached
    const double weightKg = 70.0; // Placeholder

    // 2. Calculate calories
    final viewModel = ref.read(exerciseViewModelProvider.notifier);
    final calories = await viewModel.estimateCalories(
      exerciseType: widget.type,
      intensity: _intensity,
      durationMinutes: _duration,
      weightKg: weightKg,
    );

    // 3. Navigate to Confirmation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBurnedCaloriesScreen(
          initialCalories: calories,
          onLog: (finalCalories) {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in')));
              return;
            }
            viewModel.logExercise(
              userId: uid,
              exerciseId: widget.type,
              name: widget.type == 'run' ? 'Run' : 'Cycling',
              type: ExerciseType.cardio,
              durationMinutes: _duration,
              calories: finalCalories,
              intensity: _intensity,
              details: {'environment': _isOutdoor ? 'outdoor' : 'indoor'},
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
