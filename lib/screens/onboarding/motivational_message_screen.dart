
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/services/plan_generator.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GeneratePlanScreen extends ConsumerWidget {
  const GeneratePlanScreen({super.key});

  Future<void> _onConfirm(BuildContext context, WidgetRef ref) async {
    final store = ref.read(onboardingProvider);
    
    // Generate local plan
    final profile = store.data;
    final plan = PlanGenerator.generateLocalPlan(profile);
    
    // Save plan to store/draft
    await store.saveStepData('currentPlan', plan);
    
    // Save to Firestore if signed in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          ...profile,
          'currentPlan': plan,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving to Firestore: $e');
      }
    }

    // Navigate to loading to simulate/perform server generation
    if (context.mounted) {
      context.push('/onboarding/generate-plan');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(onboardingProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress Bar removed
              const Spacer(),
              const Spacer(),
              
              // Title
              Text(
                "${(store.goal?.toLowerCase().contains('lose') ?? false) ? 'Lose' : 'Gain'} twice as much\nweight with Physiq vs\non your own",
                style: AppTextStyles.h1.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              // Graph Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE), // Light background
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Bar 1 (Without)
                        Column(
                          children: [
                            Text("Without\nPhysiq", textAlign: TextAlign.center, style: AppTextStyles.bodyBold),
                            const SizedBox(height: 12),
                            Container(
                              width: 80,
                              height: 60, // ~20% of right bar
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text("20%", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Bar 2 (With)
                        Column(
                          children: [
                            Text("With\nPhysiq", textAlign: TextAlign.center, style: AppTextStyles.bodyBold),
                            const SizedBox(height: 12),
                            Container( 
                              width: 80,
                              height: 150, // Full height
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: const Text("2X", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Physiq makes it easy and holds\nyou accountable",
                      style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 2),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onConfirm(context, ref),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}


