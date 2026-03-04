import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/screens/streak_calendar_screen.dart';
import 'package:physiq/screens/streak_screen.dart';

const LinearGradient _fireGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFE65100),
    Color(0xFFFF8A00),
    Color(0xFFFFC107),
  ],
);

class HeaderWidget extends StatefulWidget {
  final String title;
  final bool showActions;
  final int streak;

  const HeaderWidget({
    super.key,
    required this.title,
    this.showActions = true,
    this.streak = 0,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side: Title
          Text(
            widget.title,
            style: AppTextStyles.heading2.copyWith(fontSize: 24),
          ),

          // Right Side: Calendar Button + Streak Icon
          if (widget.showActions)
            Row(
              children: [
                // Calendar Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StreakCalendarScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      boxShadow: [AppShadows.card],
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primaryText,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Streak Pill
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StreakScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (rect) =>
                              _fireGradient.createShader(rect),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.streak}',
                          style: AppTextStyles.button.copyWith(
                            fontSize: 16,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
