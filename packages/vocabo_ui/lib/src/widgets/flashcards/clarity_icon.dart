import 'dart:math' as math;

import 'package:flutter/material.dart';

enum Clarity { blank, fuzzy, clear }

/// Circle that fills up with how clearly a word was remembered: dashed and
/// empty for blank, half filled for fuzzy, solid for clear.
class ClarityIcon extends StatelessWidget {
  const ClarityIcon({
    super.key,
    required this.clarity,
    required this.color,
    this.size = 18,
  });

  final Clarity clarity;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ClarityPainter(clarity, color)),
    );
  }
}

class _ClarityPainter extends CustomPainter {
  _ClarityPainter(this.clarity, this.color);

  final Clarity clarity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.11;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;

    switch (clarity) {
      case Clarity.blank:
        const dashes = 8;
        const sweep = 2 * math.pi / dashes;
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(rect, i * sweep, sweep * 0.55, false, outline);
        }
      case Clarity.fuzzy:
        canvas.drawCircle(center, radius, outline);
        canvas.drawArc(rect, math.pi / 2, math.pi, true, fill);
      case Clarity.clear:
        canvas.drawCircle(center, radius + stroke / 2, fill);
    }
  }

  @override
  bool shouldRepaint(_ClarityPainter oldDelegate) =>
      oldDelegate.clarity != clarity || oldDelegate.color != color;
}
