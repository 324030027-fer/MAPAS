import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Color color;
  final int divisions;

  GridPainter({required this.color, required this.divisions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double cellWidth = size.width / divisions;
    final double cellHeight = size.height / divisions;

    // Dibujar líneas verticales
    for (int i = 1; i < divisions; i++) {
      double x = cellWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Dibujar líneas horizontales
    for (int i = 1; i < divisions; i++) {
      double y = cellHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dibujar borde exterior
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.divisions != divisions;
  }
}