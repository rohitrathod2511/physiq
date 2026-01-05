
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/widgets/central_pill_buttons.dart';

class DietPreferenceScreen extends ConsumerStatefulWidget {
  const DietPreferenceScreen({super.key});

  @override
  ConsumerState<DietPreferenceScreen> createState() => _DietPreferenceScreenState();
}

class _DietPreferenceScreenState extends ConsumerState<DietPreferenceScreen> {
  String? _selectedDiet;

  final List<String> _options = ['Classic', 'Vegetarian', 'Vegan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(onboardingProvider);
      if (store.dietPreference != null) {
        setState(() => _selectedDiet = store.dietPreference);
      }
    });
  }

  void _onContinue() {
    if (_selectedDiet != null) {
      ref.read(onboardingProvider).saveStepData('dietPreference', _selectedDiet);
      context.push('/onboarding/notification');
    }
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
            const Spacer(),
            Text(
              "Diet Preference",
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ..._options.asMap().entries.map((entry) {
              final option = entry.value;
              final isSelected = option == _selectedDiet;
              IconData icon;
              switch (option) {
                case 'Classic':
                  icon = Icons.restaurant;
                  break;
                case 'Vegetarian':
                  icon = Icons.grass;
                  break;
                case 'Vegan':
                  icon = Icons.eco;
                  break;
                default:
                  icon = Icons.circle;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDiet = option);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDiet != null ? _onContinue : null,
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
