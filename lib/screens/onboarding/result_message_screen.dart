
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/providers/onboarding_provider.dart';

class ResultMessageScreen extends ConsumerWidget {
  const ResultMessageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(onboardingProvider);
    final current = store.weightKg ?? 0;
    final target = store.targetWeightKg ?? 0;
    final diff = target - current;
    final isGain = diff >= 0;
    final absDiff = diff.abs();
    
    // Convert to lbs for display to match reference style if needed, 
    // or keep kg depending on app setting. Using kg for consistency with inputs, 
    // but reference says "lbs". Let's stick to "kg" as the app seems kg-based 
    // (inputs were kg). Or display both? "5.0 kg"
    final diffString = "${absDiff.toStringAsFixed(1)} kg";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dynamic Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.h1.copyWith(fontSize: 32, height: 1.3),
                        children: [
                          TextSpan(text: isGain ? "Gaining " : "Losing "),
                          TextSpan(
                            text: diffString,
                            style: const TextStyle(color: Color(0xFFD4A373)), // Light brown/orange
                          ),
                          const TextSpan(text: " is a\nrealistic target. it's\nnot hard at all!"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      "90% of users say that the change is obvious after using Physiq and it is not easy to rebound.",
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryText,
                        height: 1.5,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/timeframe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
