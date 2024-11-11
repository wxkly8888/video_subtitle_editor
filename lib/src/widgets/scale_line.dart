import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScalePainter extends CustomPainter {
  final int tickCount;

  ScalePainter({
    required this.tickCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define the paint properties for the scale line
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw the horizontal scale line
    canvas.drawLine(
      Offset(0, size.height), // Start point
      Offset(size.width, size.height), // End point
      paint,
    );

    // Define the number of tick marks and their spacing
    double tickSpacing = size.width / (tickCount * 2);

    for (int i = 0; i <= 2 * tickCount; i++) {
      double xPosition = i * tickSpacing;
      double tickHeight =
          (i % 2 == 0) ? 10.0 : 5.0; // Make the first tick mark longer
      if (i % 2 == 0) {
        TextSpan span = TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 10.0),
          text: Duration(seconds: i ~/ 2)
              .toString()
              .split('.')
              .first
              .substring(2)
              .padLeft(5, '0'),
        );
        TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        //calculate text span width
        tp.layout();
        tp.paint(canvas, Offset(xPosition - tp.width / 2, size.height - 22));
      }
      // Draw the tick marks
      canvas.drawLine(
        Offset(xPosition, size.height - tickHeight),
        Offset(xPosition, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
