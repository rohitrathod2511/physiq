import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/revenuecat_service.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/providers/subscription_provider.dart';

class PaywallFreeScreen extends ConsumerStatefulWidget {
  const PaywallFreeScreen({super.key});

  @override
  ConsumerState<PaywallFreeScreen> createState() => _PaywallFreeScreenState();
}

class _PaywallFreeScreenState extends ConsumerState<PaywallFreeScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await _authService.completeOnboarding();
  }

  void _navigateToNextPaywall() {
    context.push('/onboarding/paywall-notification');
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
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.80,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.85, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        'assets/Physique.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Try for \$0.00'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Just ₹250.00 per month",
              style: AppTextStyles.smallLabel,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}