import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:dotted_border/dotted_border.dart';

class DateSlider extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const DateSlider({super.key, required this.onDateSelected});

  @override
  _DateSliderState createState() => _DateSliderState();
}

class _DateSliderState extends State<DateSlider> {
  DateTime _selectedDate = DateTime.now();
  late final ScrollController _scrollController;

  // Constants for the slider layout
  static const double _itemWidth = 62.0; // 50 for item, 12 for margin
  static const int _totalDays = 31;
  static const int _centerIndex = 15;

  @override
  void initState() {
    super.initState();
    // This calculation sets the initial scroll position to roughly center the current day.
    final initialOffset = (_itemWidth * _centerIndex) - (_itemWidth * 2.5);
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        itemCount: _totalDays,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - _centerIndex));
          final isSelected =
              date.day == _selectedDate.day && date.month == _selectedDate.month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              widget.onDateSelected(date);
            },
            child: Container(
              width: 45, // Reduced width
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      DateFormat.E().format(date).toUpperCase(),
                      style: AppTextStyles.smallLabel.copyWith(
                        fontSize: 10, // Smaller font
                        color: isSelected ? AppColors.accent : AppColors.secondaryText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildDateBubble(date, isSelected),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateBubble(DateTime date, bool isSelected) {
    if (isSelected) {
      return Container(
        width: 32, // Reduced size
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent, width: 2),
          boxShadow: [AppShadows.card],
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: AppTextStyles.button.copyWith(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),
      );
    } else {
      return Container(
        width: 30, // Reduced size
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.secondaryText.withOpacity(0.2), // Very light solid border
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: AppTextStyles.label.copyWith(
              fontSize: 12, // Smaller font
              color: AppColors.secondaryText,
            ),
          ),
        ),
      );
    }
  }
}
