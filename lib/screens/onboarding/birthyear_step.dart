import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class BirthYearStep extends StatelessWidget {
  final int? birthYear;
  final ValueChanged<int> onChanged;

  const BirthYearStep({super.key, this.birthYear, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final startYear = 1950;
    final years = List.generate(currentYear - startYear + 1, (index) => startYear + index);
    
    // Default to middle if not set
    int initialIndex = 0;
    if (birthYear != null) {
      initialIndex = years.indexOf(birthYear!);
      if (initialIndex == -1) initialIndex = 0;
    } else {
      initialIndex = years.length ~/ 2;
      // Trigger default selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(years[initialIndex]);
      });
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Birth Year', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your age accurately.',
            style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 300,
                child: CupertinoPicker(
                  itemExtent: 50,
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  onSelectedItemChanged: (index) {
                    onChanged(years[index]);
                  },
                  selectionOverlay: Container(
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                      ),
                    ),
                  ),
                  children: years.map((year) => Center(
                    child: Text(
                      year.toString(),
                      style: AppTextStyles.h3.copyWith(fontSize: 24),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
