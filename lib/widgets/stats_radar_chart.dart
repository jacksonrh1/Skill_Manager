import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/skill.dart';

class StatsRadarChart extends StatelessWidget {
  const StatsRadarChart({
    super.key,
    required this.skills,
  });

  final List<Skill> skills;

  @override
  Widget build(BuildContext context) {
    final chartSkills = skills.take(6).toList();
    if (chartSkills.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: Text('Add skills to see your stats.'),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: CustomPaint(
        painter: _RadarChartPainter(
          chartSkills,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
        child: Container(),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter(
    this.skills, {
    required this.isDark,
  });

  final List<Skill> skills;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 16);
    final radius = math.min(size.width, size.height) * 0.28;
    final step = (math.pi * 2) / skills.length;

    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF334058) : const Color(0xFFE7EAF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = isDark ? const Color(0xFF43506B) : const Color(0xFFD6DDEB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = const Color(0xFFFF956A).withValues(alpha: 0.54)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFF8A5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var ring = 1; ring <= 4; ring++) {
      final ringPath = Path();
      final ringRadius = radius * (ring / 4);
      for (var i = 0; i < skills.length; i++) {
        final point = _pointFor(i, center, ringRadius, step);
        if (i == 0) {
          ringPath.moveTo(point.dx, point.dy);
        } else {
          ringPath.lineTo(point.dx, point.dy);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }

    for (var i = 0; i < skills.length; i++) {
      final point = _pointFor(i, center, radius, step);
      canvas.drawLine(center, point, axisPaint);
      canvas.drawCircle(
        point,
        2.5,
        Paint()..color = isDark ? const Color(0xFF7080A4) : const Color(0xFFB7C2D8),
      );
    }

    final dataPath = Path();
    for (var i = 0; i < skills.length; i++) {
      final point = _pointFor(i, center, radius * skills[i].progress, step);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    for (var i = 0; i < skills.length; i++) {
      final labelPoint = _pointFor(i, center, radius + 34, step);
      final painter = TextPainter(
        text: TextSpan(
          text: _wrapLabel(skills[i].title),
          style: TextStyle(
            color: isDark ? const Color(0xFF9FAACA) : const Color(0xFF73829C),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 86);

      painter.paint(
        canvas,
        Offset(
          labelPoint.dx - painter.width / 2,
          labelPoint.dy - painter.height / 2,
        ),
      );
    }
  }

  Offset _pointFor(int index, Offset center, double radius, double step) {
    final angle = (-math.pi / 2) + (index * step);
    return Offset(
      center.dx + (radius * math.cos(angle)),
      center.dy + (radius * math.sin(angle)),
    );
  }

  String _wrapLabel(String value) {
    final parts = value.split(' ');
    if (parts.length < 2) {
      return value;
    }
    final midpoint = (parts.length / 2).ceil();
    return '${parts.take(midpoint).join(' ')}\n${parts.skip(midpoint).join(' ')}';
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.skills != skills;
  }
}
