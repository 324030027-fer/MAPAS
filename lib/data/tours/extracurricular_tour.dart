import '../../models/tour.dart';

/// Vista 360° del edificio de talleres extracurriculares (una sola foto, por
/// fuera). Cuando haya fotos de los talleres, agrégalas como paradas.
final Tour extracurricularTour = Tour(
  id: 'extracurricular',
  title: 'Extracurricular',
  shortName: 'EXTRACURRICULAR',
  subtitle: 'Talleres de deporte, arte, cultura y salud',
  coverAsset: 'assets/extracurricular.jpg',
  badge: 'VISTA 360°',
  startId: 'EXT',
  mapLocationId: 'EXTRACURRICULAR',
  stops: const [
    TourStop('EXT', 'Edificio Extracurricular', 'Entrada', 'assets/extracurricular.jpg'),
  ],
  edges: const [],
);
