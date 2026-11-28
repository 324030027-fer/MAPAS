import 'package:flutter_test/flutter_test.dart';
import 'package:nullcore_maps/data/academic_calendar.dart';
import 'package:nullcore_maps/data/rooms.dart';
import 'package:nullcore_maps/models/contact.dart';
import 'package:nullcore_maps/providers/map_provider.dart';

void main() {
  group('salones', () {
    test('ids únicos y en edificios que existen en el mapa', () {
      final ids = kRooms.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
      final buildings = MapProvider(syncWithFirestore: false).mapPoints.map((l) => l.id).toSet();
      for (final r in kRooms) {
        expect(buildings, contains(r.buildingId), reason: '${r.id} apunta a ${r.buildingId}');
      }
    });

    test('"7" encuentra el salón 7 y no el 17', () {
      final hits = searchRooms('7');
      expect(hits.first.id, 'UD2-07');
      expect(hits.where((r) => r.label == '17'), isEmpty);
    });

    test('acepta "salón 7", "ud2 7" y nombres sin acentos', () {
      expect(searchRooms('salón 7').first.id, 'UD2-07');
      expect(searchRooms('UD2 7').first.id, 'UD2-07');
      expect(searchRooms('moviles').first.id, 'UD2-MOVILES');
      expect(searchRooms('ud1 7'), isEmpty);
    });
  });

  group('calendario 2026', () {
    test('cuatrimestres y semana como en la columna SEM', () {
      final t = AcademicCalendar.termOf(DateTime(2026, 11, 25))!;
      expect(t.name, 'Septiembre – Diciembre');
      expect(t.weekOf(DateTime(2026, 11, 25)), 13);
      expect(t.totalWeeks, 15);
      expect(AcademicCalendar.termOf(DateTime(2026, 8, 25)), isNull); // entre cuatrimestres
    });

    test('eventos ordenados por fecha y dentro del año', () {
      for (final e in AcademicCalendar.events) {
        expect(e.start.year, 2026);
        expect(e.end.isBefore(e.start), isFalse, reason: e.label);
      }
      final next = AcademicCalendar.upcoming(DateTime(2026, 11, 25));
      expect(next.first.type, CalendarEventType.reporteCalificaciones); // 30 nov
    });

    test('16 de septiembre es asueto', () {
      expect(AcademicCalendar.on(DateTime(2026, 9, 16)).single.type, CalendarEventType.asueto);
    });
  });

  test('profesores sin clase quedan "Por asignar"', () {
    expect(Contact.fromMap('x', {'name': 'A'}).group, TeacherGroup.porAsignar);
    expect(Contact.fromMap('x', {'name': 'A', 'group': 'ingles'}).group, TeacherGroup.ingles);
  });
}
