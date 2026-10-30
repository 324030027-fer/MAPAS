import '../../models/tour.dart';
import 'lt_tour.dart';

/// Todos los recorridos de la app, en el orden en que aparecen en la pestaña
/// Recorridos. Para sumar un edificio: crea su archivo `<edificio>_tour.dart`
/// y agrégalo aquí (ver docs/GUIA_RECORRIDOS.md).
final List<Tour> kTours = [
  ltTour,
];

/// Recorrido del edificio con id de ubicación [mapLocationId] (null si aún no
/// tiene recorrido).
Tour? tourForMapLocation(String mapLocationId) {
  for (final tour in kTours) {
    if (tour.mapLocationId == mapLocationId) return tour;
  }
  return null;
}
