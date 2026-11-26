import '../models/room.dart';
import 'building_outlines.dart' show kShortNames;

/// Salones con acceso directo en 360°, por edificio.
///
/// PROPUESTA PARA UD2: los números y plantas de abajo son de ejemplo. Al tener
/// las fotos, ajusta la lista al edificio real y llena `pano` con la ruta de
/// cada panorama (`assets/ud2/salon_07.jpg`). Mientras `pano` sea null el
/// salón aparece como "foto pendiente". Guía completa en
/// docs/GUIA_RECORRIDOS.md, sección "Salones con acceso directo".
const List<Room> kRooms = [
  // ---------- UD2 · Planta baja ----------
  Room(id: 'UD2-01', buildingId: 'UD2', label: '1', name: 'Salón 1', floor: 'PB'),
  Room(id: 'UD2-02', buildingId: 'UD2', label: '2', name: 'Salón 2', floor: 'PB'),
  Room(id: 'UD2-03', buildingId: 'UD2', label: '3', name: 'Salón 3', floor: 'PB'),
  Room(id: 'UD2-04', buildingId: 'UD2', label: '4', name: 'Salón 4', floor: 'PB'),
  Room(id: 'UD2-05', buildingId: 'UD2', label: '5', name: 'Salón 5', floor: 'PB'),
  Room(id: 'UD2-06', buildingId: 'UD2', label: '6', name: 'Salón 6', floor: 'PB'),
  Room(
    id: 'UD2-MOVILES',
    buildingId: 'UD2',
    label: 'Móviles',
    name: 'Laboratorio de Tecnologías Móviles',
    floor: 'PB',
    kind: RoomKind.laboratorio,
    pano: 'assets/moviles.jpg',
    aliases: ['lab moviles', 'laboratorio moviles'],
  ),
  // ---------- UD2 · Planta alta ----------
  Room(id: 'UD2-07', buildingId: 'UD2', label: '7', name: 'Salón 7', floor: 'PA'),
  Room(id: 'UD2-08', buildingId: 'UD2', label: '8', name: 'Salón 8', floor: 'PA'),
  Room(id: 'UD2-09', buildingId: 'UD2', label: '9', name: 'Salón 9', floor: 'PA'),
  Room(id: 'UD2-10', buildingId: 'UD2', label: '10', name: 'Salón 10', floor: 'PA'),
  Room(id: 'UD2-11', buildingId: 'UD2', label: '11', name: 'Salón 11', floor: 'PA'),
  Room(id: 'UD2-12', buildingId: 'UD2', label: '12', name: 'Salón 12', floor: 'PA'),
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
