import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class IntensitySlider extends StatelessWidget {
  final String currentIntensity;
  final ValueChanged<String> onChanged;

  const IntensitySlider({
    super.key,
    required this.currentIntensity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Map string to slider value
    double sliderValue = 1.0;
    if (currentIntensity == 'low') sliderValue = 0.0;
    if (currentIntensity == 'medium') sliderValue = 1.0;
    if (currentIntensity == 'high') sliderValue = 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set Intensity', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
            trackHeight: 6.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
          ),
          child: Slider(
            value: sliderValue,
            min: 0.0,
            max: 2.0,
            divisions: 2,
            onChanged: (val) {
              if (val == 0.0) onChanged('low');
              if (val == 1.0) onChanged('medium');
              if (val == 2.0) onChanged('high');
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Low', 'Run', currentIntensity == 'low'),
            _buildLabel('Medium', 'Jog', currentIntensity == 'medium'),
            _buildLabel('High', 'Sprint', currentIntensity == 'high'),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String title, String subtitle, bool isActive) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.bodyBold.copyWith(
            color: isActive ? AppColors.primary : AppColors.secondaryText,
          ),
        ),
        Text(
          subtitle,
          style: AppTextStyles.smallLabel.copyWith(
            color: isActive ? AppColors.primary : AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
