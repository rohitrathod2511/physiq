import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/exercise_viewmodel.dart';
import 'package:physiq/models/exercise_log_model.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _controller = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manual Entry', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 16,
                      color: AppColors.primary,
                      backgroundColor: AppColors.secondaryText.withOpacity(0.1),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.largeNumber.copyWith(fontSize: 48),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                              ),
                            ),
                          ),
                          Icon(Icons.edit, size: 20, color: AppColors.secondaryText),
                        ],
                      ),
                      Text('Calories', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Log', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _onLog() {
    final calories = double.tryParse(_controller.text) ?? 0.0;
    if (calories <= 0) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    ref.read(exerciseViewModelProvider.notifier).logExercise(
      userId: uid,
      exerciseId: 'manual',
      name: 'Manual Entry',
      type: ExerciseType.manual,
      durationMinutes: 0,
      calories: calories,
      intensity: 'medium',
      isManualOverride: true,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged successfully!')));
  }
}
