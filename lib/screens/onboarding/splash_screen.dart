
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/theme/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for animation + delay
    await Future.delayed(const Duration(milliseconds: 1500)); // 700ms animation + some hold time
    
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 64, color: Colors.black),
              const SizedBox(height: 16),
              Text(
                'Physiq AI',
                style: AppTextStyles.h1.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w600, // Semi-bold
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
