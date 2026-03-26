import 'package:advance_ruler_slider/advance_ruler_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physiq/theme/design_system.dart';

class SliderWeight extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String unit;

  const SliderWeight({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.unit,
    this.step = 0.1,
  });

  @override
  State<SliderWeight> createState() => _SliderWeightState();
}

class _SliderWeightState extends State<SliderWeight> {
  static const Color _indicatorColor = Color(0xFF3B82F6);

  final RulerScaleController _controller = RulerScaleController();
  late double _currentValue;
  bool _syncingFromParent = false;

  double get _majorTickInterval => widget.unit.toLowerCase() == 'kg' ? 5.0 : 10.0;

  @override
  void initState() {
    super.initState();
    _currentValue = _normalize(_clamp(widget.value));
  }

  @override
  void didUpdateWidget(covariant SliderWeight oldWidget) {
    super.didUpdateWidget(oldWidget);

    final incomingValue = _normalize(_clamp(widget.value));
    final rangeChanged =
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.unit != widget.unit ||
        oldWidget.step != widget.step;

    if (rangeChanged || (incomingValue - _currentValue).abs() > 0.0001) {
      _currentValue = incomingValue;
      _syncingFromParent = true;

      // Keep the ruler aligned when the parent updates the value or unit.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.jumpToValue(_currentValue);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncingFromParent = false;
        });
      });
    }
  }

  double _clamp(double value) {
    if (value < widget.min) return widget.min;
    if (value > widget.max) return widget.max;
    return value;
  }

  double _normalize(double value) {
    return double.parse(value.toStringAsFixed(1));
  }

  int _majorBucket(double value) {
    return (value / _majorTickInterval).floor();
  }

  void _handleValueChanged(double value) {
    final nextValue = _normalize(_clamp(value));
    if ((nextValue - _currentValue).abs() < 0.0001) {
      return;
    }

    final crossedMajorTick = _majorBucket(nextValue) != _majorBucket(_currentValue);

    setState(() {
      _currentValue = nextValue;
    });

    if (_syncingFromParent) {
      return;
    }

    if (crossedMajorTick) {
      HapticFeedback.selectionClick();
    }

    widget.onChanged(nextValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.97,
                  end: 1,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Text(
            '${_currentValue.toStringAsFixed(1)} ${widget.unit}',
            key: ValueKey('${_currentValue.toStringAsFixed(1)}-${widget.unit}'),
            style: AppTextStyles.largeNumber.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 90,
          child: RulerScale(
            controller: _controller,
            direction: Axis.horizontal,
            minValue: widget.min,
            maxValue: widget.max,
            initialValue: _currentValue,
            step: widget.step,
            majorTickInterval: _majorTickInterval,
            unitSpacing: 10,
            rulerExtent: 90,
            scrollPhysics: const BouncingScrollPhysics(),
            useScrollAnimation: true,
            hapticFeedbackEnabled: false,
            showDefaultIndicator: false,
            showBoundaryLabels: true,
            majorTickColor: AppColors.primaryText.withOpacity(0.48),
            minorTickColor: AppColors.secondaryText.withOpacity(0.26),
            selectedTickColor: _indicatorColor,
            selectedTickWidth: 2.5,
            selectedTickLength: 34,
            labelStyle: AppTextStyles.smallLabel.copyWith(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
            labelFormatter: (value) => value.toStringAsFixed(0),
            customIndicator: const _CenterIndicator(),
            onValueChanged: _handleValueChanged,
          ),
        ),
      ],
    );
  }
}

class _CenterIndicator extends StatelessWidget {
  const _CenterIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.arrow_drop_down_rounded,
          color: _SliderWeightState._indicatorColor,
          size: 30,
        ),
        Container(
          width: 4,
          height: 54,
          decoration: BoxDecoration(
            color: _SliderWeightState._indicatorColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}
