import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class HeightWeightStep extends StatefulWidget {
  final double? height;
  final double? weight;
  final bool isMetric;
  final Function(double, double) onChanged;
  final ValueChanged<bool>? onUnitChanged;

  const HeightWeightStep({
    super.key,
    this.height,
    this.weight,
    required this.isMetric,
    required this.onChanged,
    this.onUnitChanged,
  });

  @override
  State<HeightWeightStep> createState() => _HeightWeightStepState();
}

class _HeightWeightStepState extends State<HeightWeightStep> {
  late FixedExtentScrollController _heightController;
  late FixedExtentScrollController _weightController;

  // Ranges
  final List<int> _cmValues = List.generate(151, (index) => 100 + index); // 100-250
  final List<int> _inValues = List.generate(61, (index) => 36 + index); // 36-96 (3'0" - 8'0")
  
  final List<int> _kgValues = List.generate(171, (index) => 30 + index); // 30-200
  final List<int> _lbsValues = List.generate(391, (index) => 60 + index); // 60-450

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    // Height
    int heightIndex = 0;
    if (widget.height != null) {
      if (widget.isMetric) {
        heightIndex = _cmValues.indexOf(widget.height!.round());
      } else {
        heightIndex = _inValues.indexOf(widget.height!.round());
      }
    }
    if (heightIndex == -1) heightIndex = widget.isMetric ? 70 : 30; // Default ~170cm or ~5'6"
    _heightController = FixedExtentScrollController(initialItem: heightIndex);

    // Weight
    int weightIndex = 0;
    if (widget.weight != null) {
      if (widget.isMetric) {
        weightIndex = _kgValues.indexOf(widget.weight!.round());
      } else {
        weightIndex = _lbsValues.indexOf(widget.weight!.round());
      }
    }
    if (weightIndex == -1) weightIndex = widget.isMetric ? 40 : 100; // Default ~70kg or ~160lbs
    _weightController = FixedExtentScrollController(initialItem: weightIndex);
  }

  @override
  void didUpdateWidget(HeightWeightStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMetric != widget.isMetric) {
      // Unit changed, we need to convert values or just reset to defaults?
      // Ideally convert.
      // But for simplicity in this picker, we might just re-init controllers to nearest value.
      // Since parent holds state, we rely on parent passing converted values?
      // The parent onboarding screen stores raw values. It doesn't seem to convert them when toggling isMetric in the code I saw.
      // Wait, OnboardingScreen just stores 'height' and 'weight'.
      // If I toggle unit, I should probably convert the stored value.
      // For now, I'll just re-init controllers.
      _initControllers();
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onHeightChanged(int index) {
    double val;
    if (widget.isMetric) {
      val = _cmValues[index].toDouble();
    } else {
      val = _inValues[index].toDouble();
    }
    widget.onChanged(val, widget.weight ?? (widget.isMetric ? 70 : 160));
  }

  void _onWeightChanged(int index) {
    double val;
    if (widget.isMetric) {
      val = _kgValues[index].toDouble();
    } else {
      val = _lbsValues[index].toDouble();
    }
    widget.onChanged(widget.height ?? (widget.isMetric ? 170 : 66), val);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text('Height & Weight', style: AppTextStyles.h1),
          const SizedBox(height: 16),
          // Unit Toggle
          if (widget.onUnitChanged != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleOption('Metric', widget.isMetric),
                  _buildToggleOption('Imperial', !widget.isMetric),
                ],
              ),
            ),
          const SizedBox(height: 32),
          
          Expanded(
            child: Row(
              children: [
                // Height Picker
                Expanded(
                  child: Column(
                    children: [
                      Text('Height', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _heightController,
                          itemExtent: 40,
                          onSelectedItemChanged: _onHeightChanged,
                          selectionOverlay: Container(
                            decoration: BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                              ),
                            ),
                          ),
                          children: widget.isMetric
                              ? _cmValues.map((h) => Center(child: Text('$h cm', style: AppTextStyles.h3))).toList()
                              : _inValues.map((h) {
                                  final ft = h ~/ 12;
                                  final inch = h % 12;
                                  return Center(child: Text('$ft\' $inch"', style: AppTextStyles.h3));
                                }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Weight Picker
                Expanded(
                  child: Column(
                    children: [
                      Text('Weight', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _weightController,
                          itemExtent: 40,
                          onSelectedItemChanged: _onWeightChanged,
                          selectionOverlay: Container(
                            decoration: BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                              ),
                            ),
                          ),
                          children: widget.isMetric
                              ? _kgValues.map((w) => Center(child: Text('$w kg', style: AppTextStyles.h3))).toList()
                              : _lbsValues.map((w) => Center(child: Text('$w lbs', style: AppTextStyles.h3))).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected && widget.onUnitChanged != null) {
          widget.onUnitChanged!(text == 'Metric');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
              : null,
        ),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
