import 'dart:ui';

import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  bool isVisible;
  DashedLinePainter(this.isVisible);
  @override
  void paint(Canvas canvas, Size size) {
    if (!isVisible) return;
    final paint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashWidth = 5;
    final dashSpace = 5;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Bottom line
    double bottomY = size.height;
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, bottomY),
        Offset(startX + dashWidth, bottomY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Left line
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Right line
    double rightX = size.width;
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(rightX, startY),
        Offset(rightX, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => false;
}

class DashedLineWidget extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  const DashedLineWidget(
      {super.key, required this.child, this.isVisible = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedLinePainter(isVisible),
      child: child,
    );
  }
}
