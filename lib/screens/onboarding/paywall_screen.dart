import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // Skip logic -> Go to Home
                      context.go('/home');
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Unlock Physiq AI Premium', style: AppTextStyles.h1),
              const SizedBox(height: 16),
              _buildFeatureItem('AI Snap Meal Tracking'),
              _buildFeatureItem('Voice Log Entry'),
              _buildFeatureItem('Priority Processing'),
              _buildFeatureItem('Leaderboards'),

              const Spacer(),

              // Mock Subscription Options
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Radio(
                      value: true,
                      groupValue: true,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yearly Plan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$250.00 / year',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BEST VALUE',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Radio(value: false, groupValue: true, onChanged: (_) {}),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Plan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$990.00 / month',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    // Mock Purchase -> Go to Home
                    context.go('/home');
                  },
                  child: Text(
                    'Start My Journey',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
