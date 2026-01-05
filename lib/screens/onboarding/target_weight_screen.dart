
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/utils/conversions.dart';
import 'package:physiq/widgets/unit_toggle.dart';
import 'package:physiq/widgets/slider_weight.dart';

class TargetWeightScreen extends ConsumerStatefulWidget {
  const TargetWeightScreen({super.key});

  @override
  ConsumerState<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends ConsumerState<TargetWeightScreen> {
  String _unitSystem = 'Metric';
  double _targetWeightKg = 70.0;
  double _currentWeightKg = 70.0;
  String? _goal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(onboardingProvider);
      if (store.weightKg != null) {
        _currentWeightKg = store.weightKg!;
        // Default target slightly different based on goal
        if (store.goal == 'Lose') {
          _targetWeightKg = _currentWeightKg * 0.9;
        } else if (store.goal == 'Gain') {
          _targetWeightKg = _currentWeightKg * 1.1;
        } else {
          _targetWeightKg = _currentWeightKg;
        }
      }
      if (store.targetWeightKg != null) {
        _targetWeightKg = store.targetWeightKg!;
      }
      _goal = store.goal;
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
    context.push('/onboarding/motivational-message');
  }

  @override
  Widget build(BuildContext context) {
    final isMetric = _unitSystem == 'Metric';
    double displayVal = isMetric ? _targetWeightKg : Conversions.kgToLbs(_targetWeightKg);
    String unit = isMetric ? 'kg' : 'lbs';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    "Target Weight",
                    style: AppTextStyles.h1,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  
                  SliderWeight(
                    value: displayVal,
                    min: isMetric ? 30 : 66,
                    max: isMetric ? 200 : 440,
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

                  const Spacer(),

                  UnitToggle(
                    value: _unitSystem,
                    onChanged: _onUnitChanged,
                    leftLabel: 'Metric',
                    rightLabel: 'Imperial',
                  ),

                  const SizedBox(height: 24),

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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
