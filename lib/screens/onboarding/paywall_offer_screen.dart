import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/navigation/paywall_navigator.dart';
import 'package:physiq/providers/subscription_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/revenuecat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallOfferScreen extends ConsumerStatefulWidget {
  const PaywallOfferScreen({super.key});

  @override
  ConsumerState<PaywallOfferScreen> createState() => _PaywallOfferScreenState();
}

class _PaywallOfferScreenState extends ConsumerState<PaywallOfferScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isRestoring = false;

  Package? _specialPackage;
  String? _referenceYearlyPrice;

  @override
  void initState() {
    super.initState();
    _loadSpecialOffer();
  }

  Future<void> _loadSpecialOffer() async {
    try {
      await RevenueCatService.instance.getOfferings(forceRefresh: true);

      if (mounted) {
        setState(() {
          _specialPackage = RevenueCatService.instance.getSpecialPackage();
          _referenceYearlyPrice =
              RevenueCatService.instance.getYearlyPackage()?.storeProduct.priceString;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load special offer: $e');
    }
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

  Future<void> _onPurchaseSuccess() async {
    ref.read(isPremiumNotifierProvider.notifier).updatePremiumStatus(true);

    if (!PaywallNavigator.isInAppSession(GoRouterState.of(context))) {
      await _authService.completeOnboarding();
    }

    if (mounted) {
      PaywallNavigator.onPurchaseSuccess(context, ref);
    }
  }

  Future<void> _purchaseSpecialOffer() async {
    if (_isLoading) return;

    if (_specialPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer not available. Please try again.')),
      );
      await _loadSpecialOffer();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success =
          await RevenueCatService.instance.purchasePackage(_specialPackage!);

      if (!mounted) return;

      if (success) {
        await _onPurchaseSuccess();
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
    if (_isRestoring) return;

    setState(() => _isRestoring = true);

    try {
      final restored = await RevenueCatService.instance.restorePurchases();

      if (!mounted) return;

      if (restored) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase restored successfully!')),
        );
        await _onPurchaseSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No previous purchases found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceString = _specialPackage?.storeProduct.priceString;
    final strikethrough = _referenceYearlyPrice;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: AppColors.primaryText),
            onPressed: _handleClose,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Your one-time offer",
                        style: AppTextStyles.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "80% OFF",
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontSize: 40,
                              ),
                            ),
                            Text(
                              "FOREVER",
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.grey,
                                fontSize: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      if (priceString != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (strikethrough != null) ...[
                              Text(
                                strikethrough,
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.secondaryText,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              priceString,
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.redAccent,
                                fontSize: 32,
                              ),
                            ),
                            Text(
                              " /year",
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Loading offer...',
                          style: AppTextStyles.body,
                        ),
                      const SizedBox(height: 34),
                      _buildBenefitRow(
                        Icons.coffee,
                        "Less than a coffee for dream body.",
                      ),
                      _buildBenefitRow(
                        Icons.warning_amber_rounded,
                        "Close this screen? This price is gone",
                        isWarning: true,
                      ),
                      _buildBenefitRow(
                        Icons.person,
                        "What are you waiting for?",
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(
                          color: AppColors.primaryText,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Special Offer", style: AppTextStyles.h3),
                              Text(
                                priceString ?? '...',
                                style: AppTextStyles.h3,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 44),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _purchaseSpecialOffer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
                            : Text(
                                _specialPackage == null
                                    ? 'Retry Loading Offer'
                                    : 'Start My Journey',
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isRestoring ? null : _restorePurchases,
                      child: _isRestoring
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              "Restore Purchases",
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(
    IconData icon,
    String text, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: isWarning ? Colors.amber : AppColors.secondaryText,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
