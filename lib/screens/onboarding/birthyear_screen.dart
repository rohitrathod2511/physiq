
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
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final store = ref.read(onboardingProvider);
    _selectedYear = store.birthYear ?? 2000;
  }

  void _onContinue() {
    ref.read(onboardingProvider).saveStepData('birthYear', _selectedYear);
    context.push('/onboarding/height-weight');
  }

  @override
  Widget build(BuildContext context) {
    // Generate years in ascending order (e.g., 1924 to 2014)
    final years = List.generate(101, (index) => (_currentYear - 110) + index);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Select your Birth Year",
              style: AppTextStyles.h1,
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  height: 300,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    controller: FixedExtentScrollController(
                      initialItem: years.indexOf(_selectedYear) != -1 ? years.indexOf(_selectedYear) : years.indexOf(2000),
                    ),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedYear = years[index];
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: years.length,
                      builder: (context, index) {
                        final year = years[index];
                        final isSelected = year == _selectedYear;
                        return Center(
                          child: Text(
                            year.toString(),
                            style: isSelected
                                ? AppTextStyles.h1.copyWith(fontSize: 32)
                                : AppTextStyles.h2.copyWith(color: Colors.grey.shade400),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade300,
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
