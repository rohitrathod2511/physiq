import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/navigation/paywall_navigator.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/revenuecat_service.dart';

class PaywallNotificationScreen extends StatefulWidget {
  const PaywallNotificationScreen({super.key});

  @override
  State<PaywallNotificationScreen> createState() =>
      _PaywallNotificationScreenState();
}

class _PaywallNotificationScreenState extends State<PaywallNotificationScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _monthlyPriceLabel;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    await RevenueCatService.instance.getOfferings(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _monthlyPriceLabel = RevenueCatService.instance.getMonthlyPriceLabel();
    });
  }

  Future<void> _handleClose() async {
    if (_isLoading) return;

    if (PaywallNavigator.isInAppSession(GoRouterState.of(context))) {
      PaywallNavigator.dismissInApp(context);
      return;
    }

    setState(() => _isLoading = true);
    await _authService.completeOnboarding();
  }

  void _navigateToNextPaywall() {
    PaywallNavigator.pushStep(context, '/onboarding/paywall-main');
  }

  @override
  Widget build(BuildContext context) {
    final footerPrice = _monthlyPriceLabel ?? 'Loading price...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: _handleClose,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: _handleClose,
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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
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
                onPressed: _isLoading ? null : _navigateToNextPaywall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Continue for FREE'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _monthlyPriceLabel != null ? 'Just $footerPrice' : footerPrice,
              style: AppTextStyles.smallLabel,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
