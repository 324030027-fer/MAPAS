import 'package:flutter/material.dart';

/// Tipos de zona de un plano, con su color e icono.
enum ZoneKind {
  biblioteca(Color(0xFF2E9BFF), Icons.local_library, 'Biblioteca'),
  administrativo(Color(0xFF2ECC71), Icons.badge_outlined, 'Administrativo'),
  cubiculos(Color(0xFFE74C3C), Icons.meeting_room_outlined, 'Cubículos'),
  banos(Color(0xFF5B5BFF), Icons.wc, 'Baños'),
  salon(Color(0xFFFF8C00), Icons.class_outlined, 'Salón'),
  pendiente(Color(0xFF9E9E9E), Icons.hourglass_empty, 'Por definir');

  const ZoneKind(this.color, this.icon, this.label);
  final Color color;
  final IconData icon;
  final String label;
}

/// Una zona del plano. [rect] va en FRACCIONES (0..1) del rectángulo que
/// encierra la silueta del edificio: (0,0) esquina sup. izquierda, (1,1) la
/// inferior derecha. Lo que no cubre ninguna zona se ve como pasillo.
class FloorZone {
  const FloorZone(this.name, this.kind, this.rect, {this.detail, this.pin, this.guide});

  /// Guía relacionada (texto del botón → ruta), p. ej. trámites de la oficina.
  final (String, String)? guide;
  final String name;
  final ZoneKind kind;
  final Rect rect;
  final String? detail;

  /// Dónde va el indicador (fracciones del edificio). Por defecto, el centro
  /// de la zona; útil para separar indicadores de zonas vecinas.
  final Offset? pin;
  Offset get pinPoint => pin ?? rect.center;
}

class Floor {
  const Floor(this.label, this.name, this.zones);
  final String label; // corto, para el selector: PB, PA
  final String name;
  final List<FloorZone> zones;
}

/// id del edificio → plantas (la primera es la que se muestra al entrar).
const Map<String, List<Floor>> kFloorPlans = {
  'RECTORIA': [
    Floor('PB', 'Planta baja', [
      FloorZone('Biblioteca', ZoneKind.biblioteca, Rect.fromLTRB(0.24, 0.0, 1.0, 0.44),
          detail: 'Acervo, área digital y préstamo de material'),
      FloorZone('Control Escolar', ZoneKind.administrativo, Rect.fromLTRB(0.13, 0.56, 0.34, 1.0),
          detail: 'Trámites, constancias e inscripciones', pin: Offset(0.24, 0.62),
          guide: ('Cómo pedir una constancia', '/constancias')),
      FloorZone('Baños', ZoneKind.banos, Rect.fromLTRB(0.0, 0.56, 0.13, 1.0), pin: Offset(0.08, 0.86)),
      FloorZone('Cubículos', ZoneKind.cubiculos, Rect.fromLTRB(0.36, 0.7, 0.80, 1.0),
          detail: 'Área de Sistemas y otras áreas · incluye el cuarto de TI y baños'),
    ]),
    Floor('PA', 'Planta alta', [
      FloorZone('Salones por definir', ZoneKind.pendiente, Rect.fromLTRB(0.05, 0.05, 0.95, 0.95),
          detail: 'Falta el orden de los salones de la planta alta'),
    ]),
  ],
  // UD1 y UD2: dos plantas, con los baños en el mismo lugar en ambas.
  'UD1': [
    Floor('PB', 'Planta baja', [
      FloorZone('Baños', ZoneKind.banos, Rect.fromLTRB(0.33, 0.5, 0.41, 0.62), detail: '2 baños'),
      FloorZone('Salones por definir', ZoneKind.pendiente, Rect.fromLTRB(0.55, 0.3, 0.85, 0.7)),
    ]),
    Floor('PA', 'Planta alta', [
      FloorZone('Baños', ZoneKind.banos, Rect.fromLTRB(0.33, 0.5, 0.41, 0.62), detail: '2 baños'),
      FloorZone('Salones por definir', ZoneKind.pendiente, Rect.fromLTRB(0.55, 0.3, 0.85, 0.7)),
    ]),
  ],
  'UD2': [
    Floor('PB', 'Planta baja', [
      FloorZone('Baños', ZoneKind.banos, Rect.fromLTRB(0.63, 0.48, 0.71, 0.60), detail: '2 baños'),
      FloorZone('Salones por definir', ZoneKind.pendiente, Rect.fromLTRB(0.1, 0.45, 0.3, 0.65)),
    ]),
    Floor('PA', 'Planta alta', [
      FloorZone('Baños', ZoneKind.banos, Rect.fromLTRB(0.63, 0.48, 0.71, 0.60), detail: '2 baños'),
      FloorZone('Salones por definir', ZoneKind.pendiente, Rect.fromLTRB(0.1, 0.45, 0.3, 0.65)),
    ]),
  ],
};
