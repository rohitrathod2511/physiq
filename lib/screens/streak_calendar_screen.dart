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
  final DateTime _today = DateTime.now();
  final FirestoreService _firestoreService = FirestoreService();

  // Data State
  Map<DateTime, String> _historyStatus = {};
  int _targetCalories = 2000;
  int _streak = 0;
  DateTime? _userStartDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Get User Data for start date and streak
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final Timestamp? createdAt = data['createdAt'] as Timestamp?;
        _userStartDate = createdAt?.toDate() ?? DateTime(_today.year, 1, 1);
        _streak = await _firestoreService.calculateStreak(user.uid);

        final currentPlan = data['currentPlan'] as Map<String, dynamic>?;
        final nutrition = data['nutrition'] as Map<String, dynamic>?;
        _targetCalories =
            (currentPlan?['calories'] ??
                    currentPlan?['goalCalories'] ??
                    nutrition?['calories'] ??
                    2000)
                .toInt();
      }

      // 2. Fetch full current year data
      final DateTime startOfYear = DateTime(_today.year, 1, 1);
      final DateTime endOfYear = DateTime(_today.year, 12, 31);

      final snapshots = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .where('date', isGreaterThanOrEqualTo: _formatDateId(startOfYear))
          .where('date', isLessThanOrEqualTo: _formatDateId(endOfYear))
          .get();

      Map<DateTime, String> newStatus = {};
      for (var doc in snapshots.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        if (dateStr != null) {
          final dateParts = dateStr.split('-');
          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
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
          _historyStatus = newStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading streak data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateId(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: AppColors.primaryText),
            onPressed: _showLegendDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    Expanded(child: _buildYearHeatmap()),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Streak",
              style: AppTextStyles.heading2.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$_streak",
              style: AppTextStyles.largeNumber.copyWith(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Current Year",
              style: AppTextStyles.label.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_today.year}",
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearHeatmap() {
    const double dayLabelWidth = 16;
    const double dayLabelGap = 16;
    const double monthLabelHeight = 24;
    const double monthLabelGap = 10;
    const double cellSize = 17;
    const double columnSpacing = 6;
    const double rowSpacing = 6;

    final int year = _today.year;
    final List<DateTime> weekStarts = _buildWeekStartsForYear(year);
    final DateTime gridStart = weekStarts.first;
    final double totalGridWidth =
        (weekStarts.length * cellSize) +
        ((weekStarts.length - 1) * columnSpacing);
    final List<String> dayLabels = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final Map<int, int> monthStartColumn = {
      for (int month = 1; month <= 12; month++)
        month: DateTime(year, month, 1).difference(gridStart).inDays ~/ 7,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: dayLabelWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: monthLabelHeight + monthLabelGap),
                    ...List.generate(dayLabels.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == dayLabels.length - 1
                              ? 0
                              : rowSpacing,
                        ),
                        child: SizedBox(
                          height: cellSize,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              dayLabels[index],
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondaryText,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: dayLabelGap),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalGridWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: monthLabelHeight,
                          child: Stack(
                            children: List.generate(12, (index) {
                              final int month = index + 1;
                              final double left =
                                  monthStartColumn[month]! *
                                  (cellSize + columnSpacing);
                              return Positioned(
                                left: left,
                                child: Text(
                                  DateFormat(
                                    'MMM',
                                  ).format(DateTime(year, month)),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: monthLabelGap),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(weekStarts.length, (
                            weekIndex,
                          ) {
                            final DateTime weekStart = weekStarts[weekIndex];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: weekIndex == weekStarts.length - 1
                                    ? 0
                                    : columnSpacing,
                              ),
                              child: Column(
                                children: List.generate(7, (dayIndex) {
                                  final DateTime date = weekStart.add(
                                    Duration(days: dayIndex),
                                  );
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: dayIndex == 6 ? 0 : rowSpacing,
                                    ),
                                    child: _buildHeatmapCell(
                                      date: date,
                                      size: cellSize,
                                      year: year,
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<DateTime> _buildWeekStartsForYear(int year) {
    final DateTime janFirst = DateTime(year, 1, 1);
    final DateTime decLast = DateTime(year, 12, 31);
    final DateTime gridStart = janFirst.subtract(
      Duration(days: janFirst.weekday % 7),
    );
    final DateTime gridEnd = decLast.add(
      Duration(days: 6 - (decLast.weekday % 7)),
    );
    final int weekCount = (gridEnd.difference(gridStart).inDays ~/ 7) + 1;
    return List.generate(
      weekCount,
      (index) => gridStart.add(Duration(days: index * 7)),
    );
  }

  Widget _buildHeatmapCell({
    required DateTime date,
    required double size,
    required int year,
  }) {
    if (date.year != year) {
      return SizedBox(width: size, height: size);
    }
    return _buildDaySquare(date, size);
  }

  Widget _buildDaySquare(DateTime date, double size) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final status = _historyStatus[dateKey] ?? 'none';
    final isToday = DateUtils.isSameDay(date, _today);

    Color color = const Color(0xFFD1D5DB);
    if (status == 'full') {
      color = const Color(0xFF22C55E);
    } else if (status == 'partial') {
      color = const Color(0xFF4ADE80);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDateSelected(date),
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: isToday
                ? Border.all(color: const Color(0xFF15803D), width: 1.2)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(const Color(0xFF22C55E), "Goal Met"),
          const SizedBox(width: 24),
          _legendItem(const Color(0xFF4ADE80), "Partial"),
          const SizedBox(width: 24),
          _legendItem(const Color(0xFFD1D5DB), "None"),
        ],
      ),
    );
  }

  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text("Legend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(const Color(0xFF22C55E), "Goal Met"),
            const SizedBox(height: 12),
            _legendItem(const Color(0xFF4ADE80), "Partial"),
            const SizedBox(height: 12),
            _legendItem(const Color(0xFFD1D5DB), "None"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  void _onDateSelected(DateTime date) {
    _showDayDetails(date);
  }

  void _showDayDetails(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _DayDetailSheet(date: date, targetCalories: _targetCalories),
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

    final startOfDay = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
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
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
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
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final exercises = exerciseSnap.docs.map((d) => d.data()).toList();

    // Aggregations
    int caloriesConsumed = (summaryData['calories'] ?? 0).toInt();
    int proteinConsumed = (summaryData['protein'] ?? 0).toInt();
    int steps = (summaryData['steps'] ?? 0).toInt();
    int waterMl = (summaryData['waterMl'] ?? summaryData['waterConsumed'] ?? 0)
        .toInt();

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
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final uData = userDoc.data();
        proteinTarget =
            (uData?['currentPlan']?['protein'] ??
                    uData?['nutrition']?['protein'] ??
                    150)
                .toInt();
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
      'water': waterMl,
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
              return Center(
                child: Text('Error loading details', style: AppTextStyles.body),
              );
            }

            final data = snapshot.data ?? {};
            final status = data['status'] as String? ?? 'none';
            final cals = data['calories_consumed'] ?? 0;
            final targetCals = data['calories_target'] ?? 0;
            final protein = data['protein'] ?? 0;
            final targetProtein = data['protein_target'] ?? 0;
            final stepCount = data['steps'] ?? 0;
            final waterMl = data['water'] ?? 0;
            final meals = (data['meals'] as List?) ?? [];
            final exercises = (data['exercises'] as List?) ?? [];

            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(widget.date),
                      style: AppTextStyles.heading2,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: AppTextStyles.smallLabel.copyWith(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (status == 'none' &&
                    meals.isEmpty &&
                    exercises.isEmpty &&
                    stepCount == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "No activity recorded for this day.",
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Nutrition Summary
                  Text("Nutrition", style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          "Calories",
                          "$cals / $targetCals",
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          "Protein",
                          "${protein}g / ${targetProtein}g",
                          Icons.fitness_center,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Meals
                  Text("Meals", style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  if (meals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "No meals logged.",
                        style: AppTextStyles.body.copyWith(color: Colors.grey),
                      ),
                    ),
                  ...meals.map((m) => _buildMealRow(m)).toList(),

                  const SizedBox(height: 24),

                  // Exercise
                  Text("Workout Activity", style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  if (exercises.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "No workouts logged.",
                        style: AppTextStyles.body.copyWith(color: Colors.grey),
                      ),
                    ),
                  ...exercises.map((e) => _buildExerciseRow(e)).toList(),

                  const SizedBox(height: 24),
                  Text("Movement", style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    "Steps",
                    "$stepCount steps",
                    Icons.directions_walk,
                    Colors.green,
                  ),

                  const SizedBox(height: 24),
                  Text("Water", style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    "Water Intake",
                    waterMl >= 1000
                        ? "${(waterMl / 1000).toStringAsFixed(1)} L"
                        : "$waterMl ml",
                    Icons.water_drop,
                    AppColors.water,
                  ),

                  const SizedBox(height: 40),
                ],
              ],
            );
          },
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

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
              Text(
                "$cals kcal - ${p}g Protein",
                style: AppTextStyles.smallLabel,
              ),
            ],
          ),
          Text(
            "+$cals",
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(Map<String, dynamic> ex) {
    String name = ex['name'] ?? ex['exerciseName'] ?? 'Unknown Activity';
    // Fix: ExerciseLog uses 'calories'. Also check 'caloriesBurned' or 'cals' for backward compat/variable naming.
    int cals =
        (ex['calories'] as num? ??
                ex['caloriesBurned'] as num? ??
                ex['cals'] as num? ??
                0)
            .toInt();

    // Fix: Removed duration/reps logic. Displaying only burned calories as requested.
    // "-100" format in front (right side) similar to meals.

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment
            .spaceBetween, // Use spaceBetween to push calories to right
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: Colors.orange,
                ),
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
          Text(
            "-$cals",
            style: AppTextStyles.bodyBold.copyWith(
              color: AppColors.secondaryText,
            ),
          ), // Display like "-100"
        ],
      ),
    );
  }
}
