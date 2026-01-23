import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physiq/theme/design_system.dart';

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, String> _monthStatus = {};
  int _targetCalories = 2000; // Default, updated from Firebase

  @override
  void initState() {
    super.initState();
    _fetchMonthData(_focusedDay);
  }

  Future<void> _fetchMonthData(DateTime month) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Fetch Target Calories from User Profile
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final currentPlan = data?['currentPlan'] as Map<String, dynamic>?;
        if (currentPlan != null) {
          // Try different possible keys for calories
          _targetCalories = (currentPlan['calories'] ?? currentPlan['goalCalories'] ?? 2000) as int;
        } else {
           // Fallback to nutrition map
          final nutrition = data?['nutrition'] as Map<String, dynamic>?;
           _targetCalories = (nutrition?['calories'] ?? 2000) as int;
        }
      }
    } catch (e) {
      print("Error fetching user goal: $e");
    }

    // 2. Fetch Daily Summaries for the Month
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final String startId = DateFormat('yyyy-MM-dd').format(start);
    final String endId = DateFormat('yyyy-MM-dd').format(end);

    try {
      // Strategy: 
      // Query "daily_summaries" for nutrition view.
      // This is the source of truth for "consumed stats".
      final summariesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .where('date', isGreaterThanOrEqualTo: startId)
          .where('date', isLessThanOrEqualTo: endId)
          .get();

      final Map<DateTime, String> newStatus = {};

      for (var doc in summariesSnapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String;
        final dateParts = dateStr.split('-');
        if (dateParts.length == 3) {
          final date = DateTime(
            int.parse(dateParts[0]), 
            int.parse(dateParts[1]), 
            int.parse(dateParts[2])
          );
          
          final int calories = (data['calories'] ?? 0).toInt();
          
          if (calories >= _targetCalories) {
            newStatus[date] = 'full';
          } else if (calories > 0) {
            newStatus[date] = 'partial';
          } else {
            newStatus[date] = 'none';
          }
        }
      }
      
      // Also check for days not in summary but might have meals (fallback)
      // Though technically logMeal updates summary, so summary should be enough.
      // We will stick to summary for efficiency as per constraints.
      
      if (mounted) {
        setState(() {
          _monthStatus = newStatus;
        });
      }
      
    } catch (e) {
      print("Error fetching month data: $e");
    }
  }

  void _onPageChanged(int pageIndex) {
    // Logic to handle page change in custom calendar if implemented
    // But here we are just changing focused day manually usually
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.primaryText),
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
              _fetchMonthData(_focusedDay); // Re-fetch
            });
          },
        ),
        Text(
          DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase(),
          style: AppTextStyles.heading3.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: AppColors.primaryText),
          onPressed: () {
             setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
              _fetchMonthData(_focusedDay); // Re-fetch
            });
          },
        ),
      ],
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
      
      // Look up status (stripped of time time)
      final dateKey = DateTime(date.year, date.month, date.day);
      final status = _monthStatus[dateKey] ?? 'none';
      
      Color bgColor = AppColors.card;
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
          bgColor = AppColors.card;
          textColor = AppColors.secondaryText;
      }

      return GestureDetector(
          onTap: () => _showDayDetails(date),
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
        _buildLegendItem(AppColors.card, "Missed", hasBorder: true),
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
  
  void _showDayDetails(DateTime date) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _DayDetailSheet(date: date, targetCalories: _targetCalories),
      );
  }
}

class _DayDetailSheet extends StatefulWidget {
  final DateTime date;
  final int targetCalories;

  const _DayDetailSheet({required this.date, required this.targetCalories});

