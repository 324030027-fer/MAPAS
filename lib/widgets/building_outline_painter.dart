import 'package:flutter/material.dart';

/// Dibuja las siluetas de los edificios con un brillo que "respira" para que
/// se lean como botones sin tapar la foto del mapa.
class BuildingOutlinePainter extends CustomPainter {
  BuildingOutlinePainter({
    required this.outlines,
    required this.pulse,
    required this.color,
    required this.highlightColor,
    required this.scale,
    this.hoverId,
    this.focusId,
    this.glow = 1.0,
    this.highlightAll = false,
  }) : super(repaint: pulse);

  /// Resalta todas las siluetas (p. ej. al filtrar por categoría).
  final bool highlightAll;

  /// Intensidad del brillo en reposo (1 = normal). En modo claro se baja
  /// para que el contorno no se vea deslumbrante sobre la foto.
  final double glow;

  final Map<String, List<Offset>> outlines; // normalizadas 0..1
  final Animation<double> pulse; // 0..1..0
  final Color color;
  final Color highlightColor;
  final double scale; // zoom actual, para mantener el grosor en pantalla
  final String? hoverId;
  final String? focusId;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(pulse.value);
    for (final e in outlines.entries) {
      final path = Path()..addPolygon(e.value.map((o) => Offset(o.dx * size.width, o.dy * size.height)).toList(), true);
      final active = highlightAll || e.key == hoverId || e.key == focusId;
      final c = active ? highlightColor : color;

      // Relleno muy tenue: deja ver el techo del edificio.
      canvas.drawPath(path, Paint()..color = c.withValues(alpha: active ? 0.22 : (0.05 + 0.09 * t) * glow));
      // Halo difuso que parpadea.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (active ? 7 : (4 + 4 * t) * glow) / scale
          ..color = c.withValues(alpha: active ? 0.7 : (0.25 + 0.4 * t) * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 / scale),
      );
      // Borde nítido.
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = (active ? 2.2 : 1.4) / scale
          ..color = c.withValues(alpha: active ? 0.95 : (0.55 + 0.35 * t) * (0.4 + 0.6 * glow)),
      );
    }
  }

  @override
  bool shouldRepaint(BuildingOutlinePainter old) =>
      old.outlines != outlines || old.scale != scale || old.hoverId != hoverId ||
      old.focusId != focusId || old.color != color || old.glow != glow || old.highlightAll != highlightAll;
}
