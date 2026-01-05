import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physiq/theme/design_system.dart';

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
    // Center the current day (index 15).
    // Assuming screen width ~360-400. Center is ~180-200.
    // Item center is at 15 * 62 + 31 = 961.
    // Offset = 961 - 180 = 781.
    // Current: 62 * 12.5 = 775. Close enough.
    final initialOffset = (_itemWidth * _centerIndex) - (_itemWidth * 2.5);
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    
    // Ensure we scroll to center after build to be precise
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final screenWidth = MediaQuery.of(context).size.width;
        final centerOffset = (_itemWidth * _centerIndex) + (_itemWidth / 2) - (screenWidth / 2);
        _scrollController.jumpTo(centerOffset);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
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
              width: 45,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        fontSize: 10,
                        color: isSelected ? AppColors.accent : AppColors.secondaryText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: AppTextStyles.button.copyWith(fontSize: 16, color: AppColors.primaryText),
          ),
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: AppColors.secondaryText.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: AppTextStyles.label.copyWith(
              fontSize: 14,
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }
}