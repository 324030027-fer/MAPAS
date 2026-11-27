import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/room.dart';

/// Altura (grados bajo el horizonte) a la que se colocan las flechas del
/// recorrido: sobre el piso del pasillo, para no ocupar el centro de la vista.
const double kTourArrowPitch = -22;

/// Altura por defecto (grados) del recuadro de un salón: a media puerta.
const double kRoomTagPitch = 4;

/// Tamaño del hotspot que aloja a [RoomDoorTag].
const double kRoomTagWidth = 210;
const double kRoomTagHeight = 92;

/// Inclinación (radianes) con la que la flecha "se recuesta" sobre el piso.
const double _kFloorTilt = 0.55;

/// Flecha del recorrido: disco ámbar sólido con chevrón oscuro, borde blanco
/// y sombra, para que resalte sobre pisos claros y oscuros. Late suavemente
/// para invitar a tocarla. Con [label] muestra el destino en una pastilla
/// oscura legible sobre cualquier fondo.
///
/// [selected] la resalta en el editor de flechas (admin).
class TourArrow extends StatefulWidget {
  final String? label;
  final VoidCallback onTap;
  final bool selected;

  const TourArrow({super.key, required this.onTap, this.label, this.selected = false});

  @override
  State<TourArrow> createState() => _TourArrowState();
}

class _TourArrowState extends State<TourArrow> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  bool _down = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = widget.selected ? const Color(0xFF4FC3F7) : Colors.white;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      behavior: HitTestBehavior.opaque,
      child: Align(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_pulse.value);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateX(_kFloorTilt)
                    ..translateByDouble(0.0, -4 * t, 0.0, 1.0)
                    ..scaleByDouble(_down ? 0.9 : 1 + 0.05 * t, _down ? 0.9 : 1 + 0.05 * t, 1.0, 1.0),
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent,
                      border: Border.all(color: ring, width: widget.selected ? 4 : 3),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 10, offset: const Offset(0, 4)),
                        BoxShadow(
                          color: (widget.selected ? ring : AppColors.accent).withValues(alpha: 0.35 + 0.35 * t),
                          blurRadius: 18 + 10 * t,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.onAccent, size: 54),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xE61B2230),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.8)),
                ),
                child: Text(
                  widget.label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Recuadro flotante junto a la puerta de un salón: dice qué salón es.
/// El salón elegido va en ámbar con su "puntero"; los vecinos, discretos.
class RoomDoorTag extends StatelessWidget {
  const RoomDoorTag({
    super.key,
    required this.room,
    required this.selected,
    required this.onTap,
    this.editing = false,
  });

  final Room room;
  final bool selected;
  final bool editing;
  final VoidCallback onTap;

  String get _door {
    final door = room.aliases.where((a) => a.startsWith('puerta ')).firstOrNull;
    final floor = floorName(room.floor);
    return [if (door != null) 'Puerta ${door.substring(7)}', if (room.floor.isNotEmpty) floor].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.accent : const Color(0xE61B2230);
    final fg = selected ? AppColors.onAccent : Colors.white;
    final sub = selected ? AppColors.onAccent.withValues(alpha: 0.75) : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: editing ? const Color(0xFF4FC3F7) : Colors.white.withValues(alpha: selected ? 0.9 : 0.45),
                  width: editing ? 2.5 : 1.5,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(room.kind.icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fg, fontSize: 13.5, fontWeight: FontWeight.w900),
                        ),
                        if (_door.isNotEmpty)
                          Text(_door, maxLines: 1, style: TextStyle(color: sub, fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Puntero hacia la puerta.
            CustomPaint(size: const Size(16, 9), painter: _PointerPainter(bg)),
          ],
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
