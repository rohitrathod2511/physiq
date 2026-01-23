
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

import 'package:physiq/services/auth_service.dart';

class PaywallNotificationScreen extends StatefulWidget {
  const PaywallNotificationScreen({super.key});

  @override
  State<PaywallNotificationScreen> createState() => _PaywallNotificationScreenState();
}

class _PaywallNotificationScreenState extends State<PaywallNotificationScreen> {
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
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: _completeOnboarding,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: _completeOnboarding,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Text(
              "We'll send you\na reminder before your\nfree trial ends",
              style: AppTextStyles.h1.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Notification Bell Icon
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(Icons.notifications, size: 120, color: Colors.grey.shade300),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ],
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
                onPressed: () => context.push('/onboarding/paywall-main'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Continue for FREE'),
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
