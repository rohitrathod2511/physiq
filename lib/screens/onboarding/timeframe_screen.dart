
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';

class TimeframeScreen extends ConsumerStatefulWidget {
  const TimeframeScreen({super.key});

  @override
  ConsumerState<TimeframeScreen> createState() => _TimeframeScreenState();
}

class _TimeframeScreenState extends ConsumerState<TimeframeScreen> {
  final List<int> _options = [1, 3, 6, 9, 12];
  late FixedExtentScrollController _scrollController;
  int _selectedMonths = 6;

  @override
  void initState() {
    super.initState();
    // Default to 6 months (index 2: 1, 3, [6], 9, 12)
    final initialIndex = _options.indexOf(6);
    _scrollController = FixedExtentScrollController(initialItem: initialIndex != -1 ? initialIndex : 2);
    _selectedMonths = 6;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onContinue() {
    ref.read(onboardingProvider).saveStepData('timeframeMonths', _selectedMonths);
    context.push('/onboarding/diet-preference');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("How fast do you want to reach your goal?", style: AppTextStyles.h1),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Selection Highlight Overlay (optional, subtle lines)
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: AppColors.secondaryText.withOpacity(0.2)),
                        ),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: _scrollController,
                      itemExtent: 70,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMonths = _options[index];
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _options.length,
                        builder: (context, index) {
                          final value = _options[index];
                          final isSelected = value == _selectedMonths;
                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: isSelected
                                  ? AppTextStyles.largeNumber.copyWith(fontSize: 48, color: AppColors.primary)
                                  : AppTextStyles.heading1.copyWith(fontSize: 32, color: AppColors.secondaryText.withOpacity(0.4)),
                              child: Text('$value Months'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 74),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
