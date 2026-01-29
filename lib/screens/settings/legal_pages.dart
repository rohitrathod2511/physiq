import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Terms & Conditions', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Introduction', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Welcome to Physiq AI. By using our app, you agree to these terms...',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            Text('Services', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Physiq AI provides health and fitness tracking services...',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            Text('User Obligations', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'You agree to provide accurate information and use the app responsibly...',
              style: AppTextStyles.body,
            ),
            // Add more sections as needed
          ],
        ),
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Privacy Policy', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Collection', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'We collect personal data such as name, email, and health metrics...',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            Text('Usage', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Your data is used to provide personalized health insights...',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            Text('Storage', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Data is stored securely on our servers...',
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
