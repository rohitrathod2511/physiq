import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class PaywallSpinnerScreen extends StatefulWidget {
  const PaywallSpinnerScreen({super.key});

  @override
  State<PaywallSpinnerScreen> createState() => _PaywallSpinnerScreenState();
}

class _PaywallSpinnerScreenState extends State<PaywallSpinnerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _spinCount = 0;
  bool _isSpinning = false;
  
  // 0: No Luck, 1: Gift, 2: No Luck, 3: No Luck, 4: Gift, 5: No Luck
  final List<SpinSegment> _segments = [
    SpinSegment(text: "No Luck", isGift: false, color: const Color(0xFFF5F5F5), contentColor: Colors.black),
    SpinSegment(text: "Gift", isGift: true, color: Colors.black, contentColor: Colors.white),
    SpinSegment(text: "No Luck", isGift: false, color: Colors.white, contentColor: Colors.black),
    SpinSegment(text: "Gift", isGift: true, color: Colors.black, contentColor: Colors.white),
    SpinSegment(text: "No Luck", isGift: false, color: const Color(0xFFF5F5F5), contentColor: Colors.black),
    SpinSegment(text: "Gift", isGift: true, color: Colors.black, contentColor: Colors.white),
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
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _spinCount++;
    });

    // Angle calculations
    // We want to land on specific segments.
    // Segment Index to land on
    int targetIndex = 0;
    
    if (_spinCount == 1) {
      // First spin: Land on "No Luck". Let's pick index 2.
      targetIndex = 2;
    } else {
      // Second spin: Land on "Gift". Let's pick index 1.
      targetIndex = 1;
    }

    // Each segment is 60 degrees (pi/3).
    // The pointer is at the top (negative Y axis, or 270 degrees visual, or -pi/2).
    // However, usually we draw starting from 0 (East).
    // If pointer is TOP, that is -90deg or 270deg.
    // Rotation of wheel moves segments.
    // Target Angle = (TargetIndex * SegmentWidth) ... adjusted for pointer.
    
    // Simplest way: Random extra spins + specific stop.
    double currentRotation = _controller.value;
    double segmentAngle = 2 * math.pi / _segments.length; // 60 degrees
    
    // Calculate stop angle to align targetIndex with Top Pointer.
    // If Segment 0 is at 0 degrees.
    // To get Segment X to top (-pi/2), we rotate the wheel such that Segment X is at -pi/2.
    // Position of Segment X starts at X * segmentAngle.
    // We want (X * segmentAngle + TotalRotation) % 2pi = -pi/2 (or 3pi/2)
    
    // Actually, let's just reverse engineer:
    // We want the wheel to stop where the pointer points to the target.
    // If we draw start angle 0 at Right.
    // Index 0 spans [0, 60].
    // Index 1 spans [60, 120].
    // Pointer is at Top (270 degrees or -90).
    // We want center of target segment to effectively be at 270.
    // Center of segment i is (i + 0.5) * segmentAngle.
    // Required Rotation R: (Center + R) = 270 deg (in radians 1.5 * pi)
    // R = 1.5 * pi - Center;
    
    double segmentCenter = (targetIndex + 0.5) * segmentAngle;
    double targetRotation = (1.5 * math.pi) - segmentCenter;
    
    // Add extra spins (3-5 full rotations) to current base
    double extraSpins = 4 * 2 * math.pi;
    
    // We need to animate FROM current value TO target.
    // Ensure we are always moving forward.
    // Current total rotation is based on previous runs.
    // We reset controller usually, or standardise range.
    // Let's use a explicit Tween approach via listeners or just setting values.
    // Easier: _controller runs 0 to 1. We map 0-1 to [StartAngle, EndAngle].
    
    double startAngle = _controller.value == 0 ? 0 : _endAngle; // Store previous end
    double endAngle = startAngle + extraSpins + (targetRotation - (startAngle % (2 * math.pi)));
    
    // Normalize text direction? No, wheel spins.
    // Fix logic:
    // Just find the nearest valid targetRotation > current + extraSpins.
    
    _endAngle = startAngle + extraSpins;
    // Adjust remainder
    double currentMod = _endAngle % (2 * math.pi);
    double targetMod = targetRotation % (2 * math.pi);
    if (targetMod < 0) targetMod += 2 * math.pi;
    
    double adjustment = targetMod - currentMod;
    if (adjustment < 0) adjustment += 2 * math.pi;
    
    _endAngle += adjustment;

    _controller.duration = const Duration(seconds: 4);
    _controller.reset();
    _animation = Tween<double>(begin: startAngle, end: _endAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate)
    );
    _controller.forward();
  }

  double _endAngle = 0;

  void _handleSpinResult() {
    if (_spinCount == 1) {
      // First attempt logic
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(child: Text("Almost there!", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You have one more chance to try your luck.",
                style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        ),
      );
    } else if (_spinCount == 2) {
      // Second attempt logic -> Success
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(child: Text("🎉 You Unlocked a Special Offer!", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18), textAlign: TextAlign.center)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Your exclusive offer is ready. Unlock it now.",
                style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pushReplacement('/onboarding/paywall-offer');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Unlock Offer", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        ),
      );
    }
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
                "Try Your Luck to Unlock an Offer 🎁",
                style: AppTextStyles.h1.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "You get two chances to spin and unlock a reward.",
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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: CustomPaint(
                            painter: WheelPainter(segments: _segments),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Center Hub with "Spin" or icon
                GestureDetector(
                   onTap: _spinWheel,
                   child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.touch_app, color: Colors.black, size: 28),
                    ),
                  ),
                ),

                // Top Pointer
                Positioned(
                  top: 0,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: const Icon(Icons.arrow_drop_down, size: 50, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Helper Text
            Text(
              _isSpinning ? "Good luck..." : "Tap the wheel to spin",
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
  final bool isGift;
  final Color color;
  final Color contentColor;

  SpinSegment({required this.text, required this.isGift, required this.color, required this.contentColor});
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
      
      // Draw Border
      final borderPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawArc(rect, i * anglePerSegment, anglePerSegment, true, borderPaint);

      // Draw Content (Text/Icon)
      canvas.save();
      // Rotate to center of segment
      double rotationAngle = i * anglePerSegment + anglePerSegment / 2;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationAngle);
      canvas.translate(radius * 0.65, 0); // Move out to text position

      if (segments[i].isGift) {
        // Draw Gift Icon
        final icon = Icons.card_giftcard;
        TextSpan span = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 32,
            fontFamily: icon.fontFamily,
            color: segments[i].contentColor,
            fontWeight: FontWeight.bold
          ),
        );
        textPainter.text = span;
        textPainter.layout();
        // Rotate text to be upright or radial? Radial 90 deg usually looks best if text, but icon upright relative to center.
        // Let's keep it radial.
         canvas.rotate(math.pi / 2); // Rotate to face outward
         textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      } else {
        // Draw Text "No Luck"
        // Multiline?
        TextSpan span = TextSpan(
          text: "No\nLuck",
          style: TextStyle(
            fontSize: 14,
            color: segments[i].contentColor,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        );
        textPainter.text = span;
        textPainter.textAlign = TextAlign.center;
        textPainter.layout();
         canvas.rotate(math.pi / 2);
         textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      }
      
      canvas.restore();
    }
    
    // Outer Border
    paint
      ..color = AppColors.primaryText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
