import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class TimeframeStep extends StatelessWidget {
  final int? timeframe; // months
  final ValueChanged<int> onChanged;

  const TimeframeStep({super.key, this.timeframe, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Map slider value (0-4) to months
    final steps = [1, 3, 6, 9, 12];
    double sliderValue = 2.0; // Default index 1 -> 3 months
    
    if (timeframe != null) {
      int index = steps.indexOf(timeframe!);
      if (index != -1) {
        sliderValue = index.toDouble();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timeframe', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'How quickly do you want to reach your goal?',
            style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 48),
          
          Center(
            child: Text(
              '${steps[sliderValue.toInt()]} Months',
              style: AppTextStyles.h1.copyWith(color: AppColors.primary, fontSize: 48),
            ),
          ),
          const SizedBox(height: 48),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
              trackHeight: 8.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
            ),
            child: Slider(
              value: sliderValue,
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (val) {
                onChanged(steps[val.toInt()]);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Faster', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              Text('Slower', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
