import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/screens/streak_calendar_screen.dart';

class HeaderWidget extends StatefulWidget {
  final String title;
  final bool showActions;
  final int streak;

  const HeaderWidget({super.key, required this.title, this.showActions = true, this.streak = 0});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  OverlayEntry? _streakOverlay;
  final LayerLink _streakLayerLink = LayerLink();

  @override
  void dispose() {
    _removeStreakOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      MaterialPageRoute(builder: (context) => const StreakCalendarScreen()),
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
                    child: Icon(Icons.calendar_month_rounded, color: AppColors.primaryText, size: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Streak Pill
                CompositedTransformTarget(
                  link: _streakLayerLink,
                  child: GestureDetector(
                    onTap: _toggleStreakOverlay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 6),
                          Text('${widget.streak}', style: AppTextStyles.button.copyWith(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _toggleStreakOverlay() {
    if (_streakOverlay != null) {
      _removeStreakOverlay();
    } else {
      _showStreakOverlay();
    }
  }

  void _removeStreakOverlay() {
    _streakOverlay?.remove();
    _streakOverlay = null;
  }

  void _showStreakOverlay() {
    late OverlayEntry overlayEntry;
    
    // Animation controller setup would typically require a StatefulWidget for the overlay content
    // or using a built-in animated widget.
    // Here we use a simple TweenAnimationBuilder for the slide effect.
    
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeStreakOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _streakLayerLink,
            offset: const Offset(-150, 50),
            showWhenUnlinked: false,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -20 * (1 - value)), // Slide down from -20
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    boxShadow: [AppShadows.card],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Current Streak', style: AppTextStyles.smallLabel),
                      const SizedBox(height: 4),
                      Text('${widget.streak} Days', style: AppTextStyles.heading2.copyWith(color: Colors.orange)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final isCompleted = index < 3; // Mock data
                          return Column(
                            children: [
                              Text(
                                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                                style: AppTextStyles.smallLabel.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 16,
                                color: isCompleted ? Colors.orange : AppColors.secondaryText.withOpacity(0.3),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    _streakOverlay = overlayEntry;
    Overlay.of(context).insert(overlayEntry);
  }
}
