import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:table_calendar/table_calendar.dart';

void showStreakCalendar(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.bigCard)),
    ),
    builder: (context) => const StreakCalendarPopup(),
  );
}

class StreakCalendarPopup extends StatefulWidget {
  const StreakCalendarPopup({super.key});

  @override
  State<StreakCalendarPopup> createState() => _StreakCalendarPopupState();
}

class _StreakCalendarPopupState extends State<StreakCalendarPopup> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // Dummy data for streak statuses
  final Map<DateTime, String> _streakStatus = {
    DateTime.utc(2025, 11, 18): 'green',
    DateTime.utc(2025, 11, 19): 'yellow',
    DateTime.utc(2025, 11, 20): 'red',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Streak Calendar', style: AppTextStyles.heading1.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            _buildCalendar(),
            const SizedBox(height: 24),
            if (_selectedDay != null) _buildDaySummaryPanel(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'You have a 24-hour grace period to edit your entries.',
                style: AppTextStyles.subheading,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: AppTextStyles.bodyBold.copyWith(fontSize: 16),
        leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.accent),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.accent),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTextStyles.subheading.copyWith(fontSize: 12),
        weekendStyle: AppTextStyles.subheading.copyWith(fontSize: 12),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final status = _streakStatus[DateTime.utc(date.year, date.month, date.day)];
          if (status == null) return null;
          return Positioned(
            bottom: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status == 'green'
                    ? Colors.green
                    : status == 'yellow'
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          );
        },
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: AppTextStyles.body,
        weekendTextStyle: AppTextStyles.body,
        outsideTextStyle: AppTextStyles.subheading,
        disabledTextStyle: AppTextStyles.subheading,
        selectedTextStyle: AppTextStyles.bodyBold.copyWith(color: Colors.white), // Visible on Black (Light) & Dark (Dark)
        todayTextStyle: AppTextStyles.bodyBold.copyWith(color: Colors.white),
        selectedDecoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildDaySummaryPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.smallCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMd().format(_selectedDay!),
            style: AppTextStyles.bodyBold,
          ),
          const SizedBox(height: 12),
          // Placeholder for summary details
          Text('Calories eaten: 500', style: AppTextStyles.body),
          Text('Calories burned: 200', style: AppTextStyles.body),
          const SizedBox(height: 8),
          Text('Meals:', style: AppTextStyles.bodyBold),
          Text('- Meal A', style: AppTextStyles.body),
          Text('- Meal B', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
