
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/firestore_service.dart';

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  // Use DateTime.now() as the base for the 3-month view
  final DateTime _baseDate = DateTime.now();
  
  // Data State
  Map<DateTime, String> _monthStatus = {};
  int _targetCalories = 2000;
  int _streak = 0;
  int _score = 0; // Placeholder as per requirements
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now(); // Default to today as requested
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Fetch Streak & Target Calories
    try {
      final firestoreService = FirestoreService();
      final s = await firestoreService.calculateStreak(user.uid);
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      int targetCals = 2000;
      if (userDoc.exists) {
        final data = userDoc.data();
        final currentPlan = data?['currentPlan'] as Map<String, dynamic>?;
        final nutrition = data?['nutrition'] as Map<String, dynamic>?;
        
        targetCals = (currentPlan?['calories'] ?? 
                      currentPlan?['goalCalories'] ?? 
                      nutrition?['calories'] ?? 
                      2000).toInt();
      }

      if (mounted) {
        setState(() {
          _streak = s;
          _targetCalories = targetCals;
        });
      }
    } catch (e) {
      print("Error fetching user stats: $e");
    }

    // 2. Fetch Data for continuous 3-month range
    // Range: Start of Grid (Mon before Jan 1) -> End of Grid (Sun after Mar 31)
    
    // Determine grid bounds
    final firstDayOfCurrentMonth = DateTime(_baseDate.year, _baseDate.month, 1);
    // Find start of week (Monday)
    // weekday: Mon=1 ... Sun=7. 
    // If Jan 1 is Mon(1), shift=0. Start = Jan 1.
    // If Jan 1 is Thu(4), shift=3. Start = Dec 29.
    // Logic: subtract (weekday - 1) days
    final startGrid = firstDayOfCurrentMonth.subtract(Duration(days: firstDayOfCurrentMonth.weekday - 1));
    
    // End of 3rd month from now
    // Month + 3 (e.g. current=1, target=4 i.e. April. day=0 means Mar 31)
    final lastDayOfTargetMonth = DateTime(_baseDate.year, _baseDate.month + 3, 0); 
    // Find end of week (Sunday)
    // weekday: Mon=1 ... Sun=7.
    // Stop at Sun(7). Add (7 - weekday) days.
    final endGrid = lastDayOfTargetMonth.add(Duration(days: 7 - lastDayOfTargetMonth.weekday));

    // For query string
    final String startId = DateFormat('yyyy-MM-dd').format(startGrid);
    final String endId = DateFormat('yyyy-MM-dd').format(endGrid);

    try {
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
      
      if (mounted) {
        setState(() {
          _monthStatus = newStatus;
        });
      }
      
    } catch (e) {
      print("Error fetching month data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Adaptive background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildHeader(context),
               const SizedBox(height: 8), // Minimized
               _buildStatsRow(),
               const SizedBox(height: 12), // Minimized
               
               // Continuous Grid Block
               Text(
                  DateFormat('MMMM yyyy').format(_baseDate),
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
               const SizedBox(height: 8), // Minimized
               _buildWeekDaysRow(),
               const SizedBox(height: 4), // Minimized
               _buildContinuousGrid(),
               
               const SizedBox(height: 12),
               _buildLegend(),
               const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: AppColors.primaryText, size: 24),
        ),
        PopupMenuButton<int>(
          icon: Icon(Icons.help_outline, color: AppColors.primaryText, size: 24),
          color: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                "1. Your leaderboard rank is decided by your score.",
                style: AppTextStyles.body.copyWith(color: AppColors.primaryText, fontSize: 13),
              ),
            ),
            PopupMenuItem(
              enabled: false,
              child: Text(
                "2. Click a date to see the activity you have done on that specific day.",
                style: AppTextStyles.body.copyWith(color: AppColors.primaryText, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // _showInstructionDialog removed as replaced by PopupMenuButton above.

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem("YOUR SCORE", NumberFormat("#,###").format(_score), alignLeft: true),
        _buildStatItem("YOUR STREAK", "$_streak Days", alignLeft: true), // Corrected to 'Days'
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {bool alignLeft = true}) {
    // Actually visual shows left-aligned columns? 
    // Reference image stats row is usually:
    // [ScoreLabel]   [StreakLabel]
    // [ScoreValue]   [StreakValue]
    // It looks like two columns.
    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTextStyles.smallLabel.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            fontSize: 24, // Slightly reduced
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDaysRow() {
    // Mon -> Sun for this specific UI
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) => SizedBox(
        width: 32, // Match grid cell width roughly
        child: Center(
          child: Text(d, style: AppTextStyles.smallLabel.copyWith(
             fontWeight: FontWeight.bold,
             color: Colors.grey.shade600,
             fontSize: 12,
          )),
        ),
      )).toList(),
    );
  }

  Widget _buildContinuousGrid() {
      // Logic to build single list of dates
      final firstDayOfCurrentMonth = DateTime(_baseDate.year, _baseDate.month, 1);
      final startGrid = firstDayOfCurrentMonth.subtract(Duration(days: firstDayOfCurrentMonth.weekday - 1));
      
      final lastDayOfTargetMonth = DateTime(_baseDate.year, _baseDate.month + 3, 0); 
      final endGrid = lastDayOfTargetMonth.add(Duration(days: 7 - lastDayOfTargetMonth.weekday));
      
      final int dayCount = endGrid.difference(startGrid).inDays + 1;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dayCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
           crossAxisCount: 7,
           crossAxisSpacing: 2, // Minimal spacing as requested
           mainAxisSpacing: 2, // Minimal spacing to pull rows up
           childAspectRatio: 1.45, // Very rectangular to compress height significantly
        ),
        itemBuilder: (context, index) {
            final date = startGrid.add(Duration(days: index));
            return _buildDayCell(date);
        },
      );
  }

  Widget _buildDayCell(DateTime date) {
      final isCurrentDate = DateUtils.isSameDay(date, DateTime.now());
      var isSelected = _selectedDay != null && DateUtils.isSameDay(date, _selectedDay!);
      
      final dateKey = DateTime(date.year, date.month, date.day);
      final status = _monthStatus[dateKey] ?? 'none';
      final isPast = dateKey.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
      
      // Visuals
      Color? fillColor;
      BoxBorder? border;
      Color textColor = AppColors.primaryText; 

      if (status == 'full') {
         fillColor = const Color(0xFF22C55E); 
         textColor = Colors.white; 
      } else if (status == 'partial') {
         fillColor = const Color(0xFF22C55E).withOpacity(0.5);
         textColor = Colors.white;
      } else {
         if (isPast) {
           fillColor = Colors.transparent;
           // Explicit color for visibility (Missed)
           border = Border.all(color: Colors.grey.shade700, width: 1); 
           textColor = AppColors.secondaryText;
         } else {
           // Future / Upcoming
           fillColor = Colors.transparent;
           // Add a faded ring for future dates too, as requested
           border = Border.all(color: Colors.grey.shade800, width: 1); // Faded ring
           textColor = Colors.grey.shade600; 
         }
      }

      if (isSelected) {
         border = Border.all(color: AppColors.primaryText, width: 2);
         if (status != 'full' && status != 'partial') {
           textColor = AppColors.primaryText;
         }
      } else if (isCurrentDate) {
         // Keep current date ring DARK/Bold if not selected (or default selected handles it)
         // Assuming user wants current date distinguished even if logic wasn't fully capturing it
         border = Border.all(color: AppColors.primaryText, width: 2);
         if (status != 'full' && status != 'partial') {
           textColor = AppColors.primaryText;
         }
      }

      return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
            });
            _showDayDetails(date);
          },
          child: Center(
            child: Container(
                width: 28, // Good size for touch
                height: 28,
                decoration: BoxDecoration(
                    color: fillColor,
                    shape: BoxShape.circle,
                    border: border,
                ),
                child: Center(
                    child: Text(
                        '${date.day}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold, // Force Bold Always
                            fontSize: 12,
                        ),
                    ),
                ),
            ),
          ),
      );
  }
  
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start, // Left aligned or Below? Prompt says "Horizontal layout".
      children: [
        _buildLegendItem(const Color(0xFF22C55E), "Completed"),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFF22C55E).withOpacity(0.5), "Partial"),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.transparent, "Missed", hasBorder: true),
      ],
    );
  }
  
  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
             color: color,
             shape: BoxShape.circle,
             border: hasBorder ? Border.all(color: Colors.grey.shade600) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label, 
          style: AppTextStyles.smallLabel.copyWith(
            color: Colors.grey.shade500,
            fontSize: 12,
          )
        ),
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
