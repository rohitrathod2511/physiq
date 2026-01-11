
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/widgets/central_pill_buttons.dart';

class ActivityLifestyleScreen extends ConsumerStatefulWidget {
  const ActivityLifestyleScreen({super.key});

  @override
  ConsumerState<ActivityLifestyleScreen> createState() => _ActivityLifestyleScreenState();
}

class _ActivityLifestyleScreenState extends ConsumerState<ActivityLifestyleScreen> {
  // Map UI Label -> {Internal Value, Subtitle}
  final List<Map<String, String>> _activityOptions = [
    {
      'label': 'Sedentary',
      'value': 'Sedentary',
      'subtitle': 'No workouts / desk job',
    },
    {
      'label': 'Active', // Was "Lightly Active"
      'value': 'Lightly active',
      'subtitle': '3–5 workouts per week',
    },
    {
      'label': 'Athletic',
      'value': 'Athletic',
      'subtitle': '6+ workouts or physical job',
    },
  ];

  String? _selectedInternalValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(onboardingProvider);
      if (store.activityLevel != null) {
        // Try to match stored value with available internal values
        if (_activityOptions.any((opt) => opt['value'] == store.activityLevel)) {
           setState(() => _selectedInternalValue = store.activityLevel);
        }
      }
    });
  }

  void _onContinue() {
    if (_selectedInternalValue != null) {
      ref.read(onboardingProvider).saveStepData('activityLevel', _selectedInternalValue);
      context.push('/onboarding/goal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select your Activity Level", style: AppTextStyles.h1),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _activityOptions.map((option) {
                        final isSelected = _selectedInternalValue == option['value'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedInternalValue = option['value']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.card,
                              borderRadius: BorderRadius.circular(AppRadii.card),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: isSelected 
                                  ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] 
                                  : [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  option['label']!,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.heading2.copyWith(
                                    color: isSelected ? Colors.white : AppColors.primaryText,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  option['subtitle']!,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.secondaryText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedInternalValue != null ? _onContinue : null,
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
            ],
          ),
        ),
      ),
    );
  }
}
