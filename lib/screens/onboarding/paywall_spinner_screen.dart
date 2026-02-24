import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class PaywallSpinnerScreen extends StatefulWidget {
  const PaywallSpinnerScreen({super.key});

  @override
  State<PaywallSpinnerScreen> createState() => _PaywallSpinnerScreenState();
}

class _PaywallSpinnerScreenState extends State<PaywallSpinnerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _spinCount = 0;
  bool _isSpinning = false;

  // 6 specific segments: alternating colors
  final List<SpinSegment> _segments = [
    SpinSegment(
      text: "10% OFF",
      color: Colors.white,
      contentColor: Colors.black,
    ),
    SpinSegment(
      text: "20% OFF",
      color: Colors.black,
      contentColor: Colors.white,
    ),
    SpinSegment(
      text: "No Offer",
      color: Colors.white,
      contentColor: Colors.black,
    ),
    SpinSegment(
      text: "60% OFF",
      color: Colors.black,
      contentColor: Colors.white,
    ),
    SpinSegment(
      text: "80% OFF",
      color: Colors.white,
      contentColor: Colors.black,
    ),
    SpinSegment(
      text: "No Offer",
      color: Colors.black,
      contentColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.decelerate);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isSpinning = false;
        _handleSpinResult();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning || _spinCount > 0) return;

    setState(() {
      _isSpinning = true;
      _spinCount++;
    });

    // We want to land on "80% OFF" which is index 4.
    int targetIndex = 4;

    double segmentAngle = 2 * math.pi / _segments.length; // 60 degrees (pi/3)

    // Calculate rotation to align targetIndex with Top Pointer.
    // Pointer is at Top (1.5 * pi or 270 degrees).
    // Center of segment i is (i + 0.5) * segmentAngle.
    // (Center + TotalRotation) % 2pi = 1.5 * pi
    double segmentCenter = (targetIndex + 0.5) * segmentAngle;
    double targetRotation = (1.5 * math.pi) - segmentCenter;

    // Add extra spins (5-7 full rotations) for a natural look
    double extraSpins = 6 * 2 * math.pi;

    double startAngle = _endAngle;
    _endAngle = startAngle + extraSpins;

    // Adjust remainder to hit target
    double currentMod = _endAngle % (2 * math.pi);
    double targetMod = targetRotation % (2 * math.pi);
    if (targetMod < 0) targetMod += 2 * math.pi;

    double adjustment = targetMod - currentMod;
    if (adjustment < 0) adjustment += 2 * math.pi;

    _endAngle += adjustment;

    _controller.duration = const Duration(seconds: 5);
    _controller.reset();
    _animation = Tween<double>(begin: startAngle, end: _endAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward();
  }

  double _endAngle = 0;

  void _handleSpinResult() {
    // Navigate directly to Paywall Offer Screen after 80% OFF result
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        context.pushReplacement('/onboarding/paywall-offer');
      }
    });
  }

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
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Spin to Unlock an Offer 🎁",
                style: AppTextStyles.h1.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "Spin once to reveal your special discount.",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // Spinner System
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glow/Border
                Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 25,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Wheel
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animation.value,
                      child: GestureDetector(
                        onTap: _spinWheel,
                        child: Container(
                          width: 320,
                          height: 320,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: CustomPaint(
                            painter: WheelPainter(segments: _segments),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Center Hub with premium styling
                GestureDetector(
                  onTap: _spinWheel,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.bolt, color: Colors.white, size: 32),
                    ),
                  ),
                ),

                // Top Pointer (More premium arrow)
                Positioned(
                  top: 0,
                  child: Transform.translate(
                    offset: const Offset(0, -15),
                    child: const Icon(
                      Icons.arrow_drop_down,
                      size: 60,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Helper Text
            Text(
              _isSpinning ? "Revealing your offer..." : "Tap the wheel to spin",
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600, // Medium-Bold
              ),
            ),

            const Spacer(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class SpinSegment {
  final String text;
  final Color color;
  final Color contentColor;

  SpinSegment({
    required this.text,
    required this.color,
    required this.contentColor,
  });
}

class WheelPainter extends CustomPainter {
  final List<SpinSegment> segments;

  WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    double anglePerSegment = 2 * math.pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      paint.color = segments[i].color;

      // Draw Arc
      canvas.drawArc(rect, i * anglePerSegment, anglePerSegment, true, paint);

      // Draw thin border between segments
      final borderPaint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        rect,
        i * anglePerSegment,
        anglePerSegment,
        true,
        borderPaint,
      );

      // Draw Content (Text)
      canvas.save();
      // Rotate to center of segment
      double rotationAngle = i * anglePerSegment + anglePerSegment / 2;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationAngle);
      canvas.translate(radius * 0.68, 0); // Move out to text position

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].text,
          style: TextStyle(
            fontSize: 18,
            color: segments[i].contentColor,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      // Rotate text to be radial
      canvas.rotate(math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Outer premium border
    paint
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, paint);

    paint
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
