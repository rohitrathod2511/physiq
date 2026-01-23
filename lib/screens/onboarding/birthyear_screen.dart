
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';

class BirthYearScreen extends ConsumerStatefulWidget {
  const BirthYearScreen({super.key});

  @override
  ConsumerState<BirthYearScreen> createState() => _BirthYearScreenState();
}

class _BirthYearScreenState extends ConsumerState<BirthYearScreen> {
  late int _selectedYear;
  late int _selectedMonth; // 1-12
  late int _selectedDay;   // 1-31
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final store = ref.read(onboardingProvider);
    _selectedYear = store.birthYear ?? 2000;
    _selectedMonth = (store.data['birthMonth'] as int?) ?? 1;
    _selectedDay = (store.data['birthDay'] as int?) ?? 1;
  }

  void _onContinue() {
    final store = ref.read(onboardingProvider);
    store.saveStepData('birthYear', _selectedYear);
    store.saveStepData('birthMonth', _selectedMonth);
    store.saveStepData('birthDay', _selectedDay);
    context.push('/onboarding/height-weight');
  }

  @override
  Widget build(BuildContext context) {
    // Generate years in ascending order (e.g., 1924 to 2014)
    final years = List.generate(101, (index) => (_currentYear - 110) + index);
    
    // Default day/month if not set
    // This is simple selection.
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Select your Birth Date",
              style: AppTextStyles.h1,
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Selection Highlight Overlay
                  Container(
                    height: 60,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Day Slider
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(initialItem: _selectedDay - 1),
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                               setState(() => _selectedDay = index + 1);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 31,
                              builder: (context, index) {
                                return Center(
                                  child: Text(
                                    (index + 1).toString(),
                                    style: AppTextStyles.h2.copyWith(
                                      fontSize: 24,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Month Slider
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(initialItem: _selectedMonth - 1),
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                               setState(() => _selectedMonth = index + 1);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 12,
                              builder: (context, index) {
                                final months = [
                                  "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                                  "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
                                ];
                                return Center(
                                  child: Text(
                                    months[index],
                                    style: AppTextStyles.h2.copyWith(
                                      fontSize: 24,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Year Slider
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(
                              initialItem: years.indexOf(_selectedYear) != -1 ? years.indexOf(_selectedYear) : years.indexOf(2000),
                            ),
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                 if (index >= 0 && index < years.length) {
                                  _selectedYear = years[index];
                                 }
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: years.length,
                              builder: (context, index) {
                                final year = years[index];
                                final isSelected = year == _selectedYear;
                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: isSelected
                                        ? AppTextStyles.h1.copyWith(fontSize: 28, color: AppColors.primaryText)
                                        : AppTextStyles.h2.copyWith(fontSize: 24, color: AppColors.secondaryText.withOpacity(0.4)),
                                    child: Text(year.toString()),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.secondaryText.withOpacity(0.3),
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
