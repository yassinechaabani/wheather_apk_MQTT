import 'package:flutter/material.dart';
import 'dart:math' as math;

class WeatherGauge extends StatelessWidget {
  final double value;
  final String title;
  final String unit;
  final double minValue;
  final double maxValue;
  final IconData icon;
  final Color color;

  const WeatherGauge({
    Key? key,
    required this.value,
    required this.title,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: _GaugePainter(
              value: value,
              minValue: minValue,
              maxValue: maxValue,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final Color color;

  _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      backgroundPaint,
    );

    // Draw value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final normalizedValue = (value - minValue) / (maxValue - minValue);
    final sweepAngle = math.pi * 1.5 * normalizedValue;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      math.pi * 0.75,
      sweepAngle,
      false,
      valuePaint,
    );

    // Draw center circle
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color;
  }
}
