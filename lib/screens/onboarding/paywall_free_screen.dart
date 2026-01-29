
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

import 'package:physiq/services/auth_service.dart';

class PaywallFreeScreen extends StatefulWidget {
  const PaywallFreeScreen({super.key});

  @override
  State<PaywallFreeScreen> createState() => _PaywallFreeScreenState();
}

class _PaywallFreeScreenState extends State<PaywallFreeScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await _authService.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: _completeOnboarding,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "We want you to\ntry Physiq AI for free.",
              style: AppTextStyles.h1.copyWith(fontSize: 32),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, color: AppColors.primaryText),
                const SizedBox(width: 8),
                Text("No Payment Due Now", style: AppTextStyles.bodyBold),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/onboarding/paywall-notification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Try for \$0.00'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Just ₹1,999.00 per year (₹166.58/mo)",
              style: AppTextStyles.smallLabel,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
