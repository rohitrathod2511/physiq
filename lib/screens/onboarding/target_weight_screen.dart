import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/utils/conversions.dart';
import 'package:physiq/widgets/slider_weight.dart';
import 'package:physiq/widgets/unit_toggle.dart';

class TargetWeightScreen extends ConsumerStatefulWidget {
  const TargetWeightScreen({super.key});

  @override
  ConsumerState<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends ConsumerState<TargetWeightScreen> {
  String _unitSystem = 'Metric';
  double _targetWeight = 0;

  String? _normalizeGoal(String? goal) {
    final normalizedGoal = goal?.trim().toLowerCase();
    if (normalizedGoal == null || normalizedGoal.isEmpty) {
      return null;
    }
    if (normalizedGoal.contains('gain')) {
      return 'gain';
    }
    if (normalizedGoal.contains('lose') || normalizedGoal.contains('loss')) {
      return 'lose';
    }
    if (normalizedGoal.contains('maintain')) {
      return 'maintain';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    final store = ref.read(onboardingProvider);
    final goal = _normalizeGoal(store.goal);
    final currentWeight = (store.weightKg ?? 80.0).toDouble();

    if (goal == 'gain') {
      _targetWeight = currentWeight + 10;
    } else if (goal == 'lose') {
      _targetWeight = currentWeight - 10;
    } else {
      _targetWeight = currentWeight;
    }

    if (store.targetWeightKg != null) {
      _targetWeight = store.targetWeightKg!;
    }

    _targetWeight = _targetWeight.clamp(30.0, 200.0).toDouble();

    print('Goal: $goal');
    print('Current Weight: $currentWeight');
    print('Target Weight: $_targetWeight');
  }

  void _onUnitChanged(String newUnit) {
    setState(() {
      _unitSystem = newUnit;
    });
  }

  void _onContinue() {
    ref.read(onboardingProvider).saveStepData('targetWeightKg', _targetWeight);
    context.push('/onboarding/result-message');
  }

  @override
  Widget build(BuildContext context) {
    final isMetric = _unitSystem == 'Metric';
    final double displayVal = isMetric
        ? _targetWeight
        : Conversions.kgToLbs(_targetWeight);
    final String unit = isMetric ? 'kg' : 'lbs';

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
            Text("What is your Target Weight?", style: AppTextStyles.h1),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SliderWeight(
                        value: displayVal,
                        min: isMetric ? 30.0 : Conversions.kgToLbs(30.0),
                        max: isMetric ? 200.0 : Conversions.kgToLbs(200.0),
                        unit: unit,
                        onChanged: (value) {
                          setState(() {
                            if (isMetric) {
                              _targetWeight = value;
                            } else {
                              _targetWeight = Conversions.lbsToKg(value);
                            }
                            _targetWeight = _targetWeight
                                .clamp(30.0, 200.0)
                                .toDouble();
                          });
                        },
                      ),
                      const SizedBox(height: 50),
                      UnitToggle(
                        value: _unitSystem,
                        onChanged: _onUnitChanged,
                        leftLabel: 'Metric',
                        rightLabel: 'Imperial',
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
    );
  }
}
