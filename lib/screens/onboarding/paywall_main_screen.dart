
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';

class PaywallMainScreen extends StatefulWidget {
  const PaywallMainScreen({super.key});

  @override
  State<PaywallMainScreen> createState() => _PaywallMainScreenState();
}

class _PaywallMainScreenState extends State<PaywallMainScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _selectedPlan = 'Yearly'; // Monthly or Yearly

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await _authService.completeOnboarding();
    // No manual navigation needed; router will detect change and redirect to /home
  }

  void _handleBack() {
    context.push('/onboarding/paywall-spinner');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: _handleBack,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Unlock Physiq to get your Dream Body.",
                style: AppTextStyles.h1.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildFeatureItem('Activate Leaderboard (Yearly)', 'Win ₹1,00,000 by following streak'),
              _buildFeatureItem('Get your dream body', 'We keep it simple to make getting results easy'),
              _buildFeatureItem('Track your progress', 'Stay on track with personalized insights and smart reminders'),
             
            
              const Spacer(),
              
              Row(
                children: [
                  Expanded(child: _buildPlanCard('Monthly', '₹999.00/mo', false)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPlanCard('Yearly', '₹166.58/mo', true)),
                ],
              ),
              
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: AppColors.primaryText, size: 20),
                  const SizedBox(width: 8),
                  Text("No Commitment - Cancel Anytime", style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Start My Journey'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _selectedPlan == 'Yearly' 
                      ? "Just ₹166.58 per month" 
                      : "Just ₹999.00 per month",
                  style: AppTextStyles.smallLabel,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: AppColors.primaryText),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.body.copyWith(color: AppColors.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, bool isBestValue) {
    final isSelected = _selectedPlan == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = title),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primaryText : AppColors.secondaryText.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body),
                const SizedBox(height: 8),
                Text(price, style: AppTextStyles.h3),
                if (title == 'Yearly') ...[
                  const SizedBox(height: 4),
                  Text(
                    "Less than the cost of a pizza for dream body.",
                    style: AppTextStyles.smallLabel.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (isBestValue)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '3 DAYS FREE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
