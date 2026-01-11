
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    // Simulate server processing time
    // In a real app, you would call your Cloud Function here
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.push('/review');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Percentage
              const Text(
                "47%",
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              // Main Title
              Text(
                "We're setting\neverything up for you",
                style: AppTextStyles.h2.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Progress Bar
              LinearPercentIndicator(
                animation: true,
                lineHeight: 8.0,
                animationDuration: 2500,
                percent: 1.0,
                barRadius: const Radius.circular(4),
                progressColor: const Color(0xFF6B8EFF), // Blue-ish purple gradient in image substitute
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 16),
              
              // Status Text
              Text(
                "Applying BMR formula...",
                style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
              ),
              
              const SizedBox(height: 48),
              
              // Recommendation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE), // Light background color from image
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily recommendation for",
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    _buildCheckItem("Calories"),
                    _buildCheckItem("Carbs"),
                    _buildCheckItem("Protein"),
                    _buildCheckItem("Fats"),
                    _buildCheckItem("Health score"),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.body.copyWith(fontSize: 16)),
          const Icon(Icons.check_circle, color: Colors.black, size: 24),
        ],
      ),
    );
  }

}
