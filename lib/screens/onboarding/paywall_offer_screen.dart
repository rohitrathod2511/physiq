
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class PaywallOfferScreen extends StatelessWidget {
  const PaywallOfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.go('/home'),
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
                    const SizedBox(height: 40),
            
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
            
                    const SizedBox(height: 40),
            
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "₹3,000.00",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "₹166.66",
                          style: AppTextStyles.h1.copyWith(color: Colors.redAccent, fontSize: 32),
                        ),
                        Text(
                          " /mo",
                          style: AppTextStyles.h3.copyWith(color: Colors.redAccent),
                        ),
                      ],
                    ),
            
                    const SizedBox(height: 32),
            
                    _buildBenefitRow(Icons.coffee, "Less than a coffee."),
                    _buildBenefitRow(Icons.warning_amber_rounded, "Close this screen? This price is gone", isWarning: true),
                    _buildBenefitRow(Icons.person, "What are you waiting for?"),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Fixed Bottom Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Free Trial Toggle (Visual only)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Free Trial Enabled", style: AppTextStyles.body),
                      Switch(value: true, onChanged: (val) {}, activeColor: Colors.black),
                    ],
                  ),
            
                  const SizedBox(height: 16),
            
                  // Plan Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '3-DAY FREE TRIAL',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Yearly Plan", style: AppTextStyles.h3),
                            Text("₹166.66 /mo", style: AppTextStyles.h3),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("12mo • ₹2,000.00", style: AppTextStyles.body.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
            
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Start Free Trial'),
                    ),
                  ),
            
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, color: Colors.black, size: 16),
                      const SizedBox(width: 8),
                      Text("No Commitment - Cancel Anytime", style: AppTextStyles.smallLabel.copyWith(color: Colors.black)),
                    ],
                  ),
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
