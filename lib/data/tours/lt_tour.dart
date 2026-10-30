import '../../models/tour.dart';

/// Recorrido 360° del edificio de laboratorios (LT).
///
/// Orden (perímetro del edificio, en un solo sentido). Derecha/Izquierda se
/// ven desde la entrada trasera: el ala izquierda del mapa (E2, P1, P3) baja
/// hasta BH, pasa por la entrada principal (EP) y sube por el ala derecha
/// (BM, P4, P2 con acceso a los laboratorios) hasta E3:
///
///   E1 → E2 → P1 → P3 → BH → EP → BM → P4 → P2 → E3 → E1
final Tour ltTour = Tour(
  id: 'lt',
  title: 'Recorrido LT',
  shortName: 'LT',
  subtitle: 'Entradas · Pasillos · Laboratorios',
  coverAsset: 'assets/E1.jpg',
  startId: 'E1',
  mapLocationId: 'LT_MAP',
  stops: const [
    TourStop('E1', 'Entrada Trasera', 'Entrada', 'assets/E1.jpg'),
    TourStop('E2', 'Esquina Derecha', 'Esquina', 'assets/E2.jpg'),
    TourStop('P1', 'Pasillo 1', 'Pasillo', 'assets/P1.jpg'),
    TourStop('P3', 'Pasillo Central', 'Pasillo', 'assets/P3.jpg'),
    TourStop('BH', 'Baños Hombres', 'Baños H', 'assets/S2.jpg'),
    TourStop('EP', 'Entrada Principal', 'Entrada', 'assets/S1.jpg'),
    TourStop('BM', 'Baños Mujeres', 'Baños M', 'assets/S3.jpg'),
    TourStop('P4', 'Pasillo 4', 'Pasillo', 'assets/P4.jpg'),
    TourStop('P2', 'Pasillo 2', 'Pasillo', 'assets/P2.jpg'),
    TourStop('E3', 'Esquina Izquierda', 'Esquina', 'assets/E3.jpg'),
    // Interiores de laboratorios
    TourStop('LT', 'LAB TELEMATICA', 'Edificio', 'assets/pano_telematica.jpg'),
    TourStop('LE', 'LAB ELECTRONICA', 'Edificio', 'assets/pano_electronica.jpg'),
  ],
  edges: const [
    // (A, rumbo en A hacia B, B, rumbo en B hacia A)
    TourEdge('E1', 93, 'E2', -45),
    TourEdge('E2', 45, 'P1', -85),
    TourEdge('P1', 140, 'P3', 180),
    TourEdge('P3', 0, 'BH', -55),
    TourEdge('BH', 37, 'EP', -85),
    TourEdge('EP', 90, 'BM', -45),
    TourEdge('BM', 45, 'P4', -90),
    TourEdge('P4', 90, 'P2', -90),
    TourEdge('P2', 90, 'E3', -45),
    TourEdge('E3', 42, 'E1', -87),
    // Ramales a laboratorios (siempre al final de los enlaces del pasillo).
    TourEdge('P2', -110, 'LT', -45),
    // Puerta del laboratorio de Electrónica en Pasillo 4 (≈ -70°); en su
    // panorama la salida está en ≈ 18°.
    TourEdge('P4', -70, 'LE', 18),
  ],
  labs: const {
    'LT': TourLabRef(
      locationId: 'LT_MAP',
      labName: 'LAB. DE TELEMÁTICA',
      scheduleName: 'Telemática',
      // Pared lisa del fondo del salón (≈131° a ≈234° en el panorama).
      wallYaw: 180,
      wallPitch: 6,
    ),
    'LE': TourLabRef(
      locationId: 'LT_MAP',
      labName: 'LAB. DE ELECTRÓNICA',
      scheduleName: 'Electrónica',
      // Pared con ventanas del lado derecho del salón (≈ 72° a 150°).
      wallYaw: 110,
      wallPitch: 8,
    ),
  },
);
