import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class CalorieMainCard extends StatefulWidget {
  final Map<String, dynamic> dailySummary;

  const CalorieMainCard({super.key, required this.dailySummary});

  @override
  State<CalorieMainCard> createState() => _CalorieMainCardState();
}

class _CalorieMainCardState extends State<CalorieMainCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    updateAnimation();
  }

  @override
  void didUpdateWidget(covariant CalorieMainCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dailySummary != oldWidget.dailySummary) {
      updateAnimation();
    }
  }

  void updateAnimation() {
    final double caloriesEaten =
        (widget.dailySummary['caloriesEaten'] ?? 0).toDouble();
    final double calorieTarget =
        (widget.dailySummary['macroTarget']?['calories'] ?? 2800).toDouble();
    final double endProgress =
        calorieTarget > 0 ? (caloriesEaten / calorieTarget) : 0;

    _progressAnimation = Tween<double>(begin: 0, end: endProgress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double caloriesEaten =
        (widget.dailySummary['caloriesEaten'] ?? 0).toDouble();
    final double caloriesBurned =
        (widget.dailySummary['caloriesBurned'] ?? 0).toDouble();
    final double calorieTarget =
        (widget.dailySummary['macroTarget']?['calories'] ?? 2800).toDouble();
    final double caloriesLeft = calorieTarget - caloriesEaten + caloriesBurned;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card.withAlpha(230), AppColors.card],
        ),
        borderRadius: BorderRadius.circular(AppRadii.bigCard),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(caloriesLeft.round().toString(),
                  style: AppTextStyles.largeNumber),
              
              // NEW: KCAL + Left text
              Row(
                children: [
                  Text('KCAL', 
                    style: AppTextStyles.label.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                    )
                  ),
                  const SizedBox(width: 4),
                  Text('Left', 
                    style: AppTextStyles.label.copyWith(
                      fontStyle: FontStyle.italic
                    )
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Text('${caloriesEaten.round()} eaten',
                      style: AppTextStyles.label),
                  const SizedBox(width: 16),
                  Text('${caloriesBurned.round()} burned',
                      style: AppTextStyles.label),
                ],
              ),
            ],
          ),
          SizedBox(
            height: 70,
            width: 70,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _progressAnimation.value,
                      strokeWidth: 8,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            caloriesLeft.round().toString(),
                            style: AppTextStyles.h3.copyWith(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'KCAL',
                            style: AppTextStyles.smallLabel.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // Slightly smaller to fit
                            ),
                          ),
                          Text(
                            'Left',
                            style: AppTextStyles.smallLabel.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
