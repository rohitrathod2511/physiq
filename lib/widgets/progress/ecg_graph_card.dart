import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:physiq/models/weight_model.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:intl/intl.dart';

class EcgGraphCard extends StatelessWidget {
  final List<WeightEntry> history;
  final double currentWeight;
  final double? goalWeight;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const EcgGraphCard({
    super.key,
    required this.history,
    required this.currentWeight,
    this.goalWeight,
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
            children: [_buildRangeSelector()],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: history.isEmpty
                ? Center(
                    child: Text(
                      'No weight logs yet.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : ClipRect(child: LineChart(_buildChartData())),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      children: ['1M', '3M', '6M', '9M', '1Y'].map((range) {
        final isSelected = range == selectedRange;
        return GestureDetector(
          onTap: () => onRangeChanged(range),
          child: Container(
            margin: const EdgeInsets.only(left: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              range,
              style: AppTextStyles.smallLabel.copyWith(
                color: isSelected
                    ? AppColors.background
                    : AppColors.secondaryText,
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

    // DYNAMIC Y RANGE: min/max of (start, goal, logs) + buffer
    double minWeight = history
        .map((e) => e.weightKg)
        .reduce((a, b) => a < b ? a : b);
    double maxWeight = history
        .map((e) => e.weightKg)
        .reduce((a, b) => a > b ? a : b);

    if (goalWeight != null && goalWeight! > 0) {
      if (goalWeight! < minWeight) minWeight = goalWeight!;
      if (goalWeight! > maxWeight) maxWeight = goalWeight!;
    }

    const double verticalBuffer = 3.0;
    final minY = minWeight - verticalBuffer;
    final maxY = maxWeight + verticalBuffer;

    final isSinglePoint = history.length == 1;
    final maxX = isSinglePoint ? 1.0 : (history.length - 1).toDouble();

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          // Current Weight Baseline (Dashed)
          HorizontalLine(
            y: currentWeight,
            color: AppColors.secondaryText.withOpacity(0.2),
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              style: AppTextStyles.smallLabel.copyWith(
                color: AppColors.secondaryText.withOpacity(0.4),
                fontSize: 9,
              ),
              labelResolver: (line) => 'Current',
            ),
          ),
          // Goal Weight Line (Dashed)
          if (goalWeight != null && goalWeight! > 0)
            HorizontalLine(
              y: goalWeight!,
              color: AppColors.accent.withOpacity(0.4),
              strokeWidth: 1.5,
              dashArray: [8, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 8, top: 8),
                style: AppTextStyles.smallLabel.copyWith(
                  color: AppColors.accent.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (line) =>
                    'Goal: ${goalWeight!.toStringAsFixed(1)} kg',
              ),
            ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: !isSinglePoint,
          color: AppColors.accent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: isSinglePoint),
          belowBarData: BarAreaData(
            show: !isSinglePoint,
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
