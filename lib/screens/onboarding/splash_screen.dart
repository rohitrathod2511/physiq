import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    // Navigate after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // In a real app, you would check auth status here.
        // For now, we go directly to the get-started screen.
        context.go('/get-started');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Physiq', style: AppTextStyles.h1.copyWith(fontSize: 48)),
      ),
    );
  }
}
