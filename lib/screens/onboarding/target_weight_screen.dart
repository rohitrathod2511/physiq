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
  double _targetWeightKg = 80.0;
  double _currentWeightKg = 80.0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(onboardingProvider);
      if (store.weightKg != null) {
        _currentWeightKg = store.weightKg!;
        switch (_normalizeGoal(store.goal)) {
          case 'gain':
            _targetWeightKg = _currentWeightKg + 5;
            break;
          case 'lose':
            _targetWeightKg = _currentWeightKg - 5;
            break;
          default:
            _targetWeightKg = _currentWeightKg;
        }
      }
      if (store.targetWeightKg != null) {
        _targetWeightKg = store.targetWeightKg!;
      }
      setState(() {});
    });
  }

  void _onUnitChanged(String newUnit) {
    setState(() {
      _unitSystem = newUnit;
    });
  }

  void _onContinue() {
    ref.read(onboardingProvider).saveStepData('targetWeightKg', _targetWeightKg);
    context.push('/onboarding/result-message');
  }

  @override
  Widget build(BuildContext context) {
    final isMetric = _unitSystem == 'Metric';
    final double displayVal = isMetric
        ? _targetWeightKg
        : Conversions.kgToLbs(_targetWeightKg);
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
            Text(
              "What is your Target Weight?",
              style: AppTextStyles.h1,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SliderWeight(
                        value: displayVal,
                        min: isMetric ? 30 : 66,
                        max: isMetric ? 140 : 308.7,
                        unit: unit,
                        onChanged: (val) {
                          setState(() {
                            if (isMetric) {
                              _targetWeightKg = val;
                            } else {
                              _targetWeightKg = Conversions.lbsToKg(val);
                            }
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
