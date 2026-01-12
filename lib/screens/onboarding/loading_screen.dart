
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
  double _percent = 0.0;
  int _currentStepIndex = 0;
  
  final List<String> _statusMessages = [
    "Applying BMR formula",
    "Calculating calories",
    "Calculating carbs",
    "Calculating protein",
    "Calculating fats",
    "Calculating health score"
  ];
  
  final List<String> _checkItems = [
    "Calories",
    "Carbs",
    "Protein", 
    "Fats",
    "Health score"
  ];

  @override
  void initState() {
    super.initState();
    _startLoadingAnimation();
  }

  void _startLoadingAnimation() async {
    // Total duration approx 3-4 seconds
    const totalSteps = 100;
    const stepDuration = Duration(milliseconds: 40); 
    
    for (int i = 1; i <= totalSteps; i++) {
        if (!mounted) return;
        
        await Future.delayed(stepDuration);
        
        setState(() {
            _percent = i / 100.0;
            
            // Sync Status Text (6 messages distributed over 100%)
            // 0-16: BMR
            // 16-32: Calories
            // 32-48: Carbs
            // 48-64: Protein
            // 64-80: Fats
            // 80-100: Health Score
            _currentStepIndex = (i / (100 / _statusMessages.length)).floor();
            if (_currentStepIndex >= _statusMessages.length) _currentStepIndex = _statusMessages.length - 1;
        });
    }

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
              Text(
                "${(_percent * 100).toInt()}%",
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.black),
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
                animateFromLastPercent: true,
                animation: false, // Controlled manually via setState
                lineHeight: 8.0,
                percent: _percent,
                barRadius: const Radius.circular(4),
                progressColor: const Color(0xFF6B8EFF),
                backgroundColor: Colors.grey.shade200,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              
              // Status Text
              Text(
                "${_statusMessages[_currentStepIndex]}...",
                style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                key: ValueKey<int>(_currentStepIndex), // Animate switch?
              ),
              
              const SizedBox(height: 48),
              
                // Recommendation List (Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily recommendation for",
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(_checkItems.length, (index) {
                        // Checkmark Logic:
                        // Item 0 (Calories) visible after BMR done? 
                        // Let's sync with status text or percentage.
                        // 5 items. 
                        // Item 0 visible > 15%
                        // Item 1 visible > 30%
                        // Item 2 visible > 50%
                        // Item 3 visible > 70%
                        // Item 4 visible > 85%
                        
                        final threshold = (index + 1) * (1.0 / (_checkItems.length + 1));
                        final isVisible = _percent > threshold;
                        
                        return _buildCheckItem(_checkItems[index], isVisible);
                    }),
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

  Widget _buildCheckItem(String title, bool isVisible) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.body.copyWith(fontSize: 16)),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isVisible ? 1.0 : 0.0,
            child: const Icon(Icons.check_circle, color: Colors.black, size: 24),
          ),
        ],
      ),
    );
  }

}
