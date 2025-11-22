import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:physiq/services/exercise_repository.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  List<ExerciseLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final logs = await ref.read(exerciseRepositoryProvider).getWorkoutHistory();
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Workout History', style: AppTextStyles.heading2),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(child: Text('No workout history yet.', style: AppTextStyles.bodyMedium))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadii.smallCard),
                        boxShadow: [AppShadows.card],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.title, style: AppTextStyles.bodyBold),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(log.endedAt),
                                style: AppTextStyles.smallLabel,
                              ),
                            ],
                          ),
                          Text(
                            '${log.exerciseCalories.round()} kcal',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
