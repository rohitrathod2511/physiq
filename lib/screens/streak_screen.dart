import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

const LinearGradient _fireGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFE65100), Color(0xFFFF8A00), Color(0xFFFFC107)],
);

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final int streak = ref.watch(homeViewModelProvider).streak;
    final int safeStreak = streak < 0 ? 0 : streak;
    final TextStyle numberStyle =
        textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _FireIcon(size: 88),
                const SizedBox(height: 12),
                Text('$safeStreak', style: numberStyle),
                const SizedBox(height: 4),
                Text(
                  'Day Streak',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep building your physique by staying consistent.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                _WeeklyTracker(
                  streak: safeStreak,
                  activeGradient: _fireGradient,
                  inactiveColor: theme.dividerColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyTracker extends StatelessWidget {
  final int streak;
  final Gradient activeGradient;
  final Color inactiveColor;

  const _WeeklyTracker({
    required this.streak,
    required this.activeGradient,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final int todayIndex = now.weekday % 7; // Sunday=0 ... Saturday=6
    final int highlightCount = streak <= 0
        ? 0
        : (streak < (todayIndex + 1) ? streak : (todayIndex + 1));
    final int startIndex = highlightCount == 0
        ? 0
        : (todayIndex - highlightCount + 1);

    bool isHighlighted(int index) {
      if (highlightCount == 0) return false;
      return index >= startIndex && index <= todayIndex;
    }

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(label, style: textTheme.labelMedium),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (index) {
            final active = isHighlighted(index);
            return Expanded(
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: active ? null : inactiveColor,
                    gradient: active ? activeGradient : null,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FireIcon extends StatelessWidget {
  final double size;

  const _FireIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => _fireGradient.createShader(rect),
      child: Icon(
        Icons.local_fire_department_rounded,
        size: size,
        color: Colors.white,
      ),
    );
  }
}
