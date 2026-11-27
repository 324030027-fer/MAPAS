import '../models/room.dart';
import 'building_outlines.dart' show kShortNames;

/// Salones con acceso directo en 360°, por edificio.
///
/// Varias aulas comparten la foto del pasillo frente a sus puertas: cada una
/// abre esa foto mirando a SU puerta ([Room.initialYaw]) y dentro del
/// recorrido del edificio ([Room.tourStopId]), así se puede seguir caminando.
/// Los rumbos se midieron en cada panorama (yaw = x / ancho · 360 − 180).
/// Guía: docs/GUIA_RECORRIDOS.md, sección "Salones con acceso directo".
const List<Room> kRooms = [
  // ---------- UD2 · Planta baja ----------
  Room(id: 'UD2-03', buildingId: 'UD2', label: '3', name: 'Aula 3', floor: 'PB',
      pano: 'assets/ud2/a4a3a22.jpg', initialYaw: -150, tourStopId: 'A4322', aliases: ['puerta abierta']),
  Room(id: 'UD2-04', buildingId: 'UD2', label: '4', name: 'Aula 4', floor: 'PB',
      pano: 'assets/ud2/a4a3a22.jpg', initialYaw: -10, tourStopId: 'A4322', aliases: ['puerta 7']),
  Room(id: 'UD2-05', buildingId: 'UD2', label: '5', name: 'Aula 5', floor: 'PB',
      pano: 'assets/ud2/a5y6.jpg', initialYaw: -25, tourStopId: 'A56'),
  Room(id: 'UD2-06', buildingId: 'UD2', label: '6', name: 'Aula 6', floor: 'PB',
      pano: 'assets/ud2/a5y6.jpg', initialYaw: 25, tourStopId: 'A56'),
  Room(id: 'UD2-07', buildingId: 'UD2', label: '7', name: 'Aula 7', floor: 'PB',
      pano: 'assets/ud2/a7.jpg', initialYaw: 5, tourStopId: 'A7'),
  Room(id: 'UD2-22', buildingId: 'UD2', label: '22', name: 'Aula 22', floor: 'PB',
      pano: 'assets/ud2/a4a3a22.jpg', initialYaw: -175, tourStopId: 'A4322', aliases: ['puerta 12']),
  Room(
    id: 'UD2-IDIOMAS',
    buildingId: 'UD2',
    label: 'Idiomas',
    name: 'Centro de Idiomas',
    floor: 'PB',
    kind: RoomKind.otro,
    pano: 'assets/ud2/id1.jpg',
    tourStopId: 'ID1',
    aliases: ['ingles', 'idiomas', 'centro de idiomas'],
  ),
  Room(
    id: 'UD2-MOVILES',
    buildingId: 'UD2',
    label: 'Móviles',
    name: 'Laboratorio de Tecnologías Móviles',
    floor: 'PB',
    kind: RoomKind.laboratorio,
    pano: 'assets/moviles.jpg',
    tourStopId: 'MOV',
    aliases: ['lab moviles', 'laboratorio moviles', 'puerta 29'],
  ),
  // ---------- UD2 · Planta alta ----------
  Room(id: 'UD2-10', buildingId: 'UD2', label: '10', name: 'Aula 10', floor: 'PA',
      pano: 'assets/ud2/a11a10a23.jpg', initialYaw: 140, tourStopId: 'A111023', aliases: ['puerta 34']),
  Room(id: 'UD2-11', buildingId: 'UD2', label: '11', name: 'Aula 11', floor: 'PA',
      pano: 'assets/ud2/a11a10a23.jpg', initialYaw: -30, tourStopId: 'A111023', aliases: ['puerta 39']),
  Room(id: 'UD2-12', buildingId: 'UD2', label: '12', name: 'Aula 12', floor: 'PA',
      pano: 'assets/ud2/a12ya13.jpg', initialYaw: -20, tourStopId: 'A1213', aliases: ['puerta 38']),
  Room(id: 'UD2-13', buildingId: 'UD2', label: '13', name: 'Aula 13', floor: 'PA',
      pano: 'assets/ud2/a12ya13.jpg', initialYaw: 25, tourStopId: 'A1213', aliases: ['puerta 37']),
  // Sin foto todavía.
  Room(id: 'UD2-14', buildingId: 'UD2', label: '14', name: 'Aula 14', floor: 'PA'),
  Room(id: 'UD2-17', buildingId: 'UD2', label: '17', name: 'Aula 17', floor: 'PA',
      pano: 'assets/ud2/a17ya18.jpg', initialYaw: 120, tourStopId: 'A1718', aliases: ['puerta 44']),
  Room(id: 'UD2-18', buildingId: 'UD2', label: '18', name: 'Aula 18', floor: 'PA',
      pano: 'assets/ud2/a17ya18.jpg', initialYaw: -100, tourStopId: 'A1718', aliases: ['puerta 58']),
  Room(id: 'UD2-19', buildingId: 'UD2', label: '19', name: 'Aula 19', floor: 'PA',
      pano: 'assets/ud2/a19y20.jpg', initialYaw: -15, tourStopId: 'A1920', aliases: ['puerta 57']),
  Room(id: 'UD2-20', buildingId: 'UD2', label: '20', name: 'Aula 20', floor: 'PA',
      pano: 'assets/ud2/a19y20.jpg', initialYaw: 20, tourStopId: 'A1920', aliases: ['puerta 56']),
  Room(id: 'UD2-21', buildingId: 'UD2', label: '21', name: 'Aula 21', floor: 'PA',
      pano: 'assets/ud2/a21cn.jpg', initialYaw: 5, tourStopId: 'A21CN', aliases: ['puerta 55']),
  Room(id: 'UD2-23', buildingId: 'UD2', label: '23', name: 'Aula 23', floor: 'PA',
      pano: 'assets/ud2/a11a10a23.jpg', initialYaw: -175, tourStopId: 'A111023', aliases: ['puerta 35']),
  Room(
    id: 'UD2-NEGOCIOS',
    buildingId: 'UD2',
    label: 'Negocios',
    name: 'Laboratorio Centro de Negocios',
    floor: 'PA',
    kind: RoomKind.laboratorio,
    pano: 'assets/ud2/a21cn.jpg',
    initialYaw: 40,
    tourStopId: 'A21CN',
    aliases: ['centro de negocios', 'cn', 'puerta 54', 'ifi', 'lag'],
  ),
];

