
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/widgets/central_pill_buttons.dart';

class ActivityLifestyleScreen extends ConsumerStatefulWidget {
  const ActivityLifestyleScreen({super.key});

  @override
  ConsumerState<ActivityLifestyleScreen> createState() => _ActivityLifestyleScreenState();
}

class _ActivityLifestyleScreenState extends ConsumerState<ActivityLifestyleScreen> {
  String? _selectedActivity;

  final List<String> _options = [
    'Sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
    'Athletic',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(onboardingProvider);
      if (store.activityLevel != null) {
        setState(() => _selectedActivity = store.activityLevel);
      }
    });
  }

  void _onContinue() {
    if (_selectedActivity != null) {
      ref.read(onboardingProvider).saveStepData('activityLevel', _selectedActivity);
      context.push('/onboarding/goal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Text(
              "Activity Level",
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            CentralPillButtons(
              options: _options,
              selectedOption: _selectedActivity,
              onOptionSelected: (value) {
                setState(() => _selectedActivity = value);
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedActivity != null ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
