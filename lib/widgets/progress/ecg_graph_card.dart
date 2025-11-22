import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:physiq/models/weight_model.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:intl/intl.dart';

class EcgGraphCard extends StatelessWidget {
  final List<WeightEntry> history;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const EcgGraphCard({
    super.key,
    required this.history,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Goal Progress', style: AppTextStyles.heading2),
              _buildRangeSelector(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: history.isEmpty
                ? Center(child: Text('No weight logs yet.', style: AppTextStyles.bodyMedium))
                : LineChart(
                    _buildChartData(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      children: ['1M', '3M', '6M', '1Y'].map((range) {
        final isSelected = range == selectedRange;
        return GestureDetector(
          onTap: () => onRangeChanged(range),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              range,
              style: AppTextStyles.smallLabel.copyWith(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  LineChartData _buildChartData() {
    if (history.isEmpty) return LineChartData();

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weightKg);
    }).toList();

    final minY = history.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = history.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b) + 2;

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (history.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.accent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.accent.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = history[spot.x.toInt()].date;
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} kg\n${DateFormat('MMM d').format(date)}',
                const TextStyle(color: Colors.white),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
