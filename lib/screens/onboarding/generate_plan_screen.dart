
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class MotivationalMessageScreen extends StatelessWidget {
  const MotivationalMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              // Progress Bar removed
              const Spacer(flex: 2),
              const Spacer(flex: 2),
             
              // Gradient Circle with Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade100, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                     padding: const EdgeInsets.all(30),
                     // Icon representation of the hand/heart
                     child: const Icon(Icons.favorite, size: 80, color: Color(0xFFE57373)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
             
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text("All done!", style: AppTextStyles.bodyBold.copyWith(color: Colors.black)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
             
              // Title
              Text(
                "Time to generate your\ncustom plan!",
                style: AppTextStyles.h1.copyWith(fontSize: 32),
                textAlign: TextAlign.center,
              ),
             
              const Spacer(flex: 3),
             
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/loading'),
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

