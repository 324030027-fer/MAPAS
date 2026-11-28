import 'package:flutter/material.dart';

/// Tipo de espacio dentro de un edificio.
enum RoomKind {
  salon('Salón', Icons.class_outlined),
  laboratorio('Laboratorio', Icons.science_outlined),
  computo('Sala de cómputo', Icons.computer_outlined),
  otro('Espacio', Icons.meeting_room_outlined);

  const RoomKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Un salón (o laboratorio, sala…) al que se puede entrar directo en 360°,
/// sin recorrer el edificio desde la entrada.
///
/// Se declaran en `lib/data/rooms.dart`. Ver la guía en
/// `docs/GUIA_RECORRIDOS.md` (sección "Salones con acceso directo").
class Room {
  const Room({
    required this.id,
    required this.buildingId,
    required this.label,
    required this.name,
    this.floor = '',
    this.kind = RoomKind.salon,
    this.pano,
    this.initialYaw = 0,
    this.tagPitch = 4,
    this.tourStopId,
    this.aliases = const [],
  });

  /// Único en toda la app, p. ej. `UD2-07`.
  final String id;

  /// Id del edificio en el mapa (`MapLocation.id`), p. ej. `UD2`.
  final String buildingId;

  /// Texto corto del botón: el número (`7`) o un nombre breve (`Móviles`).
  final String label;

  /// Nombre completo: `Salón 7`, `Laboratorio de Móviles`.
  final String name;

  /// Planta, con la misma etiqueta que `kFloorPlans` (`PB`, `PA`). Vacío si
  /// el edificio tiene una sola planta.
  final String floor;

  final RoomKind kind;

  /// Panorama 360° (equirectangular 2:1). Null mientras no hay foto: el botón
  /// se muestra como "pendiente".
  final String? pano;

  /// Rumbo (grados, −180 a 180) hacia donde se mira al entrar; conviene que
  /// sea el pizarrón o el frente del salón.
  final double initialYaw;

  /// Altura (grados) del recuadro flotante del salón: a media puerta.
  /// El recuadro se coloca en [initialYaw] a esta altura.
  final double tagPitch;

  /// Si el salón también es parada del recorrido del edificio, su id ahí:
  /// se entra al recorrido en ese punto y se puede seguir caminando.
  final String? tourStopId;

  /// Otras formas de buscarlo: `aula 7`, `S7`, `móviles`.
  final List<String> aliases;

  bool get has360 => pano != null && pano!.isNotEmpty;

  /// Es un número (salón numerado): se dibuja como botón cuadrado.
  bool get isNumbered => int.tryParse(label) != null;
}

/// Nombre de cada planta para encabezados.
String floorName(String floor) => switch (floor) {
      'PB' => 'Planta baja',
      'PA' => 'Planta alta',
      'P1' => 'Primer piso',
      'P2' => 'Segundo piso',
      _ => floor,
    };
