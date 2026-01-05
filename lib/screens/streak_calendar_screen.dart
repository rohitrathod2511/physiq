import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:intl/intl.dart';

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock data for demonstration
  final Map<DateTime, Map<String, dynamic>> _dayData = {
    DateTime.now().subtract(const Duration(days: 1)): {
      'status': 'full', // full, partial, none
      'meals': [
        {'name': 'Oatmeal', 'calories': 350, 'protein': 12},
        {'name': 'Chicken Salad', 'calories': 450, 'protein': 40},
      ],
      'calories': 2100,
      'protein': 140,
      'carbs': 200,
      'fats': 60,
      'exercises': ['Running (5km)', 'Pushups (3x15)'],
    },
    DateTime.now().subtract(const Duration(days: 2)): {
      'status': 'partial',
      'meals': [
        {'name': 'Toast', 'calories': 150, 'protein': 4},
      ],
      'calories': 1200,
      'protein': 60,
      'carbs': 150,
      'fats': 40,
      'exercises': [],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
        title: Text('Streak Calendar', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCalendar(),
            const SizedBox(height: 24),
            if (_selectedDay != null) _buildDayDetails(_selectedDay!),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final int firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        children: [
          // Month Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.secondaryText),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: AppTextStyles.heading3,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Days of Week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    day,
                    style: AppTextStyles.smallLabel.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth + (firstWeekday - 1),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox();
              }
              final day = index - (firstWeekday - 1) + 1;
              final date = DateTime(_focusedDay.year, _focusedDay.month, day);
              return _buildCalendarDay(date);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    final isSelected = _selectedDay != null && DateUtils.isSameDay(date, _selectedDay);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    
    // Determine color based on status
    Color bgColor = Colors.transparent;
    Color textColor = AppColors.primaryText;

    // Check mock data (ignoring time)
    final dateKey = _dayData.keys.firstWhere(
      (k) => DateUtils.isSameDay(k, date),
      orElse: () => DateTime(0),
    );
    
    if (dateKey.year != 0) {
      final status = _dayData[dateKey]!['status'];
      if (status == 'full') {
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green[800]!;
      } else if (status == 'partial') {
        bgColor = Colors.yellow.withOpacity(0.2);
        textColor = Colors.orange[800]!;
      } else if (status == 'none') {
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[800]!;
      }
    } else if (date.isBefore(DateTime.now())) {
       // Default for past days with no data
       bgColor = Colors.red.withOpacity(0.1);
       textColor = Colors.red[800]!;
    }

    if (isSelected) {
      bgColor = AppColors.accent;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = date;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: AppColors.accent, width: 1.5) : null,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: AppTextStyles.body.copyWith(
              color: textColor,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayDetails(DateTime date) {
    final dateKey = _dayData.keys.firstWhere(
      (k) => DateUtils.isSameDay(k, date),
      orElse: () => DateTime(0),
    );

    if (dateKey.year == 0) {
      return Center(
        child: Text(
          'No data for ${DateFormat('MMM d').format(date)}',
          style: AppTextStyles.secondaryLabel,
        ),
      );
    }

    final data = _dayData[dateKey]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(date),
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Calories', '${data['calories']} kcal'),
          _buildDetailRow('Protein', '${data['protein']}g'),
          _buildDetailRow('Carbs', '${data['carbs']}g'),
          _buildDetailRow('Fats', '${data['fats']}g'),
          const Divider(height: 24),
          Text('Meals', style: AppTextStyles.bodyBold),
          const SizedBox(height: 8),
          ...(data['meals'] as List).map((meal) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(meal['name'], style: AppTextStyles.body),
                Text('${meal['calories']} kcal', style: AppTextStyles.secondaryLabel),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Text('Exercises', style: AppTextStyles.bodyBold),
          const SizedBox(height: 8),
          if ((data['exercises'] as List).isEmpty)
            Text('No exercises', style: AppTextStyles.secondaryLabel)
          else
            ...(data['exercises'] as List).map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(ex, style: AppTextStyles.body),
            )),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.secondaryLabel),
          Text(value, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }
}
