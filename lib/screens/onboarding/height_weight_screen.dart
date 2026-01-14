
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/utils/conversions.dart';
import 'package:physiq/widgets/unit_toggle.dart';


class HeightWeightScreen extends ConsumerStatefulWidget {
  const HeightWeightScreen({super.key});

  @override
  ConsumerState<HeightWeightScreen> createState() => _HeightWeightScreenState();
}

class _HeightWeightScreenState extends ConsumerState<HeightWeightScreen> {
  String _unitSystem = 'Metric'; // Metric or Imperial
  double _heightCm = 170.0;
  double _weightKg = 70.0;
  bool _isSwitchingUnits = false;

  late FixedExtentScrollController _heightController;
  late FixedExtentScrollController _weightController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default/initial values
    _heightController = FixedExtentScrollController(initialItem: (_heightCm - 100).round());
    _weightController = FixedExtentScrollController(initialItem: (_weightKg - 30).round());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(onboardingProvider);
      bool dataChanged = false;
      if (store.heightCm != null) {
        _heightCm = store.heightCm!;
        dataChanged = true;
      }
      if (store.weightKg != null) {
        _weightKg = store.weightKg!;
        dataChanged = true;
      }
      
      if (dataChanged) {
        setState(() {
          // Update controllers to reflect loaded data
          // Assuming stored data is always Metric (cm/kg) as per variable names
          if (_unitSystem == 'Metric') {
             _heightController.jumpToItem((_heightCm - 100).round().clamp(0, 120));
             _weightController.jumpToItem((_weightKg - 30).round().clamp(0, 170));
          } else {
             // Convert to Imperial indices
             int heightIndex = ((_heightCm / 2.54).round() - 40).clamp(0, 47);
             int weightIndex = ((_weightKg * 2.20462).round() - 66).clamp(0, 334);
             _heightController.jumpToItem(heightIndex);
             _weightController.jumpToItem(weightIndex);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onUnitChanged(String newUnit) {
    setState(() {
      _isSwitchingUnits = true;
      _unitSystem = newUnit;

      // Update controllers to new unit indices WITHOUT mutating value state
      if (newUnit == 'Metric') {
        int heightIndex = (_heightCm - 100).round().clamp(0, 120);
        int weightIndex = (_weightKg - 30).round().clamp(0, 170);

        _heightController.jumpToItem(heightIndex);
        _weightController.jumpToItem(weightIndex);
      } else {
        int heightIndex = ((_heightCm / 2.54).round() - 40).clamp(0, 47);
        int weightIndex = ((_weightKg * 2.20462).round() - 66).clamp(0, 334);

        _heightController.jumpToItem(heightIndex);
        _weightController.jumpToItem(weightIndex);
      }
    });

    // Reset flag after frame to allow slider interaction again
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isSwitchingUnits = false;
        });
      }
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
            const SizedBox(height: 16),
            Text(
              "Height & Weight",
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            
            // Expanded Scrollable Content
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
                      children: [
                        // Height Slider
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: _heightController,
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              if (_isSwitchingUnits) return;
                              setState(() {
                                if (isMetric) {
                                  _heightCm = (100 + index).toDouble();
                                } else {
                                  // Imperial: index 0 = 40 inches
                                  double inches = (40 + index).toDouble();
                                  _heightCm = inches * 2.54;
                                }
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: isMetric ? 121 : 48, // 100-220cm vs 40-87 inches
                              builder: (context, index) {
                                final selectedIndex = isMetric 
                                    ? (_heightCm - 100).round() 
                                    : ((_heightCm / 2.54).round() - 40);
                                final isSelected = index == selectedIndex;
                                
                                String text;
                                if (isMetric) {
                                  text = "${100 + index} cm";
                                } else {
                                  int inchesTotal = 40 + index;
                                  int ft = inchesTotal ~/ 12;
                                  int inch = inchesTotal % 12;
                                  text = "$ft' $inch\"";
                                }

                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: isSelected
                                        ? const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          )
                                        : TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 24,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.withOpacity(0.4),
                                          ),
                                    child: Text(text),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Weight Slider
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: _weightController,
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              if (_isSwitchingUnits) return;
                              setState(() {
                                if (isMetric) {
                                  _weightKg = (30 + index).toDouble();
                                } else {
                                  // Imperial: index 0 = 66 lbs
                                  double lbs = (66 + index).toDouble();
                                  _weightKg = lbs * 0.453592; 
                                }
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: isMetric ? 171 : 335, // 30-200kg vs 66-400lbs
                              builder: (context, index) {
                                final selectedIndex = isMetric 
                                    ? (_weightKg - 30).round() 
                                    : ((_weightKg * 2.20462).round() - 66);
                                final isSelected = index == selectedIndex;
                                
                                String text;
                                if (isMetric) {
                                  text = "${30 + index} kg";
                                } else {
                                  text = "${66 + index} lbs";
                                }

                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: isSelected
                                        ? const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          )
                                        : TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 24,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.withOpacity(0.4),
                                          ),
                                    child: Text(text),
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
            
            // Toggle above Continue button
            UnitToggle(
              value: _unitSystem,
              onChanged: _onUnitChanged,
              leftLabel: 'Metric',
              rightLabel: 'Imperial',
            ),
            const SizedBox(height: 30),

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
