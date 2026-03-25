import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class PotentialScreen extends StatelessWidget {
  const PotentialScreen({super.key});

  static const Color _lineColor = Color(0xFFB37748);
  static const Color _fillStartColor = Color(0xFFF5D8B8);
  static const Color _fillEndColor = Color(0x00F5D8B8);
  static const Color _badgeColor = Color(0xFFE5A365);

  @override
  Widget build(BuildContext context) {
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
                'You have great\npotential to crush\nyour\ngoal',
                style: AppTextStyles.h1.copyWith(
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: SingleChildScrollView(
                  child: _PotentialGraphCard(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/diet-preference'),
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

class _PotentialGraphCard extends StatelessWidget {
  const _PotentialGraphCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          AppShadows.card,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your weight transition',
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 18,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth;
              const chartHeight = 188.0;
              final chartWidth = math.max(cardWidth - 12, 0.0);

              return SizedBox(
                height: chartHeight + 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: SizedBox(
                        width: chartWidth,
                        height: chartHeight,
                        child: CustomPaint(
                          painter: _PotentialChartPainter(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: chartWidth * 0.88,
                      top: 18,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: PotentialScreen._badgeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: PotentialScreen._badgeColor.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      left: chartWidth * 0.02,
                      right: chartWidth * 0.04,
                      bottom: 0,
                      child: const _ChartLabels(),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Based on Physiq AI's historical data, progress is usually delayed at first, but after 7 days, you can build unstoppable momentum.",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                height: 1.5,
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLabels extends StatelessWidget {
  const _ChartLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '3 Days',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.primaryText,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '7 Days',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.primaryText,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '30 Days',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _PotentialChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final baselineY = size.height * 0.86;
    final guideTopY = size.height * 0.29;
    final guideMidY = size.height * 0.54;

    final guidelinePaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(0, guideTopY),
      Offset(size.width, guideTopY),
      guidelinePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, guideMidY),
      Offset(size.width * 0.74, guideMidY),
      guidelinePaint,
    );

    final axisPaint = Paint()
      ..color = const Color(0xFF252525)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      axisPaint,
    );

    final points = [
      Offset(size.width * 0.02, size.height * 0.70),
      Offset(size.width * 0.27, size.height * 0.67),
      Offset(size.width * 0.52, size.height * 0.40),
      Offset(size.width * 0.98, size.height * 0.15),
    ];

    final verticalGuidePaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final point in points.take(3)) {
      _drawDashedLine(
        canvas,
        Offset(point.dx, point.dy),
        Offset(point.dx, baselineY),
        verticalGuidePaint,
        dashLength: 4,
        gapLength: 4,
      );
    }
    _drawDashedLine(
      canvas,
      Offset(points.last.dx, points.last.dy),
      Offset(points.last.dx, baselineY),
      verticalGuidePaint,
      dashLength: 4,
      gapLength: 4,
    );

    final linePath = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..cubicTo(
        size.width * 0.10,
        size.height * 0.72,
        size.width * 0.18,
        size.height * 0.69,
        points[1].dx,
        points[1].dy,
      )
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.66,
        size.width * 0.41,
        size.height * 0.47,
        points[2].dx,
        points[2].dy,
      )
      ..cubicTo(
        size.width * 0.69,
        size.height * 0.21,
        size.width * 0.86,
        size.height * 0.16,
        points[3].dx,
        points[3].dy,
      );

    final fillPath = Path()
      ..moveTo(points[1].dx, baselineY)
      ..lineTo(points[1].dx, points[1].dy)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.66,
        size.width * 0.41,
        size.height * 0.47,
        points[2].dx,
        points[2].dy,
      )
      ..cubicTo(
        size.width * 0.69,
        size.height * 0.21,
        size.width * 0.86,
        size.height * 0.16,
        points[3].dx,
        points[3].dy,
      )
      ..lineTo(points[3].dx, baselineY)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          PotentialScreen._fillEndColor,
          PotentialScreen._fillStartColor,
        ],
      ).createShader(Rect.fromLTWH(points[1].dx, 0, size.width - points[1].dx, baselineY));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = PotentialScreen._lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    final markerStrokePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final markerFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final point in points.take(3)) {
      canvas.drawCircle(point, 10, markerFillPaint);
      canvas.drawCircle(point, 10, markerStrokePaint);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashLength = 5,
    double gapLength = 5,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt((dx * dx) + (dy * dy));
    if (distance == 0) return;

    final dashSpace = dashLength + gapLength;
    final dashCount = (distance / dashSpace).floor();
    final direction = Offset(dx / distance, dy / distance);

    for (int i = 0; i <= dashCount; i++) {
      final dashStart = Offset(
        start.dx + (direction.dx * dashSpace * i),
        start.dy + (direction.dy * dashSpace * i),
      );
      final dashEnd = Offset(
        dashStart.dx + (direction.dx * dashLength),
        dashStart.dy + (direction.dy * dashLength),
      );
      canvas.drawLine(
        dashStart,
        Offset(
          dashEnd.dx.clamp(math.min(start.dx, end.dx), math.max(start.dx, end.dx)),
          dashEnd.dy.clamp(math.min(start.dy, end.dy), math.max(start.dy, end.dy)),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
