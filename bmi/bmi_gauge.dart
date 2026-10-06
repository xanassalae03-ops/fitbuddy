import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'bmi_colors.dart';

class GaugeZone {
  final double from;
  final double to;
  final Color color;
  const GaugeZone(this.from, this.to, this.color);
}

class BmiGaugePainter extends CustomPainter {
  final double bmi;
  final bool isDarkMode;

  static const double min = 15;
  static const double max = 40;
  static const List<GaugeZone> _zones = [
    GaugeZone(15, 18.5, BmiColors.underweight),
    GaugeZone(18.5, 23, BmiColors.normal),
    GaugeZone(23, 25, BmiColors.overweight),
    GaugeZone(25, 30, BmiColors.obese),
    GaugeZone(30, 40, BmiColors.veryObese),
  ];

  BmiGaugePainter(this.bmi, {required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 20.0;
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (final zone in _zones) {
      final startFrac = (zone.from - min) / (max - min);
      final endFrac = (zone.to - min) / (max - min);
      final startAngle = math.pi + startFrac * math.pi;
      final sweep = (endFrac - startFrac) * math.pi;
      final paint = Paint()
        ..color = zone.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
    }

    final clamped = bmi.clamp(min, max);
    final f = (clamped - min) / (max - min);
    final angle = math.pi + f * math.pi;
    final needleLength = radius - strokeWidth / 2 - 4;
    final tip = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );

    final needleColor = isDarkMode ? BmiColors.inkDark : BmiColors.inkLight;

    final needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant BmiGaugePainter oldDelegate) =>
      oldDelegate.bmi != bmi || oldDelegate.isDarkMode != isDarkMode;
}

class AnimatedBmiGauge extends StatefulWidget {
  final double targetBmi;
  final bool isDarkMode;
  const AnimatedBmiGauge({super.key, required this.targetBmi, required this.isDarkMode});

  @override
  State<AnimatedBmiGauge> createState() => _AnimatedBmiGaugeState();
}

class _AnimatedBmiGaugeState extends State<AnimatedBmiGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 15.0, end: widget.targetBmi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: 240,
          height: 130,
          child: CustomPaint(painter: BmiGaugePainter(_animation.value, isDarkMode: widget.isDarkMode)),
        );
      },
    );
  }
}