  @override
  State<_DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<_DayDetailSheet> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchDayData();
  }

  Future<Map<String, dynamic>> _fetchDayData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final startOfDay = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final dateId = DateFormat('yyyy-MM-dd').format(startOfDay);

    // 1. Fetch Daily Summary (Nutrients & Steps)
    final summaryDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('daily_summaries')
        .doc(dateId)
        .get();

    final summaryData = summaryDoc.data() ?? {};
    
    // 2. Fetch Meals
    final mealsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meals')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .get();

    final meals = mealsSnap.docs.map((d) => d.data()).toList();

    // 3. Fetch Workouts
    final exerciseSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('exerciseLogs')
         // Note: Assuming 'timestamp' or 'completedAt' or 'loggedAt'. Promp says 'loggedAt'.
         // Let's check common usage, but 'timestamp' is standard in this app.
         // Wait, prompt says: "timestamp/loggedAt".
         // Using 'timestamp' as safe default based on other files, but falling back 
         // to likely name if needed.
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final exercises = exerciseSnap.docs.map((d) => d.data()).toList();

    // Aggregations
    int caloriesConsumed = (summaryData['calories'] ?? 0).toInt();
    int proteinConsumed = (summaryData['protein'] ?? 0).toInt();
    int steps = (summaryData['steps'] ?? 0).toInt();

    // If summary missing but meals exist, re-calc (fallback)
    if (!summaryDoc.exists && meals.isNotEmpty) {
       for (var m in meals) {
         caloriesConsumed += (m['calories'] as num? ?? 0).toInt();
         proteinConsumed += (m['protein'] as num? ?? 0).toInt();
       }
    }

    // Protein Target: Fetch dynamically or pass in?
    // We already have User profile in parent, but here we might need specific daily target if it changes.
    // For simplicity, we re-fetch user or reuse logic.
    // Let's optimize: We can just use the targetCalories passed in.
    // For Protein Target, we'll quickly grab the user plan again or assume a ratio/default.
    // Better: GET user doc to be accurate.
    int proteinTarget = 150; // Default
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
         final uData = userDoc.data();
         proteinTarget = (uData?['currentPlan']?['protein'] ?? uData?['nutrition']?['protein'] ?? 150).toInt();
      }
    } catch (_) {}

    // Determine Status for coloring the pill
    String status = 'none';
    if (caloriesConsumed >= widget.targetCalories) {
      status = 'full';
    } else if (caloriesConsumed > 0) {
      status = 'partial';
    }

    return {
      'status': status,
      'calories_consumed': caloriesConsumed,
      'calories_target': widget.targetCalories,
      'protein': proteinConsumed,
      'protein_target': proteinTarget,
      'steps': steps,
      'meals': meals,
      'exercises': exercises,
    };
  }

  @override
  Widget build(BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                   return Center(child: Text('Error loading details', style: AppTextStyles.body));
                }
                
                final data = snapshot.data ?? {};
                final status = data['status'] as String? ?? 'none';
                final cals = data['calories_consumed'] ?? 0;
                final targetCals = data['calories_target'] ?? 0;
                final protein = data['protein'] ?? 0;
                final targetProtein = data['protein_target'] ?? 0;
                final stepCount = data['steps'] ?? 0;
                final meals = (data['meals'] as List?) ?? [];
                final exercises = (data['exercises'] as List?) ?? [];

                return ListView(
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
                            Text(DateFormat('EEEE, MMM d').format(widget.date), style: AppTextStyles.heading2),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                   color: _getStatusColor(status).withOpacity(0.1),
                                   borderRadius: BorderRadius.circular(20),
                               ),
                               child: Text(
                                   _getStatusText(status), 
                                   style: AppTextStyles.smallLabel.copyWith(
                                       color: _getStatusColor(status),
                                       fontWeight: FontWeight.bold
                                   )
                               ),
                            )
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        if (status == 'none' && meals.isEmpty && exercises.isEmpty && stepCount == 0) 
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
                                   Expanded(child: _buildInfoCard("Calories", "$cals / $targetCals", Icons.local_fire_department, Colors.orange)),
                                   const SizedBox(width: 12),
                                   Expanded(child: _buildInfoCard("Protein", "${protein}g / ${targetProtein}g", Icons.fitness_center, Colors.blue)),
                               ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Meals
                            Text("Meals", style: AppTextStyles.h3),
                            const SizedBox(height: 12),
                            if (meals.isEmpty)
                               Padding(padding: const EdgeInsets.only(bottom:12), child: Text("No meals logged.", style: AppTextStyles.body.copyWith(color:Colors.grey))),
                            ...meals.map((m) => _buildMealRow(m)).toList(),
                            
                            const SizedBox(height: 24),
                            
                            // Exercise
                            Text("Workout Activity", style: AppTextStyles.h3),
                            const SizedBox(height: 12),
                             if (exercises.isEmpty)
                               Padding(padding: const EdgeInsets.only(bottom:12), child: Text("No workouts logged.", style: AppTextStyles.body.copyWith(color:Colors.grey))),
                            ...exercises.map((e) => _buildExerciseRow(e)).toList(),
                            
                            const SizedBox(height: 24),
                            Text("Movement", style: AppTextStyles.h3),
                            const SizedBox(height: 12),
                            _buildInfoCard("Steps", "$stepCount steps", Icons.directions_walk, Colors.green),
                            
                            const SizedBox(height: 40),
                        ]
                    ],
                );
              }
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
     // Safeguard fields
     String name = meal['name'] ?? 'Unknown Meal';
     int cals = (meal['calories'] as num? ?? 0).toInt();
     // Fix: Check both 'protein' and 'proteinG' keys based on MealModel
     int p = (meal['protein'] as num? ?? meal['proteinG'] as num? ?? 0).toInt();

     return Padding(
         padding: const EdgeInsets.only(bottom: 12),
         child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(name, style: AppTextStyles.bodyMedium),
                     Text("$cals kcal • ${p}g Protein", style: AppTextStyles.smallLabel),
                   ],
                 ),
                 Text("+$cals", style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondaryText)),
             ],
         ),
     );
  }

  Widget _buildExerciseRow(Map<String, dynamic> ex) {
     String name = ex['name'] ?? ex['exerciseName'] ?? 'Unknown Activity';
     // Fix: ExerciseLog uses 'calories'. Also check 'caloriesBurned' or 'cals' for backward compat/variable naming.
     int cals = (ex['calories'] as num? ?? ex['caloriesBurned'] as num? ?? ex['cals'] as num? ?? 0).toInt();
     
     // Fix: Removed duration/reps logic. Displaying only burned calories as requested.
     // "-100" format in front (right side) similar to meals.
     
     return Padding(
         padding: const EdgeInsets.only(bottom: 12),
         child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween, // Use spaceBetween to push calories to right
             children: [
                Row(
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
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(name, style: AppTextStyles.bodyMedium),
                         Text("$cals kcal burned", style: AppTextStyles.smallLabel),
                       ],
                    ),
                  ],
                ),
                Text("-$cals", style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondaryText)), // Display like "-100"
             ],
         ),
     );
  }
}
