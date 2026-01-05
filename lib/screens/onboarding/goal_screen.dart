
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/widgets/central_pill_buttons.dart';

class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  String? _selectedGoal;

  final List<String> _options = ['Gain Weight', 'Lose Weight', 'Maintain Weight'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(onboardingProvider);
      if (store.goal != null) {
        setState(() => _selectedGoal = store.goal);
      }
    });
  }

  void _onContinue() {
    if (_selectedGoal != null) {
      ref.read(onboardingProvider).saveStepData('goal', _selectedGoal);
      if (_selectedGoal == 'Maintain') {
        // Skip target weight if maintaining
        context.push('/onboarding/motivational-message');
      } else {
        context.push('/onboarding/target-weight');
      }
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
              "Fitness Goal",
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            CentralPillButtons(
              options: _options,
              selectedOption: _selectedGoal,
              onOptionSelected: (value) {
                setState(() => _selectedGoal = value);
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedGoal != null ? _onContinue : null,
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
