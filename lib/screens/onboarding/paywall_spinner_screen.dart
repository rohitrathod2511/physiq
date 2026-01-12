
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'dart:math' as math;

class PaywallSpinnerScreen extends StatefulWidget {
  const PaywallSpinnerScreen({super.key});

  @override
  State<PaywallSpinnerScreen> createState() => _PaywallSpinnerScreenState();
}

class _PaywallSpinnerScreenState extends State<PaywallSpinnerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _controller.forward().then((_) {
      // Navigate to offer screen after spin
      if (mounted) {
        context.pushReplacement('/onboarding/paywall-offer');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Spin to unlock an\nexclusive discount",
              style: AppTextStyles.h1.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 4 * math.pi, // Spin 2 times
                  child: child,
                );
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 8),
                  color: Colors.white,
                ),
                child: Stack(
                  children: [
                    // Simple segments (visual approximation)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: WheelPainter(),
                      ),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.fitness_center, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Pointer
            const Icon(Icons.arrow_drop_up, size: 40, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw segments
    final colors = [Colors.white, Colors.black];
    for (int i = 0; i < 6; i++) {
      paint.color = colors[i % 2];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * (math.pi / 3),
        math.pi / 3,
        true,
        paint,
      );
    }
    
    // Draw text (simplified)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
