import '../../models/tour.dart';

/// Recorrido 360° de la Unidad de Docencia 2 (UD2), planta baja y alta.
///
/// Rumbos medidos en cada panorama (yaw = x / ancho · 360 − 180).
///
/// Planta baja:
///   U2 (entrada) → CU (vestíbulo) → AUD → ID1 (idiomas) → MvF → Lab. Móviles
///   CU → ES1 (escaleras) → ES2 (planta alta)
///   CU ⇢ A4322 → A56 → A7 → U1 (entrada este)
///
/// Planta alta:
///   ES2 → A1718 → A1920 → A21CN
///   ES2 ⇢ A111023 → A1213
///
/// ⇢ = tramo PROVISIONAL: faltan las fotos de "a#ya#" + WC (planta baja) y
/// "u#u#" + WC (planta alta). Cuando lleguen, inserta esas paradas entre los
/// extremos y borra el tramo directo. Falta también Aula 14 (después de A1213).
final Tour ud2Tour = Tour(
  id: 'ud2',
  title: 'Recorrido UD2',
  shortName: 'UD2',
  subtitle: 'Planta baja y alta · Aulas · Laboratorios',
  coverAsset: 'assets/ud2/cu.jpg',
  startId: 'U2',
  mapLocationId: 'UD2',
  stops: const [
    // Planta baja
    TourStop('U2', 'Entrada principal UD2', 'Entrada', 'assets/ud2/u2.jpg'),
    TourStop('CU', 'Vestíbulo central', 'Pasillo', 'assets/ud2/cu.jpg'),
    TourStop('AUD', 'Pasillo oeste', 'Pasillo', 'assets/ud2/aud.jpg'),
    TourStop('ID1', 'Centro de Idiomas', 'Edificio', 'assets/ud2/id1.jpg'),
    TourStop('MvF', 'Pasillo Lab. Móviles', 'Pasillo', 'assets/ud2/mvf.jpg'),
    TourStop('MOV', 'LAB. DE TECNOLOGÍAS MÓVILES', 'Edificio', 'assets/moviles.jpg'),
    TourStop('A4322', 'Aulas 3, 4 y 22', 'Pasillo', 'assets/ud2/a4a3a22.jpg'),
    TourStop('A56', 'Aulas 5 y 6', 'Pasillo', 'assets/ud2/a5y6.jpg'),
    TourStop('A7', 'Aula 7', 'Pasillo', 'assets/ud2/a7.jpg'),
    TourStop('U1', 'Entrada este', 'Entrada', 'assets/ud2/u1.jpg'),
    TourStop('ES1', 'Escaleras', 'Escaleras', 'assets/ud2/es1.jpg'),
    // Planta alta
    TourStop('ES2', 'Planta alta', 'Escaleras', 'assets/ud2/es2.jpg'),
    TourStop('A1718', 'Aulas 17 y 18', 'Pasillo', 'assets/ud2/a17ya18.jpg'),
    TourStop('A1920', 'Aulas 19 y 20', 'Pasillo', 'assets/ud2/a19y20.jpg'),
    TourStop('A21CN', 'Aula 21 · Centro de Negocios', 'Pasillo', 'assets/ud2/a21cn.jpg'),
    TourStop('A111023', 'Aulas 10, 11 y 23', 'Pasillo', 'assets/ud2/a11a10a23.jpg'),
    TourStop('A1213', 'Aulas 12 y 13', 'Pasillo', 'assets/ud2/a12ya13.jpg'),
  ],
  edges: const [
    // (A, rumbo en A hacia B, B, rumbo en B hacia A)
    TourEdge('U2', 174.8, 'CU', -82.5),
    TourEdge('CU', 136.8, 'AUD', 96),
    TourEdge('AUD', -98.6, 'ID1', 120.7),
    TourEdge('ID1', 42.7, 'MvF', -79.3),
    TourEdge('CU', 104.3, 'ES1', -15.1),
    TourEdge('ES1', 34.6, 'ES2', -175),
    // Provisional (falta a#ya# y WC).
    TourEdge('CU', 71.4, 'A4322', -55),
    TourEdge('A4322', 101.3, 'A56', -84.6),
    TourEdge('A56', 80, 'A7', -86.6),
    TourEdge('A7', 91.1, 'U1', 0),
    TourEdge('ES2', -84.2, 'A1718', -155.5),
    TourEdge('A1718', 19.7, 'A1920', -79.2),
    TourEdge('A1920', 83.1, 'A21CN', -53.1),
    // Provisional (falta u#u# y WC de planta alta).
    TourEdge('ES2', 92.5, 'A111023', -75),
    TourEdge('A111023', 80.5, 'A1213', -81.2),
    // Ramal al laboratorio (al final de los enlaces del pasillo).
    TourEdge('MvF', -2.7, 'MOV', -45.3),
  ],
  labs: const {
    'MOV': TourLabRef(
      locationId: 'UD2',
      labName: 'LAB. DE TECNOLOGÍAS MÓVILES',
      // Pared del pizarrón, al frente del salón.
      wallYaw: 0,
      wallPitch: 6,
    ),
  },
);
