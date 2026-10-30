/// Enlace entre una ubicación del recorrido 360° que es un laboratorio y los
/// datos que se muestran en sus ventanas flotantes.
class TourLabRef {
  /// Id de la ubicación del mapa que contiene el laboratorio (p. ej. 'LT_MAP').
  final String locationId;

  /// Nombre del laboratorio en `LabInfo` (encargado, descripción, foto).
  final String labName;

  /// Nombre del laboratorio en los horarios (`LabSchedule.labName`).
  final String scheduleName;

  /// Rumbo (grados) de la pared donde se coloca la ventana de información. Al
  /// entrar al laboratorio la vista queda mirando hacia ahí.
  final double wallYaw;

  /// Altura (grados) del centro de la ventana sobre la pared.
  final double wallPitch;

  const TourLabRef({
    required this.locationId,
    required this.labName,
    required this.scheduleName,
    this.wallYaw = 0,
    this.wallPitch = 0,
  });
}

/// Ubicaciones del recorrido (por id) que son laboratorios. Para sumar uno
/// nuevo (LE, LR...) basta con añadir su ubicación al recorrido y registrarlo
/// aquí; sus datos se editan en `MapProvider` y `DefaultSchedules`.
const Map<String, TourLabRef> kTourLabs = {
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
};
