import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/navigation/paywall_navigator.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallMainScreen extends ConsumerStatefulWidget {
  const PaywallMainScreen({super.key});

  @override
  ConsumerState<PaywallMainScreen> createState() => _PaywallMainScreenState();
}

class _PaywallMainScreenState extends ConsumerState<PaywallMainScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _selectedPlan = 'Yearly';

  Package? _monthlyPackage;
  Package? _yearlyPackage;
  Package? _specialPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      await RevenueCatService.instance.getOfferings(forceRefresh: true);
      if (!mounted) return;

      setState(() {
        _monthlyPackage = RevenueCatService.instance.getMonthlyPackage();
        _yearlyPackage = RevenueCatService.instance.getYearlyPackage();
        _specialPackage = RevenueCatService.instance.getSpecialPackage();
      });
    } catch (e) {
      debugPrint('❌ Failed to load offerings: $e');
    }
  }

  Future<void> _handleClose() async {
    if (_isLoading) return;
    PaywallNavigator.pushStep(context, '/onboarding/paywall-spinner');
  }

  void _handleSystemBack() {
    PaywallNavigator.pushStep(context, '/onboarding/paywall-notification');
  }

  Future<void> _onPurchaseSuccess() async {
    // CRITICAL: Force refresh CustomerInfo before navigating
    await RevenueCatService.instance.invalidateAndFetchCustomerInfo();
    
    if (!PaywallNavigator.isInAppSession(GoRouterState.of(context))) {
      await _authService.completeOnboarding();
    }

    if (mounted) {
      PaywallNavigator.onPurchaseSuccess(context, ref);
    }
  }

  Future<void> _purchasePlan(String planType) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      Package? packageToPurchase;

      switch (planType) {
        case 'Monthly':
          packageToPurchase = _monthlyPackage;
          break;
        case 'Yearly':
          packageToPurchase = _yearlyPackage;
          break;
        case 'Special':
          packageToPurchase = _specialPackage;
          break;
      }

      if (packageToPurchase == null) {
        throw Exception('Package not found. Plan: $planType. Please try again.');
      }

      final success =
          await RevenueCatService.instance.purchasePackage(packageToPurchase);

      if (!mounted) return;

      if (success) {
        await _onPurchaseSuccess();
      } else {
        // Purchase flow completed but entitlement not immediately active
        // This can happen in sandbox mode with processing delays
        debugPrint('⚠️ [DEBUG] Purchase completed but entitlement not immediately active. Fetching fresh status...');
        
        // Force a fresh fetch to check if entitlement is now active
        final freshInfo = await RevenueCatService.instance.invalidateAndFetchCustomerInfo();
        final isPremium = RevenueCatService.instance.hasActivePremiumEntitlement(freshInfo);
        
        if (isPremium) {
          debugPrint('✅ [DEBUG] Entitlement now active after fresh fetch!');
          await _onPurchaseSuccess();
        } else if (mounted) {
          // Still not active - show helpful message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment received! Premium may take a moment to activate.\n'
                'Try tapping "Restore Purchases" or restart the app.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      final restored = await RevenueCatService.instance.restorePurchases();
      if (!mounted) return;

      if (restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully!')),
        );
        await _onPurchaseSuccess();
      } else {
        // Restore returned false - try one more fetch in case of timing issue
        debugPrint('⚠️ [DEBUG] Restore returned false, attempting fresh fetch...');
        final freshInfo = await RevenueCatService.instance.invalidateAndFetchCustomerInfo();
        final isPremium = RevenueCatService.instance.hasActivePremiumEntitlement(freshInfo);
        
        if (isPremium) {
          debugPrint('✅ [DEBUG] Entitlement found after fresh fetch!');
          await _onPurchaseSuccess();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No previous purchases found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPrice = _monthlyPackage?.storeProduct.priceString ?? '...';
    final yearlyPrice = _yearlyPackage?.storeProduct.priceString ?? '...';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const SizedBox.shrink(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Unlock Physiq AI to get your Dream Body.",
                style: AppTextStyles.h1.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 34),
              _buildFeatureItem(
                'Get your Dream Body',
                'We keep it simple to make getting results easy',
              ),
              _buildFeatureItem(
                'Track your Progress',
                'Stay on track with personalized insights and smart reminders',
              ),
              _buildFeatureItem(
                'Easy Food Scanning',
                'Track your calories with our easy to use food scanner',
              ),
              _buildFeatureItem(
                'Easy to Follow Workouts',
                'Stay on track with our easy to follow workout plans',
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _buildPlanCard(
                      'Monthly',
                      monthlyPrice,
                      null,
                      false,
                      onTap: () => setState(() => _selectedPlan = 'Monthly'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPlanCard(
                      'Yearly',
                      yearlyPrice,
                      'per year',
                      true,
                      onTap: () => setState(() => _selectedPlan = 'Yearly'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: AppColors.primaryText, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "No Commitment - Cancel Anytime",
                    style: AppTextStyles.bodyBold,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : () => _purchasePlan(_selectedPlan),
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
                      : const Text('Start My Journey'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _restorePurchases,
                  child: Text(
                    'Restore Purchases',
                    style: AppTextStyles.smallLabel.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: AppColors.primaryText, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(fontSize: 16, height: 1.15),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    height: 1.2,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String title,
    String price,
    String? subtitle,
    bool isBestValue, {
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedPlan == title;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryText
                    : AppColors.secondaryText.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body),
                const SizedBox(height: 8),
                Text(price, style: AppTextStyles.h3),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.smallLabel.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.primaryText
                        : AppColors.secondaryText,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '3 DAYS FREE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
