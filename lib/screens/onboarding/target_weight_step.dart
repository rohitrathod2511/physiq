import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class TargetWeightStep extends StatefulWidget {
  final double? targetWeight; // always in kg
  final bool isMetric;
  final ValueChanged<double> onChanged;
  final ValueChanged<bool>? onUnitChanged;

  const TargetWeightStep({
    super.key,
    this.targetWeight,
    required this.isMetric,
    required this.onChanged,
    this.onUnitChanged,
  });

  @override
  State<TargetWeightStep> createState() => _TargetWeightStepState();
}

class _TargetWeightStepState extends State<TargetWeightStep> {
  late FixedExtentScrollController _scrollController;
  
  // Ranges
  // KG: 30.0 to 200.0 in 0.1 steps? Too many items for a wheel?
  // Let's do 0.5 steps or 1.0 steps. 
  // User wants "best feel". 0.1 is too fine for a wheel usually unless it's a ruler.
  // Let's do 0.5kg steps.
  // 30 to 200 -> (200-30)*2 = 340 items. That's fine.
  
  // LBS: 60 to 450. 0.5 lbs steps?
  // (450-60)*2 = 780 items. Fine.
  
  late List<double> _values;

  @override
  void initState() {
    super.initState();
    _initValues();
    _initController();
  }

  void _initValues() {
    if (widget.isMetric) {
      _values = List.generate(((200 - 30) * 2).toInt() + 1, (index) => 30.0 + index * 0.5);
    } else {
      _values = List.generate(((450 - 60) * 2).toInt() + 1, (index) => 60.0 + index * 0.5);
    }
  }

  void _initController() {
    double currentVal = 0;
    if (widget.targetWeight != null) {
      if (widget.isMetric) {
        currentVal = widget.targetWeight!;
      } else {
        currentVal = widget.targetWeight! * 2.20462;
      }
    } else {
      currentVal = widget.isMetric ? 70.0 : 150.0;
    }

    // Find nearest value
    int index = 0;
    double minDiff = double.infinity;
    for (int i = 0; i < _values.length; i++) {
      double diff = (_values[i] - currentVal).abs();
      if (diff < minDiff) {
        minDiff = diff;
        index = i;
      }
    }
    
    _scrollController = FixedExtentScrollController(initialItem: index);
  }

  @override
  void didUpdateWidget(TargetWeightStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMetric != widget.isMetric) {
      _initValues();
      _initController();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectedItemChanged(int index) {
    double val = _values[index];
    if (widget.isMetric) {
      widget.onChanged(val);
    } else {
      widget.onChanged(val / 2.20462);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current display value
    double displayValue = 0;
    if (widget.targetWeight != null) {
      if (widget.isMetric) {
        displayValue = widget.targetWeight!;
      } else {
        displayValue = widget.targetWeight! * 2.20462;
      }
    } else {
      displayValue = widget.isMetric ? 70.0 : 150.0;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target Weight', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'What is your goal weight?',
            style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 24),
          
          // Toggle
          if (widget.onUnitChanged != null)
            Center(
              child: Container(
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
            ),
            
          const Spacer(),
          
          // Big Value Display
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayValue.toStringAsFixed(1),
                  style: AppTextStyles.h1.copyWith(fontSize: 64),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isMetric ? 'kg' : 'lbs',
                  style: AppTextStyles.h3.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Horizontal Wheel
          SizedBox(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection Indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Wheel
                RotatedBox(
                  quarterTurns: -1,
                  child: ListWheelScrollView(
                    controller: _scrollController,
                    itemExtent: 60,
                    perspective: 0.005,
                    diameterRatio: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: _onSelectedItemChanged,
                    children: _values.map((v) {
                      return RotatedBox(
                        quarterTurns: 1,
                        child: Center(
                          child: Text(
                            v.toStringAsFixed(1),
                            style: AppTextStyles.h3.copyWith(
                              color: v == displayValue 
                                  ? Colors.transparent // Hide text under indicator if we want, or just keep it
                                  : AppColors.secondaryText.withOpacity(0.5),
                              fontSize: 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
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
