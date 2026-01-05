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
  // The desired options for the goal duration in months.
  final List<int> _timeframeOptions = [1, 3, 6, 9, 12];

  // State to manage which button is currently selected.
  late List<bool> _isSelected;

  // The currently selected duration, defaulting to 6 months.
  int _selectedMonths = 6;

  @override
  void initState() {
    super.initState();
    // Initialize the selection state based on the default value.
    _isSelected = _timeframeOptions.map((months) => months == _selectedMonths).toList();
  }

  void _onContinue() {
    ref.read(onboardingProvider).saveStepData('timeframeMonths', _selectedMonths);
    context.push('/onboarding/result-message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              "Goal Duration",
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Text(
              '$_selectedMonths months',
              style: AppTextStyles.largeNumber.copyWith(fontSize: 48),
            ),
            const SizedBox(height: 24),

            // Replaced Slider with ToggleButtons for discrete options.
            ToggleButtons(
              isSelected: _isSelected,
              onPressed: (int index) {
                setState(() {
                  // Ensure only one button is selected at a time.
                  for (int i = 0; i < _isSelected.length; i++) {
                    _isSelected[i] = i == index;
                  }
                  // Update the selected months value based on the chosen button.
                  _selectedMonths = _timeframeOptions[index];
                });
              },
              borderRadius: BorderRadius.circular(30),
              selectedColor: Colors.white,
              color: Colors.black,
              fillColor: Colors.black,
              constraints: const BoxConstraints(minHeight: 40.0, minWidth: 50.0),
              children: _timeframeOptions.map((months) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('$months'),
              )).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
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
    );
  }
}
