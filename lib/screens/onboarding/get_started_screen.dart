
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/screens/onboarding/sign_in_screen.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  void _showSignInSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SignInScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Headline
              Text(
                'Build Your Dream Body',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 40),
              
              // Primary Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/name'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sign In Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: AppTextStyles.body.copyWith(color: AppColors.secondaryText, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () => _showSignInSheet(context),
                    child: Text(
                      'Sign in',
                      style: AppTextStyles.button.copyWith(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