/// Salones de un edificio, en el orden en que se declararon.
List<Room> roomsOf(String buildingId) => [for (final r in kRooms) if (r.buildingId == buildingId) r];

/// Edificios que tienen salones (en orden de aparición).
List<String> buildingsWithRooms() => {for (final r in kRooms) r.buildingId}.toList();

/// Quita acentos y pasa a minúsculas para comparar.
String normalize(String s) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ';
  const to = 'aeiouunaeiouun';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    b.write(i == -1 ? ch : to[i]);
  }
  return b.toString().toLowerCase();
}

/// Busca salones por número o nombre: `7`, `salon 7`, `ud2 7`, `moviles`.
///
/// Los números deben coincidir completos (`7` no encuentra el `17`). Primero
/// van las coincidencias exactas con el número del salón.
List<Room> searchRooms(String query, {String? buildingId, Iterable<Room>? from}) {
  final tokens = normalize(query)
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .split(' ')
      .where((t) => t.isNotEmpty)
      // Palabras de relleno que no ayudan a distinguir.
      .where((t) => !const {'salon', 'aula', 'de', 'el', 'la', 'lab', 'laboratorio'}.contains(t))
      .toList();
  final pool = (from ?? kRooms).where((r) => buildingId == null || r.buildingId == buildingId);
  if (tokens.isEmpty) {
    // Solo escribieron "salón" o "lab": se ofrecen todos (filtrados por tipo).
    final q = normalize(query);
    if (q.contains('lab')) return pool.where((r) => r.kind == RoomKind.laboratorio).toList();
    if (q.contains('salon') || q.contains('aula')) return pool.where((r) => r.kind == RoomKind.salon).toList();
    return const [];
  }

  final scored = <(Room, int)>[];
  for (final r in pool) {
    final building = normalize('${r.buildingId} ${kShortNames[r.buildingId] ?? ''}');
    final words = normalize('${r.label} ${r.name} ${r.kind.label} ${r.aliases.join(' ')} $building')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toSet();
    var ok = true;
    for (final t in tokens) {
      final numeric = int.tryParse(t) != null;
      final hit = numeric ? words.contains(t) : words.any((w) => w.startsWith(t));
      if (!hit) {
        ok = false;
        break;
      }
    }
    if (!ok) continue;
    final exact = tokens.any((t) => t == normalize(r.label));
    scored.add((r, exact ? 0 : 1));
  }
  scored.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final s in scored) s.$1];
}
