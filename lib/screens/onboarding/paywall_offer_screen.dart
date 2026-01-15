
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

import 'package:physiq/services/auth_service.dart';

class PaywallOfferScreen extends StatefulWidget {
  const PaywallOfferScreen({super.key});

  @override
  State<PaywallOfferScreen> createState() => _PaywallOfferScreenState();
}

class _PaywallOfferScreenState extends State<PaywallOfferScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await _authService.completeOnboarding();
    // No manual navigation needed; router will detect change and redirect to /home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _completeOnboarding,
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
            
                    // Offer Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "80% OFF",
                            style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 40),
                          ),
                          Text(
                            "FOREVER",
                            style: AppTextStyles.h1.copyWith(color: Colors.grey, fontSize: 40),
                          ),
                        ],
                      ),
                    ),
            
                    const SizedBox(height: 34),
            
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "₹1,999.00",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "₹99.00",
                          style: AppTextStyles.h1.copyWith(color: Colors.redAccent, fontSize: 32),
                        ),
                        Text(
                          " /mo",
                          style: AppTextStyles.h3.copyWith(color: Colors.redAccent),
                        ),
                      ],
                    ),
            
                    const SizedBox(height: 34),
            
                    _buildBenefitRow(Icons.coffee, "Less than a coffee for dream body."),
                    _buildBenefitRow(Icons.warning_amber_rounded, "Close this screen? This price is gone", isWarning: true),
                    _buildBenefitRow(Icons.person, "What are you waiting for?"),
                    
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            
            // Fixed Bottom Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Free Trial Toggle Removed

                  // Plan Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA), // Subtle contrast
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06), // Gentle elevation
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
                            Text("Yearly Plan", style: AppTextStyles.h3),
                            Text("₹99.00/mo", style: AppTextStyles.h3),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("12mo • ₹1,118.00", style: AppTextStyles.body.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 44),
            
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Start My Journey'),
                    ),
                  ),
            
                  // Disclaimer Removed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: isWarning ? Colors.amber : Colors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
