import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/theme/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Keep a slight delay for brand visibility
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.go('/home');
      } else {
        context.go('/get-started');
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
            Icon(Icons.fitness_center, size: 72, color: AppColors.primaryText),
            const SizedBox(height: 24),
            Text(
              'Physiq AI',
              style: AppTextStyles.h1.copyWith(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
