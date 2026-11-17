import 'dart:ui' show Offset, Rect;

/// Siluetas de los edificios y zonas del campus sobre `assets/mapa_base.jpg`.
///
/// Los puntos se escriben en PÍXELES de la imagen original (1024 x 962), que
/// es lo más fácil de medir en un editor de imágenes. El mapa se muestra
/// recortado a un cuadrado (se pierden 31 px a cada lado), así que [_p] los
/// convierte a las coordenadas normalizadas 0..1 que usan los pines.
Offset _p(double px, double py) => Offset((px - 31) / 962, py / 962);

/// id de la ubicación → contorno (polígono) del edificio o zona.
/// Una ubicación con contorno se dibuja como silueta tocable en vez de pin.
final Map<String, List<Offset>> kBuildingOutlines = {
  // Un solo edificio: la Biblioteca es una zona de su planta baja.
  'RECTORIA': [_p(35, 250), _p(150, 250), _p(150, 395), _p(35, 395)],
  'CANCHA': [_p(314, 235), _p(396, 237), _p(395, 345), _p(313, 343)],
  'CAFETERIA': [
    _p(565, 272), _p(642, 272), _p(642, 316), _p(656, 316), _p(656, 408),
    _p(600, 408), _p(600, 364), _p(545, 364), _p(545, 320), _p(565, 320),
  ],
  'LT_MAP': [
    _p(727, 120), _p(869, 120), _p(869, 288), _p(874, 312), _p(874, 372),
    _p(708, 372), _p(708, 310), _p(727, 288),
  ],
  'UD1': [
    _p(722, 462), _p(915, 470), _p(952, 505), _p(952, 555), _p(918, 598),
    _p(722, 588), _p(698, 548), _p(698, 512),
  ],
  'UD2': [
    _p(118, 828), _p(208, 785), _p(268, 812), _p(342, 828), _p(372, 868),
    _p(296, 912), _p(240, 882), _p(130, 866),
  ],
  'CANCHA_FUTBOL': [_p(360, 474), _p(476, 477), _p(473, 646), _p(357, 643)],
  'ESTACIONAMIENTO_ALUMNOS': [
    _p(535, 4), _p(722, 4), _p(714, 266), _p(690, 272), _p(522, 244), _p(522, 40),
  ],
};

/// Nombre corto que se muestra discretamente sobre cada silueta en la vista
/// general (sin él se usa el título de la ubicación).
const Map<String, String> kShortNames = {
  'RECTORIA': 'Rectoría · Biblioteca',
  'CANCHA': 'Cancha',
  'CAFETERIA': 'Cafetería',
  'LT_MAP': 'LT',
  'UD1': 'UD1',
  'UD2': 'UD2',
  'CANCHA_FUTBOL': 'Futbol',
  'ESTACIONAMIENTO_ALUMNOS': 'Estacionamiento',
};

/// Puntos que viven DENTRO de un edificio (baños, salones…): solo se muestran
/// al entrar al edificio, o al filtrar/buscar.
const Map<String, String> kInteriorParent = {
  'BIBLIOTECA': 'RECTORIA',
  'BANOS_RECTORIA': 'RECTORIA',
  'BANOS_CAFETERIA': 'CAFETERIA',
  'BANOS_LT': 'LT_MAP',
  'BANOS_UD1': 'UD1',
  'BANOS_UD2': 'UD2',
};

Rect outlineBounds(List<Offset> pts) {
  var l = pts.first.dx, r = l, t = pts.first.dy, b = t;
  for (final p in pts) {
    if (p.dx < l) l = p.dx;
    if (p.dx > r) r = p.dx;
    if (p.dy < t) t = p.dy;
    if (p.dy > b) b = p.dy;
  }
  return Rect.fromLTRB(l, t, r, b);
}

/// Punto dentro del polígono (ray casting). Coordenadas normalizadas.
bool outlineContains(List<Offset> pts, Offset q) {
  var inside = false;
  for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    final a = pts[i], b = pts[j];
    if ((a.dy > q.dy) != (b.dy > q.dy) &&
        q.dx < (b.dx - a.dx) * (q.dy - a.dy) / (b.dy - a.dy) + a.dx) {
      inside = !inside;
    }
  }
  return inside;
}
