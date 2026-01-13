import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physiq/theme/design_system.dart';

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  final DateTime _focusedDay = DateTime.now();
  late Map<DateTime, Map<String, dynamic>> _dayData;

  @override
  void initState() {
    super.initState();
    _generateDummyData();
  }

  void _generateDummyData() {
    _dayData = {};
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    // Generate ~20 full, ~3 partial, rest empty for visual preview
    for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(now.year, now.month, i);
        String status = 'none';
        
        // Mock pattern:
        // Mostly full to look nice/motivational
        if (date.isAfter(now)) {
           // Future days empty
           status = 'none';
        } else {
           // Create a specific pattern or random
           // Let's hardcode a nice looking pattern for the screenshot
           // Week 1: Full
           // Week 2: 1 partial, rest full
           // Week 3: 2 partial, rest full
           // Current week: Mixed
           
           if (i % 7 == 0 || i % 11 == 0) {
              status = 'partial';
           } else if (i % 9 == 0) {
              status = 'none'; // Missed day
           } else {
              status = 'full'; 
           }
        }
        
        if (status != 'none') {
             _dayData[date] = _generateDailyStats(status);
        }
    }
  }

  Map<String, dynamic> _generateDailyStats(String status) {
      return {
          'status': status,
          'calories_consumed': 2150,
          'calories_target': 2200,
          'protein': 145,
          'protein_target': 150,
          'carbs': 180,
          'fats': 65,
          'steps': 8542,
          'calories_burned': 450,
          'meals': [
              {'name': 'Oatmeal & Berries', 'cals': 350, 'p': 12, 'c': 45, 'f': 6},
              {'name': 'Grilled Chicken Salad', 'cals': 550, 'p': 45, 'c': 15, 'f': 20},
              {'name': 'Protein Shake', 'cals': 180, 'p': 25, 'c': 5, 'f': 2},
              {'name': 'Salmon & Rice', 'cals': 600, 'p': 40, 'c': 60, 'f': 15},
          ],
          'exercises': [
              {'name': 'Running (5km)', 'duration': '30 min', 'cals': 320},
              {'name': 'Pushups (3x15)', 'duration': '10 min', 'cals': 80},
          ]
      };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
      
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
             _buildMonthHeader(),
             const SizedBox(height: 32),
             _buildWeekDaysRow(),
             const SizedBox(height: 16),
             _buildCalendarGrid(),
             const SizedBox(height: 32),
             _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Text(
      DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase(),
      style: AppTextStyles.heading3.copyWith(
        letterSpacing: 1.5,
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    );
  }

  Widget _buildWeekDaysRow() {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) => SizedBox(
        width: 40,
        child: Center(
          child: Text(d, style: AppTextStyles.smallLabel.copyWith(
             fontWeight: FontWeight.bold,
             color: AppColors.secondaryText,
          )),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
      final daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
      final firstDayDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final shift = (firstDayDate.weekday == 7) ? 0 : firstDayDate.weekday;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: daysInMonth + shift,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
           crossAxisCount: 7,
           crossAxisSpacing: 10,
           mainAxisSpacing: 10,
           childAspectRatio: 1, // Square
        ),
        itemBuilder: (context, index) {
            if (index < shift) return const SizedBox();
            
            final day = index - shift + 1;
            final date = DateTime(_focusedDay.year, _focusedDay.month, day);
            return _buildDayCell(date);
        },
      );
  }

  Widget _buildDayCell(DateTime date) {
      final isToday = DateUtils.isSameDay(date, DateTime.now());
      
      final dataEntry = _dayData.entries.firstWhere(
          (e) => DateUtils.isSameDay(e.key, date),
          orElse: () => MapEntry(date, {'status': 'none'}),
      );
      
      final status = dataEntry.value['status'];
      
      Color bgColor = Colors.white;
      Color textColor = AppColors.primaryText;
      List<BoxShadow>? shadows;
      
      if (status == 'full') {
          bgColor = const Color(0xFF22C55E); // Green 500
          textColor = Colors.white;
          shadows = [
              BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
              )
          ];
      } else if (status == 'partial') {
          bgColor = const Color(0xFF86EFAC).withOpacity(0.5); // Faded Green
          textColor = const Color(0xFF14532D); // Dark Green Text
      } else {
          // Empty
          bgColor = Colors.white;
          textColor = AppColors.secondaryText;
      }

      return GestureDetector(
          onTap: () => _showDayDetails(date, dataEntry.value),
          child: Container(
              decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  // Border for today or empty cells to give shape?
                  border: isToday 
                    ? Border.all(color: Colors.black, width: 2) 
                    : (status == 'none' ? Border.all(color: Colors.grey.shade100) : null),
                  boxShadow: shadows,
              ),
              child: Center(
                  child: Text(
                      '${date.day}',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: (status == 'full' || isToday) ? FontWeight.bold : FontWeight.w500,
                      ),
                  ),
              ),
          ),
      );
  }
  
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(const Color(0xFF22C55E), "Completed"),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFF86EFAC).withOpacity(0.5), "Partial"),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.white, "Missed", hasBorder: true),
      ],
    );
  }
  
  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
             color: color,
             borderRadius: BorderRadius.circular(4),
             border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.smallLabel),
      ],
    );
  }
  
  void _showDayDetails(DateTime date, Map<String, dynamic> data) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildDetailSheet(date, data),
      );
  }

  Widget _buildDetailSheet(DateTime date, Map<String, dynamic> data) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                    Center(
                        child: Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                        )
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('EEEE, MMM d').format(date), style: AppTextStyles.heading2),
                        Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                               color: _getStatusColor(data['status']).withOpacity(0.1),
                               borderRadius: BorderRadius.circular(20),
                           ),
                           child: Text(
                               _getStatusText(data['status']), 
                               style: AppTextStyles.smallLabel.copyWith(
                                   color: _getStatusColor(data['status']),
                                   fontWeight: FontWeight.bold
                               )
                           ),
                        )
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    if (data['status'] == 'none') 
                         Padding(
                           padding: const EdgeInsets.symmetric(vertical: 40),
                           child: Center(child: Text("No activity recorded for this day.", style: AppTextStyles.body.copyWith(color: AppColors.secondaryText))),
                         )
                    else ...[
                        // Nutrition Summary
                        Text("Nutrition", style: AppTextStyles.h3),
                        const SizedBox(height: 16),
                        Row(
                           children: [
                              Expanded(child: _buildInfoCard("Calories", "${data['calories_consumed']} / ${data['calories_target']}", Icons.local_fire_department, Colors.orange)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildInfoCard("Protein", "${data['protein']}g / ${data['protein_target']}g", Icons.fitness_center, Colors.blue)),
                           ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Meals
                        Text("Meals", style: AppTextStyles.h3),
                        const SizedBox(height: 12),
                        ...(data['meals'] as List).map((m) => _buildMealRow(m)).toList(),
                        
                        const SizedBox(height: 24),
                        
                        // Exercise
                        Text("Workout Activity", style: AppTextStyles.h3),
                        const SizedBox(height: 12),
                        ...(data['exercises'] as List).map((e) => _buildExerciseRow(e)).toList(),
                        
                        const SizedBox(height: 24),
                        Text("Movement", style: AppTextStyles.h3),
                        const SizedBox(height: 12),
                        _buildInfoCard("Steps", "${data['steps']} steps", Icons.directions_walk, Colors.green),
                        
                        const SizedBox(height: 40),
                    ]
                ],
            ),
        ),
      );
  }
  
  Color _getStatusColor(String status) {
     if (status == 'full') return const Color(0xFF22C55E);
     if (status == 'partial') return Colors.orange;
     return Colors.grey;
  }
  
  String _getStatusText(String status) {
     if (status == 'full') return "Target Met";
     if (status == 'partial') return "Partial";
     return "Missed";
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
     return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
             color: AppColors.background,
             borderRadius: BorderRadius.circular(16),
         ),
         child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                 Row(
                   children: [
                     Icon(icon, size: 16, color: color),
                     const SizedBox(width: 8),
                     Text(title, style: AppTextStyles.smallLabel),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text(value, style: AppTextStyles.bodyBold),
             ],
         ),
     );
  }
  
  Widget _buildMealRow(Map<String, dynamic> meal) {
     return Padding(
         padding: const EdgeInsets.only(bottom: 12),
         child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(meal['name'], style: AppTextStyles.bodyMedium),
                     Text("${meal['cals']} kcal • ${meal['p']}g Protein", style: AppTextStyles.smallLabel),
                   ],
                 ),
                 Text("+${meal['cals']}", style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondaryText)),
             ],
         ),
     );
  }

  Widget _buildExerciseRow(Map<String, dynamic> ex) {
     return Padding(
         padding: const EdgeInsets.only(bottom: 12),
         child: Row(
             children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center, size: 16, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(ex['name'], style: AppTextStyles.bodyMedium),
                       Text("${ex['duration']} • ${ex['cals']} kcal burned", style: AppTextStyles.smallLabel),
                     ],
                  ),
                ),
             ],
         ),
     );
  }
}
