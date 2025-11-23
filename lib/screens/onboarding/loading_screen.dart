import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/onboarding_viewmodel.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule the plan generation to run after the widget tree has finished building
    // to avoid "modifying a provider while the widget tree was building" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePlan();
    });
  }

  Future<void> _generatePlan() async {
    try {
      // Trigger plan generation
      await ref.read(onboardingProvider.notifier).generatePlan();
      
      if (mounted) {
        print("Plan generated successfully. Navigating to review screen...");
        context.go('/review');
      }
    } catch (e, stack) {
      print("Error generating plan: $e");
      print(stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating plan: $e')),        );
        // Fallback or retry logic could go here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Generating your custom plan...',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: LinearPercentIndicator(
                animation: true,
                lineHeight: 8.0,
                animationDuration: 2000,
                percent: 1.0,
                barRadius: const Radius.circular(10),
                progressColor: AppColors.primary,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Applying BMR formula...',
              style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}
