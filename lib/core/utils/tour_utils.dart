import 'dart:math' as math;

import '../../models/map_location.dart';

/// Categorías de ubicación que sí llevan etiqueta en su flecha (entradas y
/// baños); pasillos y esquinas solo muestran la flecha.
const Set<String> kImportantTourCategories = {'Entrada', 'Baños H', 'Baños M'};

bool isImportantTourStop(MapLocation loc) => kImportantTourCategories.contains(loc.category);

/// Zoom mínimo permitido (alejar) para poder encuadrar las esquinas.
const double kTourMinZoom = 0.5;

/// Normaliza un ángulo (grados) a [-180, 180].
double normalizeYaw(double a) {
  a = a % 360;
  if (a > 180) a -= 360;
  return a;
}

/// Orientación con la que se llega a [target] viniendo de [fromId].
///
/// - Pasillo (el siguiente tramo sigue más o menos recto): la vista mira
///   recto, en la misma dirección en que se caminaba (opuesta al enlace de
///   regreso).
/// - Esquina (exactamente dos enlaces que forman menos de 120°): la vista mira hacia la
///   bisectriz entre ambos pasillos y se aleja lo necesario, según la
///   proporción [aspect] (ancho/alto) de la pantalla, para que se vean los
///   dos hotspots.
({double yaw, double zoom}) arrivalView(MapLocation target, String fromId, double aspect) {
  HotspotLink? back;
  final others = <HotspotLink>[];
  for (final link in target.hotspotLinks) {
    if (link.targetId == fromId) {
      back = link;
    } else {
      others.add(link);
    }
  }
  if (back == null) return (yaw: 0, zoom: 1.0);

  final straight = normalizeYaw(back.yaw + 180);
  if (others.isEmpty) return (yaw: straight, zoom: 1.0);

  // Solo las esquinas (exactamente dos pasillos); los cruces con ramales,
  // como P2 hacia el laboratorio, siguen recto.
  if (target.hotspotLinks.length != 2) return (yaw: straight, zoom: 1.0);

  final next = others.first;
  final arc = normalizeYaw(next.yaw - back.yaw); // ángulo entre los dos pasillos
  if (arc.abs() >= 120) return (yaw: straight, zoom: 1.0);

  // Esquina: encuadrar ambos pasillos (con margen para el botón del hotspot).
  final mid = normalizeYaw(back.yaw + arc / 2);
  final half = arc.abs() / 2 + 14;
  final fit = math.tan(37.5 * math.pi / 180) * aspect / math.tan(half * math.pi / 180);
  return (yaw: mid, zoom: fit.clamp(kTourMinZoom, 1.0));
}
