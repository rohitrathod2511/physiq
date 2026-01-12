
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class PaywallFreeScreen extends StatelessWidget {
  const PaywallFreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "We want you to\ntry Physiq for free.",
              style: AppTextStyles.h1.copyWith(fontSize: 32),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, color: Colors.black),
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
                  backgroundColor: Colors.black,
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
