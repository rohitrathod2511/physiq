import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/progress_repository.dart';
import 'package:physiq/models/weight_model.dart';

class WeightHistoryScreen extends ConsumerStatefulWidget {
  const WeightHistoryScreen({super.key});

  @override
  ConsumerState<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends ConsumerState<WeightHistoryScreen> {
  List<WeightEntry> _weightHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightHistory();
  }

  Future<void> _loadWeightHistory() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(progressRepositoryProvider);
      // Get all weight history
      final history = await repo.getWeightHistory('All Time');
      setState(() {
        _weightHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading weight history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Weight History', style: AppTextStyles.heading2),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _weightHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No weight logs yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log your weight from the Progress screen',
                        style: AppTextStyles.smallLabel.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _weightHistory.length,
                  itemBuilder: (context, index) {
                    // Reverse order to show latest first
                    final entry = _weightHistory[_weightHistory.length - 1 - index];
                    return _buildWeightCard(entry);
                  },
                ),
    );
  }

  Widget _buildWeightCard(WeightEntry entry) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.monitor_weight_outlined,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(entry.date),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(entry.loggedAt),
                  style: AppTextStyles.smallLabel.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.weightKg.toStringAsFixed(1)} kg',
            style: AppTextStyles.heading2.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }
}
