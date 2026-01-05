
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/utils/conversions.dart';
import 'package:physiq/widgets/unit_toggle.dart';
import 'package:physiq/widgets/slider_weight.dart';

class HeightWeightScreen extends ConsumerStatefulWidget {
  const HeightWeightScreen({super.key});

  @override
  ConsumerState<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends ConsumerState<HeightWeightScreen> {
  String _unitSystem = 'Metric'; // Metric or Imperial
  double _heightCm = 170.0;
  double _weightKg = 70.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(onboardingProvider);
      if (store.heightCm != null) {
        setState(() => _heightCm = store.heightCm!);
      }
      if (store.weightKg != null) {
        setState(() => _weightKg = store.weightKg!);
      }
    });
  }

  void _onUnitChanged(String newUnit) {
    setState(() {
      _unitSystem = newUnit;
    });
  }

  void _onContinue() {
    ref.read(onboardingProvider).saveStepData('heightCm', _heightCm);
    ref.read(onboardingProvider).saveStepData('weightKg', _weightKg);
    context.push('/onboarding/activity');
  }

  @override
  Widget build(BuildContext context) {
    final isMetric = _unitSystem == 'Metric';

    // Height Display
    String heightDisplay;
    if (isMetric) {
      heightDisplay = '${_heightCm.round()} cm';
    } else {
      heightDisplay = Conversions.cmToFeetInchesString(_heightCm);
    }

    // Weight Display
    double weightDisplayVal = isMetric ? _weightKg : Conversions.kgToLbs(_weightKg);
    String weightUnit = isMetric ? 'kg' : 'lbs';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                "Height & Weight",
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Height Section
              Text('Height', style: AppTextStyles.h2),
              const SizedBox(height: 16),
              Text(
                heightDisplay,
                style: AppTextStyles.largeNumber.copyWith(fontSize: 40),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.black,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: Colors.black,
                  trackHeight: 6.0,
                ),
                child: Slider(
                  value: _heightCm,
                  min: 100,
                  max: 250,
                  onChanged: (val) {
                    setState(() => _heightCm = val);
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Weight Section
              Text('Weight', style: AppTextStyles.h2),
              const SizedBox(height: 16),
              SliderWeight(
                value: weightDisplayVal,
                min: isMetric ? 30 : 66, // approx 30kg in lbs
                max: isMetric ? 200 : 440, // approx 200kg in lbs
                unit: weightUnit,
                onChanged: (val) {
                  setState(() {
                    if (isMetric) {
                      _weightKg = val;
                    } else {
                      _weightKg = Conversions.lbsToKg(val);
                    }
                  });
                },
              ),

              const SizedBox(height: 40),

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
    );
  }
}
