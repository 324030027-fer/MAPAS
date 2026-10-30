import 'map_location.dart';

/// Parada de un recorrido 360°: una panorámica con nombre y categoría.
///
/// Las categorías `Entrada`, `Baños H` y `Baños M` muestran su nombre en la
/// flecha que lleva hasta ellas; `Pasillo`, `Esquina` y demás solo la flecha.
class TourStop {
  final String id;
  final String title;
  final String category;

  /// Ruta del panorama (equirectangular 2:1), p. ej. `assets/E1.jpg`.
  final String asset;

  const TourStop(this.id, this.title, this.category, this.asset);
}

/// Tramo entre dos paradas, declarado una sola vez.
///
/// [yawA] es el rumbo (grados, de −180 a 180) dentro del panorama de [a] que
/// apunta hacia [b]; [yawB] es el rumbo dentro del panorama de [b] hacia [a].
/// El hotspot de ida y el de vuelta se generan juntos.
///
/// Rumbo de un punto del panorama: `yaw = x / ancho * 360 − 180`.
class TourEdge {
  final String a;
  final double yawA;
  final String b;
  final double yawB;

  const TourEdge(this.a, this.yawA, this.b, this.yawB);
}

/// Enlace entre una parada del recorrido que es un laboratorio y los datos de
/// sus ventanas flotantes.
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

/// Recorrido 360° de un edificio: paradas, tramos y laboratorios.
///
/// Los ids de las paradas solo necesitan ser únicos dentro de cada recorrido.
class Tour {
  final String id;
  final String title;

  /// Nombre corto para botones (p. ej. 'LT').
  final String shortName;
  final String subtitle;
  final String badge;

  /// Imagen de la tarjeta de la pestaña Recorridos.
  final String coverAsset;

  /// Parada donde empieza el recorrido.
  final String startId;

  /// Ubicación del mapa (edificio) a la que pertenece, para el botón
  /// "Iniciar recorrido" de su hoja de detalle.
  final String? mapLocationId;

  final List<TourStop> stops;
  final List<TourEdge> edges;

  /// Paradas que son laboratorios (id de la parada → datos).
  final Map<String, TourLabRef> labs;

  Tour({
    required this.id,
    required this.title,
    required this.shortName,
    required this.subtitle,
    required this.coverAsset,
    required this.startId,
    required this.stops,
    required this.edges,
    this.badge = 'COMPLETO',
    this.mapLocationId,
    this.labs = const {},
  });

  /// Recorrido de una sola panorámica, sin enlaces (p. ej. el 360° de un
  /// laboratorio abierto desde su lista).
  factory Tour.single({required String title, required String asset}) {
    return Tour(
      id: 'single',
      title: title,
      shortName: title,
      subtitle: '',
      coverAsset: asset,
      startId: 'start',
      stops: [TourStop('start', title, 'Edificio', asset)],
      edges: const [],
    );
  }

  late final Map<String, MapLocation> _byId = _build();

  Map<String, MapLocation> _build() {
    final links = <String, List<HotspotLink>>{};
    for (final e in edges) {
      (links[e.a] ??= []).add(HotspotLink(targetId: e.b, yaw: e.yawA));
      (links[e.b] ??= []).add(HotspotLink(targetId: e.a, yaw: e.yawB));
    }
    return {
      for (final s in stops)
        s.id: MapLocation(
          id: s.id,
          title: s.title,
          description: '',
          category: s.category,
          x: 0,
          y: 0,
          assetImage360: s.asset,
          hotspotLinks: links[s.id] ?? const [],
        ),
    };
  }

  /// Parada por id. Si no existe devuelve la inicial.
  MapLocation stop(String id) => _byId[id] ?? _byId[startId]!;

  MapLocation get start => stop(startId);

  /// Revisa que el recorrido esté bien armado y devuelve los problemas
  /// encontrados (vacío si todo está bien). Lo usa la prueba automática.
  List<String> validate() {
    final problems = <String>[];
    final ids = <String>{};
    for (final s in stops) {
      if (!ids.add(s.id)) problems.add('Parada repetida: ${s.id}');
      if (s.asset.isEmpty) problems.add('Parada ${s.id} sin panorama');
    }
    if (!ids.contains(startId)) problems.add('La parada inicial "$startId" no existe');

    final pairs = <String>{};
    final adjacent = <String, Set<String>>{};
    for (final e in edges) {
      if (!ids.contains(e.a)) problems.add('Tramo con parada inexistente: ${e.a}');
      if (!ids.contains(e.b)) problems.add('Tramo con parada inexistente: ${e.b}');
      if (e.a == e.b) problems.add('Tramo de ${e.a} consigo misma');
      final key = ([e.a, e.b]..sort()).join('|');
      if (!pairs.add(key)) problems.add('Tramo repetido: ${e.a} - ${e.b}');
      (adjacent[e.a] ??= {}).add(e.b);
      (adjacent[e.b] ??= {}).add(e.a);
    }

    for (final labId in labs.keys) {
      if (!ids.contains(labId)) problems.add('Laboratorio en parada inexistente: $labId');
    }

    // Todas las paradas deben poder alcanzarse desde la inicial.
    if (ids.contains(startId)) {
      final seen = <String>{startId};
      final pending = [startId];
      while (pending.isNotEmpty) {
        for (final next in adjacent[pending.removeLast()] ?? const <String>{}) {
          if (seen.add(next)) pending.add(next);
        }
      }
      for (final id in ids.difference(seen)) {
        problems.add('La parada $id no se alcanza desde $startId');
      }
    }
    return problems;
  }
}
