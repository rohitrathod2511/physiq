import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class DurationSelector extends StatefulWidget {
  final int initialDuration;
  final ValueChanged<int> onChanged;

  const DurationSelector({
    super.key,
    required this.initialDuration,
    required this.onChanged,
  });

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector> {
  late TextEditingController _controller;
  final List<int> _presets = [15, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDuration.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration (min)', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _presets.map((val) {
            final isSelected = widget.initialDuration == val;
            return InkWell(
              onTap: () {
                widget.onChanged(val);
                _controller.text = val.toString();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  '$val',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isSelected ? Colors.white : AppColors.primaryText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        
        // Custom Duration Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.card), // Consistent radius
            boxShadow: [AppShadows.card], // consistent shadow
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.heading2, // Match font size
                  decoration: InputDecoration(
                    labelText: 'Custom Duration',
                    labelStyle: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                    border: InputBorder.none, // Remove default border
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final intVal = int.tryParse(val);
                    if (intVal != null) {
                      widget.onChanged(intVal);
                    }
                  },
                ),
              ),
              Text(
                'min',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
