import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class LongTermResultsScreen extends StatelessWidget {
  const LongTermResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Physiq AI helps you stay fit for a long time',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const _LongTermResultsCard(),
                      const SizedBox(height: 28),
                      Text(
                        'Physiq AI supports building habits for long-term consistency.',
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/referral-step'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LongTermResultsCard extends StatelessWidget {
  const _LongTermResultsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final traditionalColor = Colors.red.shade400;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Fitness level',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ).copyWith(color: AppColors.primaryText),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 240,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final goalX = constraints.maxWidth * 0.56;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LongTermResultsChartPainter(
                          primaryColor: AppColors.primary,
                          traditionalColor: traditionalColor,
                          guideColor: AppColors.secondaryText.withOpacity(0.25),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      top: 174,
                      child: Text(
                        'PhysiqAI',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ).copyWith(color: AppColors.primaryText),
                      ),
                    ),
                    Positioned(
                      left: goalX - 42,
                      top: 12,
                      child: Text(
                        'Goal reached',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Month 1',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ).copyWith(color: AppColors.primaryText),
                          ),
                          Text(
                            'Month 6',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ).copyWith(color: AppColors.primaryText),
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

class _LongTermResultsChartPainter extends CustomPainter {
  final Color primaryColor;
  final Color traditionalColor;
  final Color guideColor;

  const _LongTermResultsChartPainter({
    required this.primaryColor,
    required this.traditionalColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = 10.0;
    final right = size.width - 10.0;
    final top = 16.0;
    final startY = top + 146;
    final goalX = size.width * 0.56;
    final goalY = top + 56;
    final start = Offset(left, startY);
    final end = Offset(right - 6, goalY + 6);
    final milestoneOne = Offset(size.width * 0.24, top + 124);
    final milestoneTwo = Offset(size.width * 0.40, top + 84);
    final goal = Offset(goalX, goalY);

    final guidePaint = Paint()
      ..color = guideColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(left, top + 26),
      Offset(right, top + 26),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(left, top + 118),
      Offset(right, top + 118),
      guidePaint,
    );

    final primaryPath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width * 0.14,
        startY - 2,
        size.width * 0.20,
        top + 132,
        milestoneOne.dx,
        milestoneOne.dy,
      )
      ..cubicTo(
        size.width * 0.30,
        top + 114,
        size.width * 0.34,
        top + 94,
        milestoneTwo.dx,
        milestoneTwo.dy,
      )
      ..cubicTo(
        size.width * 0.48,
        top + 62,
        size.width * 0.52,
        goalY,
        goal.dx,
        goal.dy,
      )
      ..cubicTo(
        size.width * 0.64,
        goalY + 4,
        size.width * 0.72,
        goalY - 5,
        size.width * 0.80,
        goalY + 2,
      )
      ..cubicTo(
        size.width * 0.88,
        goalY + 8,
        size.width * 0.94,
        goalY + 1,
        end.dx,
        end.dy,
      );

    final traditionalPath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width * 0.16,
        startY - 4,
        size.width * 0.28,
        top + 102,
        size.width * 0.40,
        top + 88,
      )
      ..cubicTo(
        size.width * 0.56,
        top + 74,
        size.width * 0.74,
        top + 132,
        right,
        top + 144,
      );

    final primaryPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final traditionalPaint = Paint()
      ..color = traditionalColor.withOpacity(0.20)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(primaryPath, primaryPaint);
    canvas.drawPath(traditionalPath, traditionalPaint);

    final milestonePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final goalMarkerStroke = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final markerFill = Paint()
      ..color = AppColors.card
      ..style = PaintingStyle.fill;
    final goalMarkerCore = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(milestoneOne, 4, milestonePaint);
    canvas.drawCircle(milestoneTwo, 4, milestonePaint);
    canvas.drawCircle(goal, 10, markerFill);
    canvas.drawCircle(goal, 10, goalMarkerStroke);
    canvas.drawCircle(goal, 4, goalMarkerCore);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double currentX = start.dx;

    while (currentX < end.dx) {
      final nextX = (currentX + dashWidth).clamp(start.dx, end.dx).toDouble();
      canvas.drawLine(Offset(currentX, start.dy), Offset(nextX, end.dy), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
