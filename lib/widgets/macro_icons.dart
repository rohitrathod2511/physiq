import 'package:flutter/material.dart';
import 'dart:math' as math;

class FishIcon extends StatelessWidget {
  final Color color;
  final double size;
  const FishIcon({super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FishPainter(color),
    );
  }
}

class WheatIcon extends StatelessWidget {
  final Color color;
  final double size;
  const WheatIcon({super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WheatPainter(color),
    );
  }
}

class AvocadoIcon extends StatelessWidget {
  final Color color;
  final double size;
  const AvocadoIcon({super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AvocadoPainter(color),
    );
  }
}

class _FishPainter extends CustomPainter {
  final Color color;
  _FishPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final w = size.width;
    final h = size.height;
    
    // Scale down slightly and center
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.scale(0.85); 
    canvas.translate(-w / 2, -h / 2);

    final path = Path();
    
    // Main body (lens shape)
    path.moveTo(w * 0.1, h * 0.5); // Snout
    path.quadraticBezierTo(w * 0.4, h * 0.1, w * 0.8, h * 0.5); // Top curve
    path.quadraticBezierTo(w * 0.4, h * 0.9, w * 0.1, h * 0.5); // Bottom curve
    
    // Tail
    final tailPath = Path();
    tailPath.moveTo(w * 0.75, h * 0.5);
    tailPath.lineTo(w * 0.95, h * 0.2); // Top tip
    tailPath.lineTo(w * 0.9, h * 0.5);  // Middle indent
    tailPath.lineTo(w * 0.95, h * 0.8); // Bottom tip
    tailPath.close();
    
    path.addPath(tailPath, Offset.zero);
    
    // Fins
    final topFin = Path();
    topFin.moveTo(w * 0.35, h * 0.23);
    topFin.quadraticBezierTo(w * 0.45, h * 0.05, w * 0.55, h * 0.15); // Fin shape
    topFin.close();
    path.addPath(topFin, Offset.zero);

    final bottomFin = Path();
    bottomFin.moveTo(w * 0.35, h * 0.77);
    bottomFin.quadraticBezierTo(w * 0.45, h * 0.95, w * 0.55, h * 0.85); // Fin shape
    bottomFin.close();
    path.addPath(bottomFin, Offset.zero);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WheatPainter extends CustomPainter {
  final Color color;
  _WheatPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final paintStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(math.pi / 4); 
    canvas.translate(-w / 2, -h / 2);

    // Stem
    final path = Path();
    path.moveTo(w * 0.5, h * 0.9);
    path.lineTo(w * 0.5, h * 0.2);
    canvas.drawPath(path, paintStroke);

    // Grains (Leaves)
    void drawGrain(double x, double y, double angle) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      final grainPath = Path();
      grainPath.moveTo(0, -h * 0.12);
      grainPath.quadraticBezierTo(w * 0.1, 0, 0, h * 0.05);
      grainPath.quadraticBezierTo(-w * 0.1, 0, 0, -h * 0.12);
      canvas.drawPath(grainPath, paint);
      canvas.restore();
    }

    drawGrain(w * 0.35, h * 0.6, -math.pi / 6);
    drawGrain(w * 0.65, h * 0.5, math.pi / 6);
    drawGrain(w * 0.35, h * 0.4, -math.pi / 6);
    drawGrain(w * 0.65, h * 0.3, math.pi / 6);
    drawGrain(w * 0.35, h * 0.2, -math.pi / 6);
    drawGrain(w * 0.65, h * 0.1, math.pi / 6);
    
    // Top grain
    drawGrain(w * 0.5, h * 0.05, 0); 
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AvocadoPainter extends CustomPainter {
  final Color color;
  _AvocadoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Avocado leaning left
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6); 
    canvas.translate(-size.width / 2, -size.height / 2);

    final w = size.width;
    final h = size.height;

    final path = Path();
    // Body: narrower at top, wider at bottom
    path.moveTo(w * 0.5, h * 0.25);
    path.cubicTo(
      w * 0.9, h * 0.3,
      w * 0.9, h * 0.85, 
      w * 0.5, h * 0.85
    );
    path.cubicTo(
      w * 0.1, h * 0.85,
      w * 0.1, h * 0.3, 
      w * 0.5, h * 0.25
    );
    path.close();

    // The pit cutout
    final pitPath = Path();
    pitPath.addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.6), radius: w * 0.15));
    
    // Combine with difference to make pit transparent
    var finalPath = Path.combine(PathOperation.difference, path, pitPath);

    // Leaf
    final leafPath = Path();
    leafPath.moveTo(w * 0.5, h * 0.25);
    leafPath.quadraticBezierTo(w * 0.7, h * 0.1, w * 0.65, h * 0.05); // shape
    leafPath.quadraticBezierTo(w * 0.45, h * 0.1, w * 0.5, h * 0.25); // shape

    finalPath = Path.combine(PathOperation.union, finalPath, leafPath);

    canvas.drawPath(finalPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
