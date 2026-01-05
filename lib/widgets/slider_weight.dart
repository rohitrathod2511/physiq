
import 'package:flutter/material.dart';

class SliderWeight extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String unit;

  const SliderWeight({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.unit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.black,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.black,
            overlayColor: Colors.black.withOpacity(0.1),
            trackHeight: 6.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
