import 'package:flutter/material.dart';

/// Tipos de zona de un plano, con su color e icono.
enum ZoneKind {
  biblioteca(Color(0xFF2E9BFF), Icons.local_library, 'Biblioteca'),
  administrativo(Color(0xFF2ECC71), Icons.badge_outlined, 'Administrativo'),
  cubiculos(Color(0xFFE74C3C), Icons.meeting_room_outlined, 'Cubículos'),
  banos(Color(0xFF5B5BFF), Icons.wc, 'Baños'),
  salon(Color(0xFFE8A33D), Icons.class_outlined, 'Salón'),
  laboratorio(Color(0xFF8DBF6A), Icons.science_outlined, 'Laboratorio'),
  escaleras(Color(0xFF8E96A8), Icons.stairs_outlined, 'Escaleras'),
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
  const FloorZone(this.name, this.kind, this.rect, {this.detail, this.pin, this.guide, this.roomId, this.label});

  /// Texto corto bajo el indicador en el mapa (por defecto, [name]). Sirve
  /// para que zonas vecinas no se encimen: "5 · 6" en vez de "Aulas 5 y 6".
  final String? label;

  /// Salón de `kRooms` que se abre en 360° desde esta zona.
  final String? roomId;

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
  // UD2: posiciones tomadas de los planos marcados (fracciones del contorno),
  // en zigzag para que los indicadores y sus etiquetas no se encimen.
  'UD2': [
    Floor('PB', 'Planta baja', [
      FloorZone('Lab. de Tecnologías Móviles', ZoneKind.laboratorio, Rect.fromLTRB(0.06, 0.30, 0.16, 0.42),
          pin: Offset(0.10, 0.37), label: 'Móviles', roomId: 'UD2-MOVILES'),
      FloorZone('Centro de Idiomas', ZoneKind.salon, Rect.fromLTRB(0.20, 0.25, 0.29, 0.36),
          pin: Offset(0.25, 0.29), label: 'Idiomas', roomId: 'UD2-IDIOMAS'),
      FloorZone('Vestíbulo', ZoneKind.administrativo, Rect.fromLTRB(0.46, 0.40, 0.55, 0.52),
          pin: Offset(0.50, 0.45), detail: 'Entrada principal y escaleras'),
      FloorZone('Baños', ZoneKind.banos, Rect.fromLTRB(0.60, 0.46, 0.67, 0.55), pin: Offset(0.63, 0.49), detail: '2 baños'),
      FloorZone('Aulas 3, 4 y 22', ZoneKind.salon, Rect.fromLTRB(0.68, 0.58, 0.75, 0.68),
          pin: Offset(0.71, 0.64), label: '3 · 4 · 22', roomId: 'UD2-04'),
      FloorZone('Aulas 5 y 6', ZoneKind.salon, Rect.fromLTRB(0.77, 0.50, 0.84, 0.60),
          pin: Offset(0.80, 0.54), label: '5 · 6', roomId: 'UD2-05'),
      FloorZone('Aula 7', ZoneKind.salon, Rect.fromLTRB(0.85, 0.61, 0.92, 0.71), pin: Offset(0.88, 0.66), label: '7', roomId: 'UD2-07'),
    ]),
    Floor('PA', 'Planta alta', [
      FloorZone('Aula 21 · Centro de Negocios', ZoneKind.laboratorio, Rect.fromLTRB(0.06, 0.31, 0.15, 0.42),
          pin: Offset(0.10, 0.37), label: '21 · CN', roomId: 'UD2-21'),
      FloorZone('Aulas 19 y 20', ZoneKind.salon, Rect.fromLTRB(0.20, 0.25, 0.29, 0.35),
          pin: Offset(0.24, 0.29), label: '19 · 20', roomId: 'UD2-19'),
      FloorZone('Aulas 17 y 18', ZoneKind.salon, Rect.fromLTRB(0.32, 0.36, 0.41, 0.46),
          pin: Offset(0.36, 0.41), label: '17 · 18', roomId: 'UD2-17'),
      FloorZone('Escaleras', ZoneKind.escaleras, Rect.fromLTRB(0.44, 0.48, 0.52, 0.58), pin: Offset(0.48, 0.53)),
      FloorZone('Baños', ZoneKind.banos, Rect.fromLTRB(0.59, 0.46, 0.66, 0.55), pin: Offset(0.62, 0.49), detail: '2 baños'),
      FloorZone('Aulas 10, 11 y 23', ZoneKind.salon, Rect.fromLTRB(0.66, 0.59, 0.73, 0.69),
          pin: Offset(0.69, 0.64), label: '10 · 11 · 23', roomId: 'UD2-11'),
      FloorZone('Aulas 12 y 13', ZoneKind.salon, Rect.fromLTRB(0.76, 0.50, 0.83, 0.60),
          pin: Offset(0.79, 0.54), label: '12 · 13', roomId: 'UD2-12'),
      FloorZone('Aula 14', ZoneKind.salon, Rect.fromLTRB(0.85, 0.61, 0.92, 0.71), pin: Offset(0.88, 0.66), label: '14', roomId: 'UD2-14'),
    ]),
  ],
};